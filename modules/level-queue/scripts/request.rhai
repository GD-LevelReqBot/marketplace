// !r <level_id> — add a level to the queue
let level_id_str = if args.len() > 0 { args[0] } else { "" };

let digits = "";
for ch in level_id_str.chars() {
    if ch >= '0' && ch <= '9' {
        digits += ch;
        if digits.len() == 9 { break; }
    } else if digits.len() > 0 {
        break;
    }
}
if digits.len() < 3 {
    chat.reply("Usage: !r <level_id> (3-9 digit ID)");
    return;
}
let level_id = parse_int(digits);

if ms.get("open") == false {
    chat.reply("The queue is currently closed.");
    return;
}

let max_size = ms.get("max_size") ?? 0;
if max_size > 0 {
    let total = ms.collection("viewer").count() + ms.collection("subscriber").count();
    if total >= max_size {
        chat.reply(`Sorry, the queue is full (${total}/${max_size} levels).`);
        return;
    }
}

let sub_mode = ms.get("sub_mode") ?? false;
let viewer_limit = ms.get("viewer_limit") ?? 1;
let sub_limit = ms.get("sub_limit") ?? 2;
let is_sub = user.isSub() && sub_mode;
let col_name = if is_sub { "subscriber" } else { "viewer" };
let col = ms.collection(col_name);

for e in col.all() {
    if e.level_id == level_id {
        chat.reply(`Level ${level_id} is already in the queue.`);
        return;
    }
}
let other = ms.collection(if is_sub { "viewer" } else { "subscriber" });
for e in other.all() {
    if e.level_id == level_id {
        chat.reply(`Level ${level_id} is already in the queue.`);
        return;
    }
}

let limit = if is_sub { sub_limit } else { viewer_limit };
let my_levels = col.all().filter(|e| e.username == user.name);
if my_levels.len() >= limit {
    chat.reply(`Sorry, you have reached your request limit of ${limit} level(s).`);
    return;
}

let position = col.count() + 1;
col.push(#{
    level_id:      level_id,
    username:      user.name,
    platform:      user.platform,
    is_subscriber: is_sub,
    position:      position,
    added_at:      time.now()
});

event.emit("queue-updated", ());
chat.reply(`Level ${level_id} added to the ${col_name} queue at position ${position}!`);
