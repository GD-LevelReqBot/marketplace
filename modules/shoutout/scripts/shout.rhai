// !so <username> — give a shoutout (mod/broadcaster only)
let args = user.args();
if args.len() == 0 {
    chat.say("Usage: !so <username>");
} else {
    let name = args[0].trim_start_matches('@');
    chat.say(`Go check out @${name}! https://twitch.tv/${name}`);
}
