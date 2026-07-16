// !delquote <index> — delete a quote by 1-based index (mod/broadcaster only)
let args = user.args();
if args.len() == 0 {
    chat.say("Usage: !delquote <number>");
} else {
    let idx = parse_int(args[0]) - 1;
    let col = ms.collection("quotes");
    let n = col.count();
    if idx < 0 || idx >= n {
        chat.say(`Quote number must be between 1 and ${n}.`);
    } else {
        let doc = col.at(idx);
        col.remove(doc._id);
        chat.say(`Quote #${idx + 1} deleted. (${col.count()} quotes remaining)`);
    }
}
