# Creating GDLQBot Modules

Modules let you add custom commands, sidebar pages, and interactive UI to GD Level Request Bot. Each module is a self-contained package of Rhai scripts, declarative UI pages, and a manifest.

**For the full UI system reference (pages, widgets, charts, forms, hot-reload), see [UI_SYSTEM.md](./UI_SYSTEM.md).**

## Quick Start

```
modules/
└── my-module/
    ├── manifest.json
    ├── scripts/
    │   └── my_command.rhai
    └── ui/
        └── main.gdui         ← declarative sidebar page (optional)
```

## manifest.json Reference

```jsonc
{
  // Unique identifier — kebab-case, no spaces
  "id": "my-module",

  // Display name shown in the app
  "name": "My Module",

  // Semantic version (MAJOR.MINOR.PATCH)
  "version": "1.0.0",

  // Minimum GDLQBot app version required
  // The app will refuse to install the module if the version requirement isn't met.
  // Use the version from the app's tauri.conf.json.
  "min_app_version": "0.1.0",

  // Author name or GitHub username
  "author": "YourName",

  // Short description shown in the marketplace
  "description": "Does something cool in your chat.",

  // Icon name — one of: queue, music, coins, poll, custom
  "icon": "custom",

  // Whether this module has been officially verified (set by maintainers, not authors)
  "verified": false,

  // Searchable tags
  "tags": ["community", "fun"],

  // Chat command triggers this module handles
  "commands": ["!mycmd", "!myothercmd"],

  // Sidebar pages — each points to a .gdui file in ui/
  // See UI_SYSTEM.md for the full page authoring reference.
  "pages": [
    { "id": "main",     "label": "Main",     "icon": "list",     "file": "ui/main.gdui" },
    { "id": "settings", "label": "Settings", "icon": "settings", "file": "ui/settings.gdui" }
  ],

  // Maps script key → relative path within this package
  // The script key matches the bot_command builtin_key in the database
  "scripts": {
    "my_cmd":       "scripts/my_command.rhai",
    "remove_entry": "scripts/remove_entry.rhai"
  }
}
```

## UI Pages

Pages are XML files in the `ui/` folder. They define the full layout and interactive controls for each sidebar entry. The system supports:

- **`<TwoColumn>`** and **`<Stack>`** — layout
- **`<Tabs>`** — tabbed views with live count badges
- **`<Toolbar>`** — open/close toggle, count badge, action buttons
- **`<List>`** — scrollable data list with row selection and row actions
- **`<DetailCard>`** — field grid driven by selection state
- **`<Form>`** — editable settings with live defaults from module store
- **`<StatCard>`** — single metric display (formatted number, percent, duration)
- **`<Chart>`** — SVG bar or line chart, no external dependencies
- **`<Import file="…">`** — splice in another `.gdui` file, for breaking large pages into smaller reusable files

See **[UI_SYSTEM.md](./UI_SYSTEM.md)** for the complete reference with examples.

## Writing Rhai Scripts

Scripts run in a sandboxed Rhai environment. The following objects are available:

### `ms` — Module Store

Namespaced key-value storage and collections for your module.

```rhai
// Key-value
ms.set("key", value);
let v = ms.get("key");
let v = ms.get_or("key", default);
ms.has("key");
ms.delete("key");
ms.incr("counter");

// Collections (lists of JSON objects, insertion-ordered — oldest first)
let col = ms.collection("items");
col.push(#{ field: "value" });     // returns doc_id
let all = col.all();               // Vec of objects, oldest first
let first = col.first();           // oldest entry
let last = col.last();             // most recently pushed entry — NOT the same as first()
let n = col.count();
col.remove(doc._id);
col.clear();
let found = col.find(10);          // first 10 items (oldest)
```

### `chat` — Send Messages

```rhai
chat.say("Hello, chat!");
chat.reply("Replying to the user who triggered this command");
chat.announce("Big news!");            // highlighted announcement on Twitch, plain say() elsewhere
chat.announce("Big news!", "purple");  // color: primary|blue|green|orange|purple
```

