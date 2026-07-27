// queue-core -- Import as: import "queue-core" as q;

fn parse_level_id(raw) {
    if raw.type_of() != "string" { return (); }
    let digits = "";
    for ch in raw.chars() {
        if ch >= '0' && ch <= '9' {
            digits += ch;
            if digits.len() == 9 { break; }
        } else if digits.len() > 0 {
            break;
        }
    }
    if digits.len() < 3 { return (); }
    parse_int(digits)
}

fn find_by_level_id(ms, level_id) {
    for col_name in ["viewer", "subscriber"] {
        for e in ms.collection(col_name).all() {
            if e.level_id == level_id {
                return #{ entry: e, col_name: col_name };
            }
        }
    }
    ()
}

fn find_by_username(ms, username) {
    let results = [];
    for col_name in ["viewer", "subscriber"] {
        for e in ms.collection(col_name).all() {
            if e.username == username {
                let r = e;
                r.col_name = col_name;
                results.push(r);
            }
        }
    }
    results
}

fn recompact(ms, col_name) {
    let col   = ms.collection(col_name);
    let items = col.all();
    let p     = 1;
    for e in items {
        col.remove(e._id);
        e.position = p;
        col.push(e);
        p += 1;
    }
}

fn add_request(ms, time, level_id, username, is_sub, platform) {
    if (ms.get("open") ?? true) == false { return "closed"; }

    let max_size = ms.get("max_size") ?? 0;
    if max_size > 0 {
        let total = ms.collection("viewer").count() + ms.collection("subscriber").count();
        if total >= max_size { return "full"; }
    }

    for col_name in ["viewer", "subscriber"] {
        for e in ms.collection(col_name).all() {
            if e.level_id == level_id { return "duplicate"; }
        }
    }

    let sub_mode     = ms.get("sub_mode") ?? false;
    let is_queue_sub = is_sub && sub_mode;
    let col_name     = if is_queue_sub { "subscriber" } else { "viewer" };
    let col          = ms.collection(col_name);
    let limit        = if is_queue_sub { ms.get("sub_limit") ?? 2 } else { ms.get("viewer_limit") ?? 1 };

    let my_count = col.all().filter(|e| e.username == username).len();
    if my_count >= limit { return "limit_reached"; }

    col.push(#{
        level_id:      level_id,
        username:      username,
        platform:      platform,
        // The requester's *actual* subscriber status — not is_queue_sub, which
        // is "should this count toward the subscriber priority queue" (also
        // gated on sub_mode being enabled). Conflating the two meant a genuine
        // subscriber's entry was indistinguishable from a viewer's whenever
        // sub_mode was off, since everyone lands in "viewer" either way — this
        // keeps the true status visible regardless of which collection they're in.
        is_subscriber: is_sub,
        position:      col.count() + 1,
        added_at:      time.now(),
    });
    "ok"
}

fn remove_entry(ms, col_name, entry_id) {
    ms.collection(col_name).remove(entry_id);
    recompact(ms, col_name);
}

fn promote_entry(ms, level_id) {
    let found = find_by_level_id(ms, level_id);
    if found == () { return false; }
    if found.entry.position == 1 { return true; }

    let col       = ms.collection(found.col_name);
    let remaining = col.all().filter(|e| e._id != found.entry._id);
    col.clear();

    let entry  = found.entry;
    entry.position = 1;
    col.push(entry);

    let p = 2;
    for e in remaining {
        e.position = p;
        col.push(e);
        p += 1;
    }
    true
}

/// Swap an entry with its immediate neighbor. `direction`: -1 = up (earlier),
/// +1 = down (later). No-op (not an error) at either end of the queue.
fn move_entry(ms, level_id, direction) {
    let found = find_by_level_id(ms, level_id);
    if found == () { return false; }

    let col   = ms.collection(found.col_name);
    let items = col.all();
    items.sort(|a, b| a.position - b.position);

    let idx = -1;
    for i in 0..items.len() {
        if items[i]._id == found.entry._id { idx = i; break; }
    }
    if idx == -1 { return false; }

    let swap_idx = idx + direction;
    if swap_idx < 0 || swap_idx >= items.len() { return true; } // already at that end

    let tmp = items[idx].position;
    items[idx].position = items[swap_idx].position;
    items[swap_idx].position = tmp;

    col.clear();
    for e in items { col.push(e); }
    true
}

fn pop_next(ms, rand, time) {
    let sub_mode   = ms.get("sub_mode") ?? false;
    let viewer_col = ms.collection("viewer");
    let sub_col    = ms.collection("subscriber");
    let history    = ms.collection("history");

    let entry       = ();
    let picked_type = "viewer";

    if sub_mode && sub_col.count() > 0 && rand.float() < 0.6 {
        entry       = sub_col.first();
        picked_type = "subscriber";
    }
    if entry == () && viewer_col.count() > 0 {
        entry       = viewer_col.first();
        picked_type = "viewer";
    }
    if entry == () && sub_mode && sub_col.count() > 0 {
        entry       = sub_col.first();
        picked_type = "subscriber";
    }

    if entry == () { return (); }

    ms.collection(picked_type).remove(entry._id);
    recompact(ms, picked_type);

    history.push(#{
        level_id:   entry.level_id,
        username:   entry.username,
        queue_type: picked_type,
        platform:   entry.platform ?? "unknown",
        nexted_at:  time.now(),
    });

    entry.queue_type = picked_type;
    entry
}

