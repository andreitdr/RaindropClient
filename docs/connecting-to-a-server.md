# Connecting to a server

Feature folder: [`lib/features/onboarding/`](../lib/features/onboarding/).

Raindrop has no directory server — a client's only way to find a server is being told its address.
[`ConnectServerFlow`](../lib/features/onboarding/controllers/connect_server_flow.dart) drives the whole
"add a server" lifecycle. It's deliberately **not** a Riverpod provider — it's a short-lived object
owned by the connect/auth screens, created fresh each time the user starts adding a server and
discarded once they finish or back out.

Nothing is typed but the address, and a username the first time. **There is no password**: the account
on a server is derived from the person's root secret and the server's identity key, and this device
signs in with its own key — see [Identity](identity.md).

## The flow, step by step

### 1. [`ConnectServerScreen`](../lib/features/onboarding/screens/connect_server_screen.dart) — host, port, nickname

The user enters a host, port (default `5001`), and an optional local nickname. Submitting:

1. `ServerService.GetServerInfo` (`flow.probe()`) confirms the server is reachable. This first call
   also opens the gRPC connection, and so triggers the TLS handshake `CertificatePinner` observes (see
   [Network layer](network-layer.md)). The server's statements are checked for consistency, and a
   server with no identity key is refused (`auth_unavailable`): there would be nothing to derive from.
2. `probe()` derives the account id (`IdentityCrypto.accountId(root, serverKey)`). **This is the id
   the server knows the person by**, the same from every device of theirs, and it doubles as this
   client's local storage key (`ServerProfile.id`).
3. A server already in the list is refused here (`already_added`).
4. `UserService.GetUserStatus` (`flow.checkStatus()`) with that id.
5. Hands off to `/connect/auth` with the flow, the status result, and the display name.

### 2. [`ServerAuthScreen`](../lib/features/onboarding/screens/server_auth_screen.dart) — signing this device in

| `state` | Screen shows | Then |
|---|---|---|
| `unregistered` (or `erased`) | A username field — or, behind *I have a claim code from the owner*, a claim code | `flow.signIn(ref, username: …)` makes the account; with a claim code, `flow.useClaim` first ([reclaiming](identity.md#reclaiming-an-account)) |
| `active`, `left_preserved` | Nothing to fill in | Signs in as soon as it opens — the person adding a server another of their devices joined, or adding back one they removed. A preserved account is restored by signing in |

If the server answers `authenticator_required` — the account has an authenticator and this device does
not hold its secret — a code field appears and the sign-in is repeated with it.

`flow.signIn` opens the server's crypto store **through `cryptoEngineProvider`** (the session that
follows opens the same file, and one store has one owner) and calls
[`signInWithDevice`](identity.md#signing-in).

On success, `flow.persist(ref, session: ..., displayName: ...)`:

1. Pins the certificate fingerprint observed during the flow — **only if nothing was pinned for this
   id yet** (trust-on-first-use; see
   [Network layer](network-layer.md#certificatepinner--trust-on-first-use)) — and the server's identity
   key, which later lets the client follow a replaced certificate and is what every sign-in is derived
   from and signed against.
2. Saves the session token to `SecureStore`.
3. Hands the new `ServerSession` over via `serverSessionProvider(guid).notifier.adopt(...)`, before the
   next step, so the session provider's first build takes this session rather than opening a second.
4. Registers the server with `ServersController` and makes it the active server.

A flow abandoned after it made this device's keys deletes them (`flow.dispose(container)`): nothing
lists the server, so nothing would ever use or remove them. It takes the app's `ProviderContainer`, not a
screen's `WidgetRef`, because it runs as the screen goes away — `ServerAuthScreen` calls it from its own
`dispose`, where its `ref` can no longer be used — and keeps going after awaits the screen does not live
through. Each screen captures the container with `ProviderScope.containerOf` while it is still mounted.
`test/features/onboarding/server_auth_screen_test.dart` backs out of the join screen and checks the keys
are deleted without an error.

## Afterwards

Signing in again is never this flow: `ServerSessionController` renews a lapsed session by itself. See
[Servers & sessions](servers-and-sessions.md).

## Related

- [Identity](identity.md) — the root, device sign-in, the vault, pairing, recovery, the authenticator.
- [Servers & sessions](servers-and-sessions.md) — `ServersController`, `ServerSession`, and what runs
  on every launch.
- [Storage](storage.md) — where each piece ends up.
- [Network layer](network-layer.md) — `RaindropChannel`, `CertificatePinner`, `UsersApi`.
