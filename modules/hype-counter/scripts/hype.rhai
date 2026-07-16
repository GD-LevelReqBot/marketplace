// !hype — add a hype to the counter
let count = ms.get("count") ?? 0;
ms.set("count", count + 1);
let messages = ["PogChamp", "LET'S GOOO", "HYPE!", "HYPEEEE", "KEKW"];
let exclaim = messages[rand.int(0, messages.len() - 1)];
chat.say(`${exclaim} ${count + 1} hypes so far!`);
