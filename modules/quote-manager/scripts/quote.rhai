// !quote — show a random saved quote
let col = ms.collection("quotes");
let n = col.count();
if n == 0 {
    chat.say("No quotes saved yet! Add one with !addquote <text>");
} else {
    let q = col.at(rand.int(0, n - 1));
    chat.say(`"${q.text}" — added by @${q.by}`);
}
