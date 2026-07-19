// @trigger !close
// @alias
// @description Close the queue
// @roles moderator, broadcaster
// @platform all
// @cooldown 0
// @user_cooldown 0

if ms.get("open") == false {
    chat.say("The queue is already closed.");
    return;
}
ms.set("open", false);
event.emit("queue-updated", ());
chat.say("The queue is now closed. No new requests will be accepted.");