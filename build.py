#!/usr/bin/env python3
"""
GDLQBot Build Tool
------------------
Packages modules (.gdmod), and bundles (.gdpck).
Libraries live inside their bundle's libraries/ subfolder — there is no top-level libraries/ dir.

Usage:
  py build.py                              build everything
  py build.py level-queue                  build one package by id
  py build.py --validate                   validate only, no output files
  py build.py --bump patch                 bump version + build all
  py build.py level-queue --bump minor     bump version for one package
  py build.py --since v1.2.0              only build packages changed since tag
  py build.py --publish <url> <token>      build + push to marketplace
  py build.py --publish <url> <token> --download-base <cdn-url>  publish with external download URLs
  py build.py --github-repo owner/repo     embed GitHub source info in catalog entries
  py build.py level-queue --watch          build then rebuild on any file change (dev mode)
  py build.py level-queue --dev-install /path/to/app/modules
                                           copy module source into a running app's modules dir
"""

import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import time
import zipfile
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional

ROOT     = Path(__file__).parent
DIST     = ROOT / "dist"
MODULES  = ROOT / "modules"
PACKAGES = ROOT / "packages"

GREEN  = "\033[92m"
YELLOW = "\033[93m"
RED    = "\033[91m"
CYAN   = "\033[96m"
RESET  = "\033[0m"
BOLD   = "\033[1m"

def ok(msg):    print(f"  {GREEN}ok{RESET}   {msg}")
def warn(msg):  print(f"  {YELLOW}warn{RESET} {msg}")
def err(msg):   print(f"  {RED}ERR{RESET}  {msg}")
def head(msg):  print(f"\n{BOLD}{CYAN}{msg}{RESET}")


# ── Git helpers ───────────────────────────────────────────────────────────────

def git_short_sha() -> str:
    try:
        return subprocess.check_output(
            ["git", "rev-parse", "--short", "HEAD"], cwd=ROOT, stderr=subprocess.DEVNULL
        ).decode().strip()
    except Exception:
        return "unknown"

def git_changed_since(tag: str) -> set[str]:
    try:
        out = subprocess.check_output(
            ["git", "diff", "--name-only", tag, "HEAD"], cwd=ROOT, stderr=subprocess.DEVNULL
        ).decode().strip()
    except Exception:
        return set()
    changed = set()
    for line in out.splitlines():
        parts = line.split("/")
        if len(parts) >= 2 and parts[0] in ("modules", "packages"):
            changed.add(parts[1])
    return changed


# ── Validation ────────────────────────────────────────────────────────────────

MODULE_REQUIRED  = ["id", "name", "version", "min_app_version", "description", "scripts"]
PACKAGE_REQUIRED = ["id", "name", "version", "author", "description", "package_type"]

def validate_semver(v: str, field: str) -> list[str]:
    parts = v.split(".")
    if len(parts) != 3 or not all(p.isdigit() for p in parts):
        return [f'{field} "{v}" is not valid semver (expected x.y.z)']
    return []

def _read_manifest(path: Path) -> tuple[dict, list[str]]:
    if not path.exists():
        return {}, [f"manifest.json not found at {path}"]
    try:
        return json.loads(path.read_text(encoding="utf-8")), []
    except json.JSONDecodeError as e:
        return {}, [f"manifest.json is invalid JSON: {e}"]

def validate_module(pkg_dir: Path) -> tuple[dict, list[str]]:
    m, errors = _read_manifest(pkg_dir / "manifest.json")
    if errors: return m, errors
    missing = [k for k in MODULE_REQUIRED if k not in m]
    if missing: errors.append(f"Missing required fields: {', '.join(missing)}")
    for field in ("version", "min_app_version"):
        if field in m: errors.extend(validate_semver(m[field], field))
    if "scripts" in m:
        for key, rel_path in m["scripts"].items():
            if not (pkg_dir / rel_path).exists():
                errors.append(f'Script "{key}" -> "{rel_path}" not found')
    for page in m.get("pages", []):
        page_file = page.get("file", "")
        if not page_file:
            errors.append(f'Page "{page.get("id", "?")}" is missing a "file" field')
        elif not (pkg_dir / page_file).exists():
            errors.append(f'Page "{page.get("id", "?")}" -> "{page_file}" not found')
    if "settings_page" in m and not (pkg_dir / m["settings_page"]).exists():
        errors.append(f'settings_page "{m["settings_page"]}" not found')
    for lib_def in m.get("bundle", {}).get("libraries", []):
        lib_file = lib_def.get("file", "")
        if lib_file and not (pkg_dir / lib_file).exists():
            errors.append(f'Bundled library "{lib_def.get("name", "?")}" -> "{lib_file}" not found')
    return m, errors

