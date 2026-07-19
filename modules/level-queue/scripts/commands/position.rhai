// @trigger !pos
// @alias !position
// @description Get your position in the queue
// @roles everyone
// @platform all
// @cooldown 0
// @user_cooldown 5

import "queue-core" as q;

let level_id = if args.len() > 0 { q::parse_level_id(args[0]) } else { () };

if level_id == () {
    let mine = q::find_by_username(ms, user.name);
    if mine.len() == 0 {
        chat.reply("You have no levels in the queue.");
    } else {
        let parts = mine.map(|e| `#${e.position} (${e.level_id})`);
        chat.reply(`Your positions: ${parts.join(", ")}`);
    }
    return;
}

let found = q::find_by_level_id(ms, level_id);
if found == () {
    chat.say(`Level ${level_id} is not in the queue.`);
} else {
    chat.say(`Level ${level_id} is #${found.entry.position} in the ${found.col_name} queue.`);
}