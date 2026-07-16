// !playlist — show the song queue
let songs = ms.collection("queue").find(5);
if songs.len() == 0 {
    chat.say("The song queue is empty!");
} else {
    let items = songs.map(|s| `"${s.title}" by @${s.username}`);
    chat.say(`Song queue (${ms.collection("queue").count()} total): ${items.join(" → ")}`);
}
