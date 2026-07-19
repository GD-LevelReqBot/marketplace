// @trigger !mylevels
// @alias
// @description Show your levels in the queue
// @roles everyone
// @platform all
// @cooldown 0
// @user_cooldown 10

import "queue-core" as q;

let mine = q::find_by_username(ms, user.name);

if mine.len() == 0 {
    chat.reply("You have no levels in the queue.");
} else {
    let parts = mine.map(|e| `${e.level_id} [${e.col_name}]`);
    chat.reply(`Your levels: ${parts.join(", ")}`);
}