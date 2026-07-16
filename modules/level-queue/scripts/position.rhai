// !pos <level_id> — get a level's position in queue
let level_id_str = if args.len() > 0 { args[0] } else { "" };
let level_id = parse_int(level_id_str);

if level_id == () {
    chat.reply(`Usage: !pos <level_id>`);
    return;
}

let all_entries = ms.collection("viewer").all() + ms.collection("subscriber").all();
let found = ();
for e in all_entries {
    if e.level_id == level_id {
        found = e;
        break;
    }
}

if found == () {
    chat.say(`Level ${level_id} is not in the queue.`);
} else {
    let qt = if found.is_subscriber == true { "subscriber" } else { "viewer" };
    chat.say(`Level ${level_id} is #${found.position} in the ${qt} queue.`);
}
