// queue-core -- Import as: import "queue-core" as q;

fn parse_level_id(raw) {
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
        is_subscriber: is_queue_sub,
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