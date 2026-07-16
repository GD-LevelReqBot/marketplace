// !mylevels — show the calling user's levels in the queue
let all = ms.collection("viewer").all() + ms.collection("subscriber").all();
let mine = all.filter(|e| e.username == user.name);

if mine.len() == 0 {
    chat.reply("You have no levels in the queue.");
} else {
    let parts = mine.map(|e| {
        let qt = if e.is_subscriber == true { "sub" } else { "viewer" };
        `${e.level_id} [${qt}]`
    });
    chat.reply(`Your levels: ${parts.join(", ")}`);
}