`announce()` posts a Twitch Helix chat announcement (the highlighted colored message type) when the command was triggered on Twitch and the bot's token has the announcement scope. It transparently falls back to a plain `say()` on YouTube, or on Twitch if Helix isn't available yet (e.g. the user hasn't reconnected since this scope was added) — it never errors your script.

### `twitch` — Twitch Helix API

General-purpose Twitch API access, available in every script (not just Twitch-triggered ones — check `is_connected()` first). Degrades gracefully to `()` / `false` when the bot isn't connected to Twitch.

```rhai
if twitch.is_connected() {
    let u = twitch.get_user("someviewer");   // #{ id, login, display_name } or ()
    if u != () {
        chat.say(u.display_name + "'s user ID is " + u.id);
    }
    twitch.announce("Hello from a script!");            // same as chat.announce(), color optional
    twitch.announce("Hello!", "green");

    // Channel-point rewards. Requires channel:manage:redemptions — the auth
    // service already requests it, so this just needs a reconnect on tokens
    // issued before that scope existed.
    let rewards = twitch.list_rewards();   // [ #{id, title, cost, prompt, is_enabled}, ... ]
    let r = twitch.create_reward("Skip the line", 500);   // or create_reward(title, cost, prompt)
}
```

#### Subscriber status

`user.isSub()` is the fast path and is already correct for real chat messages —
Twitch sends a fresh badge tag on every PRIVMSG, so there's no staleness to
worry about there. It only falls short when a script runs *without* a real
chat message behind it — a module UI action (`execute_module_action`), or a
command fired by an "Internal event" listener — where there's no badge to
read and `user.isSub()` always reports `false`. For those, `twitch.is_subscriber(login)`
does a live Helix lookup instead:

```rhai
if user.platform == "twitch" && !user.isSub() && twitch.is_subscriber(user.name) {
    // only reachable from a non-chat invocation, e.g. redeemed via a UI button
}
```

There's no YouTube equivalent — channel membership lookups by user require the
`youtube.channel-memberships.creator` OAuth scope, which isn't currently
requested (it's a more sensitive scope than what's granted today). The only
membership signal available is the same chat-message-time one `user.isSub()`
already uses (`isChatSponsor` on the live chat message) — accurate for real
chat, unavailable for non-chat invocations, with no live-lookup fallback.

#### Reacting to redemptions

Redemptions aren't polled — they arrive in real time over EventSub. To react to
one, declare `"redemption_handler": "<script_key>"` in your manifest (top
level, next to `"settings_page"`). That script runs for **every** channel-point
redemption on the channel, not just ones you created — most won't be yours, so
check and bail out immediately:

```rhai
// args: [reward_title, user_login, user_input, redemption_id, reward_id, reward_cost]
if args[0].to_lower() != "skip the line" { return; }

// It's ours — do the thing, then resolve the redemption one way or the other.
// Neither call is automatic; Twitch leaves it "unfulfilled" until you do.
twitch.complete_redemption(args[3], args[4]);   // accept
// twitch.cancel_redemption(args[3], args[4]);  // refund the viewer's points instead
```

There's no manifest-level binding from a reward to a title — reward titles are
something the streamer sets up themselves in the Twitch dashboard (this API
can't be handed a fixed reward ID at install time), so the matching has to
happen in the script, typically against an `ms`-stored setting the user
configures in your module's settings page rather than a hardcoded string like
the example above.

### `youtube` — YouTube Data API

Small by design — YouTube's chat API surface doesn't have an announcement or channel-points equivalent for the bot to trigger.

```rhai
if youtube.is_connected() {
    let ch = youtube.get_channel();   // #{ id, title } or ()
}
```

### `user` — Command Invoker Info

```rhai
let name      = user.name;            // username (string, property — no parens)
let platform  = user.platform;        // "twitch" | "youtube"
let is_mod    = user.isMod();         // bool
let is_sub    = user.isSub();         // bool
let is_bc     = user.isBroadcaster(); // bool
let is_staff  = user.isStaff();       // bool — mod OR broadcaster
```

Command arguments are `args` — a top-level array, not a method on `user`:
```rhai
let first    = args[0];
let arg_count = args.len();
```

### `event` — Emit Frontend Events

```rhai
event.emit("queue-updated", ());
event.emit("my-event", #{ key: "value" });
```

`emit()` does three things: pushes to the frontend/WebSocket (as before), and also fires any command whose "Internal event" listener is bound to that name — either the bare name, or the module-namespaced form (`<author-slug>.<module-id>.<name>`, e.g. `gdlqbot-team.level-queue.next-level`), which is what shows up in the listener picker. Declare events your module emits in the manifest's `events` array (`key`, `label`, `description`) so they actually show up there instead of requiring users to know/type the exact name.

`emit()` refuses to dispatch a name that's already earlier in the current dispatch chain (a listener command's script re-emitting the event that triggered it, directly or via other events) — logged as a cycle, not a silent no-op, so it's visible in the dev console if it happens.

```rhai
// Was this event emitted in the last 5 seconds (or a custom window)? Useful
// when the same script can be reached two independent ways (a chat command
// and a UI button both running it) and you want the second one to not repeat
// whatever the first one already did:
if event.emitted("level-nexted", 5) {
    // already advanced moments ago — restate it instead of doing it again
} else {
    // do the thing, then event.emit("level-nexted", ...)
}
```

### `time` — Timestamps

```rhai
let now = time.utc();    // ISO 8601 UTC string
let ts  = time.unix();   // Unix timestamp (i64)
```

### `rand` — Random Numbers

```rhai
let n   = rand.int(1, 100);      // random integer in [1, 100]
let f   = rand.float();          // random float in [0.0, 1.0)
let arr = rand.shuffle(my_vec);  // returns shuffled copy
```

### `io` — JSON / Data Utilities

```rhai
let json_str = io.encode_json(value);
let value    = io.parse_json(json_str);
```

### Built-in Functions

```rhai
parse_int("42")      // -> 42 or ()
parse_float("3.14")  // -> 3.14 or ()
```

## Version Compatibility

The `min_app_version` field prevents your module from being installed on an older app version that doesn't support the features you use.

**Rule of thumb:**
- If you only use `ms`, `chat`, `user`, `event`, `time`, `rand`, `io` — use `"min_app_version": "0.1.0"`
- `twitch`, `youtube`, and `chat.announce()` are newer additions — bump `min_app_version` accordingly once this app version ships, so older installs get a clear "update the app" message instead of a missing-variable script error
- New scripting APIs added in future app versions will be documented with their required minimum version

The app checks `min_app_version` using semantic versioning: `app_version >= min_app_version`.

## Packaging

Modules are packaged as `.gdmod` files (standard ZIP archives). The GitHub Actions workflow in this repository handles packaging automatically when a release tag is pushed.

To test locally, create the zip manually:
```bash
cd modules/my-module
zip -r my-module.gdmod manifest.json scripts/
```

Then install it in the app via **Modules → Install from file**.

## Locking Part of a Script

Users can save a per-command script override from Settings → Commands (it's
how they customize a builtin command's behavior). If some of your script is
load-bearing enough that an edit there would break in a confusing way — not
"wrong output," but "the queue page stops working" — wrap just that part in
`// @lock` / `// @unlock`:

```rhai
// @lock
let entry = q::pop_next(ms, rand, time);
if entry == () { chat.say("The queue is empty!"); return; }
event.emit("queue-updated", ());
// @unlock
chat.announce(`Next level: ${entry.level_id}`);  // this line stays fully editable
```

This is content-based, not position-based: everything *outside* a locked
block is freely editable (including reordering code around it), but the
locked block itself must survive verbatim into a saved override or the save
is rejected — both in the editor (before the round-trip) and server-side (the
part that actually matters, in case the frontend check is ever bypassed).
There's no whole-script lock — if a command has no lockable parts, don't add
the markers; users can already customize the whole thing today, that's the
point of the override mechanism.

## Script Key Convention

The `scripts` map keys must match the `builtin_key` of the bot commands that trigger them. When a user triggers `!mycmd`, the bot looks for a script with key `"my_cmd"` (the underscore version of the builtin_key registered in the database).

The mapping is registered automatically when you install the module — the app reads `manifest.json`'s `commands` array and creates bot_command rows for each trigger, using the first script key as the `builtin_key`.

## Testing Your Module

1. Build the `.gdmod` package locally
2. In GDLQBot → **Modules → Install from file**, pick your `.gdmod`
3. Enable the module
4. Test your commands in a connected Twitch/YouTube chat
5. Use the **Script Tester** (Settings → Developer) to run scripts in isolation
