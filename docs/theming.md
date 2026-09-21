# Theming

## Flat, solid chrome

Chrome is flat and solid — the server rail, channel sidebar, message composer, and cards all wrap
their content in [`Panel`](../lib/core/widgets/panel.dart) or the standard Material `Card`, colored
from `context.surfaces` (see below). There is **no blur/translucency layer**; visual separation between
panes comes entirely from tiered background colors (`rail` < `sidebar` < `chat` in darkness), the same
way a Discord-style client steps its panes.

`Panel` wraps its child in a transparent `Material` (not a bare `Container`) specifically so a
`ListTile`/`InkWell` inside it has a nearby ink surface to paint ripples onto.

## `AppSurfaces` — the pane color tiers

[`AppSurfaces`](../lib/core/theme/app_colors.dart) is a `ThemeExtension<AppSurfaces>` carrying five
colors, independent of Material's own `ColorScheme` surface roles:

| Role | Purpose |
|---|---|
| `rail` | The leftmost server rail — darkest tier |
| `sidebar` | The channel list sidebar |
| `chat` | The main chat pane — lightest tier, also `scaffoldBackgroundColor` |
| `raised` | Cards, input fields — anything that should read as "above" its surface |
| `onlineIndicator` | The one color unique to presence — see [Members & presence](members-presence.md) |

Read it via the `context.surfaces` extension getter (`BuildContext.surfaces` →
`Theme.of(this).extension<AppSurfaces>()!`). Only `onlineIndicator` gets a dedicated color in the
theme; every other presence state borrows a muted foreground color rather than requiring every theme
JSON to define a color for it.

## `AppThemeDefinition` — a theme is just JSON

[`AppThemeDefinition`](../lib/core/theme/theme_definition.dart) is a name, a `Brightness`, an accent
`seedColor` (everything else in the Material `ColorScheme` derives from this via
`ColorScheme.fromSeed`), and the five `AppSurfaces` colors — serialized to and from plain JSON:

```json
{
  "id": "dark",
  "name": "Dark",
  "brightness": "dark",
  "seedColor": "#4C6FFF",
  "surfaces": {
    "rail": "#16171F",
    "sidebar": "#1C1E29",
    "chat": "#23252F",
    "raised": "#2B2D3A",
    "onlineIndicator": "#3BD16F"
  }
}
```

The app ships exactly two themes, [`assets/themes/light.json`](../assets/themes/light.json) and
[`assets/themes/dark.json`](../assets/themes/dark.json), loaded once at startup
(`loadBuiltInThemes()`) and handed in via `builtInThemesProvider` — the same "load before `runApp`,
then override a provider" pattern described in
[Architecture overview](architecture-overview.md#load-before-runapp-pattern).

**Retheming either shipped theme, or adding a third bundled one, is a matter of editing/adding a JSON
file and listing it in `pubspec.yaml`'s `assets:` — not touching Dart at all.**

`AppTheme.build()` ([`lib/core/theme/app_theme.dart`](../lib/core/theme/app_theme.dart)) is the *only*
place Material component theming (app bar, cards, inputs, dividers, navigation rail) is defined, so
every theme — built-in or user-created — gets identical component styling and differs only in the
colors it supplies.

## Custom themes

Users can create their own themes: [`ThemeEditorScreen`](../lib/features/settings/screens/theme_editor_screen.dart)
is a color-by-hex-field form that saves through
[`ThemeCatalogController`](../lib/core/theme/theme_controller.dart), which persists custom themes as a
JSON array in `AppPrefs.customThemesJson` (plain `SharedPreferences` — see [Storage](storage.md)),
`SharedPreferences`, not a file on disk, since that's the storage layer every other piece of small
local app state already goes through.

- `themeCatalogProvider` — the built-in-plus-custom list the Settings screen's theme selector renders.
- `activeThemeIdProvider` — which theme id is currently selected. `kSystemThemeId` (`"system"`) is the
  special "match OS" pseudo-entry.
- `resolveActiveTheme({activeId, catalog, platformBrightness})` — turns the selected id into an actual
  `AppThemeDefinition`: `kSystemThemeId` resolves to the built-in `light`/`dark` theme based on the
  platform's live brightness; anything else is looked up in the catalog, falling back to `light` if
  it's been deleted out from under an active selection.

Two invariants `ThemeCatalogController` protects:

- **Editing a built-in theme forks it into a new custom one** rather than mutating the shipped JSON in
  place — the editor always assigns a fresh id when starting from a built-in theme.
- **Deleting a custom theme that's currently active falls back to `kSystemThemeId`** (handled in
  `SettingsScreen._deleteTheme`), so the app never ends up pointed at a theme id that no longer exists.

## Related

- [Settings](settings.md) — where theme selection and the "New theme" / edit / delete affordances live.
- [Storage](storage.md) — `AppPrefs` is the persistence layer custom themes and the active theme id use.
