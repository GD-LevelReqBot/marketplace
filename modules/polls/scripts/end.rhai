// !endpoll — end the active poll and announce results
if ms.get("active") != true {
    chat.say("No poll is currently running.");
    return;
}
let question = ms.get_or("question", "Poll");
let options: Vec<String>  = io.parse_json(ms.get_or("options", "[]"));
let votes: Map = io.parse_json(ms.get_or("votes", "{}"));

let results = [];
for i in 0..options.len() {
    let v = votes[`${i+1}`];
    results.push(#{ option: options[i], votes: if v == () { 0 } else { v }, index: i+1 });
}
results.sort_by_desc(|r| r.votes);

let winner = results[0];
let parts = results.map(|r| `${r.index}) ${r.option}: ${r.votes} votes`);

// Clear poll state
ms.set("active", false);
ms.delete("question");
ms.delete("options");
ms.delete("votes");

// Clear voter tracking
let voter_keys = ms.list_keys("voter:");
for k in voter_keys { ms.delete(k); }

event.emit("queue-updated", ());
chat.say(`Poll ended! "${question}" — ${parts.join(" | ")} — Winner: "${winner.option}" with ${winner.votes} votes!`);
