// @trigger !open
// @alias
// @description Open the queue for requests
// @roles moderator, broadcaster
// @platform all
// @cooldown 0
// @user_cooldown 0

if ms.get("open") == true {
    chat.say("The queue is already open.");
    return;
}
ms.set("open", true);
event.emit("queue-updated", ());
chat.say("The queue is now open! Use !r <level_id> to request a level.");