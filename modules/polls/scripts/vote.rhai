// !vote <option> — cast a vote in the active poll
if ms.get("active") != true {
    chat.reply("No poll is currently running.");
    return;
}
let choice = if args.len() > 0 { args[0] } else { "" };
if choice.len() == 0 {
    chat.reply("Usage: !vote <option number>");
    return;
}
let options: Vec<String> = io.parse_json(ms.get_or("options", "[]"));
let choice_n = parse_int(choice);
if choice_n == () || choice_n < 1 || choice_n > options.len() {
    chat.reply(`Please vote with a number between 1 and ${options.len()}.`);
    return;
}

// One vote per user per poll (track in voter key)
let voter_key = `voter:${username}`;
if ms.has(voter_key) {
    chat.reply("You have already voted!");
    return;
}
ms.set(voter_key, choice);

let votes: Map = io.parse_json(ms.get_or("votes", "{}"));
let cur = if votes[choice] == () { 0 } else { votes[choice] };
votes[choice] = cur + 1;
ms.set("votes", io.encode_json(votes));
chat.reply(`Vote cast for option ${choice}: "${options[choice_n - 1]}"`);
