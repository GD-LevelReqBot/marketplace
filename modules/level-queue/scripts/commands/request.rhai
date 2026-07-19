// @trigger !r
// @alias !request
// @description Add a level to the queue
// @roles everyone
// @platform all
// @cooldown 0
// @user_cooldown 0

import "queue-core" as q;

let raw      = if args.len() > 0 { args[0] } else { "" };
let level_id = q::parse_level_id(raw);

if level_id == () {
    chat.reply("Usage: !r <level_id> (3-9 digit ID)");
    return;
}

let result = q::add_request(ms, time, level_id, user.name, user.isSub(), user.platform);

switch result {
    "ok" => {
        let sub_mode = ms.get("sub_mode") ?? false;
        let col_name = if user.isSub() && sub_mode { "subscriber" } else { "viewer" };
        let pos = ms.collection(col_name).all().filter(|e| e.level_id == level_id).len();
        event.emit("queue-updated", ());
        chat.reply(`Level ${level_id} added to the queue at position #${pos}!`);
    },
    "closed"        => chat.reply("The queue is currently closed."),
    "full"          => { let max = ms.get("max_size") ?? 0; chat.reply(`The queue is full (${max} levels).`); },
    "duplicate"     => chat.reply(`Level ${level_id} is already in the queue.`),
    "limit_reached" => {
        let sub_mode = ms.get("sub_mode") ?? false;
        let limit    = if user.isSub() && sub_mode { ms.get("sub_limit") ?? 2 } else { ms.get("viewer_limit") ?? 1 };
        chat.reply(`You've reached your request limit of ${limit} level(s).`);
    },
}