// !pollresults — show current poll results
if ms.get("active") != true {
    chat.say("No poll is currently running.");
    return;
}
let question = ms.get_or("question", "Poll");
let options: Vec<String>  = io.parse_json(ms.get_or("options", "[]"));
let votes: Map = io.parse_json(ms.get_or("votes", "{}"));
let parts = [];
for i in 0..options.len() {
    let v = votes[`${i+1}`];
    parts.push(`${i+1}) ${options[i]}: ${if v == () { 0 } else { v }} votes`);
}
chat.say(`Poll "${question}": ${parts.join(" | ")}`);
