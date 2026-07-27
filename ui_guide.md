# GDUI Control Reference

Quick reference for every widget available in `.gdui` files. One example per control, key attributes listed below it. For architecture, expressions, and module setup see [`UI_SYSTEM.md`](UI_SYSTEM.md).

---

## Page structure

### `<Page>`
Root element of every `.gdui` file.
```xml
<Page id="queue" label="Queue" icon="list">
  <!-- one top-level layout element -->
</Page>
```
| Attribute | Description |
|-----------|-------------|
| `id`      | Must match `manifest.json → pages[].id` |
| `label`   | Tab label in the sidebar |
| `icon`    | Lucide name or builtin: `queue` `music` `coins` `points` `polls` |

---

### `<TwoColumn>`
Fixed-width left panel + flexible right panel.
```xml
<TwoColumn leftWidth="300">
  <Left><!-- sidebar content --></Left>
  <Right><!-- detail content --></Right>
</TwoColumn>
```
| Attribute   | Default | Description |
|-------------|---------|-------------|
| `leftWidth` | `280`   | Left panel width in px |

---

### `<Fragment>`
Root element of a `.gdui` file meant to be spliced into another page via `<Import>` — never loaded as a page on its own. Its children replace the `<Import>` tag; the `<Fragment>` wrapper itself is discarded.
```xml
<!-- ui/parts/queue-list.gdui -->
<Fragment>
  <List rowId="_id" primary="username" selectionKey="selected">
    <Section dataExpr="ms.collection('viewer').all()"/>
  </List>
</Fragment>
```

---

### `<SubPage>`
Alternate layout navigated to via `<Button navigateTo="…">`. Defined as a sibling of the root layout directly under `<Page>`. Shares page state with the root.
```xml
<Page id="main" label="Main" icon="list">
  <Stack>
    <Button label="View History" navigateTo="history"/>
  </Stack>

  <SubPage id="history">
    <Stack>
      <Button label="Back" navigateTo=".."/>
      <List rowId="_id" primary="username" …/>
    </Stack>
  </SubPage>
</Page>
```

---

## Layout

### `<Stack>`
Flex container — vertical (default) or horizontal.
```xml
<!-- Horizontal row with a spacer -->
<Stack direction="horizontal" gap="8" align="center">
  <Text value="'Hello'" style="subtitle"/>
  <Spacer/>
  <Button label="Action" actionKey="do_thing"/>
</Stack>

<!-- Vertical column that fills remaining height -->
<Stack fill="true" gap="0">
  <SectionHeader label="Items"/>
  <List …/>
</Stack>
```
| Attribute   | Default      | Description |
|-------------|--------------|-------------|
| `direction` | `"vertical"` | `"vertical"` or `"horizontal"` |
| `gap`       | `0`          | Gap between children in px |
| `fill`      | `false`      | Grow to fill remaining vertical space |
| `align`     | —            | CSS `align-items`: `start` `center` `end` `stretch` |
| `justify`   | —            | CSS `justify-content`: `start` `end` `space-between` … |
| `wrap`      | `false`      | Wrap children (horizontal stacks only) |
| `style`     | —            | Inline CSS string: `"padding: 12px; border-top: 1px solid #222"` |

---

### `<Grid>`
CSS grid with even columns or a responsive `minWidth` auto-fill.
```xml
<!-- Fixed 3-column grid -->
<Grid columns="3" gap="12">
  <StatCard label="Viewers" valueExpr="ms.collection('viewer').count()"/>
  <StatCard label="Subs"    valueExpr="ms.collection('subscriber').count()"/>
  <StatCard label="History" valueExpr="ms.collection('history').count()"/>
</Grid>

<!-- Responsive: columns as wide as possible, minimum 160px each -->
<Grid minWidth="160" gap="10">…</Grid>
```
| Attribute  | Default | Description |
|------------|---------|-------------|
| `columns`  | `2`     | Number of columns, or a CSS grid-template-columns string |
| `gap`      | `12`    | Gap in px |
| `minWidth` | —       | If set, uses `repeat(auto-fill, minmax(Npx, 1fr))` |

---

### `<Tabs>`
Tabbed container. Each `<Tab>` is one panel. Switching a tab clears the state key in `selectionKey`.
```xml
<Tabs variant="boxed" selectionKey="selected">
  <Tab label="Subscribers" icon="lucide:crown" badgeExpr="ms.collection('subscriber').count()">
    <List …/>
  </Tab>
  <Tab label="Viewers" icon="lucide:users" badgeExpr="ms.collection('viewer').count()">
    <List …/>
  </Tab>
</Tabs>
```
| Attribute      | Default       | Description |
|----------------|---------------|-------------|
| `variant`      | `"underline"` | `"underline"` · `"pills"` · `"boxed"` |
| `selectionKey` | —             | State key cleared when switching tabs |

**`<Tab>` attributes:**

