# GDUI — Module UI System

GDUI is the declarative UI format for GDLQBot modules. Pages are defined in XML files (`.gdui`) stored in the module's `ui/` folder. The app reads these files at runtime, parses them into a layout tree, and renders them as native UI panels in the sidebar.

## How it works

```
manifest.json → pages[].file → ui/queue.gdui
                                  │
                                  ▼
                        XML parsed into LayoutNode tree
                                  │
                                  ▼
                    Rendered by the app as interactive UI
```

Each page gets its own sidebar navigation entry. Clicking it loads and renders the `.gdui` file for that page.

---

## Module structure

```
my-module/
├── manifest.json
├── scripts/
│   ├── commands/              ← can nest scripts in subdirectories
│   │   └── request.rhai
│   └── save_settings.rhai     ← action scripts called by the UI
├── ui/
│   ├── main.gdui              ← sidebar pages
│   └── settings.gdui          ← settings page (shown in Settings > Modules)
├── libraries/
│   └── my-lib/                ← bundled Rhai library (auto-installed with module)
│       ├── manifest.json
│       └── my_lib.rhai
└── resources/
    ├── icons/
    │   └── my-icon.svg        ← custom icons (<Icon name="local:my-icon"/>)
    └── icon.png
```

### Nested script paths

Script paths in `manifest.json` can be nested at any depth:
```json
{
  "scripts": {
    "request":       "scripts/commands/request.rhai",
    "save_settings": "scripts/settings/save.rhai"
  }
}
```

### Bundled libraries

Modules can ship Rhai libraries that are auto-installed when the module is installed:
```json
{
  "bundle": {
    "libraries": [
      { "name": "my-lib", "file": "libraries/my-lib/my_lib.rhai", "description": "Core helpers" }
    ]
  }
}
```

Scripts then import the library:
```rhai
import "my-lib" as lib;
let result = lib::my_function(42);
```

### Settings page

Declare a settings page to surface it in the app's Settings modal under **Modules**:
```json
{
  "settings_page": "ui/settings.gdui"
}
```

### manifest.json — pages field

```json
{
  "pages": [
    { "id": "main",     "label": "Main",     "icon": "queue",    "file": "ui/main.gdui" },
    { "id": "settings", "label": "Settings", "icon": "settings", "file": "ui/settings.gdui" }
  ]
}
```

