// @trigger !blacklist
// @alias !bl
// @description Block levels, level creators, or requesters from the queue
// @roles moderator, broadcaster
// @platform all
// @cooldown 0
// @user_cooldown 0

import "queue-core" as q;

let sub   = if args.len() > 0 { args[0].to_lower() } else { "" };
let kind  = if args.len() > 1 { args[1].to_lower() } else { "" };
let value = if args.len() > 2 { args[2] } else { "" };

if sub == "list" {
    let entries = ms.collection("blacklist").all();
    if entries.len() == 0 {
        chat.say("The blacklist is empty.");
        return;
    }
    let lines = entries.map(|e| `${e.kind}:${e.value}`);
    chat.say(`Blacklist (${entries.len()}): ${lines.join(", ")}`);
    return;
}

let valid_kinds = ["level", "author", "user"];
if (sub != "add" && sub != "remove") || !valid_kinds.contains(kind) || value == "" {
    chat.reply("Usage: !blacklist add|remove|list <level|author|user> <value>");
    return;
}

if sub == "add" {
    if q::add_blacklist(ms, kind, value) {
        chat.reply(`Added ${kind} "${value}" to the blacklist.`);
    } else {
        chat.reply(`"${value}" is already blacklisted.`);
    }
} else {
    if q::remove_blacklist(ms, kind, value) {
        chat.reply(`Removed ${kind} "${value}" from the blacklist.`);
    } else {
        chat.reply(`"${value}" was not found in the blacklist.`);
    }
}