def validate_bundle(pkg_dir: Path) -> tuple[dict, list[str]]:
    m, errors = _read_manifest(pkg_dir / "manifest.json")
    if errors: return m, errors
    missing = [k for k in PACKAGE_REQUIRED if k not in m]
    if missing: errors.append(f"Missing required fields: {', '.join(missing)}")
    if "package_type" in m and m["package_type"] != "package":
        errors.append(f'package_type must be "package", got "{m["package_type"]}"')
    if "version" in m: errors.extend(validate_semver(m["version"], "version"))

    total = (len(m.get("libraries", [])) + len(m.get("modules", [])) + len(m.get("packages", [])))
    if total == 0:
        errors.append("Bundle must contain at least one library, module, or nested package")

    # Libraries live inside the package dir
    for lib_id in m.get("libraries", []):
        lib_dir = pkg_dir / "libraries" / lib_id
        if not lib_dir.is_dir() or not (lib_dir / "manifest.json").exists():
            errors.append(f'Library "{lib_id}" not found at {lib_dir.relative_to(ROOT)}')
    for mod_id in m.get("modules", []):
        mod_dir = MODULES / mod_id
        if not mod_dir.is_dir() or not (mod_dir / "manifest.json").exists():
            errors.append(f'Module "{mod_id}" not found in modules/')
    for pkg_id in m.get("packages", []):
        nested = PACKAGES / pkg_id
        if not nested.is_dir() or not (nested / "manifest.json").exists():
            errors.append(f'Nested package "{pkg_id}" not found in packages/')
    return m, errors


# ── Version bump ──────────────────────────────────────────────────────────────

def bump_semver(version: str, part: str) -> str:
    major, minor, patch = map(int, version.split("."))
    if part == "major":   major += 1; minor = 0; patch = 0
    elif part == "minor": minor += 1; patch = 0
    else:                 patch += 1
    return f"{major}.{minor}.{patch}"

def apply_version_bump(manifest_path: Path, part: str) -> str:
    text = manifest_path.read_text(encoding="utf-8")
    m = json.loads(text)
    new_ver = bump_semver(m["version"], part)
    text = re.sub(
        r'("version"\s*:\s*)"[^"]+"',
        lambda mo: f'{mo.group(0).split(":")[0]}: "{new_ver}"',
        text, count=1,
    )
    manifest_path.write_text(text, encoding="utf-8")
    return new_ver


# ── Build metadata ────────────────────────────────────────────────────────────

def build_meta(manifest: dict, pkg_type: str) -> dict:
    return {
        "built_at":   datetime.now(timezone.utc).isoformat(),
        "git_sha":    git_short_sha(),
        "package_id": manifest["id"],
        "version":    manifest["version"],
        "type":       pkg_type,
    }


# ── Checksums ─────────────────────────────────────────────────────────────────

def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


# ── Output path helpers ───────────────────────────────────────────────────────

def out_dir(pkg_id: str, version: str) -> Path:
    """Returns dist/<pkg_id>/<version>/ and ensures it exists."""
    d = DIST / pkg_id / version
    d.mkdir(parents=True, exist_ok=True)
    return d


# ── Packaging ─────────────────────────────────────────────────────────────────

def _add_dir_to_zip(zf: zipfile.ZipFile, src: Path, arc_prefix: str):
    """Recursively add all files in src to the zip under arc_prefix/."""
    if not src.is_dir():
        return
    for f in sorted(src.rglob("*")):
        if f.is_file():
            zf.write(f, f"{arc_prefix}/{f.relative_to(src)}")


