# End-to-end encryption (crypto core)

Raindrop's end-to-end encryption uses **MLS** (RFC 9420) through OpenMLS, in Rust. This page covers
the client side: where the Rust code is, how it gets into the app, and the Dart API the rest of the
client uses. For the Rust core itself — every module, the byte formats, what's implemented — see
[RaindropCrypto's own wiki](../../RaindropCrypto/docs/README.md).

**Status:**

| Part | State |
|---|---|
| Crypto core, bridge and Dart facade | Done |
| Device identities (setup, linking, recovery, revocation, session binding) | Done and wired into the app |
| Server's MLS delivery service, and its `E2eeApi` calls | Done |
| Encrypted text messages (`ChannelGroups`, `ChatController`) | Done — see [Messages & chat](messages-chat.md#end-to-end-encryption) |
| Encrypted calls (media keys from the voice channel's group, LiveKit frame encryption) | Done — see [Voice](voice.md#end-to-end-encrypted-calls) |

## Layout

| Where | What |
|---|---|
| [`../../RaindropCrypto/crates/raindrop_crypto`](../../RaindropCrypto/crates/raindrop_crypto) | The Rust core: MLS groups, identity keys and device certificates, key backup, the encrypted store. No Flutter here. |
| [`../../RaindropCrypto/crates/raindrop_crypto_ffi`](../../RaindropCrypto/crates/raindrop_crypto_ffi) | The flutter_rust_bridge API (`src/api/`), plus the generated `frb_generated.rs` |
| [`native/raindrop_crypto_builder`](../native/raindrop_crypto_builder) | Build glue (cargokit) that compiles the Rust crate during `flutter build` and links it in. No Rust here. |
| [`lib/core/crypto/bridge/`](../lib/core/crypto/bridge) | Generated Dart bindings. Never edit by hand, and the only importers are `core/crypto/` and `core/video/camera_effects_engine.dart`. |
| [`lib/core/crypto/`](../lib/core/crypto) | The Dart facade: `CryptoEngine`, `MlsCryptoEngine` and `CryptoStores` |

The Rust code lives in its own top-level folder, `RaindropCrypto/`, kept apart from the Dart client
and the C# server.

## The Dart API

- **`CryptoEngine`** (`crypto_engine.dart`) is the interface the app codes against. Like
  `VoiceEngine`, nothing above `core/crypto/` names a Rust or MLS type. Errors arrive as
  `CryptoException` with a `CryptoErrorKind`:
  - `identityChanged` is a trust decision for the user. It carries `userId` and is never resolved
    silently.
  - `storeLocked` means a missing or wrong store key.
  - `backupLocked` means wrong recovery words or a wrong passphrase.
- **`MlsCryptoEngine`** (`mls_crypto_engine.dart`) implements it over the bridge and turns the
  bridge's flat structs into sealed classes (`GroupEvent` and its subclasses).
- **`CryptoStores`** (`crypto_store.dart`) opens one engine per server:
  - The encrypted store is `<app support>/crypto/raindrop-<serverId>.db`.
  - Its random 32-byte key is `server.<id>.dbkey` in [`SecureStore`](storage.md).
  - `CryptoStores.initialize()` loads the native library and runs in `main.dart` before `runApp`.
  - `CryptoStores.delete` wipes a server's store and key. `ServersController.remove` calls it.
- **`AttachmentCipher`** (`attachment_cipher.dart`, implemented by `RustAttachmentCipher` over
  `bridge/api/attachment.dart`) encrypts and decrypts files in the core's `raindrop/attachment/v1`
  format, each under its own key, streaming from path to path. It is separate from `CryptoEngine`
  because a file's key is its own rather than the session's. `signMessageAttestationV2` on the engine
  signs a message that carries files. See [Attachments](attachments.md).
- **`groupIdForChannel(channelId)`**: every channel has one MLS group, whose id is the channel UUID
  as 16 big-endian bytes, the same as the server's `Guid.ToByteArray(bigEndian: true)`.

The engine never touches the network. It turns intentions into bytes to deliver, and delivered bytes
into plaintext or group changes.

### Commits

A change to a group (adding or removing devices, rotating keys) produces a `GroupCommit`:

1. Deliver `commit` to the group and `welcome` to the devices it adds.
2. When the server accepts it, call `mergePendingCommit`.
3. If the server answers that another commit won the epoch, call `discardPendingCommit`, process the
   winning commit, and retry if the change is still needed.

The server echoing back your own commit also merges it, so either path works.

### Why there is a message cache

MLS deletes each epoch's keys once the group moves on; that is what forward secrecy means. Ciphertext
fetched again from the server later can no longer be decrypted. `receiveMessage` therefore writes every
decrypted message into the encrypted store, and history is read from there (`cachedMessages`). The
cache is the only copy of the plaintext. Your own messages go in through `rememberSent`, because a
device cannot decrypt its own ciphertext.

### Identity and trust

- **Keys.** Each user has an Ed25519 identity key. It signs a certificate for each of their devices,
  and that certificate travels in the device's MLS credential.
- **Pinning.** Every member of every group is checked: the certificate must verify, and the identity
  key must match the one pinned for that user. A user seen for the first time is pinned there and then
  (trust on first use). A user whose key changed is refused with `identityChanged`.
- **Safety numbers.** `safetyNumber` gives the 60 digits two users compare.
- **Backup.** `sealBackupWithRecoveryKey` (24 words) or `sealBackupWithPassphrase` (Argon2id) seal
  the identity key and pins for the server to store. It cannot read them.

## Setting a device up (`features/security/`)

`deviceSetupProvider(serverId)` (`DeviceSetupController`) runs whenever a session exists, and rebuilds
with it, because the server forgets session bindings when sessions end. The server side is
[`../../RaindropServer/docs/e2ee.md`](../../RaindropServer/docs/e2ee.md).

| State | Meaning | UI |
|---|---|---|
| `DeviceSetupUnsupported` | the server lacks `e2ee.devices.v1` | nothing |
| `DeviceSetupReady` | keys present, device registered, session bound | normal shell. On the account's **first device** it carries `recoveryWords` once: the shell shows `showRecoveryWordsDialog`, which cannot be dismissed without ticking "I have saved it" |
| `DeviceSetupNeedsKeys` | the account has an identity elsewhere and this device has no keys | `EncryptionSetupPane` takes the chat pane: link, recovery key, or reset |
| `DeviceSetupLinking` | waiting for an existing device to approve the shown link code (polls every 2 s, 5 min) | the code, with copy |
| `DeviceSetupReplaced` | the identity was reset elsewhere, or this device was revoked | "Set up again", which wipes the local store |

- **First device of an account.** The controller creates the identity, registers the device, binds
  the session with a signed challenge, then seals a backup under a new recovery key and uploads it.
  `build` reruns whenever the session does, so overlapping runs share one in-flight setup per server
  (`_firstDeviceSetups`) instead of each calling `createIdentity` — the second would fail with "this
  store already holds a device identity". The recovery words are kept (`_unshownRecoveryWords`) until
  `acknowledgeRecoveryWords`, so whichever run ends up live still shows them. A run that finds keys
  in the store while that setup is still in flight joins it too, rather than activating on its heels
  and returning without the words.
- **Activating** (register, then bind with a signed challenge) runs **one at a time per session
  token** (`_activations`). The server keeps one outstanding challenge per session, so two
  activations interleaving would replace each other's nonce and both binds would fail
  (`invalid_signature`, then `no_challenge`). That is what used to leave a first launch on Windows
  stuck: two runs bound the same token at once, and the setup failed after creating the keys.
- **A device with keys and no backup on the server** (a first-device setup that stopped after
  `createIdentity`) seals one under a new recovery key when it next activates, and shows the words
  as above (`_ensureBackup`, best-effort, retried on the next build). Every activation of a device
  with keys therefore costs one `GetKeyBackup`.
- **Clearing the in-flight maps** (`_firstDeviceSetups`, `_backupChecks`) happens in a
  `whenComplete` with a block body, never `() => map.remove(id)`: `remove` returns the stored
  future — the `whenComplete` future itself — and `whenComplete` waits on a returned future, so it
  would wait on itself forever. That was the endless encryption spinner in v2.0.1: setup finished
  every step and then never reported back.
- **Linking.** The new device shows `DeviceLinkCode` (`RDL1-<link id>-<commitment>`) as text and as a
  QR code (`qr_flutter`). The user enters or scans it under Settings → Encryption → *Link a new device*
  on a device that has keys. Scanning (`mobile_scanner`, `link_code_scanner.dart`) is offered where
  `canScanCodes` says the camera can do it: iOS, Android and macOS, each with a camera permission
  string. The device refuses an offer that does not match the code, which is what stops a server
  substituting keys, however the code was entered.
- **Settings → Encryption** (`EncryptionSettingsSection`, for the active server):
  - this device and the identity fingerprint
  - the account's devices, each removable
  - *Link a new device*
  - *New recovery key*
- **Forgetting a server** closes its engine (`cryptoEngineProvider`) before deleting the store, because
  Windows will not delete an open file. `MlsCryptoEngine.dispose` is idempotent for that reason.

`E2eeApi` (`core/network/e2ee_api.dart`) is the typed wrapper over `raindrop.v1.DeviceService` and
`DeliveryService` (every key, certificate and MLS message as protobuf `bytes`), reached as
`ServerSession.e2eeApi`. Besides identities it covers the delivery service:
- groups: `createGroup`, `groupState`, `submitCommit` (throws `epoch_conflict` when another commit won),
  `putGroupInfo`, `syncGroup`, `roster`
- key packages: `uploadKeyPackages`, `keyPackageCount`, `claimKeyPackages`
- Welcomes: `welcomes`, `ackWelcomes`

The engine's key packages are `MLSMessage`-wrapped, which the server requires.

## Building

Needed on the machine (see [`CLAUDE.md`](../CLAUDE.md#commands)):

- A Rust toolchain via `rustup`, on `PATH`. Homebrew's `rustup` is keg-only:
  `export PATH=/opt/homebrew/opt/rustup/bin:$PATH`.
- **CocoaPods**, for iOS and macOS. cargokit only supports CocoaPods, so this one plugin builds
  through the existing Podfiles while the others keep using Swift Package Manager.

With those in place, `flutter build` / `flutter run` compiles the Rust crate on its own, for every
target including Android — cargokit cross-compiles with the installed NDK, so there is no separate
step. The first build takes a few minutes, mostly SQLCipher and OpenMLS.

**The same library also carries the camera effects.** `raindrop_crypto_ffi` depends on
`raindrop_video`, so one cargokit builder, one codegen and one library serve both; the two share
nothing else, and `raindrop_video` holds no key material. That is why
`core/video/camera_effects_engine.dart` imports the bridge, and why it is the only file outside
`core/crypto/` allowed to. See [Voice → Camera effects](voice.md#camera-effects) and
[RaindropCrypto's camera-effects doc](../../RaindropCrypto/docs/video-effects.md).

After changing anything under `raindrop_crypto_ffi/src/api/`, regenerate the bindings from
`RaindropClient/`:

```bash
flutter_rust_bridge_codegen generate
```

The version of the `flutter_rust_bridge` Dart package, the Rust crate's `flutter_rust_bridge`
dependency and the installed codegen must all be exactly **2.13.0**. The generated Dart avoids
`freezed`, which is why the bridge types are flat structs with a `kind` enum rather than
data-carrying enums, so there is still no `build_runner` step.

## Tests

- **Rust** (`cd ../RaindropCrypto && cargo test`):
  - the encrypted store (wrong key refused, no plaintext on disk)
  - certificates and safety numbers
  - backup sealing
  - multi-device scenarios: add, external join, removal, commit races, restart, restore from backup,
    an impostor refused
- **Dart** (`test/core/crypto/mls_crypto_engine_test.dart`): runs the facade against the real library.
  Build it first with `cargo build -p raindrop_crypto_ffi` in `RaindropCrypto/`; without it, the test
  skips itself.
- **Dart, the camera effects' C ABI** (`test/core/video/camera_effects_test.dart`): the same library,
  but it calls the per-frame function *by address*, with padded strides in real native memory, the
  way a capture pipeline does. It is the one place the C signature the platform code copies is
  checked against the one Rust exports — nothing in either language's type system can do it. It
  opens a real effects handle, waits for the first mask and asserts the frame really changed, then
  that a destroyed handle leaves it alone. Skips itself the same way.
- **Against a live server** (`test/integration/e2ee_devices_test.dart`): the real Rust core against a
  real RaindropServer. It covers:
  - the first device establishing the identity
  - session binding, and a signature from the wrong key
  - an impostor certificate
  - linking a device through the relay
  - revocation ending the device's session
  - restoring from the recovery key
  - the unbound-session restriction
  - an identity reset

  It skips itself unless `RAINDROP_TEST_SERVER=host:port` names a server with a fresh database.
  All the integration tests run in parallel against that one server, where by default everybody can
  see every channel, so they only assert about their own channels. Run them together:

  ```bash
  RAINDROP_TEST_SERVER=localhost:5097 flutter test test/integration
  ```
- **Delivery against a live server** (`test/integration/e2ee_delivery_test.dart`). It covers:
  - group creation, and a duplicate refused
  - roster, key packages uploaded and claimed
  - an add with its Welcome delivered and acknowledged
  - an external join, and every member syncing to the same epoch and key
  - a fork race, where the losing commit gets `epoch_conflict`
  - a stale group info, a commit for the wrong group, and garbage input
  - a password-only session refused
  - a revoked device leaving the roster and becoming unclaimable
- **Encrypted messages against a live server** (`test/integration/e2ee_messages_test.dart`): the app's
  own `ChannelGroups` and message API. It covers:
  - plaintext refused
  - the first message creating the group and adding members through key packages and Welcomes
  - everyone decrypting it, and the sender reading its own from the cache
  - a late joiner seeing placeholders for earlier messages
  - a revoked device reconciled out of the group
  - a ciphertext from too old an epoch refused
  - deletion leaving a tombstone without the ciphertext

  After running it, grep the server's database files for the test's secret: it must not appear.
- **Reports against a live server** (`test/integration/e2ee_reports_test.dart`). It checks that the
  Dart attestation and the C# verification agree byte for byte, with non-ASCII text, that altered text
  is refused, and that only the channel's moderators can list reports.
- **Call keys against a live server** (`test/integration/e2ee_voice_test.dart`). It covers:
  - every member of a voice channel's group deriving the same media key and slot
  - a different exporter label giving a different key
  - a rotation moving everyone to a new key, with `epochChanges` firing
  - a revoked device reconciled out, and the key moving on without it
