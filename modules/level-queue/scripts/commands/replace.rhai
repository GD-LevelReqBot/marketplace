// @trigger !replace
// @alias
// @description Swap one of your queued levels for a different one, keeping your spot
// @roles everyone
// @platform all
// @cooldown 0
// @user_cooldown 0

import "queue-core" as q;

if args.len() < 2 {
    chat.reply("Usage: !replace <old_level_id> <new_level_id>");
    return;
}

let old_id = q::parse_level_id(args[0]);
let new_id = q::parse_level_id(args[1]);

if old_id == () || new_id == () {
    chat.reply("Usage: !replace <old_level_id> <new_level_id>");
    return;
}

let found = q::find_by_level_id(ms, old_id);
if found == () {
    chat.reply(`Level ${old_id} is not in the queue.`);
    return;
}
if found.entry.username != user.name && !user.isStaff() {
    chat.reply("You can only replace your own levels.");
    return;
}
if old_id == new_id {
    chat.reply("That's already the level you have queued.");
    return;
}
if q::find_by_level_id(ms, new_id) != () {
    chat.reply(`Level ${new_id} is already in the queue.`);
    return;
}
if q::is_blacklisted(ms, "level", to_string(new_id)) {
    chat.reply("That level is blacklisted.");
    return;
}

if ms.get_or("gd_enabled", true) {
    let lvl = gd.fetch(to_string(new_id));
    if lvl != () {
        let reason = q::check_level_filters(ms, lvl);
        if reason != "" {
            chat.reply(reason);
            return;
        }
    }
}

q::replace_level(ms, found.col_name, found.entry._id, new_id);
event.emit("queue-updated", ());
chat.reply(`Replaced level ${old_id} with ${new_id} — you keep your spot!`);