def package_module(pkg_dir: Path, manifest: dict) -> Path:
    ver = manifest["version"]
    out = out_dir(manifest["id"], ver) / f"{manifest['id']}-{ver}.gdmod"
    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as zf:
        zf.write(pkg_dir / "manifest.json", "manifest.json")
        _add_dir_to_zip(zf, pkg_dir / "scripts",   "scripts")
        _add_dir_to_zip(zf, pkg_dir / "ui",        "ui")
        _add_dir_to_zip(zf, pkg_dir / "resources", "resources")
        # Include bundled libraries declared in manifest.bundle.libraries
        for lib_def in manifest.get("bundle", {}).get("libraries", []):
            lib_file = pkg_dir / lib_def["file"]
            if lib_file.exists():
                zf.write(lib_file, lib_def["file"])
            else:
                warn(f"Bundled library file not found: {lib_def['file']}")
        # Include full libraries/ subdirectory (manifests + all .rhai files)
        _add_dir_to_zip(zf, pkg_dir / "libraries", "libraries")
        zf.writestr("build-meta.json", json.dumps(build_meta(manifest, "module"), indent=2))
    return out


def _add_library_to_zip(zf: zipfile.ZipFile, lib_dir: Path, lib_id: str, zip_prefix: str):
    """Add a library from lib_dir into the zip under zip_prefix/lib_id/."""
    lib_m = json.loads((lib_dir / "manifest.json").read_text(encoding="utf-8"))
    zf.write(lib_dir / "manifest.json", f"{zip_prefix}/{lib_id}/manifest.json")
    entry_path = lib_dir / lib_m["entry"]
    if entry_path.exists():
        zf.write(entry_path, f"{zip_prefix}/{lib_id}/{lib_m['entry']}")
    for extra in sorted(lib_dir.glob("*.rhai")):
        if extra.name != lib_m["entry"]:
            zf.write(extra, f"{zip_prefix}/{lib_id}/{extra.name}")

def _add_module_to_zip(zf: zipfile.ZipFile, mod_id: str, zip_prefix: str):
    """Add a module from MODULES/mod_id into the zip under zip_prefix/mod_id/."""
    mod_dir = MODULES / mod_id
    zf.write(mod_dir / "manifest.json", f"{zip_prefix}/{mod_id}/manifest.json")
    for sub in ("scripts", "ui", "resources", "libraries"):
        sub_dir = mod_dir / sub
        if sub_dir.is_dir():
            for f in sorted(sub_dir.rglob("*")):
                if f.is_file():
                    rel = f.relative_to(sub_dir)
                    zf.write(f, f"{zip_prefix}/{mod_id}/{sub}/{rel}")

def _add_package_to_zip(zf: zipfile.ZipFile, pkg_id: str, zip_prefix: str):
    """Recursively add a nested bundle from PACKAGES/pkg_id under zip_prefix/pkg_id/."""
    pkg_dir = PACKAGES / pkg_id
    nested_m = json.loads((pkg_dir / "manifest.json").read_text(encoding="utf-8"))
    zf.write(pkg_dir / "manifest.json", f"{zip_prefix}/{pkg_id}/manifest.json")
    for lib_id in nested_m.get("libraries", []):
        lib_dir = pkg_dir / "libraries" / lib_id
        _add_library_to_zip(zf, lib_dir, lib_id, f"{zip_prefix}/{pkg_id}/libraries")
    for mod_id in nested_m.get("modules", []):
        _add_module_to_zip(zf, mod_id, f"{zip_prefix}/{pkg_id}/modules")
    for sub_id in nested_m.get("packages", []):
        _add_package_to_zip(zf, sub_id, f"{zip_prefix}/{pkg_id}/packages")

def package_bundle(pkg_dir: Path, manifest: dict) -> Path:
    """Package a .gdpck bundle.

    ZIP layout:
        manifest.json
        build-meta.json
        libraries/
            <lib_id>/
                manifest.json
                <entry.rhai>
        modules/
            <mod_id>/
                manifest.json
                scripts/<script.rhai>
        packages/
            <nested_pkg>/
                manifest.json
                libraries/ ...
    """
    ver = manifest["version"]
    out = out_dir(manifest["id"], ver) / f"{manifest['id']}-{ver}.gdpck"
    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as zf:
        zf.write(pkg_dir / "manifest.json", "manifest.json")
        zf.writestr("build-meta.json", json.dumps(build_meta(manifest, "package"), indent=2))
        for lib_id in manifest.get("libraries", []):
            lib_dir = pkg_dir / "libraries" / lib_id
            _add_library_to_zip(zf, lib_dir, lib_id, "libraries")
        for mod_id in manifest.get("modules", []):
            _add_module_to_zip(zf, mod_id, "modules")
        for pkg_id in manifest.get("packages", []):
            _add_package_to_zip(zf, pkg_id, "packages")
    return out


