// !poll Question | Option A | Option B | Option C
let text = args.join(" ");
if text.len() == 0 {
    chat.reply("Usage: !poll Question | Option A | Option B");
    return;
}
if ms.get("active") == true {
    chat.say("A poll is already running! Use !endpoll to end it first.");
    return;
}
let parts = text.split("|").map(|s| s.trim());
if parts.len() < 3 {
    chat.reply("Usage: !poll Question | Option A | Option B");
    return;
}
let question = parts[0];
let options  = parts.skip(1);
let votes    = #{};
for i in 0..options.len() {
    votes[`${i+1}`] = 0;
}
ms.set("active",   true);
ms.set("question", question);
ms.set("options",  io.encode_json(options));
ms.set("votes",    io.encode_json(votes));
event.emit("queue-updated", ());
let opts = options.map(|o, i| `${i+1}) ${o}`);
chat.say(`Poll: "${question}" — ${opts.join(" | ")} — Vote with !vote 1, !vote 2, etc.`);
