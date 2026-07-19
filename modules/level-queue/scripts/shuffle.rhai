import "queue-core" as q;

let total = ms.collection("viewer").count() + ms.collection("subscriber").count();
if total < 2 {
    chat.say("Not enough levels in queue to shuffle.");
    return;
}

q::shuffle_queue();
event.emit("queue-updated", ());
chat.say("The queue has been shuffled!");
