// Persist queue settings from the settings form.
// Called by the Form widget with args[0] = JSON-encoded field values.
let data = io.parse_json(user.args()[0]);

if data.max_size != () {
    let v = parse_int(to_string(data.max_size));
    if v != () { ms.set("max_size", v); }
}
if data.viewer_limit != () {
    let v = parse_int(to_string(data.viewer_limit));
    if v != () { ms.set("viewer_limit", v); }
}
if data.sub_limit != () {
    let v = parse_int(to_string(data.sub_limit));
    if v != () { ms.set("sub_limit", v); }
}
if data.sub_mode != () {
    ms.set("sub_mode", data.sub_mode == true);
}
if data.open != () {
    ms.set("open", data.open == true);
}

event.emit("queue-updated", ());