# ── Catalog ───────────────────────────────────────────────────────────────────

def make_catalog_entry(
    manifest: dict,
    checksum: str,
    download_base: str,
    pkg_type: str,
    github_repo: str = "",
) -> dict:
    pkg_id   = manifest["id"]
    ver      = manifest["version"]
    ext      = {"module": "gdmod", "package": "gdpck"}.get(pkg_type, "gdmod")
    filename = f"{pkg_id}-{ver}.{ext}"
    entry = {
        "id":              pkg_id,
        "name":            manifest["name"],
        "version":         ver,
        "min_app_version": manifest.get("min_app_version", "0.1.0"),
        "author":          manifest.get("author", ""),
        "description":     manifest["description"],
        "icon":            manifest.get("icon", "custom"),
        "package_type":    pkg_type,
        "verified":        manifest.get("verified", False),
        "premium":         manifest.get("premium", False),
        "tags":            manifest.get("tags", []),
        "commands":        manifest.get("commands", []),
        "libraries":       manifest.get("libraries", []),
        "modules":         manifest.get("modules", []),
        "checksum":        checksum,
        "pub_date":        datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "download_url":    f"{download_base.rstrip('/')}/{filename}" if download_base else "",
    }
    # Embed GitHub distribution metadata when a repo is provided.
    # The installer reads dist/{pkg_id}/{version}/manifest.json from the repo.
    if github_repo:
        entry["source_type"]  = "github"
        entry["github_repo"]  = github_repo
        entry["github_dir"]   = f"dist/{pkg_id}"
        entry["github_tag"]   = ""
    return entry


# ── Dist manifest ─────────────────────────────────────────────────────────────

def write_dist_manifest(out_file: Path, manifest: dict, pkg_type: str, checksum: str):
    """Write dist/<id>/<version>/manifest.json for the installer to read at install time."""
    dist_m = {
        "id":           manifest["id"],
        "version":      manifest["version"],
        "package_type": pkg_type,
        "file":         out_file.name,
        "checksum":     checksum,
    }
    dest = out_file.parent / "manifest.json"
    dest.write_text(json.dumps(dist_m, indent=2), encoding="utf-8")


# ── Publish ───────────────────────────────────────────────────────────────────

def publish_entry(entry: dict, pkg_file: Path, marketplace_url: str, token: str):
    import urllib.request, urllib.error
    from urllib.parse import quote

    # Send token both in header and as query param (nginx may strip Authorization header)
    headers = {"Content-Type": "application/json", "Authorization": f"Bearer {token}"}
    base    = marketplace_url.rstrip("/")
    tq      = f"?_token={quote(token, safe='')}"

    create_body = json.dumps({
        "id":              entry["id"],
        "name":            entry["name"],
        "author":          entry["author"],
        "description":     entry["description"],
        "package_type":    entry["package_type"],
        "icon":            entry["icon"],
        "min_app_version": entry.get("min_app_version", "0.1.0"),
        "tags":            entry["tags"],
        "verified":        entry["verified"],
        "status":          "published",
    }).encode()

    try:
        req = urllib.request.Request(f"{base}/admin/module{tq}", data=create_body, headers=headers, method="POST")
        urllib.request.urlopen(req, timeout=15)
        ok(f"Created {entry['id']}")
    except urllib.error.HTTPError as e:
        body = e.read().decode(errors="replace")
        if e.code == 409:
            warn(f"{entry['id']} already exists — adding release only")
        else:
            raise RuntimeError(f"Create failed ({e.code}): {body}") from e

    release_body = json.dumps({
        "version":      entry["version"],
        "download_url": entry["download_url"],
        "checksum":     entry["checksum"],
        "changelog":    entry.get("changelog", ""),
        "pub_date":     entry["pub_date"],
        # GitHub distribution fields (forwarded to marketplace DB)
        "source_type":  entry.get("source_type", "direct"),
        "github_repo":  entry.get("github_repo", ""),
        "github_dir":   entry.get("github_dir", ""),
        "github_tag":   entry.get("github_tag", ""),
    }).encode()
    try:
        req = urllib.request.Request(
            f"{base}/admin/module/{entry['id']}/release{tq}",
            data=release_body, headers=headers, method="POST",
        )
        urllib.request.urlopen(req, timeout=15)
        ok(f"Release v{entry['version']} published for {entry['id']}")
    except urllib.error.HTTPError as e:
        body = e.read().decode(errors="replace")
        raise RuntimeError(f"Release failed ({e.code}): {body}") from e


