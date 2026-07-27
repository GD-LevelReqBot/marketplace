// @trigger !shuffle
// @alias
// @description Shuffle the queue order
// @roles moderator, broadcaster
// @platform all
// @cooldown 0
// @user_cooldown 0

import "queue-core" as q;

let total = ms.collection("viewer").count() + ms.collection("subscriber").count();
if total < 2 {
    // Redeemed via channel points rather than typed in chat — refund the
    // viewer's points since the shuffle never actually happened.
    if redemption_id != "" {
        twitch.cancel_redemption(redemption_id, reward_id);
    }
    chat.say("Not enough levels in the queue to shuffle.");
    return;
}

q::shuffle_queue(ms, rand);
event.emit("queue-updated", ());
chat.say("The queue has been shuffled!");