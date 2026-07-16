// !pos [level_id] — get position in queue (defaults to your own levels)
let level_id_str = if args.len() > 0 { args[0] } else { "" };
let level_id = parse_int(level_id_str);

let all_entries = ms.collection("viewer").all() + ms.collection("subscriber").all();

if level_id == () {
    let mine = all_entries.filter(|e| e.username == user.name);
    if mine.len() == 0 {
        chat.reply("You have no levels in the queue.");
    } else {
        let parts = mine.map(|e| `#${e.position} (${e.level_id})`);
        chat.reply(`Your positions: ${parts.join(", ")}`);
    }
    return;
}

let found = ();
for e in all_entries {
    if e.level_id == level_id { found = e; break; }
}

if found == () {
    chat.say(`Level ${level_id} is not in the queue.`);
} else {
    let qt = if found.is_subscriber == true { "subscriber" } else { "viewer" };
    chat.say(`Level ${level_id} is #${found.position} in the ${qt} queue.`);
}
