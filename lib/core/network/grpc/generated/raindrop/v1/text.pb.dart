// This is a generated file - do not edit.
//
// Generated from raindrop/v1/text.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart'
    as $1;

import 'attachments.pbenum.dart' as $2;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// A message as a client sees it. A deleted one still arrives, with no content or ciphertext and
/// deleted set, because it keeps its place in the conversation.
class ChannelMessage extends $pb.GeneratedMessage {
  factory ChannelMessage({
    $core.String? messageId,
    $core.String? channelId,
    $core.String? authorId,
    $core.String? content,
    $1.Timestamp? sentAt,
    $core.bool? deleted,
    $1.Timestamp? deletedAt,
    $core.String? deletedBy,
    $core.List<$core.int>? ciphertext,
    $fixnum.Int64? epoch,
    $core.String? senderDeviceId,
    $core.Iterable<MessageAttachment>? attachments,
  }) {
    final result = ChannelMessage._();
    if (messageId != null) result.messageId = messageId;
    if (channelId != null) result.channelId = channelId;
    if (authorId != null) result.authorId = authorId;
    if (content != null) result.content = content;
    if (sentAt != null) result.sentAt = sentAt;
    if (deleted != null) result.deleted = deleted;
    if (deletedAt != null) result.deletedAt = deletedAt;
    if (deletedBy != null) result.deletedBy = deletedBy;
    if (ciphertext != null) result.ciphertext = ciphertext;
    if (epoch != null) result.epoch = epoch;
    if (senderDeviceId != null) result.senderDeviceId = senderDeviceId;
    if (attachments != null) result.attachments.addAll(attachments);
    return result;
  }

  ChannelMessage._();