| Field  | Required | Description |
|--------|----------|-------------|
| `id`   | ✓ | Unique identifier within this module |
| `label`| ✓ | Display name in the sidebar |
| `icon` | ✓ | Icon name — see [Icons](#icons) |
| `file` | ✓ | Relative path to the `.gdui` file |

---

## File format

A `.gdui` file is well-formed UTF-8 XML with a `<Page>` root element.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Page id="main" label="Main" icon="queue">
  <!-- one top-level layout element -->
  <TwoColumn leftWidth="300">
    <Left>
      <Stack>
        <Toolbar …/>
        <List …/>
      </Stack>
    </Left>
    <Right>
      <DetailCard …/>
    </Right>
  </TwoColumn>
</Page>
```

---

## Elements reference

### Layout elements

#### `<TwoColumn>`

Splits the page into a fixed-width left panel and a flexible right panel.

```xml
<TwoColumn leftWidth="300">
  <Left>
    <!-- left panel content -->
  </Left>
  <Right>
    <!-- right panel content -->
  </Right>
</TwoColumn>
```

| Attribute   | Default | Description |
|-------------|---------|-------------|
| `leftWidth` | `280`   | Left panel width in pixels |

---

#### `<Stack>`

Stacks children vertically (default) or horizontally.

```xml
<Stack direction="horizontal" gap="12">
  <StatCard label="Total" valueExpr="ms.count()"/>
  <StatCard label="Open"  valueExpr="ms.get(&quot;open&quot;)"/>
</Stack>
```

| Attribute   | Default      | Description |
|-------------|--------------|-------------|
| `direction` | `"vertical"` | `"vertical"` or `"horizontal"` |
| `gap`       | `0`          | Gap between children in pixels |

---

#### `<Tabs>`

Renders a tabbed container. Each `<Tab>` child becomes one tab.

```xml
<Tabs selectionKey="selected">
  <Tab label="Subscribers" badgeExpr="ms.collection(&quot;sub&quot;).count()">
    <List …/>
  </Tab>
  <Tab label="Viewers" badgeExpr="ms.collection(&quot;viewer&quot;).count()">
    <List …/>
  </Tab>
  <Tab label="Advanced" showExpr="ms.get_or(&quot;advanced_mode&quot;, false)">
    <List …/>
  </Tab>
</Tabs>
```

| Attribute      | Description |
|----------------|-------------|
| `selectionKey` | Clears shared state at this key when switching tabs |

**`<Tab>` attributes:**

| Attribute   | Description |
|-------------|-------------|
| `label`     | Tab display text |
| `badgeExpr` | Rhai expression returning a number shown as a count chip |
| `showExpr`  | Rhai expression; the whole tab (strip button + content) is hidden when falsy |
| `showKey`   | State key; same as `showExpr` but reads page state instead of evaluating Rhai |

Hiding a tab is different from wrapping its content in `<Conditional>` — a hidden tab disappears from the strip entirely, not just its content area. Every tab's `showExpr` is batched into a single eval call, so adding several gated tabs doesn't cost extra round trips. If the currently-active tab becomes hidden (e.g. a setting it depends on gets toggled off elsewhere), the view automatically switches to the first still-visible tab.

---

### Data widgets

#### `<Toolbar>`

A control bar with an open/close toggle, a count display, and action buttons.

```xml
<Toolbar
  statusExpr="ms.get(&quot;open&quot;)"
  statusOnLabel="Queue Open"
  statusOffLabel="Queue Closed"
  statusActionOn="open_queue"
  statusActionOff="close_queue"
  countExpr="ms.collection(&quot;viewer&quot;).count()"
  maxExpr="ms.get(&quot;max_size&quot;)">
  <Action label="Next"      key="next"/>
  <Action label="Shuffle"   key="shuffle"/>
  <Action label="Clear All" key="clear" style="danger"/>
</Toolbar>
```

| Attribute          | Description |
|--------------------|-------------|
| `statusExpr`       | Rhai expression returning `true` (open) or `false` (closed) |
| `statusOnLabel`    | Badge text when status is true |
| `statusOffLabel`   | Badge text when status is false |
| `statusActionOn`   | Script key to call when toggling from open → closed |
| `statusActionOff`  | Script key to call when toggling from closed → open |
| `countExpr`        | Rhai expression returning a number (shown as current count) |
| `maxExpr`          | Rhai expression returning the maximum (shown as `/max`) |

**`<Action>` attributes:**

| Attribute | Default     | Description |
|-----------|-------------|-------------|
| `label`   |             | Button text |
| `key`     |             | Module script key to execute |
| `style`   | `"default"` | `"default"` · `"danger"` · `"success"` · `"primary"` |
| `args`    |             | Comma-separated arguments passed to the script |

---

#### `<List>`

A scrollable list of rows fetched from the module store. Rows can be selected (populating a shared state slot) and have per-row action buttons.

```xml
<List
  rowId="level_id"
  primary="username"
  secondary="level_id"
  platform="platform"
  selectionKey="selected"
  emptyMessage="Nothing here yet">
  <Section label="Subscribers" dataExpr="ms.collection(&quot;subscriber&quot;).all()"/>
  <Section label="Viewers"     dataExpr="ms.collection(&quot;viewer&quot;).all()"/>
  <RowAction label="Promote" key="promote" argField="level_id"/>
  <RowAction label="Remove"  key="remove"  argField="level_id" style="danger"/>
</List>
```

| Attribute      | Description |
|----------------|-------------|
| `rowId`        | Field used as a unique row key |
| `primary`      | Field shown as the main row label |
| `secondary`    | Field shown as secondary text below primary |
| `platform`     | Field containing `"twitch"` or `"youtube"` — renders a colored dot |
| `selectionKey` | State key written when a row is clicked (value = entire row object) |
| `emptyMessage` | Text shown when all sections are empty |

**`<Section>` attributes:**

| Attribute  | Description |
|------------|-------------|
| `label`    | Optional section header (hidden when section has no rows) |
| `dataExpr` | Rhai expression returning an array of row objects |

**`<RowAction>` attributes:**

| Attribute  | Default     | Description |
|------------|-------------|-------------|
| `label`    |             | Button text |
| `key`      |             | Module script key to execute |
| `argField` | `rowId`     | Field from the row passed as `args[0]` |
| `style`    | `"default"` | `"default"` · `"danger"` |

---

#### `<DetailCard>`

Fetches data with a Rhai expression and renders it as a grid of labelled fields. Typically placed in the right panel of a `<TwoColumn>` and driven by the selection state of a `<List>`.

```xml
<DetailCard
  dataExpr="gd.get_level(selected.level_id)"
  placeholder="Select a level to view details">
  <Field key="level_name"  label="Level Name"/>
  <Field key="difficulty"  label="Difficulty"  type="badge"/>
  <Field key="stars"       label="Stars"       type="stars"/>
  <Field key="downloads"   label="Downloads"   type="number"/>
  <Field key="description" label="Description"/>
</DetailCard>
```

The entire page state is injected into the Rhai scope when `dataExpr` runs. So if a `<List>` sets `selectionKey="selected"`, then `selected.level_id` is available in the expression.

| Attribute     | Description |
|---------------|-------------|
| `dataExpr`    | Rhai expression returning an object or `null` |
| `placeholder` | Text shown when data is null / nothing is selected |

**`<Field>` attributes:**

| Attribute | Default  | Description |
|-----------|----------|-------------|
| `key`     |          | Object key to read |
| `label`   |          | Display label |
| `type`    | `"text"` | `"text"` · `"number"` · `"badge"` · `"stars"` · `"image"` |

---

#### `<Form>`

An editable settings form. All fields' `defaultExpr`s are loaded in a single Rhai call on mount (not one round trip per field), so the form appears with real data quickly instead of fields populating one at a time. By default there's **no Save button** — every change (a keystroke settling for 500ms, a toggle flip, a select change) auto-saves by calling a module script with the form's current values as a JSON string in `args[0]`. Status ("Unsaved changes…" → "Saving…" → "Saved ✓", or an error) shows in the page's shared topbar (see "Page-wide status" below) — there's nothing to click, and no per-Form status bar cluttering the page.

Set `autosave="false"` to go back to an explicit Save button instead — appropriate when the submit script has a side effect you don't want firing on every keystroke (re-registering a webhook, restarting a connection, etc.).

```xml
<Form submitKey="save_settings" title="Queue Settings">
  <Input  key="max_size"  label="Max Queue Size"  type="number"
          defaultExpr="ms.get_or(&quot;max_size&quot;, 25)" min="1" max="500"/>
  <Input  key="prefix"    label="Command Prefix"
          defaultExpr="ms.get_or(&quot;prefix&quot;, &quot;!&quot;)"/>
  <Textarea key="welcome" label="Welcome Message"
            defaultExpr="ms.get_or(&quot;welcome&quot;, &quot;&quot;)"/>
  <Select key="mode"      label="Mode" defaultExpr="ms.get_or(&quot;mode&quot;, &quot;normal&quot;)">
    <Option value="normal" label="Normal"/>
    <Option value="strict" label="Strict"/>
  </Select>
  <Toggle key="open"      label="Queue Open"
          defaultExpr="ms.get_or(&quot;open&quot;, true)"/>
</Form>
```

The module script (`submitKey`) receives **every field's current value**, not just what changed, as JSON in `args[0]` — not `user.args()`, which doesn't exist; `args` is a top-level array, same as in command scripts:

```rhai
let data = io.parse_json(args[0]);
// data.max_size, data.prefix, data.open, etc. are all present every save —
// the `!= ()` guard below is defensive (a field could be genuinely unset),
// not a "did this one change" check.
if data.max_size != () {
    ms.set("max_size", parse_int(to_string(data.max_size)));
}
event.emit("queue-updated", ());
```

| Attribute   | Default | Description |
|-------------|---------|-------------|
| `title`     | —       | Optional heading rendered above the fields |
| `submitKey` | —       | Module script key called on save, with every field's value as JSON in `args[0]` |
| `autosave`  | `true`  | `false` swaps the topbar-driven autosave for an explicit Save button |

**Organizing many fields — `group`, not multiple `<Form>`s.** Every field element (`<Input>`, `<Toggle>`, `<Select>`, `<Textarea>`) accepts a `group="…"` attribute. Consecutive fields sharing a group get one header above them; changing group starts a new section. **Don't** split a long settings page into several `<Form>`s to get this visual grouping — each `<Form>`'s root wants `flex: 1` to fill whatever contains it, and several `<Form>`s placed side by side compete for that same space instead of stacking at their natural height, which silently breaks the page's scrolling. One `<Form>`, grouped fields, scrolls correctly as a single region.

A toggle group of 4 or more renders as a wrapping chip grid (click a chip to flip it, small check mark = on) with **All** / **None** shortcuts in the header, instead of a stack of identical switch rows — appropriate for "pick which of these tiers/categories are enabled" sets (difficulty tiers, allowed lengths, …). Groups of 1–3 toggles, or ungrouped toggles, stay as classic switch rows, where a chip would read oddly for a single yes/no flag ("Enable feature X" isn't "pick from a set").

```xml
<Form submitKey="save_settings">
  <Toggle key="no_disliked_levels" label="Block disliked levels" group="General"
          defaultExpr="ms.get_or(&quot;no_disliked_levels&quot;, false)"/>

  <!-- 8 toggles in one group → renders as a chip grid with All/None -->
  <Toggle key="diff_easy"   label="Easy"   group="Difficulty" defaultExpr="ms.get_or(&quot;diff_easy&quot;, true)"/>
  <Toggle key="diff_normal" label="Normal" group="Difficulty" defaultExpr="ms.get_or(&quot;diff_normal&quot;, true)"/>
  <!-- … -->
</Form>
```

#### Page-wide status ("topbar")

Every module page has one shared status line, shown as a thin bar at the very top of the page (above everything, including sub-page back-navigation). `<Form>` posts its own save progress there automatically; any action dispatched via a `actionKey`/`submitKey`-style attribute (`<Button actionKey>`, `<Toggle actionKey>`, `<ActionMenu>`, etc.) posts there too if the action script errors. There is no way to author a `showExpr`-style hookup into it from `.gdui` XML directly — it's driven entirely by the app's own dispatch/save machinery, not something a page author configures. It exists so status feedback reads as one consistent place instead of a differently-styled toast/bar per widget:

- **pending** (amber) — an edit is debounced / a save or action is in flight
- **success** (green) — auto-clears after ~2s
- **error** (red) — stays until dismissed (×) or replaced by a newer status
- **info** (blue) — auto-clears after ~3s; reserved for future use

If a page has several logically separate settings groups, prefer several `<Tab>`s (optionally gated with `showExpr`, see `<Tabs>` above) over several `<Form>`s stacked in one view — each `<Form>` autosaves and shows its own status strip independently, which reads as several unrelated save operations if they're visibly stacked together.

**Field elements:**

| Element    | type attribute | Description |
|------------|---------------|-------------|
| `<Input>`  | `"text"` (default) or `"number"` | Single-line text or number input |
| `<Textarea>` | — | Multi-line text area |
| `<Toggle>` | — | Boolean toggle switch |
| `<Select>` | — | Dropdown with `<Option>` children |

**Common field attributes:**

| Attribute     | Description |
|---------------|-------------|
| `key`         | Field identifier — used as the key in the submitted JSON |
| `label`       | Display label |
| `defaultExpr` | Rhai expression for the initial value (evaluated on mount) |
| `placeholder` | Placeholder text (Input/Textarea only) |
| `min` / `max` | Numeric bounds (Input type=number only) |

---

#### `<StatCard>`

Displays a single evaluated value in a large metric card. Good for dashboards and stats sections.

```xml
<StatCard
  label="Total Queued"
  valueExpr="ms.collection(&quot;viewer&quot;).count() + ms.collection(&quot;sub&quot;).count()"
  format="number"/>
```

| Attribute   | Default  | Description |
|-------------|----------|-------------|
| `label`     |          | Caption below the value |
| `valueExpr` |          | Rhai expression returning a scalar |
| `format`    | `"text"` | `"number"` (localized) · `"percent"` · `"duration"` (seconds → `1h 30m`) · `"text"` |

---

#### `<Chart>`

Renders an SVG chart (no external dependencies). Expects an array of objects from `dataExpr`.

```xml
<!-- Bar chart: how many times each viewer has requested a level -->
<Chart type="bar"
       dataExpr="ms.collection(&quot;history&quot;).find(20)"
       xKey="username"
       yKey="level_id"
       color="#7c3aed"/>

<!-- Line chart: queue size over time -->
<Chart type="line"
       dataExpr="ms.get_or(&quot;size_history&quot;, [])"
       xKey="ts"
       yKey="count"/>
```

| Attribute   | Default              | Description |
|-------------|----------------------|-------------|
| `type`      | `"bar"`              | `"bar"` or `"line"` |
| `dataExpr`  |                      | Rhai expression returning an array of objects |
| `xKey`      | `"label"`            | Object field for X-axis labels |
| `yKey`      | `"value"`            | Object field for Y-axis values (must be numeric) |
| `color`     | `var(--color-accent)`| Bar/line fill color (any CSS color) |

Up to 50 data points are rendered; the rest are silently truncated.

---

### Interactive elements

#### `<Button>`

A clickable button. Can execute a module action, navigate to a sub-page, or set page state.

```xml
<!-- Execute an action -->
<Button label="Next Level" actionKey="next" variant="primary"/>

<!-- Navigate to a sub-page -->
<Button label="View Details" navigateTo="detail"/>
<Button label="Back" navigateTo=".."/>

<!-- Set state (e.g. toggle a flag) -->
<Button label="Show" stateKey="show_panel" stateValue="true"/>

<!-- Dynamic label -->
<Button labelExpr="'Count: ' + ms.collection('viewer').count()" variant="ghost"/>

<!-- After the action succeeds, pull fresh data straight into page state — e.g.
     show the level a "Next" action just popped, without the user selecting a row -->
<Button label="Next Level" actionKey="next" variant="primary"
        afterStateKey="selected" afterStateExpr="ms.collection('history').last()"/>
```

| Attribute         | Default   | Description |
|-------------------|-----------|-------------|
| `label`           | `"Button"` | Button text (static) |
| `labelExpr`       | —         | Rhai expression for dynamic label |
| `actionKey`       | —         | Module action script to run on click |
| `args`            | —         | Comma-separated args passed to action |
| `argState`        | —         | Dot-path into page state used as the action's arg (e.g. `"selected.level_id"`) — takes priority over `args`. Comma-separate for multiple args: `"new_id, new_username"` → `args[0]`, `args[1]` |
| `navigateTo`      | —         | Sub-page id to navigate to, or `".."` to go back |
| `stateKey`        | —         | State key to set immediately on click |
| `stateValue`      | `true`    | Value to set (`true`, `false`, or a string/number) |
| `afterStateKey`   | —         | State key to set once `actionKey` *succeeds* |
| `afterStateExpr`  | —         | Rhai expression evaluated (with current page state in scope) and stored under `afterStateKey` |
| `disabledExpr`    | —         | Rhai expression; button is disabled when truthy |
| `variant`         | `default` | `primary` · `ghost` · `danger` · `warn` · `success` · `default` |

`stateKey`/`stateValue` set immediately, client-side, on every click — for `afterStateKey`/`afterStateExpr`, the expression only runs (and only overwrites the state) after the dispatched action has actually completed successfully, so it can read data the action just created.

---

#### `<Text>`

Dynamic or static text display.

```xml
<Text value="if ms.get('open') { 'Queue is open' } else { 'Queue is closed' }" style="accent"/>
<Text static="Queue Module" style="title"/>
<Text value="'Total: ' + (ms.collection('viewer').count() + ms.collection('subscriber').count())" style="muted" wrap="true"/>
```

| Attribute | Default    | Description |
|-----------|------------|-------------|
| `value`   | —          | Rhai expression returning a string |
| `static`  | —          | Static (non-evaluated) string |
| `style`   | `default`  | `default` · `title` · `subtitle` · `muted` · `accent` · `error` · `code` |
| `size`    | (by style) | Font size in px |
| `wrap`    | `false`    | If `true`, wraps instead of truncating |

---

#### `<Badge>`

A compact status pill/chip.

```xml
<Badge value="if ms.get('open') { 'Open' } else { 'Closed' }" variant="success"/>
<Badge static="Beta" color="#7c3aed"/>
```

| Attribute  | Default   | Description |
|------------|-----------|-------------|
| `value`    | —         | Rhai expression |
| `static`   | —         | Static text |
| `variant`  | `default` | `default` · `success` · `warn` · `danger` · `accent` |
| `color`    | —         | Custom CSS color (overrides variant) |

---

#### `<Icon>`

Renders an icon from any provider.

```xml
<Icon name="lucide:star" size="18"/>
<Icon name="builtin:queue" size="20" color="#7c3aed"/>
<Icon name="local:my-icon" size="24"/>
```

| Namespace  | Format            | Source |
|------------|-------------------|--------|
| `lucide:`  | `lucide:star`     | [Lucide](https://lucide.dev) icon library |
| `builtin:` | `builtin:queue`   | App built-in icons: `queue` `music` `star` `coins` `check` `error` |
| `local:`   | `local:my-icon`   | SVG file from `resources/icons/<name>.svg` in the module |

---

#### `<Divider>`

A horizontal separator line, optionally labelled.

```xml
<Divider/>
<Divider label="Statistics"/>
```

---

#### `<Spacer>`

A flex spacer for pushing elements apart.

```xml
<Stack direction="horizontal">
  <Text value="'Left'" />
  <Spacer/>
  <Button label="Right" actionKey="action"/>
</Stack>

<!-- Fixed-size gap -->
<Spacer size="12"/>
```

---

### Layout elements (additional)

#### `<Grid>`

CSS grid layout with configurable columns.

```xml
<Grid columns="3" gap="12">
  <StatCard label="Viewers" valueExpr="ms.collection('viewer').count()"/>
  <StatCard label="Subscribers" valueExpr="ms.collection('subscriber').count()"/>
  <StatCard label="History" valueExpr="ms.collection('history').count()"/>
</Grid>

<!-- Custom template columns -->
<Grid columns="1fr 2fr" gap="8">
  ...
</Grid>
```

| Attribute | Default | Description |
|-----------|---------|-------------|
| `columns` | `2`     | Number of columns or CSS grid-template-columns value |
| `gap`     | `12`    | Gap between cells in px |

---

### Control flow

#### `<Conditional>`

Shows its child only when an expression or state key is truthy.

```xml
<!-- Based on module store data -->
<Conditional showExpr="ms.get('open') == true">
  <Button label="Close Queue" actionKey="close_queue" variant="danger"/>
</Conditional>

<!-- Based on page state (no Rhai eval needed) -->
<Conditional showKey="show_details">
  <DetailCard dataExpr="gd.get_level(selected.level_id)">
    <Field key="level_name" label="Name"/>
  </DetailCard>
</Conditional>
```

| Attribute   | Description |
|-------------|-------------|
| `showExpr`  | Rhai expression; renders child when truthy |
| `showKey`   | State key; renders child when `state[key]` is truthy |

---

#### `<Each>`

Repeats a template for each item in an array expression.

```xml
<Each items="ms.collection('history').all()" as="entry" keyField="_id">
  <Stack direction="horizontal">
    <Text value="entry.level_id" style="accent"/>
    <Text value="entry.username" style="muted"/>
    <Spacer/>
    <Badge value="entry.queue_type"/>
  </Stack>
</Each>
```

Inside the template, `entry` (or whatever `as` specifies) is the current item, and `entry_index` is its 0-based position.

| Attribute  | Default  | Description |
|------------|----------|-------------|
| `items`    | —        | Rhai expression returning an array |
| `as`       | `item`   | Variable name injected per iteration |
| `keyField` | —        | Field on each item used as the React key (improves performance) |

---

#### `<Import>`

Splices another `.gdui` file in place of the tag, so a large page can be broken up into smaller, reusable files instead of one giant XML document.

```xml
<!-- ui/queue.gdui -->
<Page id="queue" label="Queue">
  <Stack>
    <Import file="ui/parts/queue-header.gdui"/>
    <Import file="ui/parts/queue-list.gdui"/>
  </Stack>
</Page>
```

```xml
<!-- ui/parts/queue-list.gdui -->
<Fragment>
  <List rowId="_id" primary="username" secondary="level_id" platform="platform" selectionKey="selected">
    <Section dataExpr="ms.collection('subscriber').all()"/>
    <RowAction label="Remove" key="remove" argField="level_id" style="danger"/>
  </List>
</Fragment>
```

| Attribute | Description |
|-----------|-------------|
| `file`    | Path to the imported `.gdui` file, **relative to the module root** (same convention as page/icon paths — e.g. `"ui/parts/queue-list.gdui"`), not relative to the importing file |

Rules:
- The imported file's root element must be `<Fragment>` — the wrapper itself is discarded and its children take the `<Import>` tag's place. Any other root tag is a load error.
- A `<Fragment>` file can itself contain `<Import>` tags (resolved before it's spliced in).
- A file that (transitively) imports itself is rejected as a circular import; import chains deeper than 8 are rejected too.
- Imports are resolved once per page load, before the page is parsed — expressions and state inside an imported fragment behave exactly as if they were written inline, sharing the same page state/context as the rest of the page.

---

### Sub-pages

Sub-pages are alternate layouts within a page, navigated to via `<Button navigateTo="…">`. They share the same page state and context.

```xml
<Page id="queue" label="Queue">

  <!-- Root layout -->
  <Stack>
    <List rowId="level_id" primary="level_id" selectionKey="selected">
      <Section dataExpr="ms.collection('viewer').all()"/>
    </List>
    <Button label="View Details" navigateTo="detail" stateKey="detail_id"
            stateValue="selected.level_id"/>
  </Stack>

  <!-- Sub-page: shown when navigateTo="detail" is clicked -->
  <SubPage id="detail">
    <Stack>
      <!-- Back button is auto-provided by the header, but you can add your own -->
      <DetailCard dataExpr="gd.get_level(detail_id)">
        <Field key="level_name" label="Name"/>
        <Field key="difficulty"  label="Difficulty"/>
        <Field key="stars"       label="Stars" type="stars"/>
      </DetailCard>
    </Stack>
  </SubPage>

</Page>
```

Sub-pages are defined as `<SubPage id="…">` siblings of the root layout, directly under `<Page>`. The back navigation bar is automatically added at the top when a sub-page is active.

---

## Expressions

Every `*Expr` attribute is a Rhai snippet evaluated inside the module's scripting context. The full module scripting API is available (`ms`, `chat`, `user`, `event`, `time`, `rand`, `io`).

Additionally, the entire page state is injected as top-level variables. This is how the `<DetailCard>` can reference `selected.level_id` when a `<List>` with `selectionKey="selected"` sets that slot on row click.

```xml
<!-- List sets state["selected"] = { level_id: 12345, username: "Nova", … } -->
<List selectionKey="selected" …/>

<!-- DetailCard reads state["selected"] as a Rhai variable named "selected" -->
<DetailCard dataExpr="gd.get_level(selected.level_id)"/>
```

**Re-evaluation triggers:**
- Page first loads
- A module action completes (button click, row action, form submit)
- A `queue-updated` or `module-data-updated` event fires from any script
- The dev file watcher detects a change (dev mode only)

---

## Icons

### Page / sidebar icons

The `icon` field on `<Page>` and in `manifest.json → pages` uses the same resolution as `<Icon name="…">` but without a namespace prefix:

**Built-in** (SVG): `queue` · `music` · `points` · `polls` · `coins`

**Lucide** — any name from [lucide.dev](https://lucide.dev) in kebab-case: `list` · `settings` · `bar-chart` · `users` · `star` · etc.

Unknown names fall back to a generic box outline.

### Inline icons (`<Icon>`)

Use the `<Icon>` widget anywhere in a layout. Three namespaces are supported:

| Namespace    | Example              | Source |
|--------------|----------------------|--------|
| `lucide:`    | `lucide:star`        | Lucide icon library |
| `builtin:`   | `builtin:queue`      | App built-ins: `queue` `music` `star` `coins` `check` `error` |
| `local:`     | `local:badge`        | `resources/icons/badge.svg` in your module |

**Custom icons** — place SVG files in `resources/icons/` and reference them as `local:<filename-without-extension>`:
```
my-module/
  resources/
    icons/
      trophy.svg      →  <Icon name="local:trophy" size="20"/>
      crown.svg       →  <Icon name="local:crown" size="16" color="#f59e0b"/>
```

---

## Dev workflow

### Hot-reload

While developing, use the dev install + hot-reload path:

1. **Copy source to app modules directory:**

   ```bash
   py build.py my-module --dev-install "C:\Users\You\AppData\Roaming\com.gdlqbot.app\modules"
   ```

2. **Enable the module** in the app (Modules page → enable)

3. **Watch for changes** — the app automatically reloads `.gdui` files:

   ```bash
   py build.py my-module --watch
   ```

   Changes to any file under `modules/my-module/` trigger an immediate rebuild.
   The app's dev watcher picks up `.gdui` changes and hot-reloads the page without restarting.

### Validate before publishing

```bash
py build.py my-module --validate
```

This checks:
- All `scripts[key]` paths exist
- All `pages[].file` paths exist

### Build a distributable `.gdmod`

```bash
py build.py my-module
```

Output: `dist/my-module/<version>/my-module-<version>.gdmod`

The zip includes `manifest.json`, `scripts/`, `ui/`, `resources/`, and `libraries/` (bundled libraries).

---

## Full example

`ui/main.gdui` for a points module:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Page id="leaderboard" label="Leaderboard" icon="trophy">
  <TwoColumn leftWidth="320">

    <Left>
      <Stack>
        <Toolbar countExpr="ms.collection(&quot;points&quot;).count()">
          <Action label="Reset All" key="reset_all" style="danger"/>
        </Toolbar>
        <List
          rowId="username"
          primary="username"
          secondary="points"
          selectionKey="viewer"
          emptyMessage="No points yet — chat to earn!">
          <Section dataExpr="ms.collection(&quot;points&quot;).find(100)"/>
          <RowAction label="Add 10"  key="add_points"   argField="username"/>
          <RowAction label="Reset"   key="reset_points" argField="username" style="danger"/>
        </List>
      </Stack>
    </Left>

    <Right>
      <Stack>
        <Stack direction="horizontal" gap="0">
          <StatCard label="Total Participants" valueExpr="ms.collection(&quot;points&quot;).count()" format="number"/>
          <StatCard label="Points Given Today" valueExpr="ms.get_or(&quot;today_total&quot;, 0)"     format="number"/>
        </Stack>
        <Chart
          type="bar"
          dataExpr="ms.collection(&quot;points&quot;).find(10)"
          xKey="username"
          yKey="points"
          color="#f59e0b"/>
        <DetailCard
          dataExpr="viewer"
          placeholder="Click a viewer to see their stats">
          <Field key="username" label="Username"/>
          <Field key="points"   label="Points"    type="number"/>
          <Field key="rank"     label="Rank"      type="badge"/>
          <Field key="joined"   label="Joined"/>
        </DetailCard>
      </Stack>
    </Right>

  </TwoColumn>
</Page>
```
