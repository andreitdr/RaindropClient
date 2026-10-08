// This is a generated file - do not edit.
//
// Generated from raindrop/v1/attachments.proto.

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

import 'attachments.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'attachments.pbenum.dart';

/// A list of extensions whose presence means something (absent: any extension that is not blocked).
class ExtensionList extends $pb.GeneratedMessage {
  factory ExtensionList({
    $core.Iterable<$core.String>? extensions,
  }) {
    final result = ExtensionList._();
    if (extensions != null) result.extensions.addAll(extensions);
    return result;
  }

  ExtensionList._();

  factory ExtensionList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ExtensionList()..mergeFromBuffer(data, registry);
  factory ExtensionList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ExtensionList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ExtensionList',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: ExtensionList.$_createMessage)
    ..pPS(1, _omitFieldNames ? '' : 'extensions')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExtensionList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExtensionList copyWith(void Function(ExtensionList) updates) =>
      super.copyWith((message) => updates(message as ExtensionList))
          as ExtensionList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ExtensionList() / ExtensionList.new instead')
  static ExtensionList create() => ExtensionList._();
  static $pb.GeneratedMessage $_createMessage() => ExtensionList._();
  @$core.override
  ExtensionList createEmptyInstance() => ExtensionList._();
  @$core.pragma('dart2js:noInline')
  static ExtensionList getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ExtensionList>(
          ExtensionList.$_createMessage);
  static ExtensionList? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get extensions => $_getList(0);
}

/// What this server accepts. Extensions are lower case without the dot.
class AttachmentPolicy extends $pb.GeneratedMessage {
  factory AttachmentPolicy({
    $core.bool? enabled,
    $fixnum.Int64? maximumFileBytes,
    $core.Iterable<$core.MapEntry<$core.String, $fixnum.Int64>>?
        maximumFileBytesByExtension,
    ExtensionList? allowedExtensions,
    $core.Iterable<$core.String>? blockedExtensions,
    $core.bool? allowFilesWithoutExtension,
    $core.int? maximumFilesPerMessage,
    $fixnum.Int64? maximumThumbnailBytes,
    $core.Iterable<$core.String>? previewExtensions,
    $fixnum.Int64? previewAutoLoadMaximumBytes,
    $core.int? uploadFrameBytes,
  }) {
    final result = AttachmentPolicy._();
    if (enabled != null) result.enabled = enabled;
    if (maximumFileBytes != null) result.maximumFileBytes = maximumFileBytes;
    if (maximumFileBytesByExtension != null)
      result.maximumFileBytesByExtension
          .addEntries(maximumFileBytesByExtension);
    if (allowedExtensions != null) result.allowedExtensions = allowedExtensions;
    if (blockedExtensions != null)
      result.blockedExtensions.addAll(blockedExtensions);
    if (allowFilesWithoutExtension != null)
      result.allowFilesWithoutExtension = allowFilesWithoutExtension;
    if (maximumFilesPerMessage != null)
      result.maximumFilesPerMessage = maximumFilesPerMessage;
    if (maximumThumbnailBytes != null)
      result.maximumThumbnailBytes = maximumThumbnailBytes;
    if (previewExtensions != null)
      result.previewExtensions.addAll(previewExtensions);
    if (previewAutoLoadMaximumBytes != null)
      result.previewAutoLoadMaximumBytes = previewAutoLoadMaximumBytes;
    if (uploadFrameBytes != null) result.uploadFrameBytes = uploadFrameBytes;
    return result;
  }

  AttachmentPolicy._();

