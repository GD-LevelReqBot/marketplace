import "queue-core" as q;

// args[0] should always be a string (it's dispatched with a JS string arg),
// but Rhai won't stop a caller from passing something else — guard the type
// before .trim() rather than let a wrong-typed arg crash the whole script.
// Rhai's .trim() mutates in place and returns () — never assign its result.
let value = if args.len() > 0 && args[0].type_of() == "string" { args[0] } else { "" };
value.trim();
if value != "" {
    q::add_blacklist(ms, "user", value);
}
event.emit("queue-updated", ());
