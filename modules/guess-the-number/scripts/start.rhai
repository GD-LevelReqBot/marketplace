// !gtn [max] — start a guess-the-number game
let args = user.args();
let max = if args.len() > 0 { parse_int(args[0]) } else { 100 };
if max < 2 { max = 100; }
let num = rand.int(1, max);
ms.set("number", num);
ms.set("max", max);
ms.set("active", true);
ms.set("guesses", 0);
chat.say(`🎲 I'm thinking of a number between 1 and ${max}! Use !guess <number> to guess!`);
