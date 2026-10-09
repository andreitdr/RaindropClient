# Layout

Folders: [`lib/core/layout/`](../lib/core/layout/) (the format, the file, the generic widgets) and
[`lib/features/home/layout/`](../lib/features/home/layout/) (the main view's panes, slots, buttons and
defaults). Editor: [`layout_editor_screen.dart`](../lib/features/settings/screens/layout_editor_screen.dart),
route `/settings/layout`.

The main view (server rail, channel list, chat, member list, and the buttons in them) can be
rearranged by the user: panes reordered and resized, buttons moved between toolbars, the member list
and any button hidden. The result is a **local file**, one per install, applied to **every server**
and never sent anywhere.

It arranges the **wide layout only** (680px and up). The narrow drawer layout keeps its fixed shape,
though the toolbars it shows (the rail's footer and the user panel, inside the drawer; the chat's top
bar) still use the saved buttons.

## The model

[`LayoutConfig`](../lib/core/layout/layout_config.dart) is two things:

- **`panes`** — `PaneLayout {id, width?, visible}` in left-to-right order. A pane with no width fills
  the space the others leave (the chat).
- **`slots`** — slot id → ordered button ids. A slot is a toolbar inside a pane.

| Pane | Rule | Its toolbar (`PaneRule.slot`) |
|---|---|---|
| `servers` (rail) | Required. Fixed at 76px: its server icons are a fixed size. | `rail.footer` |
| `channels` | Required. 180–400px. | `user.trailing` |
| `content` (chat / voice view) | Required. Fills the rest. | `topBar.trailing` |
| `members` | Can be hidden. 180–400px. | none — it takes no buttons |

| Slot | Where | Default buttons |
|---|---|---|
| `rail.footer` | Under the server list, drawn as large round rail buttons | `server.add`, `app.settings` |
| `user.trailing` | Beside the signed-in user, foot of the channel list | `voice.mute`, `voice.deafen`, `app.settings` |
| `topBar.trailing` | Right end of the chat/voice pane's top bar | `members.toggle` |

The rail, channel list and chat can move but never be hidden: they are how servers, channels and
messages are reached. **Settings** (`app.settings`) must stay in at least one slot, since the editor
is behind it. The same button may sit in several slots (Settings does by default), but a slot never
lists one twice.

Ids are open strings, defined in [`main_layout_ids.dart`](../lib/features/home/layout/main_layout_ids.dart).
They are written to disk: add new ones, never rename these.

### `normalize` — the one validator

`LayoutConfig.normalize(LayoutRules)` runs on load, on import, after every edit in the editor, and
before saving, so nothing downstream copes with an invalid layout. It keeps the first of a pane listed
twice; puts back a pane the defaults have but the file lacks, next to its default neighbour (and a
missing slot gets its default buttons — an *emptied* slot stays empty); clamps widths to the pane's
range and resets widths that cannot change; makes required panes visible; de-duplicates each slot; and
returns a required button with no slot to its default slot.

**Unknown ids are kept**, not dropped: a pane, slot or button this build does not know survives a
load-and-save (so a layout from a newer build is not destroyed by an older one, and later plugins can
add their own), and renders as nothing. In the editor an unknown button is a generic chip that can
still be moved or removed.

**The other half of that is a trap worth knowing: `normalize` keeps unknown ids but never *adds* new
ones.** A missing slot gets its defaults, but a slot that already exists does not gain a button a
later build added to the default layout — so an existing user's saved `layout.json` never grows a new
button, however the defaults change. A new button that must be reachable therefore has to live
somewhere that is not layout-driven as well; the camera and share buttons are in the voice view's
in-call controls for exactly this reason. Only a new install, or Reset, picks up a changed default.
(The share button, `voice.screen`, is not in the defaults at all — it can be added from the editor.)

The rules live with the feature, not in `core/`: [`main_layout.dart`](../lib/features/home/layout/main_layout.dart)
defines `mainDefaultLayout`, `mainLayoutRules` and `mainLayoutButtons`, and `main.dart` hands the
rules to `layoutRulesProvider`.

## The file

[`LayoutStore`](../lib/core/layout/layout_store.dart): `<application support>/layout.json` (the same
directory as the crypto stores), pretty-printed JSON:

```json
{
  "version": 1,
  "panes": [
    { "id": "members", "width": 260.0, "visible": true },
    { "id": "servers", "width": 76.0, "visible": true },
    { "id": "channels", "width": 240.0, "visible": true },
    { "id": "content", "visible": true }
  ],
  "slots": {
    "rail.footer": ["server.add"],
    "user.trailing": ["voice.mute", "voice.deafen", "app.settings"],
    "topBar.trailing": ["members.toggle"]
  }
}
```

- **No file means the default layout.** Saving a layout equal to the default deletes the file instead
  of writing it, so a later build's new default reaches installs that never customised anything.
- Saved atomically (`layout.json.tmp`, then renamed).
- A file that is not a layout is **moved to `layout.json.bad`** and the app starts on the default; it
  is never overwritten, so a hand edit gone wrong can be recovered.
- A higher `version` is still read (every field is optional); the file is rewritten at this build's
  version on the next save.

It is a file rather than an `AppPrefs` key because it is meant to be the user's: exported, copied to
another machine, imported. See [Storage](storage.md).

