// This is a generated file - do not edit.
//
// Generated from raindrop/v1/voice.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart'
    as $1;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// One member in one call, the whole state: merge on (channel_id, user_id).
class VoiceParticipant extends $pb.GeneratedMessage {
  factory VoiceParticipant({
    $core.String? channelId,
    $core.String? userId,
    $core.bool? selfMute,
    $core.bool? selfDeaf,
    $core.bool? serverMute,
    $core.bool? suppressed,
    $core.bool? connected,
    $1.Timestamp? joinedAt,
  }) {
    final result = VoiceParticipant._();
    if (channelId != null) result.channelId = channelId;
    if (userId != null) result.userId = userId;
    if (selfMute != null) result.selfMute = selfMute;
    if (selfDeaf != null) result.selfDeaf = selfDeaf;
    if (serverMute != null) result.serverMute = serverMute;
    if (suppressed != null) result.suppressed = suppressed;
    if (connected != null) result.connected = connected;
    if (joinedAt != null) result.joinedAt = joinedAt;
    return result;
  }

  VoiceParticipant._();

  factory VoiceParticipant.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      VoiceParticipant()..mergeFromBuffer(data, registry);
  factory VoiceParticipant.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      VoiceParticipant()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'VoiceParticipant',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: VoiceParticipant.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'channelId')
    ..aOS(2, _omitFieldNames ? '' : 'userId')
    ..aOB(3, _omitFieldNames ? '' : 'selfMute')
    ..aOB(4, _omitFieldNames ? '' : 'selfDeaf')
    ..aOB(5, _omitFieldNames ? '' : 'serverMute')
    ..aOB(6, _omitFieldNames ? '' : 'suppressed')
    ..aOB(7, _omitFieldNames ? '' : 'connected')
    ..aOM<$1.Timestamp>(8, _omitFieldNames ? '' : 'joinedAt',
        subBuilder: $1.Timestamp.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VoiceParticipant clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VoiceParticipant copyWith(void Function(VoiceParticipant) updates) =>
      super.copyWith((message) => updates(message as VoiceParticipant))
          as VoiceParticipant;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use VoiceParticipant() / VoiceParticipant.new instead')
  static VoiceParticipant create() => VoiceParticipant._();
  static $pb.GeneratedMessage $_createMessage() => VoiceParticipant._();
  @$core.override
  VoiceParticipant createEmptyInstance() => VoiceParticipant._();
  @$core.pragma('dart2js:noInline')
  static VoiceParticipant getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<VoiceParticipant>(
          VoiceParticipant.$_createMessage);
  static VoiceParticipant? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get channelId => $_getSZ(0);
  @$pb.TagNumber(1)
  set channelId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasChannelId() => $_has(0);
  @$pb.TagNumber(1)
  void clearChannelId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get userId => $_getSZ(1);
  @$pb.TagNumber(2)
  set userId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUserId() => $_has(1);
  @$pb.TagNumber(2)
  void clearUserId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get selfMute => $_getBF(2);
  @$pb.TagNumber(3)
  set selfMute($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSelfMute() => $_has(2);
  @$pb.TagNumber(3)
  void clearSelfMute() => $_clearField(3);

  /// Implies self_mute.
  @$pb.TagNumber(4)
  $core.bool get selfDeaf => $_getBF(3);
  @$pb.TagNumber(4)
  set selfDeaf($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSelfDeaf() => $_has(3);
  @$pb.TagNumber(4)
  void clearSelfDeaf() => $_clearField(4);

  /// A moderator muted them for everyone.
  @$pb.TagNumber(5)
  $core.bool get serverMute => $_getBF(4);
  @$pb.TagNumber(5)
  set serverMute($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasServerMute() => $_has(4);
  @$pb.TagNumber(5)
  void clearServerMute() => $_clearField(5);

  /// They may listen but not talk: they lack speak.
  @$pb.TagNumber(6)
  $core.bool get suppressed => $_getBF(5);
  @$pb.TagNumber(6)
  set suppressed($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasSuppressed() => $_has(5);
  @$pb.TagNumber(6)
  void clearSuppressed() => $_clearField(6);

  /// The media server has seen them connect.
  @$pb.TagNumber(7)
  $core.bool get connected => $_getBF(6);
  @$pb.TagNumber(7)
  set connected($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasConnected() => $_has(6);
  @$pb.TagNumber(7)
  void clearConnected() => $_clearField(7);

  @$pb.TagNumber(8)
  $1.Timestamp get joinedAt => $_getN(7);
  @$pb.TagNumber(8)
  set joinedAt($1.Timestamp value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasJoinedAt() => $_has(7);
  @$pb.TagNumber(8)
  void clearJoinedAt() => $_clearField(8);
  @$pb.TagNumber(8)
  $1.Timestamp ensureJoinedAt() => $_ensure(7);
}

/// Asks for voice status.
class GetVoiceStatusRequest extends $pb.GeneratedMessage {
  factory GetVoiceStatusRequest() => GetVoiceStatusRequest._();

  GetVoiceStatusRequest._();

  factory GetVoiceStatusRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetVoiceStatusRequest()..mergeFromBuffer(data, registry);
  factory GetVoiceStatusRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetVoiceStatusRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetVoiceStatusRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: GetVoiceStatusRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetVoiceStatusRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetVoiceStatusRequest copyWith(
          void Function(GetVoiceStatusRequest) updates) =>
      super.copyWith((message) => updates(message as GetVoiceStatusRequest))
          as GetVoiceStatusRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetVoiceStatusRequest() / GetVoiceStatusRequest.new instead')
  static GetVoiceStatusRequest create() => GetVoiceStatusRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetVoiceStatusRequest._();
  @$core.override
  GetVoiceStatusRequest createEmptyInstance() => GetVoiceStatusRequest._();
  @$core.pragma('dart2js:noInline')
  static GetVoiceStatusRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetVoiceStatusRequest>(
          GetVoiceStatusRequest.$_createMessage);
  static GetVoiceStatusRequest? _defaultInstance;
}

/// Whether voice works, and every visible call.
class GetVoiceStatusResponse extends $pb.GeneratedMessage {
  factory GetVoiceStatusResponse({
    $core.bool? available,
    $core.String? transport,
    $core.int? maximumParticipants,
    $core.Iterable<VoiceParticipant>? participants,
  }) {
    final result = GetVoiceStatusResponse._();
    if (available != null) result.available = available;
    if (transport != null) result.transport = transport;
    if (maximumParticipants != null)
      result.maximumParticipants = maximumParticipants;
    if (participants != null) result.participants.addAll(participants);
    return result;
  }

  GetVoiceStatusResponse._();

  factory GetVoiceStatusResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetVoiceStatusResponse()..mergeFromBuffer(data, registry);
  factory GetVoiceStatusResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetVoiceStatusResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetVoiceStatusResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: GetVoiceStatusResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'available')
    ..aOS(2, _omitFieldNames ? '' : 'transport')
    ..aI(3, _omitFieldNames ? '' : 'maximumParticipants')
    ..pPM<VoiceParticipant>(4, _omitFieldNames ? '' : 'participants',
        subBuilder: VoiceParticipant.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetVoiceStatusResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetVoiceStatusResponse copyWith(
          void Function(GetVoiceStatusResponse) updates) =>
      super.copyWith((message) => updates(message as GetVoiceStatusResponse))
          as GetVoiceStatusResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetVoiceStatusResponse() / GetVoiceStatusResponse.new instead')
  static GetVoiceStatusResponse create() => GetVoiceStatusResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetVoiceStatusResponse._();
  @$core.override
  GetVoiceStatusResponse createEmptyInstance() => GetVoiceStatusResponse._();
  @$core.pragma('dart2js:noInline')
  static GetVoiceStatusResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetVoiceStatusResponse>(
          GetVoiceStatusResponse.$_createMessage);
  static GetVoiceStatusResponse? _defaultInstance;

  /// False when the server has no media server; joining is refused with voice_unavailable.
  @$pb.TagNumber(1)
  $core.bool get available => $_getBF(0);
  @$pb.TagNumber(1)
  set available($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAvailable() => $_has(0);
  @$pb.TagNumber(1)
  void clearAvailable() => $_clearField(1);

  /// e.g. "livekit"; "none" when unavailable.
  @$pb.TagNumber(2)
  $core.String get transport => $_getSZ(1);
  @$pb.TagNumber(2)
  set transport($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTransport() => $_has(1);
  @$pb.TagNumber(2)
  void clearTransport() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get maximumParticipants => $_getIZ(2);
  @$pb.TagNumber(3)
  set maximumParticipants($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMaximumParticipants() => $_has(2);
  @$pb.TagNumber(3)
  void clearMaximumParticipants() => $_clearField(3);

  /// By channel, then join time.
  @$pb.TagNumber(4)
  $pb.PbList<VoiceParticipant> get participants => $_getList(3);
}

/// Joins a call.
class JoinVoiceRequest extends $pb.GeneratedMessage {
  factory JoinVoiceRequest({
    $core.String? channelId,
    $core.bool? selfMute,
    $core.bool? selfDeaf,
  }) {
    final result = JoinVoiceRequest._();
    if (channelId != null) result.channelId = channelId;
    if (selfMute != null) result.selfMute = selfMute;
    if (selfDeaf != null) result.selfDeaf = selfDeaf;
    return result;
  }

  JoinVoiceRequest._();

  factory JoinVoiceRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      JoinVoiceRequest()..mergeFromBuffer(data, registry);
  factory JoinVoiceRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      JoinVoiceRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'JoinVoiceRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: JoinVoiceRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'channelId')
    ..aOB(2, _omitFieldNames ? '' : 'selfMute')
    ..aOB(3, _omitFieldNames ? '' : 'selfDeaf')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  JoinVoiceRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  JoinVoiceRequest copyWith(void Function(JoinVoiceRequest) updates) =>
      super.copyWith((message) => updates(message as JoinVoiceRequest))
          as JoinVoiceRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use JoinVoiceRequest() / JoinVoiceRequest.new instead')
  static JoinVoiceRequest create() => JoinVoiceRequest._();
  static $pb.GeneratedMessage $_createMessage() => JoinVoiceRequest._();
  @$core.override
  JoinVoiceRequest createEmptyInstance() => JoinVoiceRequest._();
  @$core.pragma('dart2js:noInline')
  static JoinVoiceRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<JoinVoiceRequest>(
          JoinVoiceRequest.$_createMessage);
  static JoinVoiceRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get channelId => $_getSZ(0);
  @$pb.TagNumber(1)
  set channelId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasChannelId() => $_has(0);
  @$pb.TagNumber(1)
  void clearChannelId() => $_clearField(1);

  /// Join already muted, so nobody sees you unmuted for a moment.
  @$pb.TagNumber(2)
  $core.bool get selfMute => $_getBF(1);
  @$pb.TagNumber(2)
  set selfMute($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSelfMute() => $_has(1);
  @$pb.TagNumber(2)
  void clearSelfMute() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get selfDeaf => $_getBF(2);
  @$pb.TagNumber(3)
  set selfDeaf($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSelfDeaf() => $_has(2);
  @$pb.TagNumber(3)
  void clearSelfDeaf() => $_clearField(3);
}

/// What a client needs to connect to the call it was just admitted to.
class JoinVoiceResponse extends $pb.GeneratedMessage {
  factory JoinVoiceResponse({
    $core.String? channelId,
    $core.String? transport,
    $core.String? url,
    $core.String? path,
    $core.String? token,
    $1.Timestamp? expiresAt,
    VoiceParticipant? you,
    $core.Iterable<VoiceParticipant>? participants,
  }) {
    final result = JoinVoiceResponse._();
    if (channelId != null) result.channelId = channelId;
    if (transport != null) result.transport = transport;
    if (url != null) result.url = url;
    if (path != null) result.path = path;
    if (token != null) result.token = token;
    if (expiresAt != null) result.expiresAt = expiresAt;
    if (you != null) result.you = you;
    if (participants != null) result.participants.addAll(participants);
    return result;
  }

  JoinVoiceResponse._();

  factory JoinVoiceResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      JoinVoiceResponse()..mergeFromBuffer(data, registry);
  factory JoinVoiceResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      JoinVoiceResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'JoinVoiceResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: JoinVoiceResponse.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'channelId')
    ..aOS(2, _omitFieldNames ? '' : 'transport')
    ..aOS(3, _omitFieldNames ? '' : 'url')
    ..aOS(4, _omitFieldNames ? '' : 'path')
    ..aOS(5, _omitFieldNames ? '' : 'token')
    ..aOM<$1.Timestamp>(6, _omitFieldNames ? '' : 'expiresAt',
        subBuilder: $1.Timestamp.$_createMessage)
    ..aOM<VoiceParticipant>(7, _omitFieldNames ? '' : 'you',
        subBuilder: VoiceParticipant.$_createMessage)
    ..pPM<VoiceParticipant>(8, _omitFieldNames ? '' : 'participants',
        subBuilder: VoiceParticipant.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  JoinVoiceResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  JoinVoiceResponse copyWith(void Function(JoinVoiceResponse) updates) =>
      super.copyWith((message) => updates(message as JoinVoiceResponse))
          as JoinVoiceResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use JoinVoiceResponse() / JoinVoiceResponse.new instead')
  static JoinVoiceResponse create() => JoinVoiceResponse._();
  static $pb.GeneratedMessage $_createMessage() => JoinVoiceResponse._();
  @$core.override
  JoinVoiceResponse createEmptyInstance() => JoinVoiceResponse._();
  @$core.pragma('dart2js:noInline')
  static JoinVoiceResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<JoinVoiceResponse>(
          JoinVoiceResponse.$_createMessage);
  static JoinVoiceResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get channelId => $_getSZ(0);
  @$pb.TagNumber(1)
  set channelId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasChannelId() => $_has(0);
  @$pb.TagNumber(1)
  void clearChannelId() => $_clearField(1);

  /// Which media transport to connect with. A client that does not know it cannot join.
  @$pb.TagNumber(2)
  $core.String get transport => $_getSZ(1);
  @$pb.TagNumber(2)
  set transport($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTransport() => $_has(1);
  @$pb.TagNumber(2)
  void clearTransport() => $_clearField(2);

  /// An absolute address, or absent to connect through this server at path.
  @$pb.TagNumber(3)
  $core.String get url => $_getSZ(2);
  @$pb.TagNumber(3)
  set url($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasUrl() => $_has(2);
  @$pb.TagNumber(3)
  void clearUrl() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get path => $_getSZ(3);
  @$pb.TagNumber(4)
  set path($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPath() => $_has(3);
  @$pb.TagNumber(4)
  void clearPath() => $_clearField(4);

  /// The transport's short-lived credential; join again for a fresh one.
  @$pb.TagNumber(5)
  $core.String get token => $_getSZ(4);
  @$pb.TagNumber(5)
  set token($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasToken() => $_has(4);
  @$pb.TagNumber(5)
  void clearToken() => $_clearField(5);

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

  @$pb.TagNumber(7)
  VoiceParticipant get you => $_getN(6);
  @$pb.TagNumber(7)
  set you(VoiceParticipant value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasYou() => $_has(6);
  @$pb.TagNumber(7)
  void clearYou() => $_clearField(7);
  @$pb.TagNumber(7)
  VoiceParticipant ensureYou() => $_ensure(6);

  /// Everybody in the call, you included, by join time.
  @$pb.TagNumber(8)
  $pb.PbList<VoiceParticipant> get participants => $_getList(7);
}

/// Leaves a call, named so a late leave cannot end a call another device has since joined.
class LeaveVoiceRequest extends $pb.GeneratedMessage {
  factory LeaveVoiceRequest({
    $core.String? channelId,
  }) {
    final result = LeaveVoiceRequest._();
    if (channelId != null) result.channelId = channelId;
    return result;
  }

  LeaveVoiceRequest._();

  factory LeaveVoiceRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LeaveVoiceRequest()..mergeFromBuffer(data, registry);
  factory LeaveVoiceRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LeaveVoiceRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LeaveVoiceRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: LeaveVoiceRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'channelId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LeaveVoiceRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LeaveVoiceRequest copyWith(void Function(LeaveVoiceRequest) updates) =>
      super.copyWith((message) => updates(message as LeaveVoiceRequest))
          as LeaveVoiceRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use LeaveVoiceRequest() / LeaveVoiceRequest.new instead')
  static LeaveVoiceRequest create() => LeaveVoiceRequest._();
  static $pb.GeneratedMessage $_createMessage() => LeaveVoiceRequest._();
  @$core.override
  LeaveVoiceRequest createEmptyInstance() => LeaveVoiceRequest._();
  @$core.pragma('dart2js:noInline')
  static LeaveVoiceRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LeaveVoiceRequest>(
          LeaveVoiceRequest.$_createMessage);
  static LeaveVoiceRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get channelId => $_getSZ(0);
  @$pb.TagNumber(1)
  set channelId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasChannelId() => $_has(0);
  @$pb.TagNumber(1)
  void clearChannelId() => $_clearField(1);
}

/// left is false when you were not in that call — not an error.
class LeaveVoiceResponse extends $pb.GeneratedMessage {
  factory LeaveVoiceResponse({
    $core.bool? left,
  }) {
    final result = LeaveVoiceResponse._();
    if (left != null) result.left = left;
    return result;
  }

  LeaveVoiceResponse._();

  factory LeaveVoiceResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LeaveVoiceResponse()..mergeFromBuffer(data, registry);
  factory LeaveVoiceResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LeaveVoiceResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LeaveVoiceResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: LeaveVoiceResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'left')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LeaveVoiceResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LeaveVoiceResponse copyWith(void Function(LeaveVoiceResponse) updates) =>
      super.copyWith((message) => updates(message as LeaveVoiceResponse))
          as LeaveVoiceResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use LeaveVoiceResponse() / LeaveVoiceResponse.new instead')
  static LeaveVoiceResponse create() => LeaveVoiceResponse._();
  static $pb.GeneratedMessage $_createMessage() => LeaveVoiceResponse._();
  @$core.override
  LeaveVoiceResponse createEmptyInstance() => LeaveVoiceResponse._();
  @$core.pragma('dart2js:noInline')
  static LeaveVoiceResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LeaveVoiceResponse>(
          LeaveVoiceResponse.$_createMessage);
  static LeaveVoiceResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get left => $_getBF(0);
  @$pb.TagNumber(1)
  set left($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLeft() => $_has(0);
  @$pb.TagNumber(1)
  void clearLeft() => $_clearField(1);
}

/// Sets your own mute and deafen.
class SetVoiceSelfStateRequest extends $pb.GeneratedMessage {
  factory SetVoiceSelfStateRequest({
    $core.bool? selfMute,
    $core.bool? selfDeaf,
  }) {
    final result = SetVoiceSelfStateRequest._();
    if (selfMute != null) result.selfMute = selfMute;
    if (selfDeaf != null) result.selfDeaf = selfDeaf;
    return result;
  }

  SetVoiceSelfStateRequest._();

  factory SetVoiceSelfStateRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetVoiceSelfStateRequest()..mergeFromBuffer(data, registry);
  factory SetVoiceSelfStateRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetVoiceSelfStateRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetVoiceSelfStateRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: SetVoiceSelfStateRequest.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'selfMute')
    ..aOB(2, _omitFieldNames ? '' : 'selfDeaf')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetVoiceSelfStateRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetVoiceSelfStateRequest copyWith(
          void Function(SetVoiceSelfStateRequest) updates) =>
      super.copyWith((message) => updates(message as SetVoiceSelfStateRequest))
          as SetVoiceSelfStateRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SetVoiceSelfStateRequest() / SetVoiceSelfStateRequest.new instead')
  static SetVoiceSelfStateRequest create() => SetVoiceSelfStateRequest._();
  static $pb.GeneratedMessage $_createMessage() => SetVoiceSelfStateRequest._();
  @$core.override
  SetVoiceSelfStateRequest createEmptyInstance() =>
      SetVoiceSelfStateRequest._();
  @$core.pragma('dart2js:noInline')
  static SetVoiceSelfStateRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetVoiceSelfStateRequest>(
          SetVoiceSelfStateRequest.$_createMessage);
  static SetVoiceSelfStateRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get selfMute => $_getBF(0);
  @$pb.TagNumber(1)
  set selfMute($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSelfMute() => $_has(0);
  @$pb.TagNumber(1)
  void clearSelfMute() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get selfDeaf => $_getBF(1);
  @$pb.TagNumber(2)
  set selfDeaf($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSelfDeaf() => $_has(1);
  @$pb.TagNumber(2)
  void clearSelfDeaf() => $_clearField(2);
}

/// Your state in the call now.
class SetVoiceSelfStateResponse extends $pb.GeneratedMessage {
  factory SetVoiceSelfStateResponse({
    VoiceParticipant? participant,
  }) {
    final result = SetVoiceSelfStateResponse._();
    if (participant != null) result.participant = participant;
    return result;
  }

  SetVoiceSelfStateResponse._();

  factory SetVoiceSelfStateResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetVoiceSelfStateResponse()..mergeFromBuffer(data, registry);
  factory SetVoiceSelfStateResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetVoiceSelfStateResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetVoiceSelfStateResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: SetVoiceSelfStateResponse.$_createMessage)
    ..aOM<VoiceParticipant>(1, _omitFieldNames ? '' : 'participant',
        subBuilder: VoiceParticipant.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetVoiceSelfStateResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetVoiceSelfStateResponse copyWith(
          void Function(SetVoiceSelfStateResponse) updates) =>
      super.copyWith((message) => updates(message as SetVoiceSelfStateResponse))
          as SetVoiceSelfStateResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SetVoiceSelfStateResponse() / SetVoiceSelfStateResponse.new instead')
  static SetVoiceSelfStateResponse create() => SetVoiceSelfStateResponse._();
  static $pb.GeneratedMessage $_createMessage() =>
      SetVoiceSelfStateResponse._();
  @$core.override
  SetVoiceSelfStateResponse createEmptyInstance() =>
      SetVoiceSelfStateResponse._();
  @$core.pragma('dart2js:noInline')
  static SetVoiceSelfStateResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetVoiceSelfStateResponse>(
          SetVoiceSelfStateResponse.$_createMessage);
  static SetVoiceSelfStateResponse? _defaultInstance;

  @$pb.TagNumber(1)
  VoiceParticipant get participant => $_getN(0);
  @$pb.TagNumber(1)
  set participant(VoiceParticipant value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasParticipant() => $_has(0);
  @$pb.TagNumber(1)
  void clearParticipant() => $_clearField(1);
  @$pb.TagNumber(1)
  VoiceParticipant ensureParticipant() => $_ensure(0);
}

/// Mutes or unmutes a member for everyone.
class MuteVoiceMemberRequest extends $pb.GeneratedMessage {
  factory MuteVoiceMemberRequest({
    $core.String? userId,
    $core.bool? muted,
  }) {
    final result = MuteVoiceMemberRequest._();
    if (userId != null) result.userId = userId;
    if (muted != null) result.muted = muted;
    return result;
  }

  MuteVoiceMemberRequest._();

  factory MuteVoiceMemberRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MuteVoiceMemberRequest()..mergeFromBuffer(data, registry);
  factory MuteVoiceMemberRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MuteVoiceMemberRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MuteVoiceMemberRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: MuteVoiceMemberRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'userId')
    ..aOB(2, _omitFieldNames ? '' : 'muted')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MuteVoiceMemberRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MuteVoiceMemberRequest copyWith(
          void Function(MuteVoiceMemberRequest) updates) =>
      super.copyWith((message) => updates(message as MuteVoiceMemberRequest))
          as MuteVoiceMemberRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use MuteVoiceMemberRequest() / MuteVoiceMemberRequest.new instead')
  static MuteVoiceMemberRequest create() => MuteVoiceMemberRequest._();
  static $pb.GeneratedMessage $_createMessage() => MuteVoiceMemberRequest._();
  @$core.override
  MuteVoiceMemberRequest createEmptyInstance() => MuteVoiceMemberRequest._();
  @$core.pragma('dart2js:noInline')
  static MuteVoiceMemberRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MuteVoiceMemberRequest>(
          MuteVoiceMemberRequest.$_createMessage);
  static MuteVoiceMemberRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get userId => $_getSZ(0);
  @$pb.TagNumber(1)
  set userId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get muted => $_getBF(1);
  @$pb.TagNumber(2)
  set muted($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMuted() => $_has(1);
  @$pb.TagNumber(2)
  void clearMuted() => $_clearField(2);
}

/// changed is false when they already were (or already were not).
class MuteVoiceMemberResponse extends $pb.GeneratedMessage {
  factory MuteVoiceMemberResponse({
    $core.String? userId,
    $core.bool? muted,
    $core.bool? changed,
  }) {
    final result = MuteVoiceMemberResponse._();
    if (userId != null) result.userId = userId;
    if (muted != null) result.muted = muted;
    if (changed != null) result.changed = changed;
    return result;
  }

  MuteVoiceMemberResponse._();

  factory MuteVoiceMemberResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MuteVoiceMemberResponse()..mergeFromBuffer(data, registry);
  factory MuteVoiceMemberResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MuteVoiceMemberResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MuteVoiceMemberResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: MuteVoiceMemberResponse.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'userId')
    ..aOB(2, _omitFieldNames ? '' : 'muted')
    ..aOB(3, _omitFieldNames ? '' : 'changed')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MuteVoiceMemberResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MuteVoiceMemberResponse copyWith(
          void Function(MuteVoiceMemberResponse) updates) =>
      super.copyWith((message) => updates(message as MuteVoiceMemberResponse))
          as MuteVoiceMemberResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use MuteVoiceMemberResponse() / MuteVoiceMemberResponse.new instead')
  static MuteVoiceMemberResponse create() => MuteVoiceMemberResponse._();
  static $pb.GeneratedMessage $_createMessage() => MuteVoiceMemberResponse._();
  @$core.override
  MuteVoiceMemberResponse createEmptyInstance() => MuteVoiceMemberResponse._();
  @$core.pragma('dart2js:noInline')
  static MuteVoiceMemberResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MuteVoiceMemberResponse>(
          MuteVoiceMemberResponse.$_createMessage);
  static MuteVoiceMemberResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get userId => $_getSZ(0);
  @$pb.TagNumber(1)
  set userId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get muted => $_getBF(1);
  @$pb.TagNumber(2)
  set muted($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMuted() => $_has(1);
  @$pb.TagNumber(2)
  void clearMuted() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get changed => $_getBF(2);
  @$pb.TagNumber(3)
  set changed($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasChanged() => $_has(2);
  @$pb.TagNumber(3)
  void clearChanged() => $_clearField(3);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
