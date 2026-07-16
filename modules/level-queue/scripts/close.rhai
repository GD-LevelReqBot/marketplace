// !close — close the queue to new requests (mod/broadcaster only)
if ms.get("open") == false {
    chat.say("The queue is already closed.");
    return;
}
ms.set("open", false);
event.emit("queue-status-changed", false);
chat.say("The queue is now closed. No new requests will be accepted.");
