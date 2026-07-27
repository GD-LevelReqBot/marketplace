import "queue-core" as q;

if args.len() < 1 { return; }
let level_id = parse_int(args[0]);
if level_id == () { return; }

q::move_entry(ms, level_id, 1);
event.emit("queue-updated", ());
