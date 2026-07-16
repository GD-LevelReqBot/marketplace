// !sr <title> — request a song
let title = args.join(" ");
if title.len() == 0 {
    chat.reply("Usage: !sr <song title or URL>");
    return;
}

let col = ms.collection("queue");
let existing = col.all();
for e in existing {
    if e.username == username {
        chat.reply("You already have a song in the queue! Wait for it to play first.");
        return;
    }
}

col.push(#{ title: title, username: username, platform: platform, added_at: time.utc() });
event.emit("queue-updated", ());
chat.reply(`Added "${title}" to the song queue!`);
