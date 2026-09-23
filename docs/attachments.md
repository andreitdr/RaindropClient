# Attachments

Members add files of any type to messages, and the chat previews the kinds it knows (images, video,
audio). Files are **end-to-end encrypted** like the messages carrying them. The server stores
ciphertext, and the rules it enforces (size, allowed and blocked extensions) are the owner's
`raindrop.json` — see the server's [Attachments doc](../../RaindropServer/docs/attachments.md).

## Where the code is

| Piece | File | Role |
|---|---|---|
| `AttachmentCipher` / `RustAttachmentCipher` | `core/crypto/attachment_cipher.dart` | Encrypts and decrypts files in the Rust core's `raindrop/attachment/v1` format, through the bridge (`bridge/api/attachment.dart`). Paths cross the bridge, not bytes. `attachmentCiphertextLength` is the same length formula in Dart |
| `AttachmentsApi`, `AttachmentPolicy` | `core/network/attachments_api.dart` | `/api/attachments/*`: policy, create, chunk, status, complete, cancel, download. `AttachmentPolicy.refusalFor` applies the server's rules before anything is sent. Also `extensionOf`, `formatBytes` |
| `ApiClient.putBytes` / `downloadTo` | `core/network/api_client.dart` | A raw `application/octet-stream` PUT, and a streamed download into a file with `Range` resume. Errors are the usual `ApiException` |
| `AttachmentDescriptor`, `ThumbnailDescriptor` | `core/crypto/message_payload.dart` | What a `files` message says about each file, inside the encryption |
| `AttachmentCache` | `core/storage/attachment_cache.dart` | Where ciphertext, plaintext and uploads live on disk, and `safeFileName` |
| `attachmentPolicyProvider`, `AttachmentTransfers` | `features/chat/controllers/attachment_transfers.dart` | The server's rules (null when it takes no files), plus uploading and opening files on one server |
| `ChatAttachment` | `features/chat/models/message.dart` | A file in a message, outgoing (path plus progress) or received (descriptor plus server record) |
| Previews, `FileCard` | `features/chat/widgets/attachments/` | `AttachmentPreviewRegistry`, image, video and audio previews, the file card, upload progress, composer chips |

## Sending

1. **Pick or drop.** The composer's paperclip (`FilePicker.pickFiles`) or, on desktop, dropping onto
   the chat (`desktop_drop`) queues files. Each is checked with `AttachmentPolicy.refusalFor` first:
   blocked or unlisted extension, no extension, too large (per-extension limits included), and at most
   `maximumFilesPerMessage` per message. A refused file never gets further, and a snackbar says why
   ("`.exe` files aren't allowed on this server"). On a phone, a picked file with no path (a content
   URI) is copied into the temporary folder first.
2. **When the button shows.** The server offers `attachments.v1` and has attachments enabled, the
   channel grants `attach_files` and `send_messages` (`Channel.canAttachFiles`), and this device
   encrypts in this server (`channelGroupsProvider`). A file's key travels inside the encrypted
   message, so there is no sending a file without end-to-end encryption.
3. **Upload** (`AttachmentTransfers.upload`, per file): encrypt into `raindrop-upload/` under a fresh
   key; `uploads/create` with the extension and ciphertext length; send chunks of the server's
   `chunkSize`. After a dropped connection or `upload_offset_mismatch`, ask `uploads/status` and carry on
   from there (three tries). Then `uploads/complete` with the ciphertext's SHA-256.
4. **Thumbnail.** For an image (up to 64 MB, decoded with `image` in an isolate) or a video (a frame
   grabbed headless with media_kit), a JPEG of at most 320 px, uploaded as its own `thumbnail`
   attachment. The descriptor also records the pixel size (so the timeline reserves the space) and, for
   video, the duration. A preview that fails is skipped; the file still goes.
5. **The message.** `MessagePayload.files(caption, descriptors)` is attested under **v2**
   (`signMessageAttestationV2`, which also signs each file's id and ciphertext hash, thumbnails after
   their files), encrypted in the channel's group, and posted to `send-encrypted` with `attachmentIds`
   in `attestedFiles` order.

Sending stays optimistic. The pending message shows an `UploadingCard` with progress for each file
(redrawn once per percent). A failure leaves it `failed` **with the descriptors already uploaded**, so
Retry does not upload them again, and Discard cancels them on the server. The composer is not locked
while files upload. The sender's own files are remembered by path (`rememberSent`), so the sent message
shows them without downloading them.

## Receiving

