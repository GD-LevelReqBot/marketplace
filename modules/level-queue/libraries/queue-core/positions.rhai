// queue-positions — position compaction helpers.
// Import as: import "queue-positions" as pos;

/// Recompact position numbers in one collection, starting from 1.
fn recompact(col_name) {
    let col   = ms.collection(col_name);
    let items = col.all();
    let p     = 1;
    for e in items {
        col.remove(e._id);
        e.position = p;
        col.push(e);
        p += 1;
    }
}

/// Recompact both queues (call after any bulk operation).
fn recompact_all() {
    recompact("viewer");
    recompact("subscriber");
}
