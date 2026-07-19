// queue-utils — shared lookup and parsing helpers for the level queue.
// Import as: import "queue-utils" as utils;

/// Parse a level ID from a raw string (first run of 3–9 digits).
/// Returns the integer ID, or () if the string doesn't contain a valid ID.
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

/// Find the first entry matching level_id across both queues.
/// Returns #{ entry, col_name } or ().
fn find_by_level_id(level_id) {
    for col_name in ["viewer", "subscriber"] {
        for e in ms.collection(col_name).all() {
            if e.level_id == level_id {
                return #{ entry: e, col_name: col_name };
            }
        }
    }
    ()
}

/// Find all entries belonging to a username across both queues.
/// Returns an array of entries (each has .col_name set).
fn find_by_username(username) {
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
