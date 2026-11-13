# Connecting to a server

Feature folder: [`lib/features/onboarding/`](../lib/features/onboarding/).

Raindrop has no directory server — a client's only way to find a server is being told its address.
[`ConnectServerFlow`](../lib/features/onboarding/controllers/connect_server_flow.dart) drives the whole
"add a server" lifecycle. It's deliberately **not** a Riverpod provider — it's a short-lived object
owned by the connect/auth screens, created fresh each time the user starts adding a server and
discarded once they finish or back out.

## The flow, step by step

### 1. [`ConnectServerScreen`](../lib/features/onboarding/screens/connect_server_screen.dart) — host, port, nickname

The user enters a host, port (default `5001`), and an optional local nickname. Submitting:

1. Generates a GUID client-side (`Uuid().v4()`). **This *is* the account identity the server will know
   the client by** — see the server's [Users doc](../../RaindropServer/docs/users.md) — and it doubles
   as this client's local storage key (`ServerProfile.id`), so there's no second synthetic id to keep
   in sync with it.
2. `ServerService.GetServerInfo` (`flow.probe()`) to confirm the server is reachable and see its
   capabilities. This first call also opens the gRPC connection, and so triggers the TLS handshake
   `CertificatePinner` observes (see [Network layer](network-layer.md)).
3. `UserService.GetUserStatus` (`flow.checkStatus()`) with that GUID. On a real first connection this
   always comes back `unregistered` — the `active`/`left_preserved` branches only matter for GUID
   re-import (below).
4. Hands off to `/connect/auth` with the flow, the status result, and the display name.

### 2. [`ServerAuthScreen`](../lib/features/onboarding/screens/server_auth_screen.dart) — register, log in, or rejoin

Branches purely on the `status.state` from step 3:

| `state` | Screen shows | Calls |
|---|---|---|
| `unregistered` (or `erased`) | Username + password fields | `flow.register(username, password)` |
| `active` | Password field only | `flow.login(password: ...)` |
| `left_preserved` | Password field only | `flow.rejoin(password: ...)` |

On success, `flow.persist(ref, session: ..., displayName: ...)`:

1. Pins the certificate fingerprint observed during the flow — **only if nothing was pinned for this
   GUID yet** (trust-on-first-use, same model as SSH host keys; see
   [Network layer](network-layer.md#certificatepinner--trust-on-first-use) and the server's
   [Transport security doc](../../RaindropServer/docs/transport-security.md)).
   It also pins the server's identity key, provided `probe()` found the server's statements consistent
   (the advertised fingerprint is the presented certificate, and the identity key signed it). The key
   is what later lets the client follow a replaced certificate. See
   [Network layer](network-layer.md#servertrust--following-a-certificate-change).
2. Saves the session token to `SecureStore`.
3. Hands the new `ServerSession` over via `serverSessionProvider(guid).notifier.adopt(...)`, so the
   shell doesn't have to re-fetch anything to pick it up. This comes before the next step, so the
   session provider's first build with the profile takes this session rather than restoring a second
   one from the saved token (see [Servers & sessions](servers-and-sessions.md)).
4. Registers the server with `ServersController` and makes it the active server.

## Reconnecting: `ConnectServerFlow.forExisting`

[`ReauthPrompt`](../lib/features/onboarding/screens/reauth_prompt.dart) is shown in the chat pane (beside the
server rail, so the app still opens on its normal layout) whenever a known server's stored session token is missing or has expired (idle timeout, or a
restart of the server's in-memory session store — see the server's
[Users doc](../../RaindropServer/docs/users.md#lifecycle)). It only asks for the password — the GUID
and pinned fingerprint are already on file.

`ConnectServerFlow.forExisting(profile)` rebuilds a flow for a server already known to
`ServersController`. Unlike the fresh-connect constructor, **this pins strictly from the start** — a
fingerprint mismatch here is treated as a real certificate change, not trust-on-first-use, since a
fingerprint was already pinned for this server. Before this prompt is reached, session restore
(`ServerSessionController`) has already tried `ServerTrust.followCertificateChange`, so a certificate
the owner replaced and signed with the pinned identity key is followed silently.

If login fails with `account_left`, the prompt offers a "Rejoin instead" button
(`flow.rejoin(...)`) — see the server's
[Users doc](../../RaindropServer/docs/users.md#lifecycle) for what `left_preserved` means.

## Related

- [Servers & sessions](servers-and-sessions.md) — `ServersController`, `ServerSession`, and cold-start
  session resolution (what runs *without* the user doing anything, on every app launch).
- [Storage](storage.md) — where the GUID, pinned fingerprint, and session token each end up.
- [Network layer](network-layer.md) — `RaindropChannel`, `CertificatePinner`, `UsersApi`.
