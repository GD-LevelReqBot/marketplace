// !resethype — reset the hype counter (mod/broadcaster only)
let old = ms.get("count") ?? 0;
ms.set("count", 0);
chat.say(`Hype counter reset! (was at ${old})`);
