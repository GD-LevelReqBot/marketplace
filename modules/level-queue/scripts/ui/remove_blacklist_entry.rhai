// Removes by doc _id — kind-agnostic, used by the Remove row action on all
// three Blacklisted * tabs. `!blacklist remove <kind> <value>` (chat command)
// uses a different, value-matching removal in queue-core instead.
if args.len() > 0 {
    ms.collection("blacklist").remove(args[0]);
}
event.emit("queue-updated", ());
