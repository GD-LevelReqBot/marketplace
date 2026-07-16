// !give <user> <amount> — give points to another viewer
if args.len() < 2 {
    chat.reply("Usage: !give @user <amount>");
    return;
}
let target = args[0].trim_start_matches("@");
let amount = parse_int(args[1]);
if amount == () || amount <= 0 {
    chat.reply("Please enter a positive amount.");
    return;
}
let my_key     = `user:${username}:points`;
let their_key  = `user:${target}:points`;
let my_points  = ms.get(my_key);
if my_points == () { my_points = 0; }
if my_points < amount {
    chat.reply(`You only have ${my_points} points!`);
    return;
}
ms.set(my_key, my_points - amount);
let their_pts = ms.get(their_key);
if their_pts == () { their_pts = 0; }
ms.set(their_key, their_pts + amount);
chat.say(`@${username} gave ${amount} points to @${target}!`);
