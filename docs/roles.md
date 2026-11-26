# Roles

Feature folder: [`lib/features/roles/`](../lib/features/roles/). API wrapper:
[`RolesApi`](../lib/core/network/roles_api.dart). Server-side reference:
[Roles & permissions](../../RaindropServer/docs/roles-and-permissions.md).

**Roles hold permissions; a member is given roles, never permissions directly, and may do the union of
the roles they hold.** Roles and permissions belong to one server and never carry over to another. Roles
are custom and editable here: a role is a name and a set of permissions, created, edited, handed out
and deleted from a page in the server's settings.

## The permission list comes from the server

Permissions are hard-coded per server build, and each build advertises the ones it knows through
`RoleService.ListPermissions`. **The editor draws only from that catalogue** —
[`permissionCatalogueProvider`](../lib/features/roles/controllers/roles_controller.dart) — never from a
list in this client. A client talking to an older and a newer server therefore sees each server's own set,
including permissions this client was never built with. (`ChannelPermissionNames` in `channels_api.dart`
is a list of names for gating buttons, such as `create_channels`, `video` and `screen_share`; the editor
never uses it.)

Each [`PermissionInfo`](../lib/core/network/roles_api.dart) has a `name`, `title`, `summary` and
`category`. The server sends a title and a category; an older server sends neither, so the title is
derived from the name (`manage_roles` becomes "Manage roles") and the category is `other`. A category the
client does not know is also filed under `other`. `PermissionCategories` fixes the groups' order and
headings (General, Text, Voice, Channels, Moderation, Administration, Other); `groupPermissions` groups a
catalogue that way, keeping the server's order inside each group and leaving empty groups out.

## Controllers

[`roles_controller.dart`](../lib/features/roles/controllers/roles_controller.dart). Every provider below
re-reads on any `role.*` or `member.roles` event and after a reconnect, through
[`LiveSync`](live-updates.md), rather than patching what it holds: role changes are rare and a stale
role is a wrong button. Each is **null when it cannot be read** (signed out, or a server without role
management), which hides the UI instead of offering something the server would refuse.

| Provider | Holds |
|---|---|
| `permissionCatalogueProvider(serverId)` | The server's permissions, in editor order |
| `rolesProvider(serverId)` | Every role. An `AsyncNotifier` that also does the writes: `create`, `save`, `delete`, `assign`, `unassign`. A write throws the server's `ApiException` (`role_name_taken`, `missing_permission`, …) for the screen to show; the list updates from the resulting event |
| `roleDetailProvider((serverId, roleId))` | One role and the UUIDs holding it |
| `memberRolesProvider((serverId, userId))` | One member's roles and what they add up to (`GetMemberRoles`) |

Helpers say, before a request is sent, what the server would say to it, so the UI does not offer what
will be refused (the server checks again): `canManage` (the caller holds `manage_roles`), `canGrantAll`
(and every permission a role grants — nobody may hand out what they do not hold), `sortRoles`
(everyone first, then by position, highest first, then by name). The caller's own permissions are
`serverPermissionsProvider` (`GetMyRoles`).

`RolesApi.update` keeps the difference the protocol makes between absent and empty: a null name, position
or permission list is left alone, while an empty permission list clears them (`PermissionSet` on the
wire).

## Screens

| Route | Screen |
|---|---|
| `/servers/:serverId/roles` | [`RolesScreen`](../lib/features/roles/screens/roles_screen.dart) — every role, with what it grants, and *New role* |
| `/servers/:serverId/roles/new`, `/servers/:serverId/roles/:roleId` | [`RoleEditorScreen`](../lib/features/roles/screens/role_editor_screen.dart) |

`RolesScreen` is opened from *Members → Roles* in [Server settings](settings.md#serversettingsscreen),
and that entry appears only when the server's permission catalogue can be read.

`RoleEditorScreen` shows the name, a switch per permission grouped by category, the members holding the
role, and delete. What it allows follows the rules above:

- **Switches the caller does not hold are disabled.** A role that grants anything the caller lacks is
  **read-only** altogether, since editing it would be escalation by another route; so is everything
  without `manage_roles`. A note at the top says which.
- **The owner role is read-only** (it holds `administrator`, and is neither editable nor deletable).
- **The everyone role's name is locked** and it cannot be deleted; its permissions can be edited.
- **Members**: a list with a remove button for each, and *Give to a member* (not offered for the everyone
  role, which nobody is given).
- **Delete** asks first. The server's refusals are shown inline under the form, not as a dialog.

## Roles from the member list

Tapping a member in the [member list](members-presence.md#rendering) opens
[`showMemberRolesSheet`](../lib/features/roles/widgets/member_roles_sheet.dart): that member's roles as
checkboxes (the everyone role is left out, as it is not handed out). A checkbox is disabled when the
caller could not give or take that role, and a note says so when the caller lacks `manage_roles`.

## Tests

- `test/features/roles/roles_test.dart` — the models and helpers: a server too old to send a title or
  category, an unknown category, who may hand out what, sorting, and the one-line summary of a role.
- `test/integration/roles_test.dart` (live server, **fresh database** — the first account to register
  owns it; no Rust core): the catalogue the editor is built from, creating, editing, handing out and
  deleting a role, and that nobody hands out what they do not hold.

  ```bash
  RAINDROP_TEST_SERVER=localhost:5001 flutter test test/integration/roles_test.dart
  ```
