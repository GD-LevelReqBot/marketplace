// @trigger !next
// @alias
// @description Pop the next level from the queue
// @roles moderator, broadcaster
// @platform all
// @cooldown 0
// @user_cooldown 0

import "queue-core" as q;

// @lock
// Chat's !next and the queue page's "Next Level" button both run this same
// script. If the queue was JUST advanced (either way) in the last few
// seconds, don't pop a second level out from under whoever's next in line —
// just restate whichever one we already popped.
if event.emitted("level-nexted", 5) {
    let last = ms.collection("history").last();
    if last != () {
        chat.announce(`Next level: ${last.level_id} - requested by @${last.username} [${last.queue_type}]`);
        return;
    }
}

let entry = q::pop_next(ms, rand, time);

if entry == () {
    chat.say("The queue is empty!");
    return;
}

event.emit("queue-updated", ());
event.emit("level-nexted", #{ level_id: entry.level_id, username: entry.username, queue_type: entry.queue_type });
// @unlock

// The pop/dedup/event logic above is locked — it's what keeps the queue page
// and the dedup-guard correct. The announcement text itself isn't, customize
// away (emotes, phrasing, whatever):
chat.announce(`Next level: ${entry.level_id} - requested by @${entry.username} [${entry.queue_type}]`);