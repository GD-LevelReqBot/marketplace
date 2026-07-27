import "queue-core" as q;

// Throwing again, deliberately, WITH the actual args seen — the prior
// silent-no-op version hid failures completely, making it impossible to
// tell "worked" from "didn't" from the UI. If this fires, the message says
// exactly what was received instead of a generic complaint.
if args.len() < 1 {
    throw `add_blacklist_level got 0 args, expected 1 (level id).`;
}
if args[0].type_of() != "string" { throw `arg[0] was type "${args[0].type_of()}", not string: ${args[0]}`; }
// Rhai's .trim() mutates in place and returns () — `let raw = args[0].trim();`
// silently assigns raw = (). Copy to a local var, then trim as its own statement.
let raw = args[0];
raw.trim();
if raw == "" { throw "Level ID field was empty."; }

let level_id = q::parse_level_id(raw);
if level_id == () { throw `"${raw}" isn't a valid level ID (need 3-9 digits).`; }

q::add_blacklist(ms, "level", to_string(level_id));
event.emit("queue-updated", ());
