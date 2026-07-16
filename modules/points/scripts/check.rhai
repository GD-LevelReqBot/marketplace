// !points [username] — check points balance
let target = if args.len() > 0 { args[0].trim_start_matches("@") } else { username };
let key = `user:${target}:points`;
let pts = ms.get(key);
if pts == () { pts = 0; }
chat.say(`@${target} has ${pts} points.`);
