// @trigger !next
// @alias
// @description Pop the next level from the queue
// @roles moderator, broadcaster
// @platform all
// @cooldown 0
// @user_cooldown 0

import "queue-core" as q;

let entry = q::pop_next(ms, rand, time);

if entry == () {
    chat.say("The queue is empty!");
    return;
}

event.emit("queue-updated", ());
event.emit("level-nexted", #{ level_id: entry.level_id, username: entry.username, queue_type: entry.queue_type });
chat.say(`Next level: ${entry.level_id} - requested by @${entry.username} [${entry.queue_type}]`);