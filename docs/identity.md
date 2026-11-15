# Identity, devices and signing in

Feature folder: [`lib/features/identity/`](../lib/features/identity/). Core:
[`core/crypto/identity_crypto.dart`](../lib/core/crypto/identity_crypto.dart),
[`core/crypto/totp.dart`](../lib/core/crypto/totp.dart),
[`core/storage/identity_store.dart`](../lib/core/storage/identity_store.dart).

**There are no passwords.** A person has one identity, held by their paired devices. Every server
account is derived from it, and a device signs in by signing a challenge with a key that identity
certified. The cryptography is the Rust core's
([RaindropCrypto: root identity](../../RaindropCrypto/docs/root-identity.md)); the server's half is in
its [Users](../../RaindropServer/docs/users.md#signing-in-with-a-device-key) and
[E2EE](../../RaindropServer/docs/e2ee.md#identity-vault-authenticator-and-pairing) docs.

## What a device holds

`IdentityStore` (the platform keystore, keys `client.*`, never touched by removing a server):

| Key | What |
|---|---|
| `client.root` | The 32-byte root secret every account is derived from |
| `client.recovery_seed` | What the device keeps of the recovery key: enough to seal the root on a server joined later, not the 24 words |
| `client.authenticator` | The authenticator's secret, when there is one — see [Authenticator](#authenticator) |
| `client.install_id` | A random id for this install, for the device list. Not secret, sent to no server |
| `client.pin_lock` | A token sealed under the app PIN, only on a device that unlocks with one |

`identityProvider` (`IdentityController`) is the identity or `null`. `HomeShell` shows
[`WelcomeScreen`](../lib/features/identity/screens/welcome_screen.dart) while it is `null` and puts
everything else behind [`LockGate`](../lib/features/identity/widgets/lock_gate.dart).

## First run

`WelcomeScreen` offers three ways to get an identity:

- **I'm new** — `IdentityController.create()` makes a root and a recovery key and shows the 24 words
  once (`showRecoveryWordsDialog`).
- **I use Raindrop on another device** — [pairing](#pairing-a-device).
- **Use my recovery words** — [recovery](#recovery-words).

## Unlocking

[`AppLock`](../lib/features/identity/controllers/app_lock.dart) (`appLockProvider`, a `bool`). The app
shows nothing and signs in nowhere until the device is unlocked, once per launch; `confirmUnlock` asks
again before pairing a device, showing recovery words, changing the authenticator and leaving a server.

| `UnlockMethod` | When | How |
|---|---|---|
| `system` | `local_auth` says the device is supported: iOS, Android, macOS, Windows with a screen lock | Face ID, Touch ID, fingerprint, Windows Hello, falling back to the device passcode |
| `pin` | Otherwise (Linux, or a phone with no screen lock), once a PIN is set | An app PIN, checked by opening a blob sealed with Argon2id in the Rust core |
| `none` | Otherwise, before a PIN is set | `LockGate` insists on choosing one (6+ characters) |

At least one always applies; there is no way to run with neither. **What the PIN is:** the keystore
guards the root at rest; the PIN is the app's check that the person at the device is its owner. It does
not encrypt the root.

Android's `MainActivity` is a `FlutterFragmentActivity` for the biometric prompt; the manifest declares
`USE_BIOMETRIC` and iOS `NSFaceIDUsageDescription`.

## Signing in

[`signInWithDevice`](../lib/features/identity/device_sign_in.dart) is the one sign-in:

1. If the server's crypto store has no device yet, `createIdentityFromRoot` makes this device's key
   and certifies it with the identity derived for this server.
2. `UserService.BeginAuth` → a nonce; the device signs it together with the server's identity key.
3. `UserService.CompleteAuth` with the certificate (ignored once the device is registered), a
   username when the account is being made, and an authenticator code when the device holds the
   secret (or the person typed one).

A code this device computed can have just been spent (a code is good once per 30 seconds); that one
refusal is waited out and retried rather than shown.

Who calls it:

- **Adding a server** — [`ConnectServerFlow`](connecting-to-a-server.md).
- **Every later launch, and every lapsed session** — `ServerSessionController` (see
  [Servers & sessions](servers-and-sessions.md)): silently, whenever the stored token is missing or
  refused. A restarted server forgets every session; nobody is asked anything.
- **`SignInPane`** — the rare cases that need the person; see
  [Servers & sessions](servers-and-sessions.md#when-signing-in-needs-the-person).

## The vault

[`Vault`](../lib/features/identity/models/vault.dart): the servers the person is on (address, pinned
fingerprint and identity key, nickname), their devices (install id, name, platform), and a
fingerprint of which authenticator they have. Kept locally in `AppPrefs` (`identity.vault` — none of
it is secret) and, sealed under the root, on every server they are on.

`VaultController.sync(session)` runs each time a session's device setup completes:
read that server's copy, merge with the local one, **add any server this device had not heard of**
(with the pins from the vault; its session then opens by itself), and write the merged vault back if
the server's copy was behind — along with the root sealed under the current recovery seed.

- It only grows: merge keeps the newer of two entries and never drops one.
- **Removing a server from a device is local.** It is recorded in `AppPrefs.hiddenServers`, which
  stops the vault putting it back; adding it again un-hides it.
- **Device names live here and nowhere else.** No server is told what a device is called.
- Not carried yet: pinned identities ("verified" marks) of other members.

## Pairing a device

Neither device needs a camera: the code can be typed.

**New device** — [`PairNewDeviceScreen`](../lib/features/identity/screens/pair_new_device_screen.dart):
the person enters one server they already use; the device makes a pairing offer, leaves it there
(`DeviceService.StartPairing`, anonymous) and shows `RDP1-<pairing id>-<commitment>` as text and a QR
code, polling `TakePairingApproval`.

**Existing device** — Settings → Identity & devices → Pair a device: the code is typed or scanned
(`scanCode`, where `canScanCodes`); the offer is looked for on each server this device is signed in to;
`readPairingOffer` checks it against the code's commitment (a relay that swapped the offer is refused
here); the person confirms the new device's name and unlocks; a `PairingPayload` — root, recovery seed,
authenticator secret, vault — is sealed to the offer and posted (`ApprovePairing`).

The new device opens it, adopts the identity, and `adoptServers` adds every server in the vault.

## Recovery words

[`RecoverScreen`](../lib/features/identity/screens/recover_screen.dart): one server address and the
24 words. The words give a recovery seed, the seed a lookup id for that server
(`DeviceService.GetSealedRoot`, anonymous), and the sealed root opens with the seed. The device adopts
the identity — **without** the authenticator secret, which the words must not be able to reach — and
adds that server; its vault brings the rest.

Settings → New recovery words makes a new key; each server's sealed root is replaced as the vault next
syncs with it, and until then the old words still open that server's copy.

## Authenticator

Optional, and recommended: with it, the recovery words alone cannot add a device.

- **Set up** (Settings → Authenticator): a new 20-byte secret is shown as an `otpauth://` QR code and
  base32 key; the person types a code to prove their app has it; the secret and ten one-time backup
  codes are enrolled on every server reachable now. The backup codes are shown once.
- **A server joined or reached later** is enrolled by `DeviceSetupController` when its session opens
  (without backup codes: the device does not keep them).
- **A paired device** receives the secret in the pairing payload and computes codes itself, so adding
  a server asks nothing. **A recovered device** does not have it: adding it to an account asks for a
  code or a backup code (`ServerAuthScreen`, `SignInPane`).
- **Lost authenticator:** any device still paired sets up a new one — no old code is needed.
- **Replaced or removed on another device:** the vault's authenticator fingerprint says so, and a
  device holding the old secret drops it instead of enrolling it again.
- **Remove:** disabled on every server reachable now. A server that was not reachable keeps asking for
  a code until an authenticator is set up again.

## Limits

- Losing every device **and** the recovery words loses the identity.
- Every paired device holds the root. Removing a device from a server stops its sessions there, but a
  device stolen while unlocked still has the identity; the remedy, a new root, is not built.
- Removing a server from a device deletes that device's keys for it, so adding it back registers a new
  device there (the old one is revoked on the way out when the server is reachable). A server allows
  ten devices per account.
- Message history does not follow a newly paired device.

## Tests

`test/features/identity/identity_logic_test.dart` (authenticator codes against RFC 6238, the pairing
code, vault merging, the pairing payload) and `test/integration/identity_test.dart`, which runs the
whole flow — two devices, the vault, recovery with an authenticator and a backup code, pairing through
the relay — against a live server with the real Rust core (`RAINDROP_TEST_SERVER`; see
[crypto](crypto.md#tests)).
