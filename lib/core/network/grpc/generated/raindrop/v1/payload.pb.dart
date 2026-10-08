// This is a generated file - do not edit.
//
// Generated from raindrop/v1/payload.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// What goes inside an end-to-end encrypted message: the plaintext of an MLS application message. Only
/// clients ever see it; the server stores and relays the ciphertext and never decodes this.
///
/// On the wire (inside the MLS message) it is the single version byte 0x02 followed by this message.
/// Version 1 was MessagePack, whose first byte is always a map marker (0x80–0x8f, 0xde, 0xdf), so the
/// two cannot be confused and clients keep reading old history.
///
/// The attestation is computed over fields, not over this encoding, so it is the same in both versions
/// (see RaindropCrypto/docs/wire-contracts.md, message attestation v1/v2).
class MessagePayload extends $pb.GeneratedMessage {
  factory MessagePayload({
    $core.String? type,
    $core.String? body,
    $core.String? clientMessageId,
    $fixnum.Int64? sentAtUnixMs,
    $core.List<$core.int>? attestation,
    $core.Iterable<AttachmentDescriptor>? files,
  }) {
    final result = MessagePayload._();
    if (type != null) result.type = type;
    if (body != null) result.body = body;
    if (clientMessageId != null) result.clientMessageId = clientMessageId;
    if (sentAtUnixMs != null) result.sentAtUnixMs = sentAtUnixMs;
    if (attestation != null) result.attestation = attestation;
    if (files != null) result.files.addAll(files);
    return result;
  }

  MessagePayload._();

