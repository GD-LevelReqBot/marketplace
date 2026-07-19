// @trigger !list
// @alias
// @description Show the current queue
// @roles everyone
// @platform all
// @cooldown 5
// @user_cooldown 0

let page = if args.len() > 0 { parse_int(args[0]) } else { 1 };
if page == () || page < 1 { page = 1; }
let per_page = 5;
let offset   = (page - 1) * per_page;
let sub_mode = ms.get("sub_mode") ?? false;
let parts    = [];

if sub_mode {
    let subs      = ms.collection("subscriber").all();
    let page_subs = subs.extract(offset, per_page);
    if page_subs.len() > 0 {
        let items = page_subs.map(|e| `#${e.position} ${e.level_id} (@${e.username})`);
        parts.push(`[Sub] ${items.join(" | ")}`);
    }
}

let viewers      = ms.collection("viewer").all();
let page_viewers = viewers.extract(offset, per_page);
if page_viewers.len() > 0 {
    let items = page_viewers.map(|e| `#${e.position} ${e.level_id} (@${e.username})`);
    parts.push(`[Viewer] ${items.join(" | ")}`);
}

if parts.len() == 0 {
    chat.say("The queue is empty!");
} else {
    chat.say(`Queue p.${page}: ${parts.join(" | ")}`);
}