  factory AttachmentPolicy.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AttachmentPolicy()..mergeFromBuffer(data, registry);
  factory AttachmentPolicy.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AttachmentPolicy()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AttachmentPolicy',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: AttachmentPolicy.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'enabled')
    ..aInt64(2, _omitFieldNames ? '' : 'maximumFileBytes')
    ..m<$core.String, $fixnum.Int64>(
        3, _omitFieldNames ? '' : 'maximumFileBytesByExtension',
        entryClassName: 'AttachmentPolicy.MaximumFileBytesByExtensionEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.O6,
        packageName: const $pb.PackageName('raindrop.v1'))
    ..aOM<ExtensionList>(4, _omitFieldNames ? '' : 'allowedExtensions',
        subBuilder: ExtensionList.$_createMessage)
    ..pPS(5, _omitFieldNames ? '' : 'blockedExtensions')
    ..aOB(6, _omitFieldNames ? '' : 'allowFilesWithoutExtension')
    ..aI(7, _omitFieldNames ? '' : 'maximumFilesPerMessage')
    ..aInt64(8, _omitFieldNames ? '' : 'maximumThumbnailBytes')
    ..pPS(9, _omitFieldNames ? '' : 'previewExtensions')
    ..aInt64(10, _omitFieldNames ? '' : 'previewAutoLoadMaximumBytes')
    ..aI(11, _omitFieldNames ? '' : 'uploadFrameBytes')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AttachmentPolicy clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AttachmentPolicy copyWith(void Function(AttachmentPolicy) updates) =>
      super.copyWith((message) => updates(message as AttachmentPolicy))
          as AttachmentPolicy;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use AttachmentPolicy() / AttachmentPolicy.new instead')
  static AttachmentPolicy create() => AttachmentPolicy._();
  static $pb.GeneratedMessage $_createMessage() => AttachmentPolicy._();
  @$core.override
  AttachmentPolicy createEmptyInstance() => AttachmentPolicy._();
  @$core.pragma('dart2js:noInline')
  static AttachmentPolicy getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AttachmentPolicy>(
          AttachmentPolicy.$_createMessage);
  static AttachmentPolicy? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get enabled => $_getBF(0);
  @$pb.TagNumber(1)
  set enabled($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEnabled() => $_has(0);
  @$pb.TagNumber(1)
  void clearEnabled() => $_clearField(1);

  /// The largest file in bytes of plaintext, unless its extension has its own limit.
  @$pb.TagNumber(2)
  $fixnum.Int64 get maximumFileBytes => $_getI64(1);
  @$pb.TagNumber(2)
  set maximumFileBytes($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMaximumFileBytes() => $_has(1);
  @$pb.TagNumber(2)
  void clearMaximumFileBytes() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbMap<$core.String, $fixnum.Int64> get maximumFileBytesByExtension =>
      $_getMap(2);

  /// The only extensions accepted; absent for any that is not blocked.
  @$pb.TagNumber(4)
  ExtensionList get allowedExtensions => $_getN(3);
  @$pb.TagNumber(4)
  set allowedExtensions(ExtensionList value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasAllowedExtensions() => $_has(3);
  @$pb.TagNumber(4)
  void clearAllowedExtensions() => $_clearField(4);
  @$pb.TagNumber(4)
  ExtensionList ensureAllowedExtensions() => $_ensure(3);

  /// Never accepted; wins over allowed_extensions.
  @$pb.TagNumber(5)
  $pb.PbList<$core.String> get blockedExtensions => $_getList(4);

  @$pb.TagNumber(6)
  $core.bool get allowFilesWithoutExtension => $_getBF(5);
  @$pb.TagNumber(6)
  set allowFilesWithoutExtension($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasAllowFilesWithoutExtension() => $_has(5);
  @$pb.TagNumber(6)
  void clearAllowFilesWithoutExtension() => $_clearField(6);

  /// Not counting thumbnails.
  @$pb.TagNumber(7)
  $core.int get maximumFilesPerMessage => $_getIZ(6);
  @$pb.TagNumber(7)
  set maximumFilesPerMessage($core.int value) => $_setSignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasMaximumFilesPerMessage() => $_has(6);
  @$pb.TagNumber(7)
  void clearMaximumFilesPerMessage() => $_clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get maximumThumbnailBytes => $_getI64(7);
  @$pb.TagNumber(8)
  set maximumThumbnailBytes($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasMaximumThumbnailBytes() => $_has(7);
  @$pb.TagNumber(8)
  void clearMaximumThumbnailBytes() => $_clearField(8);

  /// Which types clients should show inline, when they can.
  @$pb.TagNumber(9)
  $pb.PbList<$core.String> get previewExtensions => $_getList(8);

  /// The largest previewable file a client loads without being asked.
  @$pb.TagNumber(10)
  $fixnum.Int64 get previewAutoLoadMaximumBytes => $_getI64(9);
  @$pb.TagNumber(10)
  set previewAutoLoadMaximumBytes($fixnum.Int64 value) => $_setInt64(9, value);
  @$pb.TagNumber(10)
  $core.bool hasPreviewAutoLoadMaximumBytes() => $_has(9);
  @$pb.TagNumber(10)
  void clearPreviewAutoLoadMaximumBytes() => $_clearField(10);

  /// The most bytes one Upload data frame may carry.
  @$pb.TagNumber(11)
  $core.int get uploadFrameBytes => $_getIZ(10);
  @$pb.TagNumber(11)
  set uploadFrameBytes($core.int value) => $_setSignedInt32(10, value);
  @$pb.TagNumber(11)
  $core.bool hasUploadFrameBytes() => $_has(10);
  @$pb.TagNumber(11)
  void clearUploadFrameBytes() => $_clearField(11);
}

/// Where an upload stands.
class UploadStatus extends $pb.GeneratedMessage {
  factory UploadStatus({
    $core.String? attachmentId,
    UploadState? state,
    $fixnum.Int64? ciphertextSize,
    $fixnum.Int64? receivedSize,
    $core.int? frameBytes,
    $1.Timestamp? expiresAt,
  }) {
    final result = UploadStatus._();
    if (attachmentId != null) result.attachmentId = attachmentId;
    if (state != null) result.state = state;
    if (ciphertextSize != null) result.ciphertextSize = ciphertextSize;
    if (receivedSize != null) result.receivedSize = receivedSize;
    if (frameBytes != null) result.frameBytes = frameBytes;
    if (expiresAt != null) result.expiresAt = expiresAt;
    return result;
  }

  UploadStatus._();

  factory UploadStatus.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UploadStatus()..mergeFromBuffer(data, registry);
  factory UploadStatus.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UploadStatus()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UploadStatus',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: UploadStatus.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'attachmentId')
    ..aE<UploadState>(2, _omitFieldNames ? '' : 'state',
        enumValues: UploadState.values)
    ..aInt64(3, _omitFieldNames ? '' : 'ciphertextSize')
    ..aInt64(4, _omitFieldNames ? '' : 'receivedSize')
    ..aI(5, _omitFieldNames ? '' : 'frameBytes')
    ..aOM<$1.Timestamp>(6, _omitFieldNames ? '' : 'expiresAt',
        subBuilder: $1.Timestamp.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UploadStatus clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UploadStatus copyWith(void Function(UploadStatus) updates) =>
      super.copyWith((message) => updates(message as UploadStatus))
          as UploadStatus;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use UploadStatus() / UploadStatus.new instead')
  static UploadStatus create() => UploadStatus._();
  static $pb.GeneratedMessage $_createMessage() => UploadStatus._();
  @$core.override
  UploadStatus createEmptyInstance() => UploadStatus._();
  @$core.pragma('dart2js:noInline')
  static UploadStatus getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UploadStatus>(
          UploadStatus.$_createMessage);
  static UploadStatus? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get attachmentId => $_getSZ(0);
  @$pb.TagNumber(1)
  set attachmentId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAttachmentId() => $_has(0);
  @$pb.TagNumber(1)
  void clearAttachmentId() => $_clearField(1);

  @$pb.TagNumber(2)
  UploadState get state => $_getN(1);
  @$pb.TagNumber(2)
  set state(UploadState value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasState() => $_has(1);
  @$pb.TagNumber(2)
  void clearState() => $_clearField(2);

  /// How many bytes the ciphertext will be.
  @$pb.TagNumber(3)
  $fixnum.Int64 get ciphertextSize => $_getI64(2);
  @$pb.TagNumber(3)
  set ciphertextSize($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCiphertextSize() => $_has(2);
  @$pb.TagNumber(3)
  void clearCiphertextSize() => $_clearField(3);

  /// How many have arrived: where the next Upload starts.
  @$pb.TagNumber(4)
  $fixnum.Int64 get receivedSize => $_getI64(3);
  @$pb.TagNumber(4)
  set receivedSize($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasReceivedSize() => $_has(3);
  @$pb.TagNumber(4)
  void clearReceivedSize() => $_clearField(4);

  /// The most bytes one Upload data frame may carry.
  @$pb.TagNumber(5)
  $core.int get frameBytes => $_getIZ(4);
  @$pb.TagNumber(5)
  set frameBytes($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasFrameBytes() => $_has(4);
  @$pb.TagNumber(5)
  void clearFrameBytes() => $_clearField(5);

  /// When it is thrown away unless it has been sent in a message.
  @$pb.TagNumber(6)
  $1.Timestamp get expiresAt => $_getN(5);
  @$pb.TagNumber(6)
  set expiresAt($1.Timestamp value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasExpiresAt() => $_has(5);
  @$pb.TagNumber(6)
  void clearExpiresAt() => $_clearField(6);
  @$pb.TagNumber(6)
  $1.Timestamp ensureExpiresAt() => $_ensure(5);
}

/// Asks for the policy.
class GetAttachmentPolicyRequest extends $pb.GeneratedMessage {
  factory GetAttachmentPolicyRequest() => GetAttachmentPolicyRequest._();

  GetAttachmentPolicyRequest._();

  factory GetAttachmentPolicyRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetAttachmentPolicyRequest()..mergeFromBuffer(data, registry);
  factory GetAttachmentPolicyRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetAttachmentPolicyRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetAttachmentPolicyRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: GetAttachmentPolicyRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetAttachmentPolicyRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetAttachmentPolicyRequest copyWith(
          void Function(GetAttachmentPolicyRequest) updates) =>
      super.copyWith(
              (message) => updates(message as GetAttachmentPolicyRequest))
          as GetAttachmentPolicyRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetAttachmentPolicyRequest() / GetAttachmentPolicyRequest.new instead')
  static GetAttachmentPolicyRequest create() => GetAttachmentPolicyRequest._();
  static $pb.GeneratedMessage $_createMessage() =>
      GetAttachmentPolicyRequest._();
  @$core.override
  GetAttachmentPolicyRequest createEmptyInstance() =>
      GetAttachmentPolicyRequest._();
  @$core.pragma('dart2js:noInline')
  static GetAttachmentPolicyRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetAttachmentPolicyRequest>(
          GetAttachmentPolicyRequest.$_createMessage);
  static GetAttachmentPolicyRequest? _defaultInstance;
}

/// The policy.
class GetAttachmentPolicyResponse extends $pb.GeneratedMessage {
  factory GetAttachmentPolicyResponse({
    AttachmentPolicy? policy,
  }) {
    final result = GetAttachmentPolicyResponse._();
    if (policy != null) result.policy = policy;
    return result;
  }

  GetAttachmentPolicyResponse._();

  factory GetAttachmentPolicyResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetAttachmentPolicyResponse()..mergeFromBuffer(data, registry);
  factory GetAttachmentPolicyResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetAttachmentPolicyResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetAttachmentPolicyResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: GetAttachmentPolicyResponse.$_createMessage)
    ..aOM<AttachmentPolicy>(1, _omitFieldNames ? '' : 'policy',
        subBuilder: AttachmentPolicy.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetAttachmentPolicyResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetAttachmentPolicyResponse copyWith(
          void Function(GetAttachmentPolicyResponse) updates) =>
      super.copyWith(
              (message) => updates(message as GetAttachmentPolicyResponse))
          as GetAttachmentPolicyResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetAttachmentPolicyResponse() / GetAttachmentPolicyResponse.new instead')
  static GetAttachmentPolicyResponse create() =>
      GetAttachmentPolicyResponse._();
  static $pb.GeneratedMessage $_createMessage() =>
      GetAttachmentPolicyResponse._();
  @$core.override
  GetAttachmentPolicyResponse createEmptyInstance() =>
      GetAttachmentPolicyResponse._();
  @$core.pragma('dart2js:noInline')
  static GetAttachmentPolicyResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetAttachmentPolicyResponse>(
          GetAttachmentPolicyResponse.$_createMessage);
  static GetAttachmentPolicyResponse? _defaultInstance;

  @$pb.TagNumber(1)
  AttachmentPolicy get policy => $_getN(0);
  @$pb.TagNumber(1)
  set policy(AttachmentPolicy value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPolicy() => $_has(0);
  @$pb.TagNumber(1)
  void clearPolicy() => $_clearField(1);
  @$pb.TagNumber(1)
  AttachmentPolicy ensurePolicy() => $_ensure(0);
}

/// Starts an upload.
class CreateUploadRequest extends $pb.GeneratedMessage {
  factory CreateUploadRequest({
    $core.String? channelId,
    $core.String? extension_2,
    $fixnum.Int64? ciphertextSize,
    AttachmentKind? kind,
  }) {
    final result = CreateUploadRequest._();
    if (channelId != null) result.channelId = channelId;
    if (extension_2 != null) result.extension_2 = extension_2;
    if (ciphertextSize != null) result.ciphertextSize = ciphertextSize;
    if (kind != null) result.kind = kind;
    return result;
  }

  CreateUploadRequest._();

  factory CreateUploadRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreateUploadRequest()..mergeFromBuffer(data, registry);
  factory CreateUploadRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreateUploadRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateUploadRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: CreateUploadRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'channelId')
    ..aOS(2, _omitFieldNames ? '' : 'extension')
    ..aInt64(3, _omitFieldNames ? '' : 'ciphertextSize')
    ..aE<AttachmentKind>(4, _omitFieldNames ? '' : 'kind',
        enumValues: AttachmentKind.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateUploadRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateUploadRequest copyWith(void Function(CreateUploadRequest) updates) =>
      super.copyWith((message) => updates(message as CreateUploadRequest))
          as CreateUploadRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use CreateUploadRequest() / CreateUploadRequest.new instead')
  static CreateUploadRequest create() => CreateUploadRequest._();
  static $pb.GeneratedMessage $_createMessage() => CreateUploadRequest._();
  @$core.override
  CreateUploadRequest createEmptyInstance() => CreateUploadRequest._();
  @$core.pragma('dart2js:noInline')
  static CreateUploadRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateUploadRequest>(
          CreateUploadRequest.$_createMessage);
  static CreateUploadRequest? _defaultInstance;

  /// The text channel it will be sent in; it cannot be sent anywhere else.
  @$pb.TagNumber(1)
  $core.String get channelId => $_getSZ(0);
  @$pb.TagNumber(1)
  set channelId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasChannelId() => $_has(0);
  @$pb.TagNumber(1)
  void clearChannelId() => $_clearField(1);

  /// The file's extension without the dot; empty for none. Lower-cased by the server.
  @$pb.TagNumber(2)
  $core.String get extension_2 => $_getSZ(1);
  @$pb.TagNumber(2)
  set extension_2($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasExtension_2() => $_has(1);
  @$pb.TagNumber(2)
  void clearExtension_2() => $_clearField(2);

  /// The ciphertext's length, which fixes the plaintext length exactly.
  @$pb.TagNumber(3)
  $fixnum.Int64 get ciphertextSize => $_getI64(2);
  @$pb.TagNumber(3)
  set ciphertextSize($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCiphertextSize() => $_has(2);
  @$pb.TagNumber(3)
  void clearCiphertextSize() => $_clearField(3);

  /// Unspecified means file.
  @$pb.TagNumber(4)
  AttachmentKind get kind => $_getN(3);
  @$pb.TagNumber(4)
  set kind(AttachmentKind value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasKind() => $_has(3);
  @$pb.TagNumber(4)
  void clearKind() => $_clearField(4);
}

/// The new upload.
class CreateUploadResponse extends $pb.GeneratedMessage {
  factory CreateUploadResponse({
    UploadStatus? status,
  }) {
    final result = CreateUploadResponse._();
    if (status != null) result.status = status;
    return result;
  }

  CreateUploadResponse._();

  factory CreateUploadResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreateUploadResponse()..mergeFromBuffer(data, registry);
  factory CreateUploadResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreateUploadResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateUploadResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: CreateUploadResponse.$_createMessage)
    ..aOM<UploadStatus>(1, _omitFieldNames ? '' : 'status',
        subBuilder: UploadStatus.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateUploadResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateUploadResponse copyWith(void Function(CreateUploadResponse) updates) =>
      super.copyWith((message) => updates(message as CreateUploadResponse))
          as CreateUploadResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use CreateUploadResponse() / CreateUploadResponse.new instead')
  static CreateUploadResponse create() => CreateUploadResponse._();
  static $pb.GeneratedMessage $_createMessage() => CreateUploadResponse._();
  @$core.override
  CreateUploadResponse createEmptyInstance() => CreateUploadResponse._();
  @$core.pragma('dart2js:noInline')
  static CreateUploadResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateUploadResponse>(
          CreateUploadResponse.$_createMessage);
  static CreateUploadResponse? _defaultInstance;

  @$pb.TagNumber(1)
  UploadStatus get status => $_getN(0);
  @$pb.TagNumber(1)
  set status(UploadStatus value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasStatus() => $_has(0);
  @$pb.TagNumber(1)
  void clearStatus() => $_clearField(1);
  @$pb.TagNumber(1)
  UploadStatus ensureStatus() => $_ensure(0);
}

/// Which upload a stream writes to, and from where.
class UploadHeader extends $pb.GeneratedMessage {
  factory UploadHeader({
    $core.String? attachmentId,
    $fixnum.Int64? offset,
  }) {
    final result = UploadHeader._();
    if (attachmentId != null) result.attachmentId = attachmentId;
    if (offset != null) result.offset = offset;
    return result;
  }

  UploadHeader._();

  factory UploadHeader.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UploadHeader()..mergeFromBuffer(data, registry);
  factory UploadHeader.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UploadHeader()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UploadHeader',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: UploadHeader.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'attachmentId')
    ..aInt64(2, _omitFieldNames ? '' : 'offset')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UploadHeader clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UploadHeader copyWith(void Function(UploadHeader) updates) =>
      super.copyWith((message) => updates(message as UploadHeader))
          as UploadHeader;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use UploadHeader() / UploadHeader.new instead')
  static UploadHeader create() => UploadHeader._();
  static $pb.GeneratedMessage $_createMessage() => UploadHeader._();
  @$core.override
  UploadHeader createEmptyInstance() => UploadHeader._();
  @$core.pragma('dart2js:noInline')
  static UploadHeader getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UploadHeader>(
          UploadHeader.$_createMessage);
  static UploadHeader? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get attachmentId => $_getSZ(0);
  @$pb.TagNumber(1)
  set attachmentId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAttachmentId() => $_has(0);
  @$pb.TagNumber(1)
  void clearAttachmentId() => $_clearField(1);

  /// Must equal the upload's received_size.
  @$pb.TagNumber(2)
  $fixnum.Int64 get offset => $_getI64(1);
  @$pb.TagNumber(2)
  set offset($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOffset() => $_has(1);
  @$pb.TagNumber(2)
  void clearOffset() => $_clearField(2);
}

enum UploadRequest_Frame { header, data, notSet }

/// One frame of an upload stream: the header first, then data.
class UploadRequest extends $pb.GeneratedMessage {
  factory UploadRequest({
    UploadHeader? header,
    $core.List<$core.int>? data,
  }) {
    final result = UploadRequest._();
    if (header != null) result.header = header;
    if (data != null) result.data = data;
    return result;
  }

  UploadRequest._();

  factory UploadRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UploadRequest()..mergeFromBuffer(data, registry);
  factory UploadRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UploadRequest()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, UploadRequest_Frame>
      _UploadRequest_FrameByTag = {
    1: UploadRequest_Frame.header,
    2: UploadRequest_Frame.data,
    0: UploadRequest_Frame.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UploadRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: UploadRequest.$_createMessage)
    ..oo(0, [1, 2])
    ..aOM<UploadHeader>(1, _omitFieldNames ? '' : 'header',
        subBuilder: UploadHeader.$_createMessage)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'data', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UploadRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UploadRequest copyWith(void Function(UploadRequest) updates) =>
      super.copyWith((message) => updates(message as UploadRequest))
          as UploadRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use UploadRequest() / UploadRequest.new instead')
  static UploadRequest create() => UploadRequest._();
  static $pb.GeneratedMessage $_createMessage() => UploadRequest._();
  @$core.override
  UploadRequest createEmptyInstance() => UploadRequest._();
  @$core.pragma('dart2js:noInline')
  static UploadRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UploadRequest>(
          UploadRequest.$_createMessage);
  static UploadRequest? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  UploadRequest_Frame whichFrame() =>
      _UploadRequest_FrameByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearFrame() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  UploadHeader get header => $_getN(0);
  @$pb.TagNumber(1)
  set header(UploadHeader value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasHeader() => $_has(0);
  @$pb.TagNumber(1)
  void clearHeader() => $_clearField(1);
  @$pb.TagNumber(1)
  UploadHeader ensureHeader() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.List<$core.int> get data => $_getN(1);
  @$pb.TagNumber(2)
  set data($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasData() => $_has(1);
  @$pb.TagNumber(2)
  void clearData() => $_clearField(2);
}

/// Where the upload stands once the stream ends.
class UploadResponse extends $pb.GeneratedMessage {
  factory UploadResponse({
    UploadStatus? status,
  }) {
    final result = UploadResponse._();
    if (status != null) result.status = status;
    return result;
  }

  UploadResponse._();

  factory UploadResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UploadResponse()..mergeFromBuffer(data, registry);
  factory UploadResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UploadResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UploadResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: UploadResponse.$_createMessage)
    ..aOM<UploadStatus>(1, _omitFieldNames ? '' : 'status',
        subBuilder: UploadStatus.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UploadResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UploadResponse copyWith(void Function(UploadResponse) updates) =>
      super.copyWith((message) => updates(message as UploadResponse))
          as UploadResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use UploadResponse() / UploadResponse.new instead')
  static UploadResponse create() => UploadResponse._();
  static $pb.GeneratedMessage $_createMessage() => UploadResponse._();
  @$core.override
  UploadResponse createEmptyInstance() => UploadResponse._();
  @$core.pragma('dart2js:noInline')
  static UploadResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UploadResponse>(
          UploadResponse.$_createMessage);
  static UploadResponse? _defaultInstance;

  @$pb.TagNumber(1)
  UploadStatus get status => $_getN(0);
  @$pb.TagNumber(1)
  set status(UploadStatus value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasStatus() => $_has(0);
  @$pb.TagNumber(1)
  void clearStatus() => $_clearField(1);
  @$pb.TagNumber(1)
  UploadStatus ensureStatus() => $_ensure(0);
}

/// Asks where an upload stands.
class GetUploadStatusRequest extends $pb.GeneratedMessage {
  factory GetUploadStatusRequest({
    $core.String? attachmentId,
  }) {
    final result = GetUploadStatusRequest._();
    if (attachmentId != null) result.attachmentId = attachmentId;
    return result;
  }

  GetUploadStatusRequest._();

  factory GetUploadStatusRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetUploadStatusRequest()..mergeFromBuffer(data, registry);
  factory GetUploadStatusRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetUploadStatusRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetUploadStatusRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: GetUploadStatusRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'attachmentId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetUploadStatusRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetUploadStatusRequest copyWith(
          void Function(GetUploadStatusRequest) updates) =>
      super.copyWith((message) => updates(message as GetUploadStatusRequest))
          as GetUploadStatusRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetUploadStatusRequest() / GetUploadStatusRequest.new instead')
  static GetUploadStatusRequest create() => GetUploadStatusRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetUploadStatusRequest._();
  @$core.override
  GetUploadStatusRequest createEmptyInstance() => GetUploadStatusRequest._();
  @$core.pragma('dart2js:noInline')
  static GetUploadStatusRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetUploadStatusRequest>(
          GetUploadStatusRequest.$_createMessage);
  static GetUploadStatusRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get attachmentId => $_getSZ(0);
  @$pb.TagNumber(1)
  set attachmentId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAttachmentId() => $_has(0);
  @$pb.TagNumber(1)
  void clearAttachmentId() => $_clearField(1);
}

/// Where it stands.
class GetUploadStatusResponse extends $pb.GeneratedMessage {
  factory GetUploadStatusResponse({
    UploadStatus? status,
  }) {
    final result = GetUploadStatusResponse._();
    if (status != null) result.status = status;
    return result;
  }

  GetUploadStatusResponse._();

  factory GetUploadStatusResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetUploadStatusResponse()..mergeFromBuffer(data, registry);
  factory GetUploadStatusResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetUploadStatusResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetUploadStatusResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: GetUploadStatusResponse.$_createMessage)
    ..aOM<UploadStatus>(1, _omitFieldNames ? '' : 'status',
        subBuilder: UploadStatus.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetUploadStatusResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetUploadStatusResponse copyWith(
          void Function(GetUploadStatusResponse) updates) =>
      super.copyWith((message) => updates(message as GetUploadStatusResponse))
          as GetUploadStatusResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetUploadStatusResponse() / GetUploadStatusResponse.new instead')
  static GetUploadStatusResponse create() => GetUploadStatusResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetUploadStatusResponse._();
  @$core.override
  GetUploadStatusResponse createEmptyInstance() => GetUploadStatusResponse._();
  @$core.pragma('dart2js:noInline')
  static GetUploadStatusResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetUploadStatusResponse>(
          GetUploadStatusResponse.$_createMessage);
  static GetUploadStatusResponse? _defaultInstance;

  @$pb.TagNumber(1)
  UploadStatus get status => $_getN(0);
  @$pb.TagNumber(1)
  set status(UploadStatus value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasStatus() => $_has(0);
  @$pb.TagNumber(1)
  void clearStatus() => $_clearField(1);
  @$pb.TagNumber(1)
  UploadStatus ensureStatus() => $_ensure(0);
}

/// Finishes an upload.
class CompleteUploadRequest extends $pb.GeneratedMessage {
  factory CompleteUploadRequest({
    $core.String? attachmentId,
    $core.List<$core.int>? ciphertextSha256,
  }) {
    final result = CompleteUploadRequest._();
    if (attachmentId != null) result.attachmentId = attachmentId;
    if (ciphertextSha256 != null) result.ciphertextSha256 = ciphertextSha256;
    return result;
  }

  CompleteUploadRequest._();

  factory CompleteUploadRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CompleteUploadRequest()..mergeFromBuffer(data, registry);
  factory CompleteUploadRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CompleteUploadRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CompleteUploadRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: CompleteUploadRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'attachmentId')
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'ciphertextSha256', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CompleteUploadRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CompleteUploadRequest copyWith(
          void Function(CompleteUploadRequest) updates) =>
      super.copyWith((message) => updates(message as CompleteUploadRequest))
          as CompleteUploadRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use CompleteUploadRequest() / CompleteUploadRequest.new instead')
  static CompleteUploadRequest create() => CompleteUploadRequest._();
  static $pb.GeneratedMessage $_createMessage() => CompleteUploadRequest._();
  @$core.override
  CompleteUploadRequest createEmptyInstance() => CompleteUploadRequest._();
  @$core.pragma('dart2js:noInline')
  static CompleteUploadRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CompleteUploadRequest>(
          CompleteUploadRequest.$_createMessage);
  static CompleteUploadRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get attachmentId => $_getSZ(0);
  @$pb.TagNumber(1)
  set attachmentId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAttachmentId() => $_has(0);
  @$pb.TagNumber(1)
  void clearAttachmentId() => $_clearField(1);

  /// SHA-256 of the whole ciphertext, which the stored bytes must match.
  @$pb.TagNumber(2)
  $core.List<$core.int> get ciphertextSha256 => $_getN(1);
  @$pb.TagNumber(2)
  set ciphertextSha256($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCiphertextSha256() => $_has(1);
  @$pb.TagNumber(2)
  void clearCiphertextSha256() => $_clearField(2);
}

/// The finished upload.
class CompleteUploadResponse extends $pb.GeneratedMessage {
  factory CompleteUploadResponse({
    UploadStatus? status,
  }) {
    final result = CompleteUploadResponse._();
    if (status != null) result.status = status;
    return result;
  }

  CompleteUploadResponse._();

  factory CompleteUploadResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CompleteUploadResponse()..mergeFromBuffer(data, registry);
  factory CompleteUploadResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CompleteUploadResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CompleteUploadResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: CompleteUploadResponse.$_createMessage)
    ..aOM<UploadStatus>(1, _omitFieldNames ? '' : 'status',
        subBuilder: UploadStatus.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CompleteUploadResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CompleteUploadResponse copyWith(
          void Function(CompleteUploadResponse) updates) =>
      super.copyWith((message) => updates(message as CompleteUploadResponse))
          as CompleteUploadResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use CompleteUploadResponse() / CompleteUploadResponse.new instead')
  static CompleteUploadResponse create() => CompleteUploadResponse._();
  static $pb.GeneratedMessage $_createMessage() => CompleteUploadResponse._();
  @$core.override
  CompleteUploadResponse createEmptyInstance() => CompleteUploadResponse._();
  @$core.pragma('dart2js:noInline')
  static CompleteUploadResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CompleteUploadResponse>(
          CompleteUploadResponse.$_createMessage);
  static CompleteUploadResponse? _defaultInstance;

  @$pb.TagNumber(1)
  UploadStatus get status => $_getN(0);
  @$pb.TagNumber(1)
  set status(UploadStatus value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasStatus() => $_has(0);
  @$pb.TagNumber(1)
  void clearStatus() => $_clearField(1);
  @$pb.TagNumber(1)
  UploadStatus ensureStatus() => $_ensure(0);
}

/// Throws an upload away.
class CancelUploadRequest extends $pb.GeneratedMessage {
  factory CancelUploadRequest({
    $core.String? attachmentId,
  }) {
    final result = CancelUploadRequest._();
    if (attachmentId != null) result.attachmentId = attachmentId;
    return result;
  }

  CancelUploadRequest._();

  factory CancelUploadRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CancelUploadRequest()..mergeFromBuffer(data, registry);
  factory CancelUploadRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CancelUploadRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CancelUploadRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: CancelUploadRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'attachmentId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CancelUploadRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CancelUploadRequest copyWith(void Function(CancelUploadRequest) updates) =>
      super.copyWith((message) => updates(message as CancelUploadRequest))
          as CancelUploadRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use CancelUploadRequest() / CancelUploadRequest.new instead')
  static CancelUploadRequest create() => CancelUploadRequest._();
  static $pb.GeneratedMessage $_createMessage() => CancelUploadRequest._();
  @$core.override
  CancelUploadRequest createEmptyInstance() => CancelUploadRequest._();
  @$core.pragma('dart2js:noInline')
  static CancelUploadRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CancelUploadRequest>(
          CancelUploadRequest.$_createMessage);
  static CancelUploadRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get attachmentId => $_getSZ(0);
  @$pb.TagNumber(1)
  set attachmentId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAttachmentId() => $_has(0);
  @$pb.TagNumber(1)
  void clearAttachmentId() => $_clearField(1);
}

/// The upload that was thrown away.
class CancelUploadResponse extends $pb.GeneratedMessage {
  factory CancelUploadResponse({
    $core.String? attachmentId,
  }) {
    final result = CancelUploadResponse._();
    if (attachmentId != null) result.attachmentId = attachmentId;
    return result;
  }

  CancelUploadResponse._();

  factory CancelUploadResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CancelUploadResponse()..mergeFromBuffer(data, registry);
  factory CancelUploadResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CancelUploadResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CancelUploadResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: CancelUploadResponse.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'attachmentId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CancelUploadResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CancelUploadResponse copyWith(void Function(CancelUploadResponse) updates) =>
      super.copyWith((message) => updates(message as CancelUploadResponse))
          as CancelUploadResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use CancelUploadResponse() / CancelUploadResponse.new instead')
  static CancelUploadResponse create() => CancelUploadResponse._();
  static $pb.GeneratedMessage $_createMessage() => CancelUploadResponse._();
  @$core.override
  CancelUploadResponse createEmptyInstance() => CancelUploadResponse._();
  @$core.pragma('dart2js:noInline')
  static CancelUploadResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CancelUploadResponse>(
          CancelUploadResponse.$_createMessage);
  static CancelUploadResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get attachmentId => $_getSZ(0);
  @$pb.TagNumber(1)
  set attachmentId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAttachmentId() => $_has(0);
  @$pb.TagNumber(1)
  void clearAttachmentId() => $_clearField(1);
}

/// Downloads a file.
class DownloadRequest extends $pb.GeneratedMessage {
  factory DownloadRequest({
    $core.String? attachmentId,
    $fixnum.Int64? offset,
  }) {
    final result = DownloadRequest._();
    if (attachmentId != null) result.attachmentId = attachmentId;
    if (offset != null) result.offset = offset;
    return result;
  }

  DownloadRequest._();

  factory DownloadRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DownloadRequest()..mergeFromBuffer(data, registry);
  factory DownloadRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DownloadRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DownloadRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: DownloadRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'attachmentId')
    ..aInt64(2, _omitFieldNames ? '' : 'offset')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DownloadRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DownloadRequest copyWith(void Function(DownloadRequest) updates) =>
      super.copyWith((message) => updates(message as DownloadRequest))
          as DownloadRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use DownloadRequest() / DownloadRequest.new instead')
  static DownloadRequest create() => DownloadRequest._();
  static $pb.GeneratedMessage $_createMessage() => DownloadRequest._();
  @$core.override
  DownloadRequest createEmptyInstance() => DownloadRequest._();
  @$core.pragma('dart2js:noInline')
  static DownloadRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DownloadRequest>(
          DownloadRequest.$_createMessage);
  static DownloadRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get attachmentId => $_getSZ(0);
  @$pb.TagNumber(1)
  set attachmentId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAttachmentId() => $_has(0);
  @$pb.TagNumber(1)
  void clearAttachmentId() => $_clearField(1);

  /// Where to start: the size of what a client already has, to resume.
  @$pb.TagNumber(2)
  $fixnum.Int64 get offset => $_getI64(1);
  @$pb.TagNumber(2)
  set offset($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOffset() => $_has(1);
  @$pb.TagNumber(2)
  void clearOffset() => $_clearField(2);
}

/// What a download stream carries before its data.
class DownloadHeader extends $pb.GeneratedMessage {
  factory DownloadHeader({
    $fixnum.Int64? ciphertextSize,
    $fixnum.Int64? offset,
  }) {
    final result = DownloadHeader._();
    if (ciphertextSize != null) result.ciphertextSize = ciphertextSize;
    if (offset != null) result.offset = offset;
    return result;
  }

  DownloadHeader._();

  factory DownloadHeader.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DownloadHeader()..mergeFromBuffer(data, registry);
  factory DownloadHeader.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DownloadHeader()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DownloadHeader',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: DownloadHeader.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'ciphertextSize')
    ..aInt64(2, _omitFieldNames ? '' : 'offset')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DownloadHeader clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DownloadHeader copyWith(void Function(DownloadHeader) updates) =>
      super.copyWith((message) => updates(message as DownloadHeader))
          as DownloadHeader;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use DownloadHeader() / DownloadHeader.new instead')
  static DownloadHeader create() => DownloadHeader._();
  static $pb.GeneratedMessage $_createMessage() => DownloadHeader._();
  @$core.override
  DownloadHeader createEmptyInstance() => DownloadHeader._();
  @$core.pragma('dart2js:noInline')
  static DownloadHeader getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DownloadHeader>(
          DownloadHeader.$_createMessage);
  static DownloadHeader? _defaultInstance;

  /// The whole ciphertext's length.
  @$pb.TagNumber(1)
  $fixnum.Int64 get ciphertextSize => $_getI64(0);
  @$pb.TagNumber(1)
  set ciphertextSize($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCiphertextSize() => $_has(0);
  @$pb.TagNumber(1)
  void clearCiphertextSize() => $_clearField(1);

  /// Where the data frames start (the requested offset).
  @$pb.TagNumber(2)
  $fixnum.Int64 get offset => $_getI64(1);
  @$pb.TagNumber(2)
  set offset($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOffset() => $_has(1);
  @$pb.TagNumber(2)
  void clearOffset() => $_clearField(2);
}

enum DownloadResponse_Frame { header, data, notSet }

/// One frame of a download stream: the header first, then data.
class DownloadResponse extends $pb.GeneratedMessage {
  factory DownloadResponse({
    DownloadHeader? header,
    $core.List<$core.int>? data,
  }) {
    final result = DownloadResponse._();
    if (header != null) result.header = header;
    if (data != null) result.data = data;
    return result;
  }

  DownloadResponse._();

  factory DownloadResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DownloadResponse()..mergeFromBuffer(data, registry);
  factory DownloadResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DownloadResponse()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, DownloadResponse_Frame>
      _DownloadResponse_FrameByTag = {
    1: DownloadResponse_Frame.header,
    2: DownloadResponse_Frame.data,
    0: DownloadResponse_Frame.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DownloadResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: DownloadResponse.$_createMessage)
    ..oo(0, [1, 2])
    ..aOM<DownloadHeader>(1, _omitFieldNames ? '' : 'header',
        subBuilder: DownloadHeader.$_createMessage)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'data', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DownloadResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DownloadResponse copyWith(void Function(DownloadResponse) updates) =>
      super.copyWith((message) => updates(message as DownloadResponse))
          as DownloadResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use DownloadResponse() / DownloadResponse.new instead')
  static DownloadResponse create() => DownloadResponse._();
  static $pb.GeneratedMessage $_createMessage() => DownloadResponse._();
  @$core.override
  DownloadResponse createEmptyInstance() => DownloadResponse._();
  @$core.pragma('dart2js:noInline')
  static DownloadResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DownloadResponse>(
          DownloadResponse.$_createMessage);
  static DownloadResponse? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  DownloadResponse_Frame whichFrame() =>
      _DownloadResponse_FrameByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearFrame() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  DownloadHeader get header => $_getN(0);
  @$pb.TagNumber(1)
  set header(DownloadHeader value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasHeader() => $_has(0);
  @$pb.TagNumber(1)
  void clearHeader() => $_clearField(1);
  @$pb.TagNumber(1)
  DownloadHeader ensureHeader() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.List<$core.int> get data => $_getN(1);
  @$pb.TagNumber(2)
  set data($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasData() => $_has(1);
  @$pb.TagNumber(2)
  void clearData() => $_clearField(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
