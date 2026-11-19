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

`WelcomeScreen` offers three ways to get an identity — four, when a
[cloud backup](#cloud-backup) is there to restore, which then comes first:

- **I'm new** — `IdentityController.create()` makes a root and a recovery key and shows the 24 words
  once (`showRecoveryWordsDialog`, see [Keeping the words](#keeping-the-words)); on Apple devices and
  Android it then offers the cloud backup.
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

At least one always applies; there is no way to run with neither. Right after **I'm new** makes an
identity, a device the system unlocks counts as unlocked (`AppLock.trustNewIdentity`): the person who
just made it is the one the lock is for, and the system's prompt would only cover the new recovery
words. A device with no system unlock still has to choose a PIN. **What the PIN is:** the keystore
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

Settings → Identity & devices → New recovery words makes a new key; each server's sealed root is replaced as the vault next
syncs with it, and until then the old words still open that server's copy.

The words are typed or pasted as they come: case, extra spaces and the "7." numbering the dialog shows
are forgiven (`normalizeRecoveryWords`, [`models/recovery_check.dart`](../lib/features/identity/models/recovery_check.dart)).

### Keeping the words

Words nobody wrote down are no way back, so the app works at making sure they were:

- **Laid out to be copied.** The words sit in as many columns as fit, never fewer than two, so a
  phone's narrow dialog does not list 24 lines.
- **Typed back before the dialog closes.** `showRecoveryWordsDialog` shows the words, then asks for
  three random positions (`confirmationPositions`); only the right words close it. There is a way back
  to the words, none out without them.
- **The emergency kit** ([`emergency_kit.dart`](../lib/features/identity/emergency_kit.dart)): a
  one-page PDF, made with the pure-Dart `pdf` package and saved where the person chooses (a save dialog
  on the desktops, the system's own on phones), holding the words, the servers in the vault (recovering
  needs one address; blank lines for more) and what to do. The backup codes dialog offers the same kit
  with the codes. **It can only be made while they are on screen**: the device keeps the seed, never
  the words, and servers keep only hashes of the codes. The kit uses the PDF's built-in Helvetica,
  which has no Unicode — only words, codes and addresses go in it.
- **Check my recovery words** (Identity & devices): all 24 typed in, turned into a seed and compared
  with `client.recovery_seed` on the device (`recoveryWordsMatch`); nothing is sent.
- **Reminders.** `AppPrefs` records when the current words were confirmed
  (`identity.recovery_words_set_at`) and last checked (`identity.recovery_checked_at`).
  `recoveryCheckDueProvider` (`recoveryCheckDue`) puts a nudge at the top of Identity & devices a month
  after the words were made, then every half year after each check, and at once on a device that never
  saw a check.
- **The only device.** When neither the vault nor any open server's device list (`ownDevicesProvider`,
  which follows `e2ee.device.added` / `revoked` for this account) knows another device, the same place
  asks the person to pair another.

## Authenticator

Optional, and recommended: with it, the recovery words alone cannot add a device.

- **Set up** (Settings → Identity & devices → Authenticator): a new 20-byte secret is shown as an `otpauth://` QR code and
  base32 key; the person types a code to prove their app has it; the secret and ten one-time backup
  codes are enrolled on every server reachable now. The backup codes are shown once, with the
  [emergency kit](#keeping-the-words) on offer; setting up warns that an authenticator on a phone is lost
  with the phone.
- **New backup codes** (a device holding the secret): the same secret is enrolled again with ten new
  codes on every server reachable now — the device computes the code enrolling asks for. A server not
  reachable keeps the old codes.
- **A server joined or reached later** is enrolled by `DeviceSetupController` when its session opens
  (without backup codes: the device does not keep them).
- **A paired device** receives the secret in the pairing payload and computes codes itself, so adding
  a server asks nothing. **A recovered device** does not have it: adding it to an account asks for a
  code or a backup code (`ServerAuthScreen`, `SignInPane`).
- **Lost authenticator:** any device still paired sets up a new one — no old code is needed. With no
  device left and no backup code either, see [Waiting out a lost authenticator](#waiting-out-a-lost-authenticator).
- **Replaced or removed on another device:** the vault's authenticator fingerprint says so, and a
  device holding the old secret drops it instead of enrolling it again.
- **Remove:** disabled on every server reachable now. A server that was not reachable keeps asking for
  a code until an authenticator is set up again.

## Waiting out a lost authenticator

For a person with the recovery words and nothing else: every device, the authenticator and its backup
codes gone. The server can let such a device in **after a wait** (a week by default, set by its owner;
see the server's [E2EE doc](../../RaindropServer/docs/e2ee.md#recovering-without-the-authenticator)),
which the account's other devices are told about and can stop.

- **Recovering adds every server at once.** `GetSealedRoot` returns the vault beside the sealed root;
  `RecoverScreen` opens it with the root and `VaultController.adoptServers` adds every server in it.
- **Starting the wait.** `SignInPane`, asking for a code, offers *I lost my authenticator and codes*.
  After a confirmation that says what it is, `ServerSessionController.requestRecovery` signs a fresh
  challenge with this device's key (`requestRecoveryWithDevice`, beside `signInWithDevice`) and calls
  `UserService.RequestRecovery`. The pane then starts the wait on every other server in the list that
  also asks this device for a code, so the person waits once, not once per server.
- **While it runs** (`recovery_pending`), the pane says when it ends — kept per server in `AppPrefs`
  (`identity.recovery_waits`) — with *Check now* and *Enter a code instead*. `ServerSessionController`
  sets a timer for the end and signs in by itself then; a later launch simply signs in, which the server
  now allows with no code. Signing in clears the stored date. The device has no authenticator secret
  afterwards: Identity & devices → Authenticator sets up a new one.
- **Stopped** (`recovery_cancelled`): the pane says another device stopped it and asks for a code.
- **On the person's other devices.** [`pendingRecoveriesProvider`](../lib/features/security/controllers/recovery_watch.dart)
  reads a server's running waits (`DeviceService.GetRecoveryStatus`) and follows
  `e2ee.recovery.changed`. The main view listens to the open server's and asks at once
  ([`askAboutRecoveries`](../lib/features/security/widgets/recovery_alert.dart)): *It was me* remembers
  the answer (`identity.acknowledged_recoveries`); *Stop it* cancels on every server this device has a
  session with (`CancelRecovery`) and points to making new recovery words, since they have leaked.
  Identity & devices shows the same as a nudge with *Stop*. Only servers with a session already open
  are asked — signing in to every server just to look would show the person online everywhere — and the
  one on screen always has one.

## Cloud backup

Opt-in, and off until the person turns it on: a copy of the identity in **iCloud Keychain** (iOS,
macOS) or **Google's Block Store** (Android), both end-to-end encrypted, which a new phone or computer
signed in to the same Apple or Google account brings back — no recovery words. The trade is said
plainly wherever it is offered (`cloudBackupExplanation`): the identity becomes as safe as that
account. Windows and Linux have nowhere to keep one; Identity & devices says so.

- **What is kept** ([`IdentityBackup`](../lib/features/identity/models/identity_backup.dart)): a
  version byte and JSON holding the root, the recovery seed, and the vault's servers with their pins —
  as many as fit Block Store's 4 KB per entry, most recently changed first (one reachable server is
  enough; its vault brings the rest). **Never the authenticator secret**: like the words, a restored
  device still needs a code, a backup code or [the wait](#waiting-out-a-lost-authenticator).
- **Where** ([`CloudBackupStore`](../lib/core/storage/cloud_backup_store.dart), chosen by
  `cloudBackupPlatform` in `platform_info.dart`):
  - Apple: a synchronizable keychain item (`raindrop.identity_backup`, flutter_secure_storage with
    `synchronizable: true`), kept apart from the device-only `client.*` items. Syncing needs iCloud
    Keychain on and a build signed with a team; an unsigned debug build is refused, which shows as
    *unavailable*.
  - Android: one Block Store entry (`com.raindrop.identity_backup`) through `MainActivity`'s
    `raindrop/block_store` channel (`BlockStoreChannel.kt`,
    `play-services-auth-blockstore`). **Nothing is written unless Block Store would encrypt it end to
    end** (Android 9+ with a screen lock); the channel refuses, and the controller reports
    *needs a screen lock*. Restored when a new phone is set up from the Google Account.
- **The controller** ([`cloudBackupProvider`](../lib/features/identity/controllers/cloud_backup.dart)):
  `off`, `on` (it holds this identity's root), `otherIdentity` (another root — turning it on replaces
  it, and says so), `needsScreenLock`, `unavailable`, `unsupported`. `enable` (after the explanation
  and an unlock), `disable` (deletes it, here and at the platform's next sync everywhere), and
  `refresh` — after each vault sync and new recovery words, writing only what changed; on an Android
  phone whose screen lock went, it deletes the backup rather than let it be uploaded in the clear.
- **Restoring** (`restorableBackupProvider`, `restoreFromBackup`): `WelcomeScreen` offers *Restore from
  iCloud Keychain* (or the Google Account) first; the identity is adopted and the listed servers added
  as a synced vault would add them.

## Reclaiming an account

The last way back, for someone who lost every device, the recovery words and any backup: they start a
new identity, and the server's owner — satisfied it is them — runs `reclaim <username>` in the server's
console, which prints a one-time claim code `RDC1-<account id>-<secret>`, good for a day (the server's
[E2EE doc](../../RaindropServer/docs/e2ee.md#reclaiming-an-account)).

- **Joining with it.** `ServerAuthScreen`, for a server where this identity has no account yet, offers
  *I have a claim code from the owner*. [`ClaimCode`](../lib/features/onboarding/models/claim_code.dart)
  reads it (case and spaces forgiven); `ConnectServerFlow.useClaim` makes the account it names the one
  to join (deleting any keys already made for the derived one), and `signInWithDevice` certifies the
  device for that id (`createIdentityFromRoot(userId:)`, the Rust core's
  `create_identity_from_root_for`) and sends `claim_code`. The server resets the old identity — every
  member sees the safety number change — and the account, username and roles are this identity's.
- **The account id is not derivable.** The vault carries each server's `accountId`
  (`VaultServer.accountId`, written by `VaultController` from the profile's id), and everything that
  adds a server from the vault — sync, pairing, recovery words (`RecoverScreen` takes this server's id
  from the vault that comes with the root), the cloud backup — uses it before the derivation.
  `ServerSessionController` and the recovery wait pass the profile's id too. A vault written before
  this had none, which means the derived id, as it then always did.
- Old encrypted history stays unreadable to the new identity.

## Limits

- Losing every device **and** the recovery words loses the identity. Losing every device and the
  authenticator **and** its backup codes means [a wait](#waiting-out-a-lost-authenticator) before the
  words add a device (none at all on a server whose owner switched it off). The
  [cloud backup](#cloud-backup), when on, stands in for the words; with nothing at all left, the
  server's owner can let a new identity [reclaim the account](#reclaiming-an-account), one server at a
  time, without its old history.
- A device that stops a wait only reaches the servers it has a session with; a wait on a server none of
  the person's devices has opened since runs its course unseen.
- Every paired device holds the root. Removing a device from a server stops its sessions there, but a
  device stolen while unlocked still has the identity; the remedy, a new root, is not built.
- Removing a server from a device deletes that device's keys for it, so adding it back registers a new
  device there (the old one is revoked on the way out when the server is reachable). A server allows
  ten devices per account.
- Message history does not follow a newly paired device.

## Tests

`test/features/identity/identity_logic_test.dart` (authenticator codes against RFC 6238, the pairing
code, vault merging, the pairing payload), `recovery_check_test.dart` (typing the words back, the
reminder schedule, the emergency kit, the stored wait), `cloud_backup_test.dart` (what the backup
holds and its size limit, when it is written, refreshed and taken back, the restore offer), `identity_screens_test.dart` (the sign-in pane's
waiting and stopped states) and `test/integration/identity_test.dart`, which runs the
whole flow — two devices, the vault, recovery with an authenticator and a backup code, a wait that one device
stops and another sees through, pairing through the relay — against a live server with the real Rust core (`RAINDROP_TEST_SERVER`; see
[crypto](crypto.md#tests)).