| Attribute   | Description |
|-------------|-------------|
| `label`     | Tab text |
| `icon`      | Lucide icon, e.g. `lucide:users` |
| `badgeExpr` | Rhai expression → number shown as a count chip |
| `showExpr`  | Rhai expression — hides the whole tab (button + content), not just its content, when falsy |
| `showKey`   | Same, but reads page state instead of Rhai |

All tabs' `showExpr` are evaluated in one batched call. If the active tab becomes hidden, the view jumps to the first still-visible tab automatically.

---

### `<Accordion>`
Collapsible sections.
```xml
<Accordion>
  <Section label="Queue Settings" defaultOpen="true">
    <Form submitKey="save_settings">
      <Input key="max_size" label="Max Size" type="number" defaultExpr="ms.get_or('max_size', 25)"/>
    </Form>
  </Section>
  <Section label="Advanced">
    <Toggle stateKey="debug_mode" label="Debug mode"/>
  </Section>
</Accordion>
```
Each `<Section>` has `label` and optional `defaultOpen="true"`.

---

### `<Drawer>`
A panel that slides in over the content when its trigger button is clicked.
```xml
<Drawer triggerLabel="Filters" triggerIcon="sliders" triggerVariant="ghost" title="Filter Options">
  <Stack gap="12">
    <Toggle stateKey="show_subs_only" label="Subscribers only"/>
  </Stack>
</Drawer>
```
| Attribute        | Default     | Description |
|------------------|-------------|-------------|
| `triggerLabel`   | `"Open"`    | Button label |
| `triggerIcon`    | —           | Lucide icon name |
| `triggerVariant` | `"default"` | Button variant |
| `title`          | —           | Drawer header text |

---

### `<Card>`
A subtle bordered container with optional title.
```xml
<Card title="Recent Activity" padding="14" gap="10">
  <Text value="ms.get_or('last_action', 'None')" style="muted"/>
  <StatCard label="Today" valueExpr="ms.get_or('today_count', 0)" format="number"/>
</Card>
```
| Attribute | Default | Description |
|-----------|---------|-------------|
| `title`   | —       | Optional heading rendered above children |
| `padding` | `14`    | Inner padding in px |
| `gap`     | `10`    | Gap between children in px |

---

### `<ScrollArea>`
Scrollable container. Use `fill="true"` inside a `Stack fill` to claim all remaining vertical space.
```xml
<!-- Fixed max height -->
<ScrollArea maxHeight="300">
  <Each items="ms.collection('history').all()" as="entry">
    <Text value="entry.username"/>
  </Each>
</ScrollArea>

<!-- Fill available space (use inside Stack fill="true") -->
<ScrollArea fill="true">
  <DetailCard dataExpr="gd.fetch(to_string(selected.level_id))">…</DetailCard>
</ScrollArea>
```
| Attribute   | Default | Description |
|-------------|---------|-------------|
| `maxHeight` | `300`   | Max height in px (ignored when `fill="true"`) |
| `fill`      | `false` | Grow to fill remaining space |
| `gap`       | `0`     | Gap between children in px |

---

### `<Inset>`
Padding wrapper — useful for giving content breathing room inside otherwise gap-less containers.
```xml
<Inset padding="12 16">
  <SectionHeader label="Level Details"/>
</Inset>

<!-- Single value: all sides -->
<Inset padding="16">
  <Text value="'Hello'" style="muted"/>
</Inset>
```
| Attribute | Default    | Description |
|-----------|------------|-------------|
| `padding` | `"12px 16px"` | CSS shorthand; unitless numbers get `px` added automatically |

---

### `<StatBar>`
A slim horizontal bar of compact `key · value` stats separated by dots.
```xml
<StatBar>
  <Stat icon="lucide:crown" valueExpr="ms.collection('subscriber').count()" label="subs"/>
  <Stat icon="lucide:users" valueExpr="ms.collection('viewer').count()"     label="viewers"/>
  <Stat icon="lucide:list"  valueExpr="ms.get_or('max_size', 25)"           label="max"/>
</StatBar>
```
**`<Stat>` attributes:**

| Attribute   | Description |
|-------------|-------------|
| `icon`      | Lucide icon, e.g. `lucide:crown` |
| `valueExpr` | Rhai expression |
| `label`     | Text shown after the value |
| `suffix`    | Optional string appended after the value (e.g. `"%"`) |

---

## Text & display

### `<Text>`
Renders a string — either a static value or a Rhai expression.
```xml
<Text value="'@' + selected.username" style="subtitle"/>
<Text value="if ms.get('open') { 'Open' } else { 'Closed' }" style="accent"/>
<Text static="No data" style="muted"/>
```
| Attribute | Default    | Description |
|-----------|------------|-------------|
| `value`   | —          | Rhai expression |
| `static`  | —          | Static string (no eval) |
| `style`   | `"default"` | `default` · `title` · `subtitle` · `muted` · `accent` · `error` · `code` |
| `size`    | —          | Font size in px |
| `wrap`    | `false`    | Wrap instead of truncating |

---

