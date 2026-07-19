import "queue-core" as q;

q::clear_queue(false);
event.emit("queue-updated", ());
chat.say("The level queue has been cleared.");