Loaded before `runApp` like `AppPrefs` ([Architecture overview](architecture-overview.md#load-before-runapp-pattern)):
`layoutStoreProvider` and `initialLayoutProvider` are overridden in `main.dart`, and
`layoutConfigProvider` (`LayoutController`) serves the normalized layout and `save`s it.

## Rendering

- [`LayoutScope`](../lib/core/layout/layout_scope.dart) — an `InheritedWidget` carrying the layout,
  the button registry, the editor's hooks when editing, and `collapsedPanes` (panes the window is too
  narrow for right now). `HomeShell` provides the saved layout; the editor provides its draft.
- [`LayoutRow`](../lib/core/layout/layout_row.dart) — the row of panes, in order and at their widths;
  a pane the builder returns null for (unknown id, or one this screen lacks) is skipped.
- [`LayoutSlot`](../lib/core/layout/layout_slot.dart) — a toolbar: draws the slot's buttons through
  the registry (`LayoutButtonSpec.build(context, SlotStyle)`) as rail buttons or compact icon buttons.
  `ServerRail`, the channel sidebar's user panel and the chat/voice top bar each hold one.

`MainView` (in [`home_shell.dart`](../lib/features/home/screens/home_shell.dart)) is the view itself,
arranged by the nearest `LayoutScope` — so the editor's preview is the real view, not a mock-up.

**The member list** shows while the chat keeps at least `kMinContentWidth` (440px) beside it — with
the default widths, a 1000px window, as before this was configurable. Narrower, it folds behind the
**Members** button (`members.toggle`), wherever that is placed; `revealedPanesProvider` remembers the
toggle for this run only. With the member list hidden in the layout, the button draws nothing.

## The editor

Settings → Layout → **Customize layout** (disabled under 680px). A full-screen route showing
`MainView` for the active server as a live preview, over a draft; nothing is written until **Save**.
Cancel (or back) with unsaved changes asks before discarding.

- **Panes** — each is outlined, with a handle in its middle: drag it onto another pane's left or right
  half to move it there (anywhere on that pane, its handle included); the eye button hides it (member
  list only). Resizable panes have a grip on the edge facing the chat.
- **Buttons** — the tray under the preview lists every button. Drop one **anywhere on a pane** and it
  joins that pane's own toolbar (`PaneRule.slot`: the rail's footer, the channel list's user panel, the
  chat's top bar) at the end; the member list has no toolbar and takes none. Drop it **on a chip** in a
  slot instead and it lands exactly there, which is how buttons are reordered — the slot is the finer
  target and wins over the pane, decided by asking the pane's `LayoutEditBarrier` whether a slot is
  under the pointer (`layoutSlotUnder`). The tray also takes drops: a button dropped there is removed,
  a pane hidden. It refuses the last Settings button and required panes, and says why. Hidden panes are
  listed there to show again.

  Both pane-wide drop zones sit **above** the pane handle and resize grip in the `Stack`. They take no
  pointer events while nothing is dragged, and underneath those they would lose every drop aimed at the
  middle of a pane — which is exactly where the handle is.
- **Reset to default** puts the draft back to the stock layout (Save then deletes the file).
- **Import… / Export…** (desktop only, through `file_selector`): import reads and normalizes a file
  into the draft; export writes the draft. Export writes straight to the chosen file — the macOS
  sandbox allows only that file, not a temporary one beside it — which is why it is not atomic. The
  `com.apple.security.files.user-selected.read-write` entitlement this needs is already present.

A preview must look live but not act live. [`LayoutEditBarrier`](../lib/core/layout/layout_edit_barrier.dart)
wraps each pane and absorbs every pointer event (clicks, scrolls, hovers) **except over a slot**
(`LayoutHitThrough`), which an `IgnorePointer` cannot do — nothing below it can opt back in. The whole
preview is in `ExcludeFocus`, the shell's one-off reactions (recovery words dialog, call-ended notice)
are skipped while editing, and a window too narrow for every pane scales the preview down instead of
crushing the chat. A server that is not signed in shows placeholders for the panes it has no content for.

## Adding a button or a slot

- **Button**: an id in `MainButtons`, an entry in `mainLayoutButtons` (label, icon, and a `build` for
  both `SlotStyle`s). It appears in the editor's tray at once; add it to `mainDefaultLayout` to show it
  by default (installs with a saved layout get it only by adding it).
- **Slot**: an id in `MainSlots`, a `LayoutSlot(id)` where it belongs, and its default buttons in
  `mainDefaultLayout` — saved layouts pick those up, since a missing slot gets its defaults. Name it as
  a pane's `PaneRule.slot` as well, so a button dropped on that pane has somewhere to go.

## Tests

[`test/core/layout/`](../test/core/layout/): the model and `normalize`, edits, JSON, the file store
(`layout_config_test.dart`), and a widget test that panes are inert in the editor while slot chips
still drag (`layout_editing_test.dart`).

[`test/features/settings/layout_editor_parts_test.dart`](../test/features/settings/layout_editor_parts_test.dart)
drives the editor's own pieces — which is why they live in
[`widgets/layout_editor_parts.dart`](../lib/features/settings/widgets/layout_editor_parts.dart) rather
than inside the screen, since the screen needs a live session to show anything: dropping a button from
the tray onto a chip, into an emptied slot and onto a bare pane, dropping a pane over another's handle,
and bringing a hidden pane back.

## Related

- [Settings](settings.md) — where the editor is opened.
- [Native feel per platform](native-feel-per-platform.md#the-responsive-shell) — the breakpoints.
- [Storage](storage.md) — the layout file beside `AppPrefs` and `SecureStore`.
