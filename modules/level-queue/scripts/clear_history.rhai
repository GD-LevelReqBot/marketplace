// clear_history — clear the level history (mod/broadcaster only)
ms.collection("history").clear();
event.emit("queue-updated", ());
chat.say("Level history cleared.");