`ChatController._decode` reads a `files` payload into `ChatAttachment`s, each pairing the descriptor
with the server's `MessageAttachmentRef` for the same id:

- **Unavailable**: the payload names a file the server does not list for this message. It is never
  fetched, because a message may only point at files it really carries.
- **Extension mismatch**: the extension the sender declared to the server differs from the one in the
  name inside the message, which means a client lied to get past the server's type rules. The file is
  never previewed; its card carries a warning.
- A payload type this build does not know shows "This message needs a newer version of Raindrop"
  instead of the lock of an undecryptable message.

### Previews

`MessageAttachments` shows each file as a preview **only when** `AttachmentPreviewRegistry` has a
builder for its extension, the server's owner lists the extension in `preview.extensions`, and it is
neither unavailable nor mismatched. Anything else is a `FileCard` (icon, name, size, Save).

| Kind | Extensions (built in) | Behaviour |
|---|---|---|
| Image | png, jpg, jpeg, gif, webp, bmp | Loads by itself when at most `preview.autoLoadMaximumMegabytes`, otherwise shows the thumbnail with a "tap to load" size. Tap to view full screen (`InteractiveViewer`) |
| Video | mp4, webm, mov, mkv, m4v | Thumbnail, play button, duration and size. Never plays by itself; the first tap fetches, decrypts and plays inline (`media_kit_video`'s `Video` with its controls) |
| Audio | mp3, m4a, ogg, oga, wav, flac, opus, aac | A compact player: play/pause, seek bar, position |

`AttachmentPreviewRegistry.register(extensions, builder)` is the **client-side seam** for plugins,
such as a PDF page or a code snippet. The owner's `preview.extensions` still decides whether it is used.

### Opening and saving

`AttachmentTransfers.open` downloads the ciphertext into the cache (resuming a partial copy with
`Range`), then decrypts it into the temporary plaintext folder. `decryptFile` refuses a ciphertext whose
hash is not the one in the message, and one that fails its tags, and then the cached copy is thrown
away. Each file is fetched and decrypted once per run. Thumbnails are decrypted in memory
(`decryptBytes`).

**Save** asks where first on desktop (`file_selector`'s `getSaveLocation`), then copies the decrypted
file there. On phones, `FilePicker.saveFile` takes the bytes. The app never opens or runs a received
file itself.

## On disk (`AttachmentCache`)

| What | Where | Lifetime |
|---|---|---|
| Ciphertext | `<app cache>/raindrop-attachments/<server>/<attachment id>` | Kept, least recently used first out beyond 512 MB. Useless without the key, which lives only in the encrypted message cache |
| Plaintext | `<temp>/raindrop-open/<random>/<safe name>` | Only when a file is opened. Emptied at startup and on exit (`AppLifecycleListener` in `main.dart`) |
| Outgoing ciphertext | `<temp>/raindrop-upload/` | Deleted once sent; emptied at startup |

`safeFileName` keeps only the last component of a sender's file name and drops control and reserved
characters, `.`/`..` and absurd lengths. The name inside a message is never trusted as a path.

## Reports

Reporting a message with files sends `attachments: attestedFiles` with the v2 attestation.
`ChatMessage.payloadType` remembers which payload type was signed. The server checks the signature and
that those are the files stored with the message.

## Platform notes

- **macOS**: `com.apple.security.files.user-selected.read-write` is in both entitlement files, for
  picking, dropping and saving.
- **media_kit** needs `MediaKit.ensureInitialized()` (in `main.dart`) and bundles libmpv through
  `media_kit_libs_video` on every desktop and mobile target.
- Pasting an image from the clipboard is not supported yet; pick or drop it.

## Tests

- `test/core/crypto/message_payload_test.dart`: `files` payloads round-trip; a descriptor this build
  cannot read is dropped; the v2 attestation bytes match the server's golden vector.
- `test/core/network/attachments_api_test.dart`: policy refusals, the allow-list, `extensionOf`, the
  length formula, `formatBytes`, `safeFileName`.
- `test/core/crypto/attachment_cipher_test.dart` (real Rust library): a file round-trips through the
  bridge; a substituted or tampered file is refused and leaves nothing behind.
- `test/integration/e2ee_attachments_test.dart` (live server): uploads a file holding a known secret
  in chunks; checks the server's refusals (blocked type, too large, impossible size, early download,
  resending); has a second member decrypt it byte for byte and resume a download; runs a v2 report (and
  a forged one); confirms deleting the message takes the file. Grep the server's database **and
  attachments folder** for the secret afterwards: it must appear in neither.
