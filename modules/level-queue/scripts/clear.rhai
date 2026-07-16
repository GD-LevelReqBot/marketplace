// !clear — clear the entire queue (mod/broadcaster only)
ms.collection("viewer").clear();
ms.collection("subscriber").clear();
event.emit("queue-updated", ());
chat.say("The level queue has been cleared.");