  factory ChannelMessage.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ChannelMessage()..mergeFromBuffer(data, registry);
  factory ChannelMessage.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ChannelMessage()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ChannelMessage',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: ChannelMessage.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'messageId')
    ..aOS(2, _omitFieldNames ? '' : 'channelId')
    ..aOS(3, _omitFieldNames ? '' : 'authorId')
    ..aOS(4, _omitFieldNames ? '' : 'content')
    ..aOM<$1.Timestamp>(5, _omitFieldNames ? '' : 'sentAt',
        subBuilder: $1.Timestamp.$_createMessage)
    ..aOB(6, _omitFieldNames ? '' : 'deleted')
    ..aOM<$1.Timestamp>(7, _omitFieldNames ? '' : 'deletedAt',
        subBuilder: $1.Timestamp.$_createMessage)
    ..aOS(8, _omitFieldNames ? '' : 'deletedBy')
    ..a<$core.List<$core.int>>(
        9, _omitFieldNames ? '' : 'ciphertext', $pb.PbFieldType.OY)
    ..aInt64(10, _omitFieldNames ? '' : 'epoch')
    ..aOS(11, _omitFieldNames ? '' : 'senderDeviceId')
    ..pPM<MessageAttachment>(12, _omitFieldNames ? '' : 'attachments',
        subBuilder: MessageAttachment.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChannelMessage clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChannelMessage copyWith(void Function(ChannelMessage) updates) =>
      super.copyWith((message) => updates(message as ChannelMessage))
          as ChannelMessage;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ChannelMessage() / ChannelMessage.new instead')
  static ChannelMessage create() => ChannelMessage._();
  static $pb.GeneratedMessage $_createMessage() => ChannelMessage._();
  @$core.override
  ChannelMessage createEmptyInstance() => ChannelMessage._();
  @$core.pragma('dart2js:noInline')
  static ChannelMessage getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ChannelMessage>(
          ChannelMessage.$_createMessage);
  static ChannelMessage? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get messageId => $_getSZ(0);
  @$pb.TagNumber(1)
  set messageId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessageId() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessageId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get channelId => $_getSZ(1);
  @$pb.TagNumber(2)
  set channelId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasChannelId() => $_has(1);
  @$pb.TagNumber(2)
  void clearChannelId() => $_clearField(2);

  /// Resolve with UserService.LookupUser; a message names a UUID, never a username.
  @$pb.TagNumber(3)
  $core.String get authorId => $_getSZ(2);
  @$pb.TagNumber(3)
  set authorId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAuthorId() => $_has(2);
  @$pb.TagNumber(3)
  void clearAuthorId() => $_clearField(3);

  /// Plaintext messages only; absent once deleted.
  @$pb.TagNumber(4)
  $core.String get content => $_getSZ(3);
  @$pb.TagNumber(4)
  set content($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasContent() => $_has(3);
  @$pb.TagNumber(4)
  void clearContent() => $_clearField(4);

  /// When the server accepted it; the timeline is ordered by this.
  @$pb.TagNumber(5)
  $1.Timestamp get sentAt => $_getN(4);
  @$pb.TagNumber(5)
  set sentAt($1.Timestamp value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasSentAt() => $_has(4);
  @$pb.TagNumber(5)
  void clearSentAt() => $_clearField(5);
  @$pb.TagNumber(5)
  $1.Timestamp ensureSentAt() => $_ensure(4);

  @$pb.TagNumber(6)
  $core.bool get deleted => $_getBF(5);
  @$pb.TagNumber(6)
  set deleted($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasDeleted() => $_has(5);
  @$pb.TagNumber(6)
  void clearDeleted() => $_clearField(6);

  @$pb.TagNumber(7)
  $1.Timestamp get deletedAt => $_getN(6);
  @$pb.TagNumber(7)
  set deletedAt($1.Timestamp value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasDeletedAt() => $_has(6);
  @$pb.TagNumber(7)
  void clearDeletedAt() => $_clearField(7);
  @$pb.TagNumber(7)
  $1.Timestamp ensureDeletedAt() => $_ensure(6);

  @$pb.TagNumber(8)
  $core.String get deletedBy => $_getSZ(7);
  @$pb.TagNumber(8)
  set deletedBy($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasDeletedBy() => $_has(7);
  @$pb.TagNumber(8)
  void clearDeletedBy() => $_clearField(8);

  /// Encrypted messages only: the MLS application message for the channel's group.
  @$pb.TagNumber(9)
  $core.List<$core.int> get ciphertext => $_getN(8);
  @$pb.TagNumber(9)
  set ciphertext($core.List<$core.int> value) => $_setBytes(8, value);
  @$pb.TagNumber(9)
  $core.bool hasCiphertext() => $_has(8);
  @$pb.TagNumber(9)
  void clearCiphertext() => $_clearField(9);

  /// Encrypted messages only: the epoch it was sent in.
  @$pb.TagNumber(10)
  $fixnum.Int64 get epoch => $_getI64(9);
  @$pb.TagNumber(10)
  set epoch($fixnum.Int64 value) => $_setInt64(9, value);
  @$pb.TagNumber(10)
  $core.bool hasEpoch() => $_has(9);
  @$pb.TagNumber(10)
  void clearEpoch() => $_clearField(10);

  /// Encrypted messages only: the device that sent it.
  @$pb.TagNumber(11)
  $core.String get senderDeviceId => $_getSZ(10);
  @$pb.TagNumber(11)
  set senderDeviceId($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasSenderDeviceId() => $_has(10);
  @$pb.TagNumber(11)
  void clearSenderDeviceId() => $_clearField(11);

  /// The encrypted files it carries, by id; their names, types and keys are inside the ciphertext.
  @$pb.TagNumber(12)
  $pb.PbList<MessageAttachment> get attachments => $_getList(11);
}

/// An encrypted file a message carries, as far as the server can describe it.
class MessageAttachment extends $pb.GeneratedMessage {
  factory MessageAttachment({
    $core.String? attachmentId,
    $2.AttachmentKind? kind,
    $core.String? extension_3,
    $fixnum.Int64? ciphertextSize,
    $core.List<$core.int>? ciphertextSha256,
  }) {
    final result = MessageAttachment._();
    if (attachmentId != null) result.attachmentId = attachmentId;
    if (kind != null) result.kind = kind;
    if (extension_3 != null) result.extension_3 = extension_3;
    if (ciphertextSize != null) result.ciphertextSize = ciphertextSize;
    if (ciphertextSha256 != null) result.ciphertextSha256 = ciphertextSha256;
    return result;
  }

  MessageAttachment._();

  factory MessageAttachment.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MessageAttachment()..mergeFromBuffer(data, registry);
  factory MessageAttachment.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MessageAttachment()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MessageAttachment',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: MessageAttachment.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'attachmentId')
    ..aE<$2.AttachmentKind>(2, _omitFieldNames ? '' : 'kind',
        enumValues: $2.AttachmentKind.values)
    ..aOS(3, _omitFieldNames ? '' : 'extension')
    ..aInt64(4, _omitFieldNames ? '' : 'ciphertextSize')
    ..a<$core.List<$core.int>>(
        5, _omitFieldNames ? '' : 'ciphertextSha256', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MessageAttachment clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MessageAttachment copyWith(void Function(MessageAttachment) updates) =>
      super.copyWith((message) => updates(message as MessageAttachment))
          as MessageAttachment;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use MessageAttachment() / MessageAttachment.new instead')
  static MessageAttachment create() => MessageAttachment._();
  static $pb.GeneratedMessage $_createMessage() => MessageAttachment._();
  @$core.override
  MessageAttachment createEmptyInstance() => MessageAttachment._();
  @$core.pragma('dart2js:noInline')
  static MessageAttachment getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MessageAttachment>(
          MessageAttachment.$_createMessage);
  static MessageAttachment? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get attachmentId => $_getSZ(0);
  @$pb.TagNumber(1)
  set attachmentId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAttachmentId() => $_has(0);
  @$pb.TagNumber(1)
  void clearAttachmentId() => $_clearField(1);

  @$pb.TagNumber(2)
  $2.AttachmentKind get kind => $_getN(1);
  @$pb.TagNumber(2)
  set kind($2.AttachmentKind value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasKind() => $_has(1);
  @$pb.TagNumber(2)
  void clearKind() => $_clearField(2);

  /// As the sender declared it: lower case, no dot, empty for none.
  @$pb.TagNumber(3)
  $core.String get extension_3 => $_getSZ(2);
  @$pb.TagNumber(3)
  set extension_3($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasExtension_3() => $_has(2);
  @$pb.TagNumber(3)
  void clearExtension_3() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get ciphertextSize => $_getI64(3);
  @$pb.TagNumber(4)
  set ciphertextSize($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasCiphertextSize() => $_has(3);
  @$pb.TagNumber(4)
  void clearCiphertextSize() => $_clearField(4);

  /// For checking a download early; the hash that counts is the one inside the encrypted message.
  @$pb.TagNumber(5)
  $core.List<$core.int> get ciphertextSha256 => $_getN(4);
  @$pb.TagNumber(5)
  set ciphertextSha256($core.List<$core.int> value) => $_setBytes(4, value);
  @$pb.TagNumber(5)
  $core.bool hasCiphertextSha256() => $_has(4);
  @$pb.TagNumber(5)
  void clearCiphertextSha256() => $_clearField(5);
}

/// A file named in a report's attestation.
class AttestedAttachment extends $pb.GeneratedMessage {
  factory AttestedAttachment({
    $core.String? attachmentId,
    $core.List<$core.int>? ciphertextSha256,
  }) {
    final result = AttestedAttachment._();
    if (attachmentId != null) result.attachmentId = attachmentId;
    if (ciphertextSha256 != null) result.ciphertextSha256 = ciphertextSha256;
    return result;
  }

  AttestedAttachment._();

  factory AttestedAttachment.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AttestedAttachment()..mergeFromBuffer(data, registry);
  factory AttestedAttachment.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AttestedAttachment()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AttestedAttachment',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: AttestedAttachment.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'attachmentId')
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'ciphertextSha256', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AttestedAttachment clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AttestedAttachment copyWith(void Function(AttestedAttachment) updates) =>
      super.copyWith((message) => updates(message as AttestedAttachment))
          as AttestedAttachment;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use AttestedAttachment() / AttestedAttachment.new instead')
  static AttestedAttachment create() => AttestedAttachment._();
  static $pb.GeneratedMessage $_createMessage() => AttestedAttachment._();
  @$core.override
  AttestedAttachment createEmptyInstance() => AttestedAttachment._();
  @$core.pragma('dart2js:noInline')
  static AttestedAttachment getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AttestedAttachment>(
          AttestedAttachment.$_createMessage);
  static AttestedAttachment? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get attachmentId => $_getSZ(0);
  @$pb.TagNumber(1)
  set attachmentId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAttachmentId() => $_has(0);
  @$pb.TagNumber(1)
  void clearAttachmentId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get ciphertextSha256 => $_getN(1);
  @$pb.TagNumber(2)
  set ciphertextSha256($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCiphertextSha256() => $_has(1);
  @$pb.TagNumber(2)
  void clearCiphertextSha256() => $_clearField(2);
}

/// The files a v2 attestation signs. Its presence is what selects v2
/// (raindrop/message-attestation/v2), so it is a message rather than a bare repeated field.
class AttestedFiles extends $pb.GeneratedMessage {
  factory AttestedFiles({
    $core.Iterable<AttestedAttachment>? attachments,
  }) {
    final result = AttestedFiles._();
    if (attachments != null) result.attachments.addAll(attachments);
    return result;
  }

  AttestedFiles._();

  factory AttestedFiles.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AttestedFiles()..mergeFromBuffer(data, registry);
  factory AttestedFiles.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AttestedFiles()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AttestedFiles',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: AttestedFiles.$_createMessage)
    ..pPM<AttestedAttachment>(1, _omitFieldNames ? '' : 'attachments',
        subBuilder: AttestedAttachment.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AttestedFiles clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AttestedFiles copyWith(void Function(AttestedFiles) updates) =>
      super.copyWith((message) => updates(message as AttestedFiles))
          as AttestedFiles;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use AttestedFiles() / AttestedFiles.new instead')
  static AttestedFiles create() => AttestedFiles._();
  static $pb.GeneratedMessage $_createMessage() => AttestedFiles._();
  @$core.override
  AttestedFiles createEmptyInstance() => AttestedFiles._();
  @$core.pragma('dart2js:noInline')
  static AttestedFiles getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AttestedFiles>(
          AttestedFiles.$_createMessage);
  static AttestedFiles? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<AttestedAttachment> get attachments => $_getList(0);
}

/// A stored report: the only encrypted-message text the server ever holds.
class MessageReport extends $pb.GeneratedMessage {
  factory MessageReport({
    $core.String? reportId,
    $core.String? messageId,
    $core.String? channelId,
    $core.String? authorId,
    $core.String? senderDeviceId,
    $core.String? reporterId,
    $core.String? body,
    $core.String? reason,
    $1.Timestamp? messageSentAt,
    $1.Timestamp? reportedAt,
  }) {
    final result = MessageReport._();
    if (reportId != null) result.reportId = reportId;
    if (messageId != null) result.messageId = messageId;
    if (channelId != null) result.channelId = channelId;
    if (authorId != null) result.authorId = authorId;
    if (senderDeviceId != null) result.senderDeviceId = senderDeviceId;
    if (reporterId != null) result.reporterId = reporterId;
    if (body != null) result.body = body;
    if (reason != null) result.reason = reason;
    if (messageSentAt != null) result.messageSentAt = messageSentAt;
    if (reportedAt != null) result.reportedAt = reportedAt;
    return result;
  }

  MessageReport._();

  factory MessageReport.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MessageReport()..mergeFromBuffer(data, registry);
  factory MessageReport.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MessageReport()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MessageReport',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: MessageReport.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'reportId')
    ..aOS(2, _omitFieldNames ? '' : 'messageId')
    ..aOS(3, _omitFieldNames ? '' : 'channelId')
    ..aOS(4, _omitFieldNames ? '' : 'authorId')
    ..aOS(5, _omitFieldNames ? '' : 'senderDeviceId')
    ..aOS(6, _omitFieldNames ? '' : 'reporterId')
    ..aOS(7, _omitFieldNames ? '' : 'body')
    ..aOS(8, _omitFieldNames ? '' : 'reason')
    ..aOM<$1.Timestamp>(9, _omitFieldNames ? '' : 'messageSentAt',
        subBuilder: $1.Timestamp.$_createMessage)
    ..aOM<$1.Timestamp>(10, _omitFieldNames ? '' : 'reportedAt',
        subBuilder: $1.Timestamp.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MessageReport clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MessageReport copyWith(void Function(MessageReport) updates) =>
      super.copyWith((message) => updates(message as MessageReport))
          as MessageReport;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use MessageReport() / MessageReport.new instead')
  static MessageReport create() => MessageReport._();
  static $pb.GeneratedMessage $_createMessage() => MessageReport._();
  @$core.override
  MessageReport createEmptyInstance() => MessageReport._();
  @$core.pragma('dart2js:noInline')
  static MessageReport getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MessageReport>(
          MessageReport.$_createMessage);
  static MessageReport? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get reportId => $_getSZ(0);
  @$pb.TagNumber(1)
  set reportId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasReportId() => $_has(0);
  @$pb.TagNumber(1)
  void clearReportId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get messageId => $_getSZ(1);
  @$pb.TagNumber(2)
  set messageId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessageId() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessageId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get channelId => $_getSZ(2);
  @$pb.TagNumber(3)
  set channelId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasChannelId() => $_has(2);
  @$pb.TagNumber(3)
  void clearChannelId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get authorId => $_getSZ(3);
  @$pb.TagNumber(4)
  set authorId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAuthorId() => $_has(3);
  @$pb.TagNumber(4)
  void clearAuthorId() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get senderDeviceId => $_getSZ(4);
  @$pb.TagNumber(5)
  set senderDeviceId($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSenderDeviceId() => $_has(4);
  @$pb.TagNumber(5)
  void clearSenderDeviceId() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get reporterId => $_getSZ(5);
  @$pb.TagNumber(6)
  set reporterId($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasReporterId() => $_has(5);
  @$pb.TagNumber(6)
  void clearReporterId() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get body => $_getSZ(6);
  @$pb.TagNumber(7)
  set body($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasBody() => $_has(6);
  @$pb.TagNumber(7)
  void clearBody() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get reason => $_getSZ(7);
  @$pb.TagNumber(8)
  set reason($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasReason() => $_has(7);
  @$pb.TagNumber(8)
  void clearReason() => $_clearField(8);

  @$pb.TagNumber(9)
  $1.Timestamp get messageSentAt => $_getN(8);
  @$pb.TagNumber(9)
  set messageSentAt($1.Timestamp value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasMessageSentAt() => $_has(8);
  @$pb.TagNumber(9)
  void clearMessageSentAt() => $_clearField(9);
  @$pb.TagNumber(9)
  $1.Timestamp ensureMessageSentAt() => $_ensure(8);

  @$pb.TagNumber(10)
  $1.Timestamp get reportedAt => $_getN(9);
  @$pb.TagNumber(10)
  set reportedAt($1.Timestamp value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasReportedAt() => $_has(9);
  @$pb.TagNumber(10)
  void clearReportedAt() => $_clearField(10);
  @$pb.TagNumber(10)
  $1.Timestamp ensureReportedAt() => $_ensure(9);
}

/// Posts a plaintext message.
class SendMessageRequest extends $pb.GeneratedMessage {
  factory SendMessageRequest({
    $core.String? channelId,
    $core.String? content,
  }) {
    final result = SendMessageRequest._();
    if (channelId != null) result.channelId = channelId;
    if (content != null) result.content = content;
    return result;
  }

  SendMessageRequest._();

  factory SendMessageRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SendMessageRequest()..mergeFromBuffer(data, registry);
  factory SendMessageRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SendMessageRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SendMessageRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: SendMessageRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'channelId')
    ..aOS(2, _omitFieldNames ? '' : 'content')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SendMessageRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SendMessageRequest copyWith(void Function(SendMessageRequest) updates) =>
      super.copyWith((message) => updates(message as SendMessageRequest))
          as SendMessageRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SendMessageRequest() / SendMessageRequest.new instead')
  static SendMessageRequest create() => SendMessageRequest._();
  static $pb.GeneratedMessage $_createMessage() => SendMessageRequest._();
  @$core.override
  SendMessageRequest createEmptyInstance() => SendMessageRequest._();
  @$core.pragma('dart2js:noInline')
  static SendMessageRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SendMessageRequest>(
          SendMessageRequest.$_createMessage);
  static SendMessageRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get channelId => $_getSZ(0);
  @$pb.TagNumber(1)
  set channelId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasChannelId() => $_has(0);
  @$pb.TagNumber(1)
  void clearChannelId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get content => $_getSZ(1);
  @$pb.TagNumber(2)
  set content($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasContent() => $_has(1);
  @$pb.TagNumber(2)
  void clearContent() => $_clearField(2);
}

/// The stored message, with its real id and time.
class SendMessageResponse extends $pb.GeneratedMessage {
  factory SendMessageResponse({
    ChannelMessage? message,
  }) {
    final result = SendMessageResponse._();
    if (message != null) result.message = message;
    return result;
  }

  SendMessageResponse._();

  factory SendMessageResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SendMessageResponse()..mergeFromBuffer(data, registry);
  factory SendMessageResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SendMessageResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SendMessageResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: SendMessageResponse.$_createMessage)
    ..aOM<ChannelMessage>(1, _omitFieldNames ? '' : 'message',
        subBuilder: ChannelMessage.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SendMessageResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SendMessageResponse copyWith(void Function(SendMessageResponse) updates) =>
      super.copyWith((message) => updates(message as SendMessageResponse))
          as SendMessageResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use SendMessageResponse() / SendMessageResponse.new instead')
  static SendMessageResponse create() => SendMessageResponse._();
  static $pb.GeneratedMessage $_createMessage() => SendMessageResponse._();
  @$core.override
  SendMessageResponse createEmptyInstance() => SendMessageResponse._();
  @$core.pragma('dart2js:noInline')
  static SendMessageResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SendMessageResponse>(
          SendMessageResponse.$_createMessage);
  static SendMessageResponse? _defaultInstance;

  @$pb.TagNumber(1)
  ChannelMessage get message => $_getN(0);
  @$pb.TagNumber(1)
  set message(ChannelMessage value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);
  @$pb.TagNumber(1)
  ChannelMessage ensureMessage() => $_ensure(0);
}

/// Posts an encrypted message.
class SendEncryptedMessageRequest extends $pb.GeneratedMessage {
  factory SendEncryptedMessageRequest({
    $core.String? channelId,
    $core.List<$core.int>? message,
    $core.Iterable<$core.String>? attachmentIds,
  }) {
    final result = SendEncryptedMessageRequest._();
    if (channelId != null) result.channelId = channelId;
    if (message != null) result.message = message;
    if (attachmentIds != null) result.attachmentIds.addAll(attachmentIds);
    return result;
  }

  SendEncryptedMessageRequest._();

  factory SendEncryptedMessageRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SendEncryptedMessageRequest()..mergeFromBuffer(data, registry);
  factory SendEncryptedMessageRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SendEncryptedMessageRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SendEncryptedMessageRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: SendEncryptedMessageRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'channelId')
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'message', $pb.PbFieldType.OY)
    ..pPS(3, _omitFieldNames ? '' : 'attachmentIds')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SendEncryptedMessageRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SendEncryptedMessageRequest copyWith(
          void Function(SendEncryptedMessageRequest) updates) =>
      super.copyWith(
              (message) => updates(message as SendEncryptedMessageRequest))
          as SendEncryptedMessageRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SendEncryptedMessageRequest() / SendEncryptedMessageRequest.new instead')
  static SendEncryptedMessageRequest create() =>
      SendEncryptedMessageRequest._();
  static $pb.GeneratedMessage $_createMessage() =>
      SendEncryptedMessageRequest._();
  @$core.override
  SendEncryptedMessageRequest createEmptyInstance() =>
      SendEncryptedMessageRequest._();
  @$core.pragma('dart2js:noInline')
  static SendEncryptedMessageRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SendEncryptedMessageRequest>(
          SendEncryptedMessageRequest.$_createMessage);
  static SendEncryptedMessageRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get channelId => $_getSZ(0);
  @$pb.TagNumber(1)
  set channelId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasChannelId() => $_has(0);
  @$pb.TagNumber(1)
  void clearChannelId() => $_clearField(1);

  /// The MLS application message the sender's device encrypted in the group's current epoch.
  @$pb.TagNumber(2)
  $core.List<$core.int> get message => $_getN(1);
  @$pb.TagNumber(2)
  set message($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);

  /// Finished uploads to send with it, in the order the message lists them.
  @$pb.TagNumber(3)
  $pb.PbList<$core.String> get attachmentIds => $_getList(2);
}

/// The stored message, with its real id and time.
class SendEncryptedMessageResponse extends $pb.GeneratedMessage {
  factory SendEncryptedMessageResponse({
    ChannelMessage? message,
  }) {
    final result = SendEncryptedMessageResponse._();
    if (message != null) result.message = message;
    return result;
  }

  SendEncryptedMessageResponse._();

  factory SendEncryptedMessageResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SendEncryptedMessageResponse()..mergeFromBuffer(data, registry);
  factory SendEncryptedMessageResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SendEncryptedMessageResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SendEncryptedMessageResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: SendEncryptedMessageResponse.$_createMessage)
    ..aOM<ChannelMessage>(1, _omitFieldNames ? '' : 'message',
        subBuilder: ChannelMessage.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SendEncryptedMessageResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SendEncryptedMessageResponse copyWith(
          void Function(SendEncryptedMessageResponse) updates) =>
      super.copyWith(
              (message) => updates(message as SendEncryptedMessageResponse))
          as SendEncryptedMessageResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SendEncryptedMessageResponse() / SendEncryptedMessageResponse.new instead')
  static SendEncryptedMessageResponse create() =>
      SendEncryptedMessageResponse._();
  static $pb.GeneratedMessage $_createMessage() =>
      SendEncryptedMessageResponse._();
  @$core.override
  SendEncryptedMessageResponse createEmptyInstance() =>
      SendEncryptedMessageResponse._();
  @$core.pragma('dart2js:noInline')
  static SendEncryptedMessageResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SendEncryptedMessageResponse>(
          SendEncryptedMessageResponse.$_createMessage);
  static SendEncryptedMessageResponse? _defaultInstance;

  @$pb.TagNumber(1)
  ChannelMessage get message => $_getN(0);
  @$pb.TagNumber(1)
  set message(ChannelMessage value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);
  @$pb.TagNumber(1)
  ChannelMessage ensureMessage() => $_ensure(0);
}

/// Reads one page of a channel.
class GetHistoryRequest extends $pb.GeneratedMessage {
  factory GetHistoryRequest({
    $core.String? channelId,
    $core.String? before,
    $core.int? limit,
  }) {
    final result = GetHistoryRequest._();
    if (channelId != null) result.channelId = channelId;
    if (before != null) result.before = before;
    if (limit != null) result.limit = limit;
    return result;
  }

  GetHistoryRequest._();

  factory GetHistoryRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetHistoryRequest()..mergeFromBuffer(data, registry);
  factory GetHistoryRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetHistoryRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetHistoryRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: GetHistoryRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'channelId')
    ..aOS(2, _omitFieldNames ? '' : 'before')
    ..aI(3, _omitFieldNames ? '' : 'limit')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetHistoryRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetHistoryRequest copyWith(void Function(GetHistoryRequest) updates) =>
      super.copyWith((message) => updates(message as GetHistoryRequest))
          as GetHistoryRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetHistoryRequest() / GetHistoryRequest.new instead')
  static GetHistoryRequest create() => GetHistoryRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetHistoryRequest._();
  @$core.override
  GetHistoryRequest createEmptyInstance() => GetHistoryRequest._();
  @$core.pragma('dart2js:noInline')
  static GetHistoryRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetHistoryRequest>(
          GetHistoryRequest.$_createMessage);
  static GetHistoryRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get channelId => $_getSZ(0);
  @$pb.TagNumber(1)
  set channelId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasChannelId() => $_has(0);
  @$pb.TagNumber(1)
  void clearChannelId() => $_clearField(1);

  /// next_cursor from the previous page, passed back untouched; absent for the newest messages.
  @$pb.TagNumber(2)
  $core.String get before => $_getSZ(1);
  @$pb.TagNumber(2)
  set before($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasBefore() => $_has(1);
  @$pb.TagNumber(2)
  void clearBefore() => $_clearField(2);

  /// Absent: the server's default page size. More than its maximum is trimmed.
  @$pb.TagNumber(3)
  $core.int get limit => $_getIZ(2);
  @$pb.TagNumber(3)
  set limit($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLimit() => $_has(2);
  @$pb.TagNumber(3)
  void clearLimit() => $_clearField(3);
}

/// One page, oldest first as it is rendered.
class GetHistoryResponse extends $pb.GeneratedMessage {
  factory GetHistoryResponse({
    $core.String? channelId,
    $core.Iterable<ChannelMessage>? messages,
    $core.String? nextCursor,
  }) {
    final result = GetHistoryResponse._();
    if (channelId != null) result.channelId = channelId;
    if (messages != null) result.messages.addAll(messages);
    if (nextCursor != null) result.nextCursor = nextCursor;
    return result;
  }

  GetHistoryResponse._();

  factory GetHistoryResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetHistoryResponse()..mergeFromBuffer(data, registry);
  factory GetHistoryResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetHistoryResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetHistoryResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: GetHistoryResponse.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'channelId')
    ..pPM<ChannelMessage>(2, _omitFieldNames ? '' : 'messages',
        subBuilder: ChannelMessage.$_createMessage)
    ..aOS(3, _omitFieldNames ? '' : 'nextCursor')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetHistoryResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetHistoryResponse copyWith(void Function(GetHistoryResponse) updates) =>
      super.copyWith((message) => updates(message as GetHistoryResponse))
          as GetHistoryResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetHistoryResponse() / GetHistoryResponse.new instead')
  static GetHistoryResponse create() => GetHistoryResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetHistoryResponse._();
  @$core.override
  GetHistoryResponse createEmptyInstance() => GetHistoryResponse._();
  @$core.pragma('dart2js:noInline')
  static GetHistoryResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetHistoryResponse>(
          GetHistoryResponse.$_createMessage);
  static GetHistoryResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get channelId => $_getSZ(0);
  @$pb.TagNumber(1)
  set channelId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasChannelId() => $_has(0);
  @$pb.TagNumber(1)
  void clearChannelId() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<ChannelMessage> get messages => $_getList(1);

  /// For the page before this one; absent at the beginning of the channel.
  @$pb.TagNumber(3)
  $core.String get nextCursor => $_getSZ(2);
  @$pb.TagNumber(3)
  set nextCursor($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasNextCursor() => $_has(2);
  @$pb.TagNumber(3)
  void clearNextCursor() => $_clearField(3);
}

/// Deletes a message.
class DeleteMessageRequest extends $pb.GeneratedMessage {
  factory DeleteMessageRequest({
    $core.String? messageId,
  }) {
    final result = DeleteMessageRequest._();
    if (messageId != null) result.messageId = messageId;
    return result;
  }

  DeleteMessageRequest._();

  factory DeleteMessageRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DeleteMessageRequest()..mergeFromBuffer(data, registry);
  factory DeleteMessageRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DeleteMessageRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteMessageRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: DeleteMessageRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'messageId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteMessageRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteMessageRequest copyWith(void Function(DeleteMessageRequest) updates) =>
      super.copyWith((message) => updates(message as DeleteMessageRequest))
          as DeleteMessageRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use DeleteMessageRequest() / DeleteMessageRequest.new instead')
  static DeleteMessageRequest create() => DeleteMessageRequest._();
  static $pb.GeneratedMessage $_createMessage() => DeleteMessageRequest._();
  @$core.override
  DeleteMessageRequest createEmptyInstance() => DeleteMessageRequest._();
  @$core.pragma('dart2js:noInline')
  static DeleteMessageRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteMessageRequest>(
          DeleteMessageRequest.$_createMessage);
  static DeleteMessageRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get messageId => $_getSZ(0);
  @$pb.TagNumber(1)
  set messageId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessageId() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessageId() => $_clearField(1);
}

/// The tombstone.
class DeleteMessageResponse extends $pb.GeneratedMessage {
  factory DeleteMessageResponse({
    ChannelMessage? message,
  }) {
    final result = DeleteMessageResponse._();
    if (message != null) result.message = message;
    return result;
  }

  DeleteMessageResponse._();

  factory DeleteMessageResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DeleteMessageResponse()..mergeFromBuffer(data, registry);
  factory DeleteMessageResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DeleteMessageResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteMessageResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: DeleteMessageResponse.$_createMessage)
    ..aOM<ChannelMessage>(1, _omitFieldNames ? '' : 'message',
        subBuilder: ChannelMessage.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteMessageResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteMessageResponse copyWith(
          void Function(DeleteMessageResponse) updates) =>
      super.copyWith((message) => updates(message as DeleteMessageResponse))
          as DeleteMessageResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use DeleteMessageResponse() / DeleteMessageResponse.new instead')
  static DeleteMessageResponse create() => DeleteMessageResponse._();
  static $pb.GeneratedMessage $_createMessage() => DeleteMessageResponse._();
  @$core.override
  DeleteMessageResponse createEmptyInstance() => DeleteMessageResponse._();
  @$core.pragma('dart2js:noInline')
  static DeleteMessageResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteMessageResponse>(
          DeleteMessageResponse.$_createMessage);
  static DeleteMessageResponse? _defaultInstance;

  @$pb.TagNumber(1)
  ChannelMessage get message => $_getN(0);
  @$pb.TagNumber(1)
  set message(ChannelMessage value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);
  @$pb.TagNumber(1)
  ChannelMessage ensureMessage() => $_ensure(0);
}

/// Reports an encrypted message. Every signed field is exactly as the sender signed it.
class ReportMessageRequest extends $pb.GeneratedMessage {
  factory ReportMessageRequest({
    $core.String? messageId,
    $core.String? body,
    $core.String? clientMessageId,
    $fixnum.Int64? clientSentAtUnixMs,
    $core.String? type,
    $core.List<$core.int>? attestation,
    $core.String? reason,
    AttestedFiles? attestedFiles,
  }) {
    final result = ReportMessageRequest._();
    if (messageId != null) result.messageId = messageId;
    if (body != null) result.body = body;
    if (clientMessageId != null) result.clientMessageId = clientMessageId;
    if (clientSentAtUnixMs != null)
      result.clientSentAtUnixMs = clientSentAtUnixMs;
    if (type != null) result.type = type;
    if (attestation != null) result.attestation = attestation;
    if (reason != null) result.reason = reason;
    if (attestedFiles != null) result.attestedFiles = attestedFiles;
    return result;
  }

  ReportMessageRequest._();

  factory ReportMessageRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReportMessageRequest()..mergeFromBuffer(data, registry);
  factory ReportMessageRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReportMessageRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReportMessageRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: ReportMessageRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'messageId')
    ..aOS(2, _omitFieldNames ? '' : 'body')
    ..aOS(3, _omitFieldNames ? '' : 'clientMessageId')
    ..aInt64(4, _omitFieldNames ? '' : 'clientSentAtUnixMs')
    ..aOS(5, _omitFieldNames ? '' : 'type')
    ..a<$core.List<$core.int>>(
        6, _omitFieldNames ? '' : 'attestation', $pb.PbFieldType.OY)
    ..aOS(7, _omitFieldNames ? '' : 'reason')
    ..aOM<AttestedFiles>(8, _omitFieldNames ? '' : 'attestedFiles',
        subBuilder: AttestedFiles.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReportMessageRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReportMessageRequest copyWith(void Function(ReportMessageRequest) updates) =>
      super.copyWith((message) => updates(message as ReportMessageRequest))
          as ReportMessageRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ReportMessageRequest() / ReportMessageRequest.new instead')
  static ReportMessageRequest create() => ReportMessageRequest._();
  static $pb.GeneratedMessage $_createMessage() => ReportMessageRequest._();
  @$core.override
  ReportMessageRequest createEmptyInstance() => ReportMessageRequest._();
  @$core.pragma('dart2js:noInline')
  static ReportMessageRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReportMessageRequest>(
          ReportMessageRequest.$_createMessage);
  static ReportMessageRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get messageId => $_getSZ(0);
  @$pb.TagNumber(1)
  set messageId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessageId() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessageId() => $_clearField(1);

  /// The decrypted text the reporter reveals.
  @$pb.TagNumber(2)
  $core.String get body => $_getSZ(1);
  @$pb.TagNumber(2)
  set body($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasBody() => $_has(1);
  @$pb.TagNumber(2)
  void clearBody() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get clientMessageId => $_getSZ(2);
  @$pb.TagNumber(3)
  set clientMessageId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasClientMessageId() => $_has(2);
  @$pb.TagNumber(3)
  void clearClientMessageId() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get clientSentAtUnixMs => $_getI64(3);
  @$pb.TagNumber(4)
  set clientSentAtUnixMs($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasClientSentAtUnixMs() => $_has(3);
  @$pb.TagNumber(4)
  void clearClientSentAtUnixMs() => $_clearField(4);

  /// The payload type, e.g. "text" or "files".
  @$pb.TagNumber(5)
  $core.String get type => $_getSZ(4);
  @$pb.TagNumber(5)
  set type($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasType() => $_has(4);
  @$pb.TagNumber(5)
  void clearType() => $_clearField(5);

  /// The sender device's Ed25519 signature.
  @$pb.TagNumber(6)
  $core.List<$core.int> get attestation => $_getN(5);
  @$pb.TagNumber(6)
  set attestation($core.List<$core.int> value) => $_setBytes(5, value);
  @$pb.TagNumber(6)
  $core.bool hasAttestation() => $_has(5);
  @$pb.TagNumber(6)
  void clearAttestation() => $_clearField(6);

  /// At most 500 characters.
  @$pb.TagNumber(7)
  $core.String get reason => $_getSZ(6);
  @$pb.TagNumber(7)
  set reason($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasReason() => $_has(6);
  @$pb.TagNumber(7)
  void clearReason() => $_clearField(7);

  /// Present for a message that carries files: the attestation is then a v2 one.
  @$pb.TagNumber(8)
  AttestedFiles get attestedFiles => $_getN(7);
  @$pb.TagNumber(8)
  set attestedFiles(AttestedFiles value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasAttestedFiles() => $_has(7);
  @$pb.TagNumber(8)
  void clearAttestedFiles() => $_clearField(8);
  @$pb.TagNumber(8)
  AttestedFiles ensureAttestedFiles() => $_ensure(7);
}

/// The stored report.
class ReportMessageResponse extends $pb.GeneratedMessage {
  factory ReportMessageResponse({
    MessageReport? report,
  }) {
    final result = ReportMessageResponse._();
    if (report != null) result.report = report;
    return result;
  }

  ReportMessageResponse._();

  factory ReportMessageResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReportMessageResponse()..mergeFromBuffer(data, registry);
  factory ReportMessageResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReportMessageResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReportMessageResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: ReportMessageResponse.$_createMessage)
    ..aOM<MessageReport>(1, _omitFieldNames ? '' : 'report',
        subBuilder: MessageReport.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReportMessageResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReportMessageResponse copyWith(
          void Function(ReportMessageResponse) updates) =>
      super.copyWith((message) => updates(message as ReportMessageResponse))
          as ReportMessageResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ReportMessageResponse() / ReportMessageResponse.new instead')
  static ReportMessageResponse create() => ReportMessageResponse._();
  static $pb.GeneratedMessage $_createMessage() => ReportMessageResponse._();
  @$core.override
  ReportMessageResponse createEmptyInstance() => ReportMessageResponse._();
  @$core.pragma('dart2js:noInline')
  static ReportMessageResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReportMessageResponse>(
          ReportMessageResponse.$_createMessage);
  static ReportMessageResponse? _defaultInstance;

  @$pb.TagNumber(1)
  MessageReport get report => $_getN(0);
  @$pb.TagNumber(1)
  set report(MessageReport value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasReport() => $_has(0);
  @$pb.TagNumber(1)
  void clearReport() => $_clearField(1);
  @$pb.TagNumber(1)
  MessageReport ensureReport() => $_ensure(0);
}

/// Asks for a channel's reports.
class ListReportsRequest extends $pb.GeneratedMessage {
  factory ListReportsRequest({
    $core.String? channelId,
  }) {
    final result = ListReportsRequest._();
    if (channelId != null) result.channelId = channelId;
    return result;
  }

  ListReportsRequest._();

  factory ListReportsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListReportsRequest()..mergeFromBuffer(data, registry);
  factory ListReportsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListReportsRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListReportsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: ListReportsRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'channelId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListReportsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListReportsRequest copyWith(void Function(ListReportsRequest) updates) =>
      super.copyWith((message) => updates(message as ListReportsRequest))
          as ListReportsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ListReportsRequest() / ListReportsRequest.new instead')
  static ListReportsRequest create() => ListReportsRequest._();
  static $pb.GeneratedMessage $_createMessage() => ListReportsRequest._();
  @$core.override
  ListReportsRequest createEmptyInstance() => ListReportsRequest._();
  @$core.pragma('dart2js:noInline')
  static ListReportsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListReportsRequest>(
          ListReportsRequest.$_createMessage);
  static ListReportsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get channelId => $_getSZ(0);
  @$pb.TagNumber(1)
  set channelId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasChannelId() => $_has(0);
  @$pb.TagNumber(1)
  void clearChannelId() => $_clearField(1);
}

/// The channel's reports.
class ListReportsResponse extends $pb.GeneratedMessage {
  factory ListReportsResponse({
    $core.Iterable<MessageReport>? reports,
  }) {
    final result = ListReportsResponse._();
    if (reports != null) result.reports.addAll(reports);
    return result;
  }

  ListReportsResponse._();

  factory ListReportsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListReportsResponse()..mergeFromBuffer(data, registry);
  factory ListReportsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListReportsResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListReportsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: ListReportsResponse.$_createMessage)
    ..pPM<MessageReport>(1, _omitFieldNames ? '' : 'reports',
        subBuilder: MessageReport.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListReportsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListReportsResponse copyWith(void Function(ListReportsResponse) updates) =>
      super.copyWith((message) => updates(message as ListReportsResponse))
          as ListReportsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use ListReportsResponse() / ListReportsResponse.new instead')
  static ListReportsResponse create() => ListReportsResponse._();
  static $pb.GeneratedMessage $_createMessage() => ListReportsResponse._();
  @$core.override
  ListReportsResponse createEmptyInstance() => ListReportsResponse._();
  @$core.pragma('dart2js:noInline')
  static ListReportsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListReportsResponse>(
          ListReportsResponse.$_createMessage);
  static ListReportsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<MessageReport> get reports => $_getList(0);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
