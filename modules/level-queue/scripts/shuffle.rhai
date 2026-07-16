// !shuffle — randomize the viewer queue (mod/broadcaster only)
let col = ms.collection("viewer");
let entries = col.all();

if entries.len() < 2 {
    chat.say("Not enough viewers in queue to shuffle.");
    return;
}

// Fisher-Yates shuffle on positions
let shuffled = rand.shuffle(entries);
col.clear();

let pos = 1;
for e in shuffled {
    e.position = pos;
    col.push(e);
    pos += 1;
}

event.emit("queue-updated", ());
chat.say("The viewer queue has been shuffled!");
