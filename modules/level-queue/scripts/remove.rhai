// !remove <level_id> — remove a level (mod removes any; viewer removes their own)
let level_id_str = if args.len() > 0 { args[0] } else { "" };
let level_id = parse_int(level_id_str);

if level_id == () {
    chat.reply(`Usage: !remove <level_id>`);
    return;
}

let is_staff = user.isMod() || user.isBroadcaster();

// Find the entry across both queues
let found   = ();
let found_col_name = ();
for col_name in ["viewer", "subscriber"] {
    for e in ms.collection(col_name).all() {
        if e.level_id == level_id {
            found = e;
            found_col_name = col_name;
            break;
        }
    }
    if found != () { break; }
}

if found == () {
    chat.say(`Level ${level_id} is not in the queue.`);
    return;
}

if !is_staff && found.username != username {
    chat.reply("You can only remove your own levels.");
    return;
}

let col = ms.collection(found_col_name);
col.remove(found._id);

// Renumber remaining positions
let remaining = col.all();
let pos = 1;
for e in remaining {
    col.remove(e._id);
    e.position = pos;
    col.push(e);
    pos += 1;
}

event.emit("queue-updated", ());
chat.say(`Level ${level_id} has been removed from the queue.`);
