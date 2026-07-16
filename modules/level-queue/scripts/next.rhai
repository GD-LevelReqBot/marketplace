// !next — pop the next level from the queue
let sub_mode = ms.get("sub_mode") ?? false;
let viewer_col = ms.collection("viewer");
let sub_col    = ms.collection("subscriber");
let history    = ms.collection("history");

let entry       = ();
let picked_type = "viewer";

if sub_mode && sub_col.count() > 0 && rand.float() < 0.6 {
    entry       = sub_col.first();
    picked_type = "subscriber";
}
if entry == () {
    entry       = viewer_col.first();
    picked_type = "viewer";
}
if entry == () && sub_mode {
    entry       = sub_col.first();
    picked_type = "subscriber";
}

if entry == () {
    chat.say("The queue is empty!");
    return;
}

let col = ms.collection(picked_type);
col.remove(entry._id);

let remaining = col.all();
let pos = 1;
for e in remaining {
    col.remove(e._id);
    e.position = pos;
    col.push(e);
    pos += 1;
}

history.push(#{
    level_id:   entry.level_id,
    username:   entry.username,
    queue_type: picked_type,
    platform:   entry.platform ?? "unknown",
    nexted_at:  time.now()
});

event.emit("queue-updated", ());
event.emit("level-nexted", #{ level_id: entry.level_id, username: entry.username, queue_type: picked_type });

chat.say(`Next level: ${entry.level_id} — requested by @${entry.username} [${picked_type}]`);
