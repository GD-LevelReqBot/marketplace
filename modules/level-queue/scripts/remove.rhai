import "queue-core" as q;

let level_id = parse_int(if args.len() > 0 { args[0] } else { "" });
if level_id == () {
    chat.reply("Usage: !remove <level_id>");
    return;
}

let found = q::find_by_level_id(level_id);
if found == () {
    chat.say(`Level ${level_id} is not in the queue.`);
    return;
}

if !user.isStaff() && found.entry.username != user.name {
    chat.reply("You can only remove your own levels.");
    return;
}

q::remove_entry(found.col_name, found.entry._id);
event.emit("queue-updated", ());
chat.say(`Level ${level_id} has been removed from the queue.`);