// ── Blacklist (levels, authors, requesters) ────────────────────────────────
// Entries: #{ kind: "level"|"author"|"user", value: "..." } in ms.collection("blacklist")
//
// `value` here comes from wherever a caller got it — chat args, a UI dispatch,
// or a stored doc's field — and Rhai is dynamically typed, so nothing
// guarantees it's actually a string by the time it reaches these. Calling a
// string-only method (.to_lower()) on anything else (most commonly `()`, e.g.
// a caller passed no argument) is a hard runtime error, not a graceful
// "doesn't match" — so every value is type-checked before any string method
// touches it. lower_str(x) is the single choke point for that.

fn lower_str(x) {
    if x.type_of() == "string" { x.to_lower() } else { () }
}

fn is_blacklisted(ms, kind, value) {
    let needle = lower_str(value);
    if needle == () || needle == "" { return false; }
    for e in ms.collection("blacklist").all() {
        if e.kind == kind && lower_str(e.value) == needle { return true; }
    }
    false
}

fn add_blacklist(ms, kind, value) {
    if value.type_of() != "string" || value == "" { return false; }
    if is_blacklisted(ms, kind, value) { return false; }
    ms.collection("blacklist").push(#{ kind: kind, value: value });
    true
}

fn remove_blacklist(ms, kind, value) {
    let needle = lower_str(value);
    if needle == () { return false; }
    let col = ms.collection("blacklist");
    for e in col.all() {
        if e.kind == kind && lower_str(e.value) == needle {
            col.remove(e._id);
            return true;
        }
    }
    false
}

// ── Request filters (difficulty / length / dislikes / author blacklist) ────
// All derived from GD level data, so callers only need to check these when
// GD integration is enabled and gd.fetch() succeeded for the requested level.
//
// Difficulty/length are individual checkboxes in Settings → Filters, checked
// (= allowed) by default — unchecking one removes just that tier, rather than
// starting from "nothing restricted" and having to build an allow-list.

fn difficulty_allowed(ms, difficulty) {
    switch difficulty {
        "Auto"          => ms.get_or("diff_auto", true),
        "NA"            => ms.get_or("diff_unrated", true), // 0-star / unrated levels
        "Easy"          => ms.get_or("diff_easy", true),
        "Normal"        => ms.get_or("diff_normal", true),
        "Hard"          => ms.get_or("diff_hard", true),
        "Harder"        => ms.get_or("diff_harder", true),
        "Insane"        => ms.get_or("diff_insane", true),
        "Easy Demon"    => ms.get_or("diff_demon_easy", true),
        "Medium Demon"  => ms.get_or("diff_demon_medium", true),
        "Hard Demon"    => ms.get_or("diff_demon_hard", true),
        "Insane Demon"  => ms.get_or("diff_demon_insane", true),
        "Extreme Demon" => ms.get_or("diff_demon_extreme", true),
        _               => true, // unrecognised — never blocked
    }
}

fn length_allowed(ms, length) {
    switch length {
        "Tiny"       => ms.get_or("len_tiny", true),
        "Short"      => ms.get_or("len_short", true),
        "Medium"     => ms.get_or("len_medium", true),
        "Long"       => ms.get_or("len_long", true),
        "XL"         => ms.get_or("len_xl", true),
        "Platformer" => ms.get_or("len_platformer", true),
        _            => true,
    }
}

/// Returns "" if `lvl` (a gd.fetch() result) passes all configured filters,
/// or a user-facing rejection reason string otherwise.
fn check_level_filters(ms, lvl) {
    if is_blacklisted(ms, "author", lvl.author) {
        return "That level's creator is blacklisted.";
    }
    if !difficulty_allowed(ms, lvl.difficulty) {
        return `Difficulty "${lvl.difficulty}" is not allowed right now.`;
    }
    if !length_allowed(ms, lvl.length) {
        return `Level length "${lvl.length}" is not allowed right now.`;
    }
    if (ms.get_or("no_disliked_levels", false)) && lvl.likes < 0 {
        return "That level has more dislikes than likes.";
    }
    ""
}

// ── Replace ──────────────────────────────────────────────────────────────
// Swaps the level_id of an existing entry in place, preserving its queue
// position (unlike remove+add, which would push it to the back).

fn replace_level(ms, col_name, old_entry_id, new_level_id) {
    let col   = ms.collection(col_name);
    let items = col.all();
    col.clear();
    let p = 1;
    for e in items {
        if e._id == old_entry_id {
            e.level_id = new_level_id;
        }
        e.position = p;
        col.push(e);
        p += 1;
    }
}

fn shuffle_queue(ms, rand) {
    for col_name in ["viewer", "subscriber"] {
        let col      = ms.collection(col_name);
        let shuffled = rand.shuffle(col.all());
        col.clear();
        let p = 1;
        for e in shuffled {
            e.position = p;
            col.push(e);
            p += 1;
        }
    }
}

fn clear_queue(ms, include_history) {
    ms.collection("viewer").clear();
    ms.collection("subscriber").clear();
    if include_history { ms.collection("history").clear(); }
}