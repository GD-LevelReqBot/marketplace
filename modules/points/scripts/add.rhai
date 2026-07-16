// !addpoints <user> <amount> — add points to a user (mod only)
if args.len() < 2 {
    chat.reply("Usage: !addpoints @user <amount>");
    return;
}
let target = args[0].trim_start_matches("@");
let amount = parse_int(args[1]);
if amount == () {
    chat.reply("Please enter a valid amount.");
    return;
}
let key = `user:${target}:points`;
let cur = ms.get(key);
if cur == () { cur = 0; }
let new_total = cur + amount;
ms.set(key, new_total);
chat.say(`@${target} now has ${new_total} points.`);