# ── Discovery ─────────────────────────────────────────────────────────────────

def discover_packages() -> list[tuple[Path, str]]:
    pkgs = []
    for kind, base in [("module", MODULES), ("package", PACKAGES)]:
        if base.is_dir():
            for d in sorted(base.iterdir()):
                if d.is_dir() and (d / "manifest.json").exists():
                    pkgs.append((d, kind))
    return pkgs


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="Build GDLQBot packages")
    parser.add_argument("target",    nargs="?", help="Package ID to build (default: all)")
    parser.add_argument("--validate", action="store_true")
    parser.add_argument("--bump",    choices=["patch", "minor", "major"])
    parser.add_argument("--since",   metavar="TAG")
    parser.add_argument("--publish", nargs=2, metavar=("URL", "TOKEN"))
    parser.add_argument("--download-base", metavar="URL",
                        help="Base URL for file downloads (e.g. GitHub releases). "
                             "Separate from --publish which is the marketplace API URL.")
    parser.add_argument("--github-repo", metavar="OWNER/REPO",
                        help="Embed GitHub source info in catalog entries so the app "
                             "can install directly from the repo's dist tree. "
                             "Example: GD-LevelReqBot/marketplace")
    parser.add_argument("--watch", action="store_true",
                        help="After building, watch for file changes and rebuild automatically. "
                             "Requires --target (a single package ID).")
    parser.add_argument("--dev-install", metavar="MODULES_DIR",
                        help="Copy the module source directory into a running app's modules folder "
                             "for live testing. Requires --target. Does not build a .gdmod — "
                             "the app hot-reloads the source directory directly.")
    args = parser.parse_args()

    marketplace_url, token = args.publish if args.publish else (None, None)
    download_base = args.download_base or ""
    github_repo   = args.github_repo   or ""
    changed_since = git_changed_since(args.since) if args.since else None

    # ── Dev-install: copy source dir into a running app's modules folder ─────
    if args.dev_install:
        if not args.target:
            print(f"{RED}--dev-install requires a target package ID{RESET}")
            sys.exit(1)
        pkg_dir  = MODULES / args.target
        if not pkg_dir.is_dir():
            print(f"{RED}Module '{args.target}' not found under modules/{RESET}")
            sys.exit(1)
        dest = Path(args.dev_install) / args.target
        if dest.exists():
            shutil.rmtree(dest)
        shutil.copytree(pkg_dir, dest)
        ok(f"Installed '{args.target}' -> {dest}")
        print(f"\n{GREEN}{BOLD}Dev install complete.{RESET}  "
              f"Enable the module in the app, then use --watch to auto-rebuild on changes.")
        sys.exit(0)

    packages = discover_packages()
    if not packages:
        print(f"{RED}No packages found under modules/ or packages/{RESET}")
        sys.exit(1)

    if args.target:
        packages = [(d, k) for d, k in packages if d.name == args.target]
        if not packages:
            print(f"{RED}Package '{args.target}' not found{RESET}")
            sys.exit(1)

    if changed_since is not None:
        filtered = [(d, k) for d, k in packages if d.name in changed_since]
        if not filtered:
            print(f"{YELLOW}No packages changed since {args.since} — nothing to build.{RESET}")
            sys.exit(0)
        skipped = len(packages) - len(filtered)
        if skipped: print(f"{YELLOW}Skipping {skipped} unchanged package(s){RESET}")
        packages = filtered

    validate_fns = {"module": validate_module, "package": validate_bundle}
    package_fns  = {"module": package_module,  "package": package_bundle}

    any_error   = False
    catalog     = []
    built_files = []

    for pkg_dir, kind in packages:
        head(f"{pkg_dir.name}  ({kind})")

        if args.bump:
            new_ver = apply_version_bump(pkg_dir / "manifest.json", args.bump)
            ok(f"Bumped version -> {new_ver}")

        manifest, errors = validate_fns[kind](pkg_dir)
        if errors:
            for e in errors: err(e)
            any_error = True
            continue

        ok(f"v{manifest['version']}  min_app={manifest.get('min_app_version', 'n/a')}")

        if args.validate:
            continue

        try:
            out_file = package_fns[kind](pkg_dir, manifest)
        except Exception as ex:
            err(f"Packaging failed: {ex}")
            any_error = True
            continue

        checksum = sha256_file(out_file)
        sha_path = out_file.parent / f"{out_file.name}.sha256"
        sha_path.write_text(f"{checksum}  {out_file.name}\n")
        size_kb = out_file.stat().st_size // 1024
        rel = out_file.relative_to(ROOT)
        ok(f"-> {rel}  ({size_kb} KB)  sha256:{checksum[:12]}…")

        # Write the dist manifest — tells the installer what file to download
        # and its checksum, without needing to enumerate source files.
        write_dist_manifest(out_file, manifest, kind, checksum)
        ok(f"-> dist/{manifest['id']}/{manifest['version']}/manifest.json")

        entry = make_catalog_entry(manifest, checksum, download_base, kind, github_repo)
        catalog.append(entry)
        built_files.append((entry, out_file))

    if not args.validate and catalog:
        existing: dict[str, dict] = {}
        catalog_path = DIST / "catalog.json"
        if catalog_path.exists():
            try:
                for e in json.loads(catalog_path.read_text(encoding="utf-8")):
                    existing[e["id"]] = e
            except Exception:
                pass
        for e in catalog:
            existing[e["id"]] = e
        catalog_path.write_text(json.dumps(list(existing.values()), indent=2), encoding="utf-8")
        head("Output")
        ok(f"dist/catalog.json  ({len(existing)} total packages, {len(catalog)} updated)")

    if marketplace_url and built_files:
        head("Publishing")
        for entry, pkg_file in built_files:
            try:
                publish_entry(entry, pkg_file, marketplace_url, token)
            except RuntimeError as ex:
                err(str(ex))
                any_error = True

    print()
    if any_error:
        print(f"{RED}{BOLD}Build finished with errors.{RESET}")
        if not args.watch:
            sys.exit(1)
    else:
        print(f"{GREEN}{BOLD}Done.{RESET}")

    # ── Watch mode: rebuild on any source file change ─────────────────────────
    if args.watch:
        if not args.target:
            print(f"{RED}--watch requires a target package ID{RESET}")
            sys.exit(1)
        watch_root = MODULES / args.target
        if not watch_root.is_dir():
            watch_root = PACKAGES / args.target
        if not watch_root.is_dir():
            print(f"{RED}Package '{args.target}' not found{RESET}")
            sys.exit(1)

        print(f"\n{CYAN}Watching {watch_root.relative_to(ROOT)} for changes…  (Ctrl+C to stop){RESET}\n")

        def _snapshot(root: Path) -> dict[Path, float]:
            snap = {}
            for f in root.rglob("*"):
                if f.is_file():
                    try:
                        snap[f] = f.stat().st_mtime
                    except OSError:
                        pass
            return snap

        prev = _snapshot(watch_root)
        try:
            while True:
                time.sleep(1)
                curr = _snapshot(watch_root)
                changed_files = [
                    f for f, mt in curr.items()
                    if prev.get(f) != mt
                ] + [f for f in prev if f not in curr]

                if changed_files:
                    rel_names = [f.relative_to(watch_root) for f in changed_files[:3]]
                    extra = len(changed_files) - 3
                    label = ", ".join(str(r) for r in rel_names)
                    if extra > 0: label += f" (+{extra} more)"
                    print(f"  {CYAN}changed{RESET} {label} — rebuilding…")

                    # Re-run the same build logic for the target
                    sub = [sys.executable, __file__, args.target]
                    if args.validate: sub.append("--validate")
                    result = subprocess.run(sub, cwd=ROOT)
                    if result.returncode == 0:
                        print(f"  {GREEN}ok{RESET}   rebuild complete\n")
                    else:
                        print(f"  {RED}ERR{RESET}  rebuild had errors\n")
                    prev = _snapshot(watch_root)
        except KeyboardInterrupt:
            print(f"\n{YELLOW}Watch stopped.{RESET}")

if __name__ == "__main__":
    main()
