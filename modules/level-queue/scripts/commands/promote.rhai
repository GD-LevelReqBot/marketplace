// @trigger !promote
// @alias
// @description Move a level to the front of the queue
// @roles moderator, broadcaster
// @platform all
// @cooldown 0
// @user_cooldown 0

import "queue-core" as q;

let level_id = if args.len() > 0 { q::parse_level_id(args[0]) } else { () };
if level_id == () {
    chat.reply("Usage: !promote <level_id>");
    return;
}

let found = q::find_by_level_id(ms, level_id);
if found == () {
    chat.say(`Level ${level_id} is not in the queue.`);
    return;
}
if found.entry.position == 1 {
    chat.say(`Level ${level_id} is already at the front.`);
    return;
}

q::promote_entry(ms, level_id);
event.emit("queue-updated", ());
chat.say(`Level ${level_id} promoted to the front of the ${found.col_name} queue.`);