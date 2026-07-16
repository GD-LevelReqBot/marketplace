// !addquote <text> — save a new quote (any viewer)
let args = user.args();
if args.len() == 0 {
    chat.say("Usage: !addquote <quote text>");
} else {
    let text = args.join(" ");
    let col = ms.collection("quotes");
    col.push(#{ text: text, by: user.name() });
    chat.say(`Quote #${col.count()} saved!`);
}
