// @trigger !clear
// @alias
// @description Clear the entire queue
// @roles moderator, broadcaster
// @platform all
// @cooldown 0
// @user_cooldown 0

import "queue-core" as q;

q::clear_queue(ms, false);
event.emit("queue-updated", ());
chat.say("The level queue has been cleared.");