### `<Badge>`
Compact colored chip.
```xml
<Badge value="'#' + to_string(selected.position)" variant="accent"/>
<Badge static="Sub" variant="success"/>
<Badge value="selected.queue_type" color="#f59e0b"/>
```
| Attribute | Default   | Description |
|-----------|-----------|-------------|
| `value`   | —         | Rhai expression |
| `static`  | —         | Static string |
| `variant` | `default` | `default` · `success` · `warn` · `danger` · `accent` |
| `color`   | —         | Custom CSS color (overrides variant) |

---

### `<Heading>`
Section headings with consistent sizing.
```xml
<Heading label="Queue Overview" variant="page" icon="lucide:list"/>
<Heading label="Subscribers" variant="section"/>
<Heading label="Sorted by position" variant="sub"/>
```
| Attribute | Default    | Description |
|-----------|------------|-------------|
| `label`   | —          | Heading text |
| `variant` | `"section"` | `"page"` · `"section"` · `"sub"` |
| `icon`    | —          | Lucide icon displayed before the label |

---

### `<SectionHeader>`
A labeled row with optional count badge and action button. Used to label groups of content.
```xml
<SectionHeader label="Level Details"/>
<SectionHeader label="Requests" countExpr="ms.collection('viewer').count()"
               actionKey="clear" actionLabel="Clear"/>

<!-- Collapsible section -->
<SectionHeader label="Advanced" collapsible="true" stateKey="adv_open"/>
<Conditional showKey="adv_open">
  <Stack>…</Stack>
</Conditional>
```
| Attribute     | Description |
|---------------|-------------|
| `label`       | Section title |
| `countExpr`   | Rhai expression → number shown as a dim badge |
| `actionKey`   | Module script key for an optional action button |
| `actionLabel` | Label for the optional action button |
| `collapsible` | If `"true"`, clicking the header toggles `stateKey` |
| `stateKey`    | State key written when toggled (use with `<Conditional showKey>`) |

---

### `<Icon>`
Renders a single icon from Lucide, builtins, or your module's SVG files.
```xml
<Icon name="lucide:star"  size="18"/>
<Icon name="builtin:queue" size="20" color="#7c3aed"/>
<Icon name="local:trophy" size="24"/>
```
| Namespace   | Example            | Source |
|-------------|--------------------|--------|
| `lucide:`   | `lucide:star`      | [lucide.dev](https://lucide.dev) |
| `builtin:`  | `builtin:queue`    | `queue` `music` `coins` `points` `polls` `check` `error` |
| `local:`    | `local:my-icon`    | `resources/icons/my-icon.svg` in your module |

---

### `<Image>`
Renders an image from a URL.
```xml
<Image srcExpr="'https://levelthumbs.prevter.me/thumbnail/' + to_string(selected.level_id)"
       height="150"/>
<Image src="https://example.com/banner.png" fit="contain"/>
```
| Attribute      | Default  | Description |
|----------------|----------|-------------|
| `srcExpr`      | —        | Rhai expression → URL string |
| `src`          | —        | Static URL |
| `height`       | —        | Fixed height in px |
| `borderRadius` | `0`      | Corner radius in px |
| `fit`          | `"cover"` | CSS object-fit: `"cover"` `"contain"` `"fill"` |

---

### `<Avatar>`
Circular user avatar with an optional status dot.
```xml
<Avatar nameExpr="selected.username" srcExpr="selected.avatar_url" size="40" status="online"/>
<Avatar name="Anonymous" size="32"/>
```
| Attribute    | Description |
|--------------|-------------|
| `name`       | Static display name (used for initials fallback) |
| `nameExpr`   | Rhai expression |
| `src`        | Static avatar URL |
| `srcExpr`    | Rhai expression |
| `size`       | Diameter in px (default `32`) |
| `status`     | `"online"` · `"away"` · `"busy"` · `"offline"` |

---

### `<Code>`
Monospace code block with optional copy button.
```xml
<Code expr="io.encode_json(ms.collection('history').all())" copyable="true"/>
<Code static="!request 12345" copyable="true"/>
```
| Attribute  | Default | Description |
|------------|---------|-------------|
| `expr`     | —       | Rhai expression |
| `static`   | —       | Static string |
| `copyable` | `false` | Show a copy button |
| `wrap`     | `false` | Wrap long lines |

---

### `<ExpandableText>`
Text that is collapsed to N lines with a "Show more" toggle.
```xml
<ExpandableText expr="selected.description" lines="2"/>
```
| Attribute | Default | Description |
|-----------|---------|-------------|
| `expr`    | —       | Rhai expression |
| `static`  | —       | Static string |
| `lines`   | `2`     | Number of lines before collapsing |

---

### `<Tooltip>`
Wraps any single child and shows a tooltip on hover.
```xml
<Tooltip text="Removes this request from the queue" position="top">
  <Button label="Remove" actionKey="remove" variant="danger"/>
</Tooltip>
```
| Attribute  | Default  | Description |
|------------|----------|-------------|
| `text`     | —        | Tooltip content |
| `position` | `"top"`  | `"top"` · `"bottom"` · `"left"` · `"right"` |

---

### `<Divider>`
A horizontal rule, optionally with a label.
```xml
<Divider/>
<Divider label="Statistics"/>
```

---

### `<Spacer>`
Flex spacer — pushes siblings apart or adds a fixed gap.
```xml
<!-- Push items to opposite ends -->
<Stack direction="horizontal">
  <Text value="'Left'" />
  <Spacer/>
  <Button label="Right" actionKey="do_thing"/>
</Stack>

<!-- Fixed size gap -->
<Spacer size="24"/>
```

---

## Data

### `<List>`
Scrollable list of rows from a Rhai expression. Supports sections, selection, per-row actions, and inline badges.
```xml
<List
  rowId="_id"
  primary="username"
  secondary="level_id"
  secondaryPrefix="#"
  platform="platform"
  positionField="position"
  selectionKey="selected"
  emptyMessage="Nothing here yet">
  <Section label="Subscribers" dataExpr="ms.collection('subscriber').all()"/>
  <Section label="Viewers"     dataExpr="ms.collection('viewer').all()"/>
  <RowAction label="Promote" key="promote" argField="level_id"/>
  <RowAction label="Remove"  key="remove"  argField="level_id" style="danger"/>
</List>
```
| Attribute        | Description |
|------------------|-------------|
| `rowId`          | Field used as a unique row key (use `_id` for DB documents) |
| `primary`        | Main label field |
| `secondary`      | Dim secondary text field |
| `secondaryPrefix`| Static string prepended to the secondary value (e.g. `"#"`) |
| `platform`       | Field with `"twitch"` or `"youtube"` — renders a colored platform dot |
| `positionField`  | Field rendered as `#N` position number |
| `badgeField`     | Field rendered as a small chip badge |
| `selectionKey`   | State key written on row click (value = whole row object) |
| `emptyMessage`   | Shown when all sections are empty |
| `navigateTo`     | Navigate to this sub-page when a row is clicked |

---

### `<DetailCard>`
Fetches data via Rhai and displays it as a grid of labeled fields.
```xml
<DetailCard
  dataExpr="gd.fetch(to_string(selected.level_id))"
  placeholder="Loading…">
  <Field key="name"       label="Level Name"/>
  <Field key="difficulty" label="Difficulty" type="badge"/>
  <Field key="stars"      label="Stars"      type="stars"/>
  <Field key="downloads"  label="Downloads"  type="number"/>
  <Field key="is_epic"    label="Epic"       type="boolean"/>
</DetailCard>
```
| Attribute     | Description |
|---------------|-------------|
| `dataExpr`    | Rhai expression — the full page state is in scope |
| `placeholder` | Shown while loading or when data is null |

**`<Field>` types:** `text` (default) · `number` (formatted) · `badge` · `stars` (0–10 stars visual) · `boolean` (shows a chip only when true) · `image`

---

### `<Table>`
A data table rendered from a Rhai array, with optional row selection and actions.
```xml
<Table dataExpr="ms.collection('history').all()" selectionKey="row" emptyMessage="No history">
  <Column key="username" label="User"/>
  <Column key="level_id" label="Level" type="number"/>
  <Column key="queue_type" label="Type" type="badge"/>
  <RowAction label="Remove" key="remove" argField="level_id" style="danger"/>
</Table>
```
**`<Column>` types:** `text` · `number` · `badge`

---

### `<StatCard>`
Large single-value metric display.
```xml
<StatCard label="Total Requests" valueExpr="ms.collection('viewer').count()" format="number"/>
<StatCard label="Uptime"         valueExpr="time.unix() - ms.get_or('start_time', time.unix())" format="duration"/>
```
| Attribute   | Default  | Description |
|-------------|----------|-------------|
| `label`     | —        | Caption |
| `valueExpr` | —        | Rhai expression → scalar |
| `format`    | `"text"` | `"number"` · `"percent"` · `"duration"` (seconds → `1h 30m`) · `"text"` |

---

### `<Chart>`
SVG bar or line chart from a Rhai array.
```xml
<Chart type="bar"
       dataExpr="ms.collection('history').find(10)"
       xKey="username"
       yKey="level_id"
       color="#7c3aed"/>
```
| Attribute  | Default              | Description |
|------------|----------------------|-------------|
| `type`     | `"bar"`              | `"bar"` · `"line"` |
| `dataExpr` | —                    | Array of objects |
| `xKey`     | `"label"`            | Field for X-axis labels |
| `yKey`     | `"value"`            | Field for Y-axis values |
| `color`    | `var(--color-accent)` | Bar/line color |

---

### `<KVList>`
Displays an object as a key→value table.
```xml
<KVList dataExpr="gd.fetch(to_string(selected.level_id))" title="Raw Level Data"/>
```
| Attribute | Description |
|-----------|-------------|
| `dataExpr`| Rhai expression → object |
| `title`   | Optional heading |
| `emptyMessage` | Shown when data is null/empty |

---

### `<TagList>`
Renders an array of strings as chips.
```xml
<TagList valueExpr="ms.get_or('tags', [])" variant="accent" emptyMessage="No tags"/>
```
| Attribute      | Description |
|----------------|-------------|
| `valueExpr`    | Rhai expression → array of strings |
| `variant`      | `default` · `accent` · `success` · `warn` · `danger` |
| `emptyMessage` | Shown when array is empty |

---

### `<Timeline>`
Displays an array as a vertical event timeline.
```xml
<Timeline dataExpr="ms.collection('events').all()" emptyMessage="No events yet"/>
```
Expects array items with `label`, `description` (optional), and `timestamp` (optional) fields.

---

## Status & feedback

### `<Alert>`
An inline status banner.
```xml
<Alert variant="warn" title="Queue Full" message="Requests are disabled until a slot opens."/>
<Alert variant="info" expr="'Current mode: ' + ms.get_or('mode', 'normal')"/>
```
| Attribute | Default  | Description |
|-----------|----------|-------------|
| `variant` | `"info"` | `"info"` · `"warn"` · `"error"` · `"success"` |
| `title`   | —        | Bold heading |
| `message` | —        | Static body text |
| `expr`    | —        | Rhai expression for dynamic body text |

---

### `<CalloutBox>`
Styled callout with an icon, title, and message. Good for explanatory notes.
```xml
<CalloutBox kind="note" title="GD Integration Disabled"
            message="Enable GD data in module settings to view level details."/>
<CalloutBox kind="warning" title="Destructive action" message="This cannot be undone."/>
```
| Attribute | Description |
|-----------|-------------|
| `kind`    | `"tip"` · `"note"` · `"warning"` · `"danger"` · `"info"` |
| `title`   | Bold heading |
| `message` | Body text |

---

### `<EmptyState>`
Full-area placeholder shown when there's nothing to display.
```xml
<EmptyState icon="lucide:inbox" message="Select a request to view details."/>
<EmptyState icon="lucide:layers" message="No results." actionKey="clear_filters" actionLabel="Clear filters"/>
```
| Attribute     | Description |
|---------------|-------------|
| `icon`        | Lucide icon, e.g. `lucide:inbox` |
| `message`     | Descriptive text |
| `actionKey`   | Optional module action script |
| `actionLabel` | Button label for the optional action |

---

### `<Progress>`
Horizontal progress bar.
```xml
<Progress expr="ms.collection('viewer').count()"
          maxExpr="ms.get_or('max_size', 25)"
          label="Queue capacity"
          showValue="true"/>
```
| Attribute    | Description |
|--------------|-------------|
| `expr`       | Rhai expression → current value |
| `maxExpr`    | Rhai expression → max value (default `100`) |
| `label`      | Caption above the bar |
| `color`      | CSS color |
| `showValue`  | If `"true"`, shows `N / max` text |

---

### `<ProgressRing>`
Circular progress ring.
```xml
<ProgressRing expr="ms.collection('viewer').count()"
              maxExpr="ms.get_or('max_size', 25)"
              label="Capacity"
              format="percent"
              size="80"
              stroke="6"
              color="#7c3aed"/>
```
| Attribute    | Default              | Description |
|--------------|----------------------|-------------|
| `expr`       | —                    | Current value |
| `maxExpr`    | —                    | Max value |
| `label`      | —                    | Caption below the ring |
| `format`     | `"number"`           | `"number"` · `"percent"` |
| `size`       | `80`                 | Diameter in px |
| `stroke`     | `6`                  | Ring stroke width in px |
| `color`      | `var(--color-accent)` | Ring fill color |
| `trackColor` | —                    | Background track color |

---

### `<Skeleton>`
Animated loading placeholder.
```xml
<Conditional showExpr="data_loaded">
  <DetailCard …/>
  <Skeleton lines="4" height="14"/>
</Conditional>
```
| Attribute | Default | Description |
|-----------|---------|-------------|
| `lines`   | `3`     | Number of placeholder lines |
| `height`  | `12`    | Height of each line in px |

---

## Inputs

### `<Button>`
Clickable button — runs a script, navigates, or sets state.
```xml
<!-- Run a module action -->
<Button label="Next Level" icon="fast-forward" actionKey="next" variant="primary" fullWidth="true"/>

<!-- Navigate to a sub-page -->
<Button label="History" icon="clock" navigateTo="history"/>
<Button label="Back" navigateTo=".."/>

<!-- Set state without running a script -->
<Button label="Show panel" stateKey="panel_open" stateValue="true"/>

<!-- Dynamic label -->
<Button labelExpr="if ms.get('open') { 'Close Queue' } else { 'Open Queue' }" actionKey="toggle_queue"/>

<!-- After the action succeeds, load fresh data into state — e.g. auto-select
     the level a "Next" action just popped, no row click needed -->
<Button label="Next Level" actionKey="next" variant="primary"
        afterStateKey="selected" afterStateExpr="ms.collection('history').last()"/>
```
| Attribute        | Default     | Description |
|------------------|-------------|-------------|
| `label`          | `"Button"`  | Static label |
| `labelExpr`      | —           | Rhai expression for dynamic label |
| `icon`           | —           | Lucide icon name (shows before label, or alone if no label) |
| `actionKey`      | —           | Module script to run |
| `args`           | —           | Comma-separated static args |
| `argState`       | —           | Dot-path into state used as args[0]: `"selected.level_id"` — comma-separate for multiple args: `"new_id, new_username"` |
| `navigateTo`     | —           | Sub-page id, or `".."` to go back |
| `stateKey`       | —           | State key to set immediately on click |
| `stateValue`     | `true`      | Value to write (`true` `false` or string/number) |
| `afterStateKey`  | —           | State key to set once `actionKey` *succeeds* |
| `afterStateExpr` | —           | Rhai expression (evaluated with current state in scope) stored under `afterStateKey` — can read data the action just created |
| `disabledExpr`   | —           | Rhai expression; button is disabled when truthy |
| `variant`        | `"default"` | `primary` · `ghost` · `danger` · `warn` · `success` · `default` |
| `fullWidth`      | `false`     | Stretch to 100% of the container width |

---

### `<ConfirmButton>`
Two-click safety button — first click shows a confirm prompt, second click fires the action.
```xml
<ConfirmButton label="Clear All" actionKey="clear" confirmLabel="Sure?" style="danger"/>
```
| Attribute      | Default       | Description |
|----------------|---------------|-------------|
| `label`        | —             | Initial button label |
| `actionKey`    | —             | Module script |
| `confirmLabel` | `"Confirm?"`  | Label shown after first click |
| `disabledExpr` | —             | Rhai expression to disable the button |
| `args`         | —             | Comma-separated static args |

---

### `<ActionMenu>`
A dropdown button with a list of actions. Supports separators, icons, and description text.
```xml
<ActionMenu label="···" variant="ghost">
  <Action type="separator" label="Queue"/>
  <Action label="Shuffle"   icon="shuffle"  key="shuffle" text="Randomize the order"/>
  <Action type="separator"/>
  <Action label="Clear All" icon="trash-2"  key="clear"   style="danger"/>
  <Action label="History"   icon="clock"    navigateTo="history"/>
</ActionMenu>
```
| Attribute | Default     | Description |
|-----------|-------------|-------------|
| `label`   | `"Actions"` | Trigger button text |
| `icon`    | —           | Lucide icon in the trigger button |
| `variant` | `"default"` | `"default"` · `"primary"` · `"ghost"` |

**`<Action>` attributes:**

| Attribute     | Description |
|---------------|-------------|
| `label`       | Item text |
| `key`         | Module script key |
| `icon`        | Lucide icon shown before the label |
| `text`        | Dim subtitle text shown below the label |
| `style`       | `"default"` · `"danger"` · `"success"` |
| `navigateTo`  | Navigate to sub-page instead of running a script |
| `args`        | Comma-separated static args |
| `type`        | `"separator"` renders a divider line; a `label` on a separator makes it a section header |

---

### `<Toggle>`
Boolean toggle switch that binds to page state.
```xml
<!-- Binds to state["dark_mode"] -->
<Toggle stateKey="dark_mode" label="Dark mode" valueExpr="ms.get_or('dark_mode', false)"/>

<!-- Dispatch a script immediately when toggled -->
<Toggle stateKey="open" label="Queue open" valueExpr="ms.get_or('open', true)" actionKey="toggle_queue"/>
```
| Attribute    | Description |
|--------------|-------------|
| `stateKey`   | Page state key written on change |
| `label`      | Display label |
| `valueExpr`  | Rhai expression for the initial value |
| `actionKey`  | Module script dispatched on change; receives `"true"` or `"false"` as args[0] |

---

### `<Checkbox>`
A checkbox that binds to page state. Same API as `<Toggle>` but renders as a checkbox.
```xml
<Checkbox stateKey="include_subs" label="Include subscribers" valueExpr="ms.get_or('include_subs', true)"/>
```

---

### `<Input>`
Text or number input that binds to page state.
```xml
<Input stateKey="search" type="text" placeholder="Search levels…"/>
<Input stateKey="max_size" type="number" label="Max size" valueExpr="ms.get_or('max_size', 25)" min="1" max="500" actionKey="save_max"/>

<!-- Enter-to-submit next to an "Add" button, clearing itself after -->
<Input stateKey="new_item" placeholder="Value" actionKey="add_item"
       afterStateKey="new_item" afterStateExpr="''"/>
```
| Attribute        | Description |
|------------------|-------------|
| `stateKey`       | Page state key |
| `type`           | `"text"` (default) · `"number"` · `"password"` |
| `label`          | Display label |
| `placeholder`    | Placeholder text |
| `valueExpr`      | Rhai expression for initial value |
| `actionKey`      | Dispatched on **Enter only** — blur just syncs state, it doesn't dispatch (a blur-triggered dispatch would double-fire alongside a nearby button's click, since blur fires first) |
| `afterStateKey`  | State key to set once `actionKey` succeeds |
| `afterStateExpr` | Rhai expression evaluated and stored under `afterStateKey` — e.g. `"''"` to clear the field after submit |
| `min` / `max`    | Numeric bounds |

---

### `<TextArea>`
Multi-line text input that binds to page state.
```xml
<TextArea stateKey="welcome_msg" label="Welcome message"
          placeholder="Type a welcome message…"
          rows="4"
          valueExpr="ms.get_or('welcome_msg', '')"/>
```

---

### `<NumberInput>`
Numeric input with increment/decrement buttons.
```xml
<NumberInput stateKey="points" label="Points" min="0" max="1000" step="10"
             valueExpr="ms.get_or('points', 0)" actionKey="save_points"/>
```

---

### `<Slider>`
A range slider.
```xml
<Slider stateKey="volume" label="Volume" min="0" max="100" step="5"
        valueExpr="ms.get_or('volume', 50)" actionKey="save_volume"/>
```

---

### `<Select>`
A dropdown selector that binds to page state. Options can be static or from a Rhai expression.
```xml
<!-- Static options -->
<Select stateKey="sort_by" label="Sort by" valueExpr="ms.get_or('sort_by', 'date')">
  <Option value="date"  label="Date added"/>
  <Option value="level" label="Level ID"/>
  <Option value="user"  label="Username"/>
</Select>

<!-- Dynamic options from Rhai -->
<Select stateKey="platform_filter" optionsExpr="[#{'value': 'all', 'label': 'All'}, #{'value': 'twitch', 'label': 'Twitch'}]"/>
```

---

### `<MultiSelect>`
A multi-value selector.
```xml
<MultiSelect stateKey="enabled_platforms" label="Platforms">
  <Option value="twitch"  label="Twitch"/>
  <Option value="youtube" label="YouTube"/>
</MultiSelect>
```

---

### `<RadioGroup>`
Mutually exclusive option group.
```xml
<RadioGroup stateKey="queue_mode" label="Queue mode" direction="horizontal"
            valueExpr="ms.get_or('mode', 'fifo')" actionKey="save_mode">
  <Option value="fifo"   label="First in"/>
  <Option value="random" label="Random"/>
  <Option value="merit"  label="By likes"/>
</RadioGroup>
```
| Attribute    | Description |
|--------------|-------------|
| `direction`  | `"vertical"` (default) or `"horizontal"` |
| `optionsExpr`| Rhai expression → `[{value, label}]` array |

---

### `<SegmentedControl>`
A boxed tab-style picker — good for switching views.
```xml
<SegmentedControl stateKey="view" actionKey="change_view" valueExpr="ms.get_or('view', 'grid')">
  <Option value="grid" label="Grid"/>
  <Option value="list" label="List"/>
</SegmentedControl>
```

---

### `<CopyButton>`
A button that copies a value to the clipboard.
```xml
<CopyButton valueExpr="ms.get_or('token', '')" label="Copy token" variant="accent"/>
<CopyButton static="!request" label="Copy command"/>
```
| Attribute   | Description |
|-------------|-------------|
| `valueExpr` | Rhai expression |
| `static`    | Static string |
| `label`     | Button label (default `"Copy"`) |
| `variant`   | `"default"` · `"accent"` |

---

### `<Form>`
An auto-saving settings form by default — **no Save button**. All fields' `defaultExpr`s load in one batched Rhai call (not one call per field, which used to make forms with many fields visibly populate late/one-at-a-time). Every change (debounced 500ms for text, immediate-ish for toggles/selects) posts the whole form as JSON to a module script; status ("Unsaved changes…" → "Saving…" → "Saved ✓", or an error) shows in the page's shared topbar, not a per-Form bar — see "Page-wide status" in [`UI_SYSTEM.md`](UI_SYSTEM.md). Set `autosave="false"` to get an explicit Save button instead (for submit scripts with side effects you don't want firing on every keystroke).
```xml
<Form submitKey="save_settings" title="Queue Settings">
  <Input    key="max_size" label="Max size"  type="number" defaultExpr="ms.get_or('max_size', 25)"/>
  <Input    key="prefix"   label="Prefix"               defaultExpr="ms.get_or('prefix', '!')"/>
  <Textarea key="msg"      label="Welcome message"       defaultExpr="ms.get_or('msg', '')"/>
  <Toggle   key="open"     label="Queue open"            defaultExpr="ms.get_or('open', true)"/>
  <Select   key="mode"     label="Mode"                  defaultExpr="ms.get_or('mode', 'normal')">
    <Option value="normal" label="Normal"/>
    <Option value="strict" label="Strict"/>
  </Select>
</Form>

<!-- Explicit Save button instead of autosave -->
<Form submitKey="rotate_webhook" title="Danger Zone" autosave="false">
  <Input key="webhook_url" label="Webhook URL" defaultExpr="ms.get_or('webhook_url', '')"/>
</Form>
```
Each save calls the submit script with **every field's current value** (not just what changed) as a JSON string in `args[0]` (a top-level array, same as command scripts — not `user.args()`, which doesn't exist):
```rhai
let data = io.parse_json(args[0]);
if data.max_size != () { ms.set("max_size", parse_int(to_string(data.max_size))); }
```
| Attribute   | Default | Description |
|-------------|---------|-------------|
| `submitKey` | —       | Module script called on save |
| `title`     | —       | Optional form heading |
| `autosave`  | `true`  | `false` swaps the topbar-driven autosave for an explicit Save button |

**`group` on fields, not multiple `<Form>`s.** Every field (`<Input>`, `<Toggle>`, `<Select>`, `<Textarea>`) takes `group="…"` — consecutive same-group fields get one header. Use this to organize a long form into sections. Don't split into several `<Form>`s instead — each wants `flex: 1` to fill its container, and stacking several breaks the page's scroll (they fight each other for space rather than sizing to content).

4+ toggles in one group auto-render as a chip grid (click to flip, check mark = on) with **All**/**None** shortcuts, instead of stacked switch rows — good for "enable which of these tiers" sets. Fewer toggles, or ungrouped ones, stay as normal switch rows.
```xml
<Form submitKey="save_settings">
  <Toggle key="diff_easy"   label="Easy"   group="Difficulty" defaultExpr="ms.get_or('diff_easy', true)"/>
  <Toggle key="diff_normal" label="Normal" group="Difficulty" defaultExpr="ms.get_or('diff_normal', true)"/>
  <!-- … 4+ in the group → chip grid -->
</Form>
```

Prefer several `showExpr`-gated `<Tab>`s over several `<Form>`s stacked in one view — each Form auto-saves and shows status independently, which looks like unrelated saves when stacked.

---

## Control flow

### `<Conditional>`
Shows the first child when the condition is truthy; shows the second child (else branch) when falsy.
```xml
<!-- One branch -->
<Conditional showExpr="ms.get_or('open', true)">
  <Badge static="Open" variant="success"/>
</Conditional>

<!-- Two branches (then / else) -->
<Conditional showKey="selected">
  <DetailCard dataExpr="gd.fetch(to_string(selected.level_id))">
    <Field key="name" label="Name"/>
  </DetailCard>
  <EmptyState icon="lucide:layers" message="Select a request to view details."/>
</Conditional>
```
| Attribute  | Description |
|------------|-------------|
| `showExpr` | Rhai expression; first child shown when truthy |
| `showKey`  | State key; first child shown when `state[key]` is truthy |

---

### `<Each>`
Iterates over a Rhai array, rendering a template for each item.
```xml
<Each items="ms.collection('history').all()" as="entry" keyField="_id">
  <Stack direction="horizontal" gap="8" align="center">
    <Icon name="lucide:clock" size="12"/>
    <Text value="entry.username" style="subtitle"/>
    <Spacer/>
    <Badge value="entry.queue_type"/>
  </Stack>
</Each>
```
Inside the template, `entry` (or the `as` name) is the current object. `entry_index` is the 0-based position.

| Attribute  | Default  | Description |
|------------|----------|-------------|
| `items`    | —        | Rhai expression → array |
| `as`       | `"item"` | Variable name for each element |
| `keyField` | —        | Field used as the React key (boosts performance) |

---

### `<Import>`
Splices another `.gdui` file in place of the tag — lets you break a large page up into smaller reusable files. See [`<Fragment>`](#fragment) above.
```xml
<Stack>
  <Import file="ui/parts/queue-header.gdui"/>
  <Import file="ui/parts/queue-list.gdui"/>
</Stack>
```
| Attribute | Description |
|-----------|-------------|
| `file`    | Module-root-relative path to a `<Fragment>`-rooted `.gdui` file (e.g. `"ui/parts/queue-list.gdui"`) — not relative to the importing file |

The imported fragment may itself contain `<Import>` tags. Circular imports and chains deeper than 8 are rejected at load time.

---

## Expressions quick reference

Every `*Expr` attribute is a Rhai snippet. Page state variables are injected automatically so you can reference `selected`, `history_selected`, or any other key you've set via `selectionKey` or `stateKey`.

| Object  | What it gives you |
|---------|-------------------|
| `ms`    | Module key-value store and named collections |
| `gd`    | Geometry Dash API (`gd.fetch("12345")`) |
| `time`  | `time.unix()` → Unix timestamp |
| `rand`  | `rand.int(1, 100)` |
| `io`    | JSON encode/decode: `io.encode_json(val)`, `io.parse_json(str)` |

Common `ms` calls:

```rhai
ms.get('key')                     // returns value or ()
ms.get_or('key', default)         // returns value or default (typed)
ms.collection('name').count()     // number of documents
ms.collection('name').all()       // array of all documents
ms.collection('name').find(20)    // first 20 documents
```
