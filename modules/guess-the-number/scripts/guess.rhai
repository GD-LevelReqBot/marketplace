// !guess <number> — submit a guess
let active = ms.get("active") ?? false;
if !active {
    chat.say("No game running! Start one with !gtn");
} else {
    let args = user.args();
    if args.len() == 0 {
        chat.say("Usage: !guess <number>");
    } else {
        let g = parse_int(args[0]);
        let answer = ms.get("number");
        let max = ms.get("max") ?? 100;
        let guesses = (ms.get("guesses") ?? 0) + 1;
        ms.set("guesses", guesses);

        if g == answer {
            ms.set("active", false);
            chat.say(`🎉 @${user.name()} got it! The number was ${answer}! (${guesses} guesses)`);
        } else if g < answer {
            chat.say(`@${user.name()}: ${g} is too low! (guess ${guesses})`);
        } else {
            chat.say(`@${user.name()}: ${g} is too high! (guess ${guesses})`);
        }
    }
}
