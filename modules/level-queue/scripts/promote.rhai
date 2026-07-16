// !promote <level_id> — move a level to the front (mod/broadcaster only)
let level_id_str = if args.len() > 0 { args[0] } else { "" };
let level_id = parse_int(level_id_str);

if level_id == () {
    chat.reply(`Usage: !promote <level_id>`);
    return;
}

// Find the entry
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
if found.position == 1 {
    chat.say(`Level ${level_id} is already at the front.`);
    return;
}

let col = ms.collection(found_col_name);
col.remove(found._id);

// Re-insert all entries: target first, then the rest with renumbered positions
let remaining = col.all();
col.clear();

found.position = 1;
col.push(found);

let pos = 2;
for e in remaining {
    e.position = pos;
    col.push(e);
    pos += 1;
}

event.emit("queue-updated", ());
chat.say(`Level ${level_id} has been promoted to the front of the ${found_col_name} queue.`);
