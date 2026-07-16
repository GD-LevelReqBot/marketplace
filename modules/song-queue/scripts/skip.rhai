// !skipsong — skip to the next song (mod only)
let col = ms.collection("queue");
let first = col.first();
if first == () {
    chat.say("The song queue is empty!");
    return;
}
ms.set("current", first.title);
col.remove(first._id);
event.emit("queue-updated", ());
chat.say(`Skipped! Now playing: "${first.title}" (requested by @${first.username})`);
