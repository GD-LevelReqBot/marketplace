import "queue-core" as q;

// UI-triggered "add a level for someone" (queue page, not chat) — has no
// live chat message behind it, so unlike request.rhai it can't read
// user.isSub() (there's no `user` badge data for a button click). Resolves
// subscriber status with a live Helix lookup instead — otherwise every
// UI-added level would silently land in the viewer queue regardless of the
// requester's actual status.
//
// args[0]: single JSON object, e.g. #{ level_id: "123456", username: "foo" } —
// sent by the TwoFieldForm widget, which owns its two inputs as local
// component state and is NOT wired through the shared page-state bag at all.
// (The previous Input+Input+Button/argState wiring is what silently sent an
// empty level id: multi-key argState skips any unset field rather than
// sending "", which shifts array indices, and afterState cleared the field
// on ANY non-throwing dispatch — including a script that "succeeded" by
// silently no-op'ing. A single JSON arg has no index to shift.)
if args.len() < 1 {
    throw "add_level got no args — the form didn't submit anything.";
}

let data = io.parse_json(args[0]);
if data == () { throw `add_level got unparseable JSON: ${args[0]}`; }
if "level_id" !in data { throw `JSON payload had no "level_id" key: ${args[0]}`; }
if "username" !in data { throw `JSON payload had no "username" key: ${args[0]}`; }

// Rhai's `.trim()` mutates the string IN PLACE and returns () — it is NOT a
// value-returning method like JS's String.trim(). `let x = s.trim();` silently
// assigns x = () while s itself ends up trimmed. This was the actual root
// cause of every "" isn't a valid level ID" error this whole session: call
// trim() as its own statement, then use the (now-mutated) variable directly.
let raw_id = data.level_id;
if raw_id.type_of() != "string" { throw `level_id was type "${raw_id.type_of()}", not string: ${raw_id}`; }
raw_id.trim();

let username = data.username;
if username.type_of() != "string" { throw `username was type "${username.type_of()}", not string: ${username}`; }
username.trim();

if raw_id == "" { throw "Level ID field was empty."; }
if username == "" { throw "Username field was empty."; }

let level_id = q::parse_level_id(raw_id);
if level_id == () { throw "\"" + raw_id + "\" isn't a valid level ID (need 3-9 digits)."; }

if q::is_blacklisted(ms, "level", to_string(level_id)) { throw `Level ${level_id} is blacklisted.`; }
if q::is_blacklisted(ms, "user", username) { throw `User "${username}" is blacklisted.`; }

if ms.get_or("gd_enabled", true) {
    let lvl = gd.fetch(to_string(level_id));
    if lvl != () {
        let reason = q::check_level_filters(ms, lvl);
        if reason != "" { throw reason; }
    }
}

let is_sub = twitch.is_subscriber(username);
let result = q::add_request(ms, time, level_id, username, is_sub, "twitch");
if result == "ok" {
    event.emit("queue-updated", ());
} else {
    throw `Queue add failed: ${result}`;
}
