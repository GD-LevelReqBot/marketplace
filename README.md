# GDLQBot Modules

Official and community modules for [GD Level Request Bot](https://github.com/Supernova3339/gd-levelreqbot).

## Official Modules

| Module | Description | Commands |
|--------|-------------|----------|
| **Level Queue** | Manage a GD level request queue from chat | `!r`, `!next`, `!list`, `!pos`, `!remove`, `!clear`, `!open`, `!close`, `!mylevels`, `!promote`, `!shuffle` |
| **Song Queue** | Let viewers request songs during your stream | `!sr`, `!nowplaying`, `!playlist`, `!skipsong` |
| **Points** | Track a channel currency viewers earn and spend | `!points`, `!give`, `!top`, `!addpoints` |
| **Polls** | Run live chat polls with multiple choice options | `!poll`, `!vote`, `!endpoll`, `!pollresults` |
| **Quote Manager** | Store and display memorable stream quotes | `!quote`, `!addquote`, `!delquote` |
| **Hype Counter** | Track hype with a fun chat command | `!hype`, `!resethype` |
| **Shoutout** | Give shoutouts to other streamers | `!so` |
| **Guess the Number** | Run a guess-the-number mini-game | `!gtn`, `!guess` |

## Installing Modules

Open GDLQBot → **Marketplace** tab → click **Install** on any module.

Modules are downloaded from this repository's [latest release](../../releases/latest).

## Creating Your Own Module

See [CREATING_MODULES.md](CREATING_MODULES.md) for a full guide.

## Module Package Format

Each module is distributed as a `.gdmod` file — a standard ZIP archive containing:

```
your-module.gdmod
├── manifest.json    # Module metadata, commands, panels, script key mapping
└── scripts/
    ├── command1.rhai
    └── command2.rhai
```
