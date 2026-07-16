// !open — open the queue for new requests (mod/broadcaster only)
if ms.get("open") == true {
    chat.say("The queue is already open.");
    return;
}
ms.set("open", true);
event.emit("queue-status-changed", true);
chat.say("The queue is now open! Use !r <level_id> to request a level.");
