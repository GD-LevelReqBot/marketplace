# Libraries

Rhai function library packages that can be installed from the marketplace.

Each library lives in its own subdirectory:

```
libraries/
  my-lib/
    manifest.json   ← package metadata
    lib.rhai        ← the library source (may also be my-lib.rhai)
```

## manifest.json format

```json
{
  "id": "my-lib",
  "name": "My Library",
  "author": "you",
  "description": "What this library provides",
  "version": "1.0.0",
  "package_type": "library",
  "min_app_version": "0.1.0",
  "tags": ["utility"]
}
```

## How libraries differ from modules

- `package_type: "library"` — installed into the libraries DB table, not as a bot module
- No bot commands — pure Rhai functions usable in scripts via `import "lib-name"`
- Available in the **Libraries → Packages** tab in the app
