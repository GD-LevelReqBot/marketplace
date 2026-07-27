let data = io.parse_json(args[0]);

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
if data.open_on_startup != () {
    ms.set("open_on_startup", data.open_on_startup == true);
}
if data.gd_enabled != () {
    ms.set("gd_enabled", data.gd_enabled == true);
}
if data.gd_thumbnails != () {
    ms.set("gd_thumbnails", data.gd_thumbnails == true);
}
if data.no_disliked_levels != () {
    ms.set("no_disliked_levels", data.no_disliked_levels == true);
}

// Difficulty/length filter checkboxes — each is its own boolean setting key.
let bool_keys = [
    "diff_unrated", "diff_auto", "diff_easy", "diff_normal", "diff_hard", "diff_harder", "diff_insane",
    "diff_demon_easy", "diff_demon_medium", "diff_demon_hard", "diff_demon_insane", "diff_demon_extreme",
    "len_tiny", "len_short", "len_medium", "len_long", "len_xl", "len_platformer",
];
for key in bool_keys {
    if data[key] != () {
        ms.set(key, data[key] == true);
    }
}

event.emit("queue-updated", ());