  factory MessagePayload.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MessagePayload()..mergeFromBuffer(data, registry);
  factory MessagePayload.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MessagePayload()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MessagePayload',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: MessagePayload.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'type')
    ..aOS(2, _omitFieldNames ? '' : 'body')
    ..aOS(3, _omitFieldNames ? '' : 'clientMessageId')
    ..aInt64(4, _omitFieldNames ? '' : 'sentAtUnixMs')
    ..a<$core.List<$core.int>>(
        5, _omitFieldNames ? '' : 'attestation', $pb.PbFieldType.OY)
    ..pPM<AttachmentDescriptor>(6, _omitFieldNames ? '' : 'files',
        subBuilder: AttachmentDescriptor.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MessagePayload clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MessagePayload copyWith(void Function(MessagePayload) updates) =>
      super.copyWith((message) => updates(message as MessagePayload))
          as MessagePayload;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use MessagePayload() / MessagePayload.new instead')
  static MessagePayload create() => MessagePayload._();
  static $pb.GeneratedMessage $_createMessage() => MessagePayload._();
  @$core.override
  MessagePayload createEmptyInstance() => MessagePayload._();
  @$core.pragma('dart2js:noInline')
  static MessagePayload getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MessagePayload>(
          MessagePayload.$_createMessage);
  static MessagePayload? _defaultInstance;

  /// "text" or "files". An open set: a client shows a placeholder for one it does not know.
  @$pb.TagNumber(1)
  $core.String get type => $_getSZ(0);
  @$pb.TagNumber(1)
  set type($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  /// The text, or a files message's caption (possibly empty).
  @$pb.TagNumber(2)
  $core.String get body => $_getSZ(1);
  @$pb.TagNumber(2)
  set body($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasBody() => $_has(1);
  @$pb.TagNumber(2)
  void clearBody() => $_clearField(2);

  /// Chosen by the sender before encrypting, so its own copy can be matched with the server's echo.
  @$pb.TagNumber(3)
  $core.String get clientMessageId => $_getSZ(2);
  @$pb.TagNumber(3)
  set clientMessageId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasClientMessageId() => $_has(2);
  @$pb.TagNumber(3)
  void clearClientMessageId() => $_clearField(3);

  /// The sender's clock, informational; the server's sent_at orders the timeline.
  @$pb.TagNumber(4)
  $fixnum.Int64 get sentAtUnixMs => $_getI64(3);
  @$pb.TagNumber(4)
  set sentAtUnixMs($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSentAtUnixMs() => $_has(3);
  @$pb.TagNumber(4)
  void clearSentAtUnixMs() => $_clearField(4);

  /// The sending device's Ed25519 signature over the attestation bytes; absent from a client that
  /// does not attest.
  @$pb.TagNumber(5)
  $core.List<$core.int> get attestation => $_getN(4);
  @$pb.TagNumber(5)
  set attestation($core.List<$core.int> value) => $_setBytes(4, value);
  @$pb.TagNumber(5)
  $core.bool hasAttestation() => $_has(4);
  @$pb.TagNumber(5)
  void clearAttestation() => $_clearField(5);

  /// A files message's files, in the order they are shown.
  @$pb.TagNumber(6)
  $pb.PbList<AttachmentDescriptor> get files => $_getList(5);
}

/// One encrypted file as a files message describes it: everything a recipient needs to fetch and open
/// it, none of which the server sees except attachment_id.
class AttachmentDescriptor extends $pb.GeneratedMessage {
  factory AttachmentDescriptor({
    $core.String? attachmentId,
    $core.List<$core.int>? key,
    $core.String? name,
    $core.String? mimeType,
    $fixnum.Int64? size,
    $core.List<$core.int>? ciphertextSha256,
    ThumbnailDescriptor? thumbnail,
    $core.int? width,
    $core.int? height,
    $fixnum.Int64? durationMs,
  }) {
    final result = AttachmentDescriptor._();
    if (attachmentId != null) result.attachmentId = attachmentId;
    if (key != null) result.key = key;
    if (name != null) result.name = name;
    if (mimeType != null) result.mimeType = mimeType;
    if (size != null) result.size = size;
    if (ciphertextSha256 != null) result.ciphertextSha256 = ciphertextSha256;
    if (thumbnail != null) result.thumbnail = thumbnail;
    if (width != null) result.width = width;
    if (height != null) result.height = height;
    if (durationMs != null) result.durationMs = durationMs;
    return result;
  }

  AttachmentDescriptor._();

  factory AttachmentDescriptor.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AttachmentDescriptor()..mergeFromBuffer(data, registry);
  factory AttachmentDescriptor.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AttachmentDescriptor()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AttachmentDescriptor',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: AttachmentDescriptor.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'attachmentId')
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'key', $pb.PbFieldType.OY)
    ..aOS(3, _omitFieldNames ? '' : 'name')
    ..aOS(4, _omitFieldNames ? '' : 'mimeType')
    ..aInt64(5, _omitFieldNames ? '' : 'size')
    ..a<$core.List<$core.int>>(
        6, _omitFieldNames ? '' : 'ciphertextSha256', $pb.PbFieldType.OY)
    ..aOM<ThumbnailDescriptor>(7, _omitFieldNames ? '' : 'thumbnail',
        subBuilder: ThumbnailDescriptor.$_createMessage)
    ..aI(8, _omitFieldNames ? '' : 'width', fieldType: $pb.PbFieldType.OU3)
    ..aI(9, _omitFieldNames ? '' : 'height', fieldType: $pb.PbFieldType.OU3)
    ..aInt64(10, _omitFieldNames ? '' : 'durationMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AttachmentDescriptor clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AttachmentDescriptor copyWith(void Function(AttachmentDescriptor) updates) =>
      super.copyWith((message) => updates(message as AttachmentDescriptor))
          as AttachmentDescriptor;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use AttachmentDescriptor() / AttachmentDescriptor.new instead')
  static AttachmentDescriptor create() => AttachmentDescriptor._();
  static $pb.GeneratedMessage $_createMessage() => AttachmentDescriptor._();
  @$core.override
  AttachmentDescriptor createEmptyInstance() => AttachmentDescriptor._();
  @$core.pragma('dart2js:noInline')
  static AttachmentDescriptor getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AttachmentDescriptor>(
          AttachmentDescriptor.$_createMessage);
  static AttachmentDescriptor? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get attachmentId => $_getSZ(0);
  @$pb.TagNumber(1)
  set attachmentId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAttachmentId() => $_has(0);
  @$pb.TagNumber(1)
  void clearAttachmentId() => $_clearField(1);

  /// The file's own raindrop/attachment/v1 key, 32 bytes.
  @$pb.TagNumber(2)
  $core.List<$core.int> get key => $_getN(1);
  @$pb.TagNumber(2)
  set key($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasKey() => $_has(1);
  @$pb.TagNumber(2)
  void clearKey() => $_clearField(2);

  /// The sender's file name. Never trusted as a path: only its last component is used.
  @$pb.TagNumber(3)
  $core.String get name => $_getSZ(2);
  @$pb.TagNumber(3)
  set name($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasName() => $_has(2);
  @$pb.TagNumber(3)
  void clearName() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get mimeType => $_getSZ(3);
  @$pb.TagNumber(4)
  set mimeType($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasMimeType() => $_has(3);
  @$pb.TagNumber(4)
  void clearMimeType() => $_clearField(4);

  /// The plaintext size.
  @$pb.TagNumber(5)
  $fixnum.Int64 get size => $_getI64(4);
  @$pb.TagNumber(5)
  set size($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSize() => $_has(4);
  @$pb.TagNumber(5)
  void clearSize() => $_clearField(5);

  /// What the downloaded ciphertext must hash to before it is opened, 32 bytes.
  @$pb.TagNumber(6)
  $core.List<$core.int> get ciphertextSha256 => $_getN(5);
  @$pb.TagNumber(6)
  set ciphertextSha256($core.List<$core.int> value) => $_setBytes(5, value);
  @$pb.TagNumber(6)
  $core.bool hasCiphertextSha256() => $_has(5);
  @$pb.TagNumber(6)
  void clearCiphertextSha256() => $_clearField(6);

  /// A small JPEG preview the sender made, uploaded as its own attachment.
  @$pb.TagNumber(7)
  ThumbnailDescriptor get thumbnail => $_getN(6);
  @$pb.TagNumber(7)
  set thumbnail(ThumbnailDescriptor value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasThumbnail() => $_has(6);
  @$pb.TagNumber(7)
  void clearThumbnail() => $_clearField(7);
  @$pb.TagNumber(7)
  ThumbnailDescriptor ensureThumbnail() => $_ensure(6);

  /// For an image or video, its size in pixels.
  @$pb.TagNumber(8)
  $core.int get width => $_getIZ(7);
  @$pb.TagNumber(8)
  set width($core.int value) => $_setUnsignedInt32(7, value);
  @$pb.TagNumber(8)
  $core.bool hasWidth() => $_has(7);
  @$pb.TagNumber(8)
  void clearWidth() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.int get height => $_getIZ(8);
  @$pb.TagNumber(9)
  set height($core.int value) => $_setUnsignedInt32(8, value);
  @$pb.TagNumber(9)
  $core.bool hasHeight() => $_has(8);
  @$pb.TagNumber(9)
  void clearHeight() => $_clearField(9);

  /// For audio or video, how long it plays.
  @$pb.TagNumber(10)
  $fixnum.Int64 get durationMs => $_getI64(9);
  @$pb.TagNumber(10)
  set durationMs($fixnum.Int64 value) => $_setInt64(9, value);
  @$pb.TagNumber(10)
  $core.bool hasDurationMs() => $_has(9);
  @$pb.TagNumber(10)
  void clearDurationMs() => $_clearField(10);
}

/// A sender-made preview of a file.
class ThumbnailDescriptor extends $pb.GeneratedMessage {
  factory ThumbnailDescriptor({
    $core.String? attachmentId,
    $core.List<$core.int>? key,
    $core.List<$core.int>? ciphertextSha256,
  }) {
    final result = ThumbnailDescriptor._();
    if (attachmentId != null) result.attachmentId = attachmentId;
    if (key != null) result.key = key;
    if (ciphertextSha256 != null) result.ciphertextSha256 = ciphertextSha256;
    return result;
  }

  ThumbnailDescriptor._();

  factory ThumbnailDescriptor.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ThumbnailDescriptor()..mergeFromBuffer(data, registry);
  factory ThumbnailDescriptor.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ThumbnailDescriptor()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ThumbnailDescriptor',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: ThumbnailDescriptor.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'attachmentId')
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'key', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'ciphertextSha256', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ThumbnailDescriptor clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ThumbnailDescriptor copyWith(void Function(ThumbnailDescriptor) updates) =>
      super.copyWith((message) => updates(message as ThumbnailDescriptor))
          as ThumbnailDescriptor;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use ThumbnailDescriptor() / ThumbnailDescriptor.new instead')
  static ThumbnailDescriptor create() => ThumbnailDescriptor._();
  static $pb.GeneratedMessage $_createMessage() => ThumbnailDescriptor._();
  @$core.override
  ThumbnailDescriptor createEmptyInstance() => ThumbnailDescriptor._();
  @$core.pragma('dart2js:noInline')
  static ThumbnailDescriptor getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ThumbnailDescriptor>(
          ThumbnailDescriptor.$_createMessage);
  static ThumbnailDescriptor? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get attachmentId => $_getSZ(0);
  @$pb.TagNumber(1)
  set attachmentId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAttachmentId() => $_has(0);
  @$pb.TagNumber(1)
  void clearAttachmentId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get key => $_getN(1);
  @$pb.TagNumber(2)
  set key($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasKey() => $_has(1);
  @$pb.TagNumber(2)
  void clearKey() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get ciphertextSha256 => $_getN(2);
  @$pb.TagNumber(3)
  set ciphertextSha256($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCiphertextSha256() => $_has(2);
  @$pb.TagNumber(3)
  void clearCiphertextSha256() => $_clearField(3);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
