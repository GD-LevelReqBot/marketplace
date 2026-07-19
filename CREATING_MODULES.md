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

// Collections (lists of JSON objects)
let col = ms.collection("items");
col.push(#{ field: "value" });     // returns doc_id
let all = col.all();               // Vec of objects
let first = col.first();
let n = col.count();
col.remove(doc._id);
col.clear();
let found = col.find(10);          // first 10 items
```

### `chat` — Send Messages

```rhai
chat.say("Hello, chat!");
chat.reply("Replying to the user who triggered this command");
```

### `user` — Command Invoker Info

```rhai
let name      = user.name();          // username (string)
let is_mod    = user.isMod();         // bool
let is_sub    = user.isSub();         // bool
let is_bc     = user.isBroadcaster(); // bool
let arg_list  = user.args();          // Vec<String> of command arguments
```

### `event` — Emit Frontend Events

```rhai
event.emit("queue-updated", ());
event.emit("my-event", #{ key: "value" });
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

## Script Key Convention

The `scripts` map keys must match the `builtin_key` of the bot commands that trigger them. When a user triggers `!mycmd`, the bot looks for a script with key `"my_cmd"` (the underscore version of the builtin_key registered in the database).

The mapping is registered automatically when you install the module — the app reads `manifest.json`'s `commands` array and creates bot_command rows for each trigger, using the first script key as the `builtin_key`.

## Testing Your Module

1. Build the `.gdmod` package locally
2. In GDLQBot → **Modules → Install from file**, pick your `.gdmod`
3. Enable the module
4. Test your commands in a connected Twitch/YouTube chat
5. Use the **Script Tester** (Settings → Developer) to run scripts in isolation
