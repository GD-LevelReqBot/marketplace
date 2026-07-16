// !top — show points leaderboard
let keys = ms.list_keys("user:");
let entries = keys.map(|k| {
    let parts = k.split(":");
    #{ username: parts[1], points: ms.get(k) }
}).filter(|e| e.points != () && e.points > 0);

if entries.len() == 0 {
    chat.say("Nobody has any points yet!");
    return;
}

entries.sort_by_desc(|e| e.points);
let top5 = entries.take(5);
let parts = top5.map(|e, i| `${i+1}. @${e.username} (${e.points})`);
chat.say(`Points leaderboard: ${parts.join(" | ")}`);
