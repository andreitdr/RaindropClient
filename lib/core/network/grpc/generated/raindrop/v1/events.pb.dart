// This is a generated file - do not edit.
//
// Generated from raindrop/v1/events.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;
import 'package:protobuf/well_known_types/google/protobuf/duration.pb.dart'
    as $5;

import 'channels.pb.dart' as $2;
import 'members.pbenum.dart' as $6;
import 'roles.pb.dart' as $3;
import 'text.pb.dart' as $1;
import 'voice.pb.dart' as $4;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

enum ConnectRequest_Frame { heartbeat, resubscribe, notSet }

/// The client's half of the stream.
class ConnectRequest extends $pb.GeneratedMessage {
  factory ConnectRequest({
    Heartbeat? heartbeat,
    Resubscribe? resubscribe,
  }) {
    final result = ConnectRequest._();
    if (heartbeat != null) result.heartbeat = heartbeat;
    if (resubscribe != null) result.resubscribe = resubscribe;
    return result;
  }

  ConnectRequest._();

  factory ConnectRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ConnectRequest()..mergeFromBuffer(data, registry);
  factory ConnectRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ConnectRequest()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ConnectRequest_Frame>
      _ConnectRequest_FrameByTag = {
    1: ConnectRequest_Frame.heartbeat,
    2: ConnectRequest_Frame.resubscribe,
    0: ConnectRequest_Frame.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ConnectRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: ConnectRequest.$_createMessage)
    ..oo(0, [1, 2])
    ..aOM<Heartbeat>(1, _omitFieldNames ? '' : 'heartbeat',
        subBuilder: Heartbeat.$_createMessage)
    ..aOM<Resubscribe>(2, _omitFieldNames ? '' : 'resubscribe',
        subBuilder: Resubscribe.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConnectRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConnectRequest copyWith(void Function(ConnectRequest) updates) =>
      super.copyWith((message) => updates(message as ConnectRequest))
          as ConnectRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ConnectRequest() / ConnectRequest.new instead')
  static ConnectRequest create() => ConnectRequest._();
  static $pb.GeneratedMessage $_createMessage() => ConnectRequest._();
  @$core.override
  ConnectRequest createEmptyInstance() => ConnectRequest._();
  @$core.pragma('dart2js:noInline')
  static ConnectRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ConnectRequest>(
          ConnectRequest.$_createMessage);
  static ConnectRequest? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  ConnectRequest_Frame whichFrame() =>
      _ConnectRequest_FrameByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearFrame() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  Heartbeat get heartbeat => $_getN(0);
  @$pb.TagNumber(1)
  set heartbeat(Heartbeat value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasHeartbeat() => $_has(0);
  @$pb.TagNumber(1)
  void clearHeartbeat() => $_clearField(1);
  @$pb.TagNumber(1)
  Heartbeat ensureHeartbeat() => $_ensure(0);

  @$pb.TagNumber(2)
  Resubscribe get resubscribe => $_getN(1);
  @$pb.TagNumber(2)
  set resubscribe(Resubscribe value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasResubscribe() => $_has(1);
  @$pb.TagNumber(2)
  void clearResubscribe() => $_clearField(2);
  @$pb.TagNumber(2)
  Resubscribe ensureResubscribe() => $_ensure(1);
}

/// "Still here." Keeps the session alive and the member online; a stream that sends none for a while
/// is ended as connection_lost.
class Heartbeat extends $pb.GeneratedMessage {
  factory Heartbeat() => Heartbeat._();

  Heartbeat._();

  factory Heartbeat.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Heartbeat()..mergeFromBuffer(data, registry);
  factory Heartbeat.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Heartbeat()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Heartbeat',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: Heartbeat.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Heartbeat clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Heartbeat copyWith(void Function(Heartbeat) updates) =>
      super.copyWith((message) => updates(message as Heartbeat)) as Heartbeat;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Heartbeat() / Heartbeat.new instead')
  static Heartbeat create() => Heartbeat._();
  static $pb.GeneratedMessage $_createMessage() => Heartbeat._();
  @$core.override
  Heartbeat createEmptyInstance() => Heartbeat._();
  @$core.pragma('dart2js:noInline')
  static Heartbeat getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Heartbeat>(Heartbeat.$_createMessage);
  static Heartbeat? _defaultInstance;
}

/// Asks for a fresh ready on the same stream, e.g. after the app was suspended, so the client re-reads
/// without reconnecting.
class Resubscribe extends $pb.GeneratedMessage {
  factory Resubscribe() => Resubscribe._();

  Resubscribe._();

  factory Resubscribe.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Resubscribe()..mergeFromBuffer(data, registry);
  factory Resubscribe.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Resubscribe()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Resubscribe',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: Resubscribe.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Resubscribe clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Resubscribe copyWith(void Function(Resubscribe) updates) =>
      super.copyWith((message) => updates(message as Resubscribe))
          as Resubscribe;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Resubscribe() / Resubscribe.new instead')
  static Resubscribe create() => Resubscribe._();
  static $pb.GeneratedMessage $_createMessage() => Resubscribe._();
  @$core.override
  Resubscribe createEmptyInstance() => Resubscribe._();
  @$core.pragma('dart2js:noInline')
  static Resubscribe getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Resubscribe>(
          Resubscribe.$_createMessage);
  static Resubscribe? _defaultInstance;
}

/// The server's half of the stream.
class ConnectResponse extends $pb.GeneratedMessage {
  factory ConnectResponse({
    ServerEvent? event,
  }) {
    final result = ConnectResponse._();
    if (event != null) result.event = event;
    return result;
  }

  ConnectResponse._();

  factory ConnectResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ConnectResponse()..mergeFromBuffer(data, registry);
  factory ConnectResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ConnectResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ConnectResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: ConnectResponse.$_createMessage)
    ..aOM<ServerEvent>(1, _omitFieldNames ? '' : 'event',
        subBuilder: ServerEvent.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConnectResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConnectResponse copyWith(void Function(ConnectResponse) updates) =>
      super.copyWith((message) => updates(message as ConnectResponse))
          as ConnectResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ConnectResponse() / ConnectResponse.new instead')
  static ConnectResponse create() => ConnectResponse._();
  static $pb.GeneratedMessage $_createMessage() => ConnectResponse._();
  @$core.override
  ConnectResponse createEmptyInstance() => ConnectResponse._();
  @$core.pragma('dart2js:noInline')
  static ConnectResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ConnectResponse>(
          ConnectResponse.$_createMessage);
  static ConnectResponse? _defaultInstance;

  @$pb.TagNumber(1)
  ServerEvent get event => $_getN(0);
  @$pb.TagNumber(1)
  set event(ServerEvent value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasEvent() => $_has(0);
  @$pb.TagNumber(1)
  void clearEvent() => $_clearField(1);
  @$pb.TagNumber(1)
  ServerEvent ensureEvent() => $_ensure(0);
}

enum ServerEvent_Event {
  ready,
  messageCreated,
  messageDeleted,
  messageReported,
  channelCreated,
  channelRenamed,
  channelDeleted,
  memberJoined,
  memberRenamed,
  memberLeft,
  memberPresence,
  memberRoles,
  roleCreated,
  roleUpdated,
  roleDeleted,
  voiceState,
  voiceLeft,
  deviceAdded,
  deviceRevoked,
  identityReset,
  handshake,
  welcome,
  groupReconcile,
  keyPackagesLow,
  plugin,
  notSet
}

/// One change. Exactly one case is set; a client ignores a case it does not know.
class ServerEvent extends $pb.GeneratedMessage {
  factory ServerEvent({
    ReadyEvent? ready,
    $1.ChannelMessage? messageCreated,
    $1.ChannelMessage? messageDeleted,
    $1.MessageReport? messageReported,
    $2.Channel? channelCreated,
    $2.Channel? channelRenamed,
    ChannelDeletedEvent? channelDeleted,
    MemberEvent? memberJoined,
    MemberEvent? memberRenamed,
    MemberEvent? memberLeft,
    MemberPresenceEvent? memberPresence,
    MemberRolesEvent? memberRoles,
    $3.Role? roleCreated,
    $3.Role? roleUpdated,
    RoleDeletedEvent? roleDeleted,
    $4.VoiceParticipant? voiceState,
    VoiceLeftEvent? voiceLeft,
    DeviceEvent? deviceAdded,
    DeviceEvent? deviceRevoked,
    IdentityResetEvent? identityReset,
    HandshakeEvent? handshake,
    WelcomeEvent? welcome,
    GroupReconcileEvent? groupReconcile,
    KeyPackagesLowEvent? keyPackagesLow,
    PluginEvent? plugin,
  }) {
    final result = ServerEvent._();
    if (ready != null) result.ready = ready;
    if (messageCreated != null) result.messageCreated = messageCreated;
    if (messageDeleted != null) result.messageDeleted = messageDeleted;
    if (messageReported != null) result.messageReported = messageReported;
    if (channelCreated != null) result.channelCreated = channelCreated;
    if (channelRenamed != null) result.channelRenamed = channelRenamed;
    if (channelDeleted != null) result.channelDeleted = channelDeleted;
    if (memberJoined != null) result.memberJoined = memberJoined;
    if (memberRenamed != null) result.memberRenamed = memberRenamed;
    if (memberLeft != null) result.memberLeft = memberLeft;
    if (memberPresence != null) result.memberPresence = memberPresence;
    if (memberRoles != null) result.memberRoles = memberRoles;
    if (roleCreated != null) result.roleCreated = roleCreated;
    if (roleUpdated != null) result.roleUpdated = roleUpdated;
    if (roleDeleted != null) result.roleDeleted = roleDeleted;
    if (voiceState != null) result.voiceState = voiceState;
    if (voiceLeft != null) result.voiceLeft = voiceLeft;
    if (deviceAdded != null) result.deviceAdded = deviceAdded;
    if (deviceRevoked != null) result.deviceRevoked = deviceRevoked;
    if (identityReset != null) result.identityReset = identityReset;
    if (handshake != null) result.handshake = handshake;
    if (welcome != null) result.welcome = welcome;
    if (groupReconcile != null) result.groupReconcile = groupReconcile;
    if (keyPackagesLow != null) result.keyPackagesLow = keyPackagesLow;
    if (plugin != null) result.plugin = plugin;
    return result;
  }

  ServerEvent._();

  factory ServerEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ServerEvent()..mergeFromBuffer(data, registry);
  factory ServerEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ServerEvent()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ServerEvent_Event> _ServerEvent_EventByTag =
      {
    1: ServerEvent_Event.ready,
    2: ServerEvent_Event.messageCreated,
    3: ServerEvent_Event.messageDeleted,
    4: ServerEvent_Event.messageReported,
    5: ServerEvent_Event.channelCreated,
    6: ServerEvent_Event.channelRenamed,
    7: ServerEvent_Event.channelDeleted,
    8: ServerEvent_Event.memberJoined,
    9: ServerEvent_Event.memberRenamed,
    10: ServerEvent_Event.memberLeft,
    11: ServerEvent_Event.memberPresence,
    12: ServerEvent_Event.memberRoles,
    13: ServerEvent_Event.roleCreated,
    14: ServerEvent_Event.roleUpdated,
    15: ServerEvent_Event.roleDeleted,
    16: ServerEvent_Event.voiceState,
    17: ServerEvent_Event.voiceLeft,
    18: ServerEvent_Event.deviceAdded,
    19: ServerEvent_Event.deviceRevoked,
    20: ServerEvent_Event.identityReset,
    21: ServerEvent_Event.handshake,
    22: ServerEvent_Event.welcome,
    23: ServerEvent_Event.groupReconcile,
    24: ServerEvent_Event.keyPackagesLow,
    100: ServerEvent_Event.plugin,
    0: ServerEvent_Event.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ServerEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: ServerEvent.$_createMessage)
    ..oo(0, [
      1,
      2,
      3,
      4,
      5,
      6,
      7,
      8,
      9,
      10,
      11,
      12,
      13,
      14,
      15,
      16,
      17,
      18,
      19,
      20,
      21,
      22,
      23,
      24,
      100
    ])
    ..aOM<ReadyEvent>(1, _omitFieldNames ? '' : 'ready',
        subBuilder: ReadyEvent.$_createMessage)
    ..aOM<$1.ChannelMessage>(2, _omitFieldNames ? '' : 'messageCreated',
        subBuilder: $1.ChannelMessage.$_createMessage)
    ..aOM<$1.ChannelMessage>(3, _omitFieldNames ? '' : 'messageDeleted',
        subBuilder: $1.ChannelMessage.$_createMessage)
    ..aOM<$1.MessageReport>(4, _omitFieldNames ? '' : 'messageReported',
        subBuilder: $1.MessageReport.$_createMessage)
    ..aOM<$2.Channel>(5, _omitFieldNames ? '' : 'channelCreated',
        subBuilder: $2.Channel.$_createMessage)
    ..aOM<$2.Channel>(6, _omitFieldNames ? '' : 'channelRenamed',
        subBuilder: $2.Channel.$_createMessage)
    ..aOM<ChannelDeletedEvent>(7, _omitFieldNames ? '' : 'channelDeleted',
        subBuilder: ChannelDeletedEvent.$_createMessage)
    ..aOM<MemberEvent>(8, _omitFieldNames ? '' : 'memberJoined',
        subBuilder: MemberEvent.$_createMessage)
    ..aOM<MemberEvent>(9, _omitFieldNames ? '' : 'memberRenamed',
        subBuilder: MemberEvent.$_createMessage)
    ..aOM<MemberEvent>(10, _omitFieldNames ? '' : 'memberLeft',
        subBuilder: MemberEvent.$_createMessage)
    ..aOM<MemberPresenceEvent>(11, _omitFieldNames ? '' : 'memberPresence',
        subBuilder: MemberPresenceEvent.$_createMessage)
    ..aOM<MemberRolesEvent>(12, _omitFieldNames ? '' : 'memberRoles',
        subBuilder: MemberRolesEvent.$_createMessage)
    ..aOM<$3.Role>(13, _omitFieldNames ? '' : 'roleCreated',
        subBuilder: $3.Role.$_createMessage)
    ..aOM<$3.Role>(14, _omitFieldNames ? '' : 'roleUpdated',
        subBuilder: $3.Role.$_createMessage)
    ..aOM<RoleDeletedEvent>(15, _omitFieldNames ? '' : 'roleDeleted',
        subBuilder: RoleDeletedEvent.$_createMessage)
    ..aOM<$4.VoiceParticipant>(16, _omitFieldNames ? '' : 'voiceState',
        subBuilder: $4.VoiceParticipant.$_createMessage)
    ..aOM<VoiceLeftEvent>(17, _omitFieldNames ? '' : 'voiceLeft',
        subBuilder: VoiceLeftEvent.$_createMessage)
    ..aOM<DeviceEvent>(18, _omitFieldNames ? '' : 'deviceAdded',
        subBuilder: DeviceEvent.$_createMessage)
    ..aOM<DeviceEvent>(19, _omitFieldNames ? '' : 'deviceRevoked',
        subBuilder: DeviceEvent.$_createMessage)
    ..aOM<IdentityResetEvent>(20, _omitFieldNames ? '' : 'identityReset',
        subBuilder: IdentityResetEvent.$_createMessage)
    ..aOM<HandshakeEvent>(21, _omitFieldNames ? '' : 'handshake',
        subBuilder: HandshakeEvent.$_createMessage)
    ..aOM<WelcomeEvent>(22, _omitFieldNames ? '' : 'welcome',
        subBuilder: WelcomeEvent.$_createMessage)
    ..aOM<GroupReconcileEvent>(23, _omitFieldNames ? '' : 'groupReconcile',
        subBuilder: GroupReconcileEvent.$_createMessage)
    ..aOM<KeyPackagesLowEvent>(24, _omitFieldNames ? '' : 'keyPackagesLow',
        subBuilder: KeyPackagesLowEvent.$_createMessage)
    ..aOM<PluginEvent>(100, _omitFieldNames ? '' : 'plugin',
        subBuilder: PluginEvent.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ServerEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ServerEvent copyWith(void Function(ServerEvent) updates) =>
      super.copyWith((message) => updates(message as ServerEvent))
          as ServerEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ServerEvent() / ServerEvent.new instead')
  static ServerEvent create() => ServerEvent._();
  static $pb.GeneratedMessage $_createMessage() => ServerEvent._();
  @$core.override
  ServerEvent createEmptyInstance() => ServerEvent._();
  @$core.pragma('dart2js:noInline')
  static ServerEvent getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ServerEvent>(
          ServerEvent.$_createMessage);
  static ServerEvent? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  @$pb.TagNumber(7)
  @$pb.TagNumber(8)
  @$pb.TagNumber(9)
  @$pb.TagNumber(10)
  @$pb.TagNumber(11)
  @$pb.TagNumber(12)
  @$pb.TagNumber(13)
  @$pb.TagNumber(14)
  @$pb.TagNumber(15)
  @$pb.TagNumber(16)
  @$pb.TagNumber(17)
  @$pb.TagNumber(18)
  @$pb.TagNumber(19)
  @$pb.TagNumber(20)
  @$pb.TagNumber(21)
  @$pb.TagNumber(22)
  @$pb.TagNumber(23)
  @$pb.TagNumber(24)
  @$pb.TagNumber(100)
  ServerEvent_Event whichEvent() => _ServerEvent_EventByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  @$pb.TagNumber(7)
  @$pb.TagNumber(8)
  @$pb.TagNumber(9)
  @$pb.TagNumber(10)
  @$pb.TagNumber(11)
  @$pb.TagNumber(12)
  @$pb.TagNumber(13)
  @$pb.TagNumber(14)
  @$pb.TagNumber(15)
  @$pb.TagNumber(16)
  @$pb.TagNumber(17)
  @$pb.TagNumber(18)
  @$pb.TagNumber(19)
  @$pb.TagNumber(20)
  @$pb.TagNumber(21)
  @$pb.TagNumber(22)
  @$pb.TagNumber(23)
  @$pb.TagNumber(24)
  @$pb.TagNumber(100)
  void clearEvent() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  ReadyEvent get ready => $_getN(0);
  @$pb.TagNumber(1)
  set ready(ReadyEvent value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasReady() => $_has(0);
  @$pb.TagNumber(1)
  void clearReady() => $_clearField(1);
  @$pb.TagNumber(1)
  ReadyEvent ensureReady() => $_ensure(0);

  @$pb.TagNumber(2)
  $1.ChannelMessage get messageCreated => $_getN(1);
  @$pb.TagNumber(2)
  set messageCreated($1.ChannelMessage value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasMessageCreated() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessageCreated() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.ChannelMessage ensureMessageCreated() => $_ensure(1);

  /// The tombstone: no content or ciphertext, deleted set.
  @$pb.TagNumber(3)
  $1.ChannelMessage get messageDeleted => $_getN(2);
  @$pb.TagNumber(3)
  set messageDeleted($1.ChannelMessage value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasMessageDeleted() => $_has(2);
  @$pb.TagNumber(3)
  void clearMessageDeleted() => $_clearField(3);
  @$pb.TagNumber(3)
  $1.ChannelMessage ensureMessageDeleted() => $_ensure(2);

  /// To members with manage_messages in the channel.
  @$pb.TagNumber(4)
  $1.MessageReport get messageReported => $_getN(3);
  @$pb.TagNumber(4)
  set messageReported($1.MessageReport value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasMessageReported() => $_has(3);
  @$pb.TagNumber(4)
  void clearMessageReported() => $_clearField(4);
  @$pb.TagNumber(4)
  $1.MessageReport ensureMessageReported() => $_ensure(3);

  /// With the recipient's own permissions.
  @$pb.TagNumber(5)
  $2.Channel get channelCreated => $_getN(4);
  @$pb.TagNumber(5)
  set channelCreated($2.Channel value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasChannelCreated() => $_has(4);
  @$pb.TagNumber(5)
  void clearChannelCreated() => $_clearField(5);
  @$pb.TagNumber(5)
  $2.Channel ensureChannelCreated() => $_ensure(4);

  /// With the recipient's own permissions.
  @$pb.TagNumber(6)
  $2.Channel get channelRenamed => $_getN(5);
  @$pb.TagNumber(6)
  set channelRenamed($2.Channel value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasChannelRenamed() => $_has(5);
  @$pb.TagNumber(6)
  void clearChannelRenamed() => $_clearField(6);
  @$pb.TagNumber(6)
  $2.Channel ensureChannelRenamed() => $_ensure(5);

  @$pb.TagNumber(7)
  ChannelDeletedEvent get channelDeleted => $_getN(6);
  @$pb.TagNumber(7)
  set channelDeleted(ChannelDeletedEvent value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasChannelDeleted() => $_has(6);
  @$pb.TagNumber(7)
  void clearChannelDeleted() => $_clearField(7);
  @$pb.TagNumber(7)
  ChannelDeletedEvent ensureChannelDeleted() => $_ensure(6);

  /// Registered or rejoined.
  @$pb.TagNumber(8)
  MemberEvent get memberJoined => $_getN(7);
  @$pb.TagNumber(8)
  set memberJoined(MemberEvent value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasMemberJoined() => $_has(7);
  @$pb.TagNumber(8)
  void clearMemberJoined() => $_clearField(8);
  @$pb.TagNumber(8)
  MemberEvent ensureMemberJoined() => $_ensure(7);

  @$pb.TagNumber(9)
  MemberEvent get memberRenamed => $_getN(8);
  @$pb.TagNumber(9)
  set memberRenamed(MemberEvent value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasMemberRenamed() => $_has(8);
  @$pb.TagNumber(9)
  void clearMemberRenamed() => $_clearField(9);
  @$pb.TagNumber(9)
  MemberEvent ensureMemberRenamed() => $_ensure(8);

  @$pb.TagNumber(10)
  MemberEvent get memberLeft => $_getN(9);
  @$pb.TagNumber(10)
  set memberLeft(MemberEvent value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasMemberLeft() => $_has(9);
  @$pb.TagNumber(10)
  void clearMemberLeft() => $_clearField(10);
  @$pb.TagNumber(10)
  MemberEvent ensureMemberLeft() => $_ensure(9);

  @$pb.TagNumber(11)
  MemberPresenceEvent get memberPresence => $_getN(10);
  @$pb.TagNumber(11)
  set memberPresence(MemberPresenceEvent value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasMemberPresence() => $_has(10);
  @$pb.TagNumber(11)
  void clearMemberPresence() => $_clearField(11);
  @$pb.TagNumber(11)
  MemberPresenceEvent ensureMemberPresence() => $_ensure(10);

  @$pb.TagNumber(12)
  MemberRolesEvent get memberRoles => $_getN(11);
  @$pb.TagNumber(12)
  set memberRoles(MemberRolesEvent value) => $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasMemberRoles() => $_has(11);
  @$pb.TagNumber(12)
  void clearMemberRoles() => $_clearField(12);
  @$pb.TagNumber(12)
  MemberRolesEvent ensureMemberRoles() => $_ensure(11);

  @$pb.TagNumber(13)
  $3.Role get roleCreated => $_getN(12);
  @$pb.TagNumber(13)
  set roleCreated($3.Role value) => $_setField(13, value);
  @$pb.TagNumber(13)
  $core.bool hasRoleCreated() => $_has(12);
  @$pb.TagNumber(13)
  void clearRoleCreated() => $_clearField(13);
  @$pb.TagNumber(13)
  $3.Role ensureRoleCreated() => $_ensure(12);

  @$pb.TagNumber(14)
  $3.Role get roleUpdated => $_getN(13);
  @$pb.TagNumber(14)
  set roleUpdated($3.Role value) => $_setField(14, value);
  @$pb.TagNumber(14)
  $core.bool hasRoleUpdated() => $_has(13);
  @$pb.TagNumber(14)
  void clearRoleUpdated() => $_clearField(14);
  @$pb.TagNumber(14)
  $3.Role ensureRoleUpdated() => $_ensure(13);

  @$pb.TagNumber(15)
  RoleDeletedEvent get roleDeleted => $_getN(14);
  @$pb.TagNumber(15)
  set roleDeleted(RoleDeletedEvent value) => $_setField(15, value);
  @$pb.TagNumber(15)
  $core.bool hasRoleDeleted() => $_has(14);
  @$pb.TagNumber(15)
  void clearRoleDeleted() => $_clearField(15);
  @$pb.TagNumber(15)
  RoleDeletedEvent ensureRoleDeleted() => $_ensure(14);

  /// Joined a call, or their state in it changed: the whole state.
  @$pb.TagNumber(16)
  $4.VoiceParticipant get voiceState => $_getN(15);
  @$pb.TagNumber(16)
  set voiceState($4.VoiceParticipant value) => $_setField(16, value);
  @$pb.TagNumber(16)
  $core.bool hasVoiceState() => $_has(15);
  @$pb.TagNumber(16)
  void clearVoiceState() => $_clearField(16);
  @$pb.TagNumber(16)
  $4.VoiceParticipant ensureVoiceState() => $_ensure(15);

  @$pb.TagNumber(17)
  VoiceLeftEvent get voiceLeft => $_getN(16);
  @$pb.TagNumber(17)
  set voiceLeft(VoiceLeftEvent value) => $_setField(17, value);
  @$pb.TagNumber(17)
  $core.bool hasVoiceLeft() => $_has(16);
  @$pb.TagNumber(17)
  void clearVoiceLeft() => $_clearField(17);
  @$pb.TagNumber(17)
  VoiceLeftEvent ensureVoiceLeft() => $_ensure(16);

  @$pb.TagNumber(18)
  DeviceEvent get deviceAdded => $_getN(17);
  @$pb.TagNumber(18)
  set deviceAdded(DeviceEvent value) => $_setField(18, value);
  @$pb.TagNumber(18)
  $core.bool hasDeviceAdded() => $_has(17);
  @$pb.TagNumber(18)
  void clearDeviceAdded() => $_clearField(18);
  @$pb.TagNumber(18)
  DeviceEvent ensureDeviceAdded() => $_ensure(17);

  @$pb.TagNumber(19)
  DeviceEvent get deviceRevoked => $_getN(18);
  @$pb.TagNumber(19)
  set deviceRevoked(DeviceEvent value) => $_setField(19, value);
  @$pb.TagNumber(19)
  $core.bool hasDeviceRevoked() => $_has(18);
  @$pb.TagNumber(19)
  void clearDeviceRevoked() => $_clearField(19);
  @$pb.TagNumber(19)
  DeviceEvent ensureDeviceRevoked() => $_ensure(18);

  /// The user replaced their identity key, revoking every device: show their safety number as changed.
  @$pb.TagNumber(20)
  IdentityResetEvent get identityReset => $_getN(19);
  @$pb.TagNumber(20)
  set identityReset(IdentityResetEvent value) => $_setField(20, value);
  @$pb.TagNumber(20)
  $core.bool hasIdentityReset() => $_has(19);
  @$pb.TagNumber(20)
  void clearIdentityReset() => $_clearField(20);
  @$pb.TagNumber(20)
  IdentityResetEvent ensureIdentityReset() => $_ensure(19);

  /// A commit was accepted, to everyone allowed in the group.
  @$pb.TagNumber(21)
  HandshakeEvent get handshake => $_getN(20);
  @$pb.TagNumber(21)
  set handshake(HandshakeEvent value) => $_setField(21, value);
  @$pb.TagNumber(21)
  $core.bool hasHandshake() => $_has(20);
  @$pb.TagNumber(21)
  void clearHandshake() => $_clearField(21);
  @$pb.TagNumber(21)
  HandshakeEvent ensureHandshake() => $_ensure(20);

  /// A Welcome is waiting for one of the recipient's devices.
  @$pb.TagNumber(22)
  WelcomeEvent get welcome => $_getN(21);
  @$pb.TagNumber(22)
  set welcome(WelcomeEvent value) => $_setField(22, value);
  @$pb.TagNumber(22)
  $core.bool hasWelcome() => $_has(21);
  @$pb.TagNumber(22)
  void clearWelcome() => $_clearField(22);
  @$pb.TagNumber(22)
  WelcomeEvent ensureWelcome() => $_ensure(21);

  /// Who should be in a group may have changed: compare with GetGroupRoster and commit the difference.
  @$pb.TagNumber(23)
  GroupReconcileEvent get groupReconcile => $_getN(22);
  @$pb.TagNumber(23)
  set groupReconcile(GroupReconcileEvent value) => $_setField(23, value);
  @$pb.TagNumber(23)
  $core.bool hasGroupReconcile() => $_has(22);
  @$pb.TagNumber(23)
  void clearGroupReconcile() => $_clearField(23);
  @$pb.TagNumber(23)
  GroupReconcileEvent ensureGroupReconcile() => $_ensure(22);

  /// To its owner: a device is running out of one-time key packages.
  @$pb.TagNumber(24)
  KeyPackagesLowEvent get keyPackagesLow => $_getN(23);
  @$pb.TagNumber(24)
  set keyPackagesLow(KeyPackagesLowEvent value) => $_setField(24, value);
  @$pb.TagNumber(24)
  $core.bool hasKeyPackagesLow() => $_has(23);
  @$pb.TagNumber(24)
  void clearKeyPackagesLow() => $_clearField(24);
  @$pb.TagNumber(24)
  KeyPackagesLowEvent ensureKeyPackagesLow() => $_ensure(23);

  /// An event a server plugin publishes. Built-in events never use it.
  @$pb.TagNumber(100)
  PluginEvent get plugin => $_getN(24);
  @$pb.TagNumber(100)
  set plugin(PluginEvent value) => $_setField(100, value);
  @$pb.TagNumber(100)
  $core.bool hasPlugin() => $_has(24);
  @$pb.TagNumber(100)
  void clearPlugin() => $_clearField(100);
  @$pb.TagNumber(100)
  PluginEvent ensurePlugin() => $_ensure(24);
}

/// The stream is open. Sent first, and again after a Resubscribe; a client re-reads after it.
class ReadyEvent extends $pb.GeneratedMessage {
  factory ReadyEvent({
    $core.String? userId,
    $core.String? protocolVersion,
    $5.Duration? heartbeatInterval,
  }) {
    final result = ReadyEvent._();
    if (userId != null) result.userId = userId;
    if (protocolVersion != null) result.protocolVersion = protocolVersion;
    if (heartbeatInterval != null) result.heartbeatInterval = heartbeatInterval;
    return result;
  }

  ReadyEvent._();

  factory ReadyEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReadyEvent()..mergeFromBuffer(data, registry);
  factory ReadyEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReadyEvent()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReadyEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: ReadyEvent.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'userId')
    ..aOS(2, _omitFieldNames ? '' : 'protocolVersion')
    ..aOM<$5.Duration>(3, _omitFieldNames ? '' : 'heartbeatInterval',
        subBuilder: $5.Duration.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReadyEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReadyEvent copyWith(void Function(ReadyEvent) updates) =>
      super.copyWith((message) => updates(message as ReadyEvent)) as ReadyEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReadyEvent() / ReadyEvent.new instead')
  static ReadyEvent create() => ReadyEvent._();
  static $pb.GeneratedMessage $_createMessage() => ReadyEvent._();
  @$core.override
  ReadyEvent createEmptyInstance() => ReadyEvent._();
  @$core.pragma('dart2js:noInline')
  static ReadyEvent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReadyEvent>(ReadyEvent.$_createMessage);
  static ReadyEvent? _defaultInstance;

  /// The stream's own member.
  @$pb.TagNumber(1)
  $core.String get userId => $_getSZ(0);
  @$pb.TagNumber(1)
  set userId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get protocolVersion => $_getSZ(1);
  @$pb.TagNumber(2)
  set protocolVersion($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasProtocolVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearProtocolVersion() => $_clearField(2);

  /// How often to send a heartbeat.
  @$pb.TagNumber(3)
  $5.Duration get heartbeatInterval => $_getN(2);
  @$pb.TagNumber(3)
  set heartbeatInterval($5.Duration value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasHeartbeatInterval() => $_has(2);
  @$pb.TagNumber(3)
  void clearHeartbeatInterval() => $_clearField(3);
  @$pb.TagNumber(3)
  $5.Duration ensureHeartbeatInterval() => $_ensure(2);
}

/// A channel and everything in it were deleted.
class ChannelDeletedEvent extends $pb.GeneratedMessage {
  factory ChannelDeletedEvent({
    $core.String? channelId,
  }) {
    final result = ChannelDeletedEvent._();
    if (channelId != null) result.channelId = channelId;
    return result;
  }

  ChannelDeletedEvent._();

  factory ChannelDeletedEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ChannelDeletedEvent()..mergeFromBuffer(data, registry);
  factory ChannelDeletedEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ChannelDeletedEvent()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ChannelDeletedEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: ChannelDeletedEvent.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'channelId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChannelDeletedEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChannelDeletedEvent copyWith(void Function(ChannelDeletedEvent) updates) =>
      super.copyWith((message) => updates(message as ChannelDeletedEvent))
          as ChannelDeletedEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use ChannelDeletedEvent() / ChannelDeletedEvent.new instead')
  static ChannelDeletedEvent create() => ChannelDeletedEvent._();
  static $pb.GeneratedMessage $_createMessage() => ChannelDeletedEvent._();
  @$core.override
  ChannelDeletedEvent createEmptyInstance() => ChannelDeletedEvent._();
  @$core.pragma('dart2js:noInline')
  static ChannelDeletedEvent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ChannelDeletedEvent>(
          ChannelDeletedEvent.$_createMessage);
  static ChannelDeletedEvent? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get channelId => $_getSZ(0);
  @$pb.TagNumber(1)
  set channelId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasChannelId() => $_has(0);
  @$pb.TagNumber(1)
  void clearChannelId() => $_clearField(1);
}

/// A member joined, was renamed, or left.
class MemberEvent extends $pb.GeneratedMessage {
  factory MemberEvent({
    $core.String? userId,
    $core.String? username,
  }) {
    final result = MemberEvent._();
    if (userId != null) result.userId = userId;
    if (username != null) result.username = username;
    return result;
  }

  MemberEvent._();

  factory MemberEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MemberEvent()..mergeFromBuffer(data, registry);
  factory MemberEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MemberEvent()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MemberEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: MemberEvent.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'userId')
    ..aOS(2, _omitFieldNames ? '' : 'username')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MemberEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MemberEvent copyWith(void Function(MemberEvent) updates) =>
      super.copyWith((message) => updates(message as MemberEvent))
          as MemberEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use MemberEvent() / MemberEvent.new instead')
  static MemberEvent create() => MemberEvent._();
  static $pb.GeneratedMessage $_createMessage() => MemberEvent._();
  @$core.override
  MemberEvent createEmptyInstance() => MemberEvent._();
  @$core.pragma('dart2js:noInline')
  static MemberEvent getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MemberEvent>(
          MemberEvent.$_createMessage);
  static MemberEvent? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get userId => $_getSZ(0);
  @$pb.TagNumber(1)
  set userId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => $_clearField(1);

  /// Their username now; absent once they have left and it has been erased.
  @$pb.TagNumber(2)
  $core.String get username => $_getSZ(1);
  @$pb.TagNumber(2)
  set username($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUsername() => $_has(1);
  @$pb.TagNumber(2)
  void clearUsername() => $_clearField(2);
}

/// A member came online or went offline.
class MemberPresenceEvent extends $pb.GeneratedMessage {
  factory MemberPresenceEvent({
    $core.String? userId,
    $6.Presence? presence,
  }) {
    final result = MemberPresenceEvent._();
    if (userId != null) result.userId = userId;
    if (presence != null) result.presence = presence;
    return result;
  }

  MemberPresenceEvent._();

  factory MemberPresenceEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MemberPresenceEvent()..mergeFromBuffer(data, registry);
  factory MemberPresenceEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MemberPresenceEvent()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MemberPresenceEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: MemberPresenceEvent.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'userId')
    ..aE<$6.Presence>(2, _omitFieldNames ? '' : 'presence',
        enumValues: $6.Presence.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MemberPresenceEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MemberPresenceEvent copyWith(void Function(MemberPresenceEvent) updates) =>
      super.copyWith((message) => updates(message as MemberPresenceEvent))
          as MemberPresenceEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use MemberPresenceEvent() / MemberPresenceEvent.new instead')
  static MemberPresenceEvent create() => MemberPresenceEvent._();
  static $pb.GeneratedMessage $_createMessage() => MemberPresenceEvent._();
  @$core.override
  MemberPresenceEvent createEmptyInstance() => MemberPresenceEvent._();
  @$core.pragma('dart2js:noInline')
  static MemberPresenceEvent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MemberPresenceEvent>(
          MemberPresenceEvent.$_createMessage);
  static MemberPresenceEvent? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get userId => $_getSZ(0);
  @$pb.TagNumber(1)
  set userId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => $_clearField(1);

  @$pb.TagNumber(2)
  $6.Presence get presence => $_getN(1);
  @$pb.TagNumber(2)
  set presence($6.Presence value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasPresence() => $_has(1);
  @$pb.TagNumber(2)
  void clearPresence() => $_clearField(2);
}

/// A member was given or lost a role.
class MemberRolesEvent extends $pb.GeneratedMessage {
  factory MemberRolesEvent({
    $core.String? userId,
    $core.String? roleId,
    $core.bool? assigned,
  }) {
    final result = MemberRolesEvent._();
    if (userId != null) result.userId = userId;
    if (roleId != null) result.roleId = roleId;
    if (assigned != null) result.assigned = assigned;
    return result;
  }

  MemberRolesEvent._();

  factory MemberRolesEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MemberRolesEvent()..mergeFromBuffer(data, registry);
  factory MemberRolesEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MemberRolesEvent()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MemberRolesEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: MemberRolesEvent.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'userId')
    ..aOS(2, _omitFieldNames ? '' : 'roleId')
    ..aOB(3, _omitFieldNames ? '' : 'assigned')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MemberRolesEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MemberRolesEvent copyWith(void Function(MemberRolesEvent) updates) =>
      super.copyWith((message) => updates(message as MemberRolesEvent))
          as MemberRolesEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use MemberRolesEvent() / MemberRolesEvent.new instead')
  static MemberRolesEvent create() => MemberRolesEvent._();
  static $pb.GeneratedMessage $_createMessage() => MemberRolesEvent._();
  @$core.override
  MemberRolesEvent createEmptyInstance() => MemberRolesEvent._();
  @$core.pragma('dart2js:noInline')
  static MemberRolesEvent getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MemberRolesEvent>(
          MemberRolesEvent.$_createMessage);
  static MemberRolesEvent? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get userId => $_getSZ(0);
  @$pb.TagNumber(1)
  set userId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get roleId => $_getSZ(1);
  @$pb.TagNumber(2)
  set roleId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRoleId() => $_has(1);
  @$pb.TagNumber(2)
  void clearRoleId() => $_clearField(2);

  /// True when they now hold it.
  @$pb.TagNumber(3)
  $core.bool get assigned => $_getBF(2);
  @$pb.TagNumber(3)
  set assigned($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAssigned() => $_has(2);
  @$pb.TagNumber(3)
  void clearAssigned() => $_clearField(3);
}

/// A role was deleted and taken away from everyone.
class RoleDeletedEvent extends $pb.GeneratedMessage {
  factory RoleDeletedEvent({
    $core.String? roleId,
  }) {
    final result = RoleDeletedEvent._();
    if (roleId != null) result.roleId = roleId;
    return result;
  }

  RoleDeletedEvent._();

  factory RoleDeletedEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RoleDeletedEvent()..mergeFromBuffer(data, registry);
  factory RoleDeletedEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RoleDeletedEvent()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RoleDeletedEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: RoleDeletedEvent.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'roleId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RoleDeletedEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RoleDeletedEvent copyWith(void Function(RoleDeletedEvent) updates) =>
      super.copyWith((message) => updates(message as RoleDeletedEvent))
          as RoleDeletedEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RoleDeletedEvent() / RoleDeletedEvent.new instead')
  static RoleDeletedEvent create() => RoleDeletedEvent._();
  static $pb.GeneratedMessage $_createMessage() => RoleDeletedEvent._();
  @$core.override
  RoleDeletedEvent createEmptyInstance() => RoleDeletedEvent._();
  @$core.pragma('dart2js:noInline')
  static RoleDeletedEvent getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RoleDeletedEvent>(
          RoleDeletedEvent.$_createMessage);
  static RoleDeletedEvent? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get roleId => $_getSZ(0);
  @$pb.TagNumber(1)
  set roleId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRoleId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRoleId() => $_clearField(1);
}

/// Somebody is no longer in a call.
class VoiceLeftEvent extends $pb.GeneratedMessage {
  factory VoiceLeftEvent({
    $core.String? channelId,
    $core.String? userId,
    $core.String? reason,
  }) {
    final result = VoiceLeftEvent._();
    if (channelId != null) result.channelId = channelId;
    if (userId != null) result.userId = userId;
    if (reason != null) result.reason = reason;
    return result;
  }

  VoiceLeftEvent._();

  factory VoiceLeftEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      VoiceLeftEvent()..mergeFromBuffer(data, registry);
  factory VoiceLeftEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      VoiceLeftEvent()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'VoiceLeftEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: VoiceLeftEvent.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'channelId')
    ..aOS(2, _omitFieldNames ? '' : 'userId')
    ..aOS(3, _omitFieldNames ? '' : 'reason')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VoiceLeftEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VoiceLeftEvent copyWith(void Function(VoiceLeftEvent) updates) =>
      super.copyWith((message) => updates(message as VoiceLeftEvent))
          as VoiceLeftEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use VoiceLeftEvent() / VoiceLeftEvent.new instead')
  static VoiceLeftEvent create() => VoiceLeftEvent._();
  static $pb.GeneratedMessage $_createMessage() => VoiceLeftEvent._();
  @$core.override
  VoiceLeftEvent createEmptyInstance() => VoiceLeftEvent._();
  @$core.pragma('dart2js:noInline')
  static VoiceLeftEvent getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<VoiceLeftEvent>(
          VoiceLeftEvent.$_createMessage);
  static VoiceLeftEvent? _defaultInstance;

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

  /// left, moved, disconnected, replaced, permission_lost, session_ended, channel_deleted,
  /// server_ended — an open set: treat one you do not know as left.
  @$pb.TagNumber(3)
  $core.String get reason => $_getSZ(2);
  @$pb.TagNumber(3)
  set reason($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasReason() => $_has(2);
  @$pb.TagNumber(3)
  void clearReason() => $_clearField(3);
}

/// A device was registered or revoked.
class DeviceEvent extends $pb.GeneratedMessage {
  factory DeviceEvent({
    $core.String? userId,
    $core.String? deviceId,
    $core.List<$core.int>? certificate,
  }) {
    final result = DeviceEvent._();
    if (userId != null) result.userId = userId;
    if (deviceId != null) result.deviceId = deviceId;
    if (certificate != null) result.certificate = certificate;
    return result;
  }

  DeviceEvent._();

  factory DeviceEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DeviceEvent()..mergeFromBuffer(data, registry);
  factory DeviceEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DeviceEvent()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeviceEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: DeviceEvent.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'userId')
    ..aOS(2, _omitFieldNames ? '' : 'deviceId')
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'certificate', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeviceEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeviceEvent copyWith(void Function(DeviceEvent) updates) =>
      super.copyWith((message) => updates(message as DeviceEvent))
          as DeviceEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use DeviceEvent() / DeviceEvent.new instead')
  static DeviceEvent create() => DeviceEvent._();
  static $pb.GeneratedMessage $_createMessage() => DeviceEvent._();
  @$core.override
  DeviceEvent createEmptyInstance() => DeviceEvent._();
  @$core.pragma('dart2js:noInline')
  static DeviceEvent getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DeviceEvent>(
          DeviceEvent.$_createMessage);
  static DeviceEvent? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get userId => $_getSZ(0);
  @$pb.TagNumber(1)
  set userId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get deviceId => $_getSZ(1);
  @$pb.TagNumber(2)
  set deviceId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDeviceId() => $_has(1);
  @$pb.TagNumber(2)
  void clearDeviceId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get certificate => $_getN(2);
  @$pb.TagNumber(3)
  set certificate($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCertificate() => $_has(2);
  @$pb.TagNumber(3)
  void clearCertificate() => $_clearField(3);
}

/// A user reset their identity key.
class IdentityResetEvent extends $pb.GeneratedMessage {
  factory IdentityResetEvent({
    $core.String? userId,
  }) {
    final result = IdentityResetEvent._();
    if (userId != null) result.userId = userId;
    return result;
  }

  IdentityResetEvent._();

  factory IdentityResetEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      IdentityResetEvent()..mergeFromBuffer(data, registry);
  factory IdentityResetEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      IdentityResetEvent()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'IdentityResetEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: IdentityResetEvent.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'userId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IdentityResetEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IdentityResetEvent copyWith(void Function(IdentityResetEvent) updates) =>
      super.copyWith((message) => updates(message as IdentityResetEvent))
          as IdentityResetEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use IdentityResetEvent() / IdentityResetEvent.new instead')
  static IdentityResetEvent create() => IdentityResetEvent._();
  static $pb.GeneratedMessage $_createMessage() => IdentityResetEvent._();
  @$core.override
  IdentityResetEvent createEmptyInstance() => IdentityResetEvent._();
  @$core.pragma('dart2js:noInline')
  static IdentityResetEvent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<IdentityResetEvent>(
          IdentityResetEvent.$_createMessage);
  static IdentityResetEvent? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get userId => $_getSZ(0);
  @$pb.TagNumber(1)
  set userId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => $_clearField(1);
}

/// A commit was accepted.
class HandshakeEvent extends $pb.GeneratedMessage {
  factory HandshakeEvent({
    $core.String? channelId,
    $fixnum.Int64? epoch,
    $core.List<$core.int>? message,
  }) {
    final result = HandshakeEvent._();
    if (channelId != null) result.channelId = channelId;
    if (epoch != null) result.epoch = epoch;
    if (message != null) result.message = message;
    return result;
  }

  HandshakeEvent._();

  factory HandshakeEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      HandshakeEvent()..mergeFromBuffer(data, registry);
  factory HandshakeEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      HandshakeEvent()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'HandshakeEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: HandshakeEvent.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'channelId')
    ..aInt64(2, _omitFieldNames ? '' : 'epoch')
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'message', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HandshakeEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HandshakeEvent copyWith(void Function(HandshakeEvent) updates) =>
      super.copyWith((message) => updates(message as HandshakeEvent))
          as HandshakeEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use HandshakeEvent() / HandshakeEvent.new instead')
  static HandshakeEvent create() => HandshakeEvent._();
  static $pb.GeneratedMessage $_createMessage() => HandshakeEvent._();
  @$core.override
  HandshakeEvent createEmptyInstance() => HandshakeEvent._();
  @$core.pragma('dart2js:noInline')
  static HandshakeEvent getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<HandshakeEvent>(
          HandshakeEvent.$_createMessage);
  static HandshakeEvent? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get channelId => $_getSZ(0);
  @$pb.TagNumber(1)
  set channelId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasChannelId() => $_has(0);
  @$pb.TagNumber(1)
  void clearChannelId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get epoch => $_getI64(1);
  @$pb.TagNumber(2)
  set epoch($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEpoch() => $_has(1);
  @$pb.TagNumber(2)
  void clearEpoch() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get message => $_getN(2);
  @$pb.TagNumber(3)
  set message($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMessage() => $_has(2);
  @$pb.TagNumber(3)
  void clearMessage() => $_clearField(3);
}

/// A Welcome is waiting for one of the recipient's devices.
class WelcomeEvent extends $pb.GeneratedMessage {
  factory WelcomeEvent({
    $core.String? channelId,
    $core.String? deviceId,
  }) {
    final result = WelcomeEvent._();
    if (channelId != null) result.channelId = channelId;
    if (deviceId != null) result.deviceId = deviceId;
    return result;
  }

  WelcomeEvent._();

  factory WelcomeEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      WelcomeEvent()..mergeFromBuffer(data, registry);
  factory WelcomeEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      WelcomeEvent()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WelcomeEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: WelcomeEvent.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'channelId')
    ..aOS(2, _omitFieldNames ? '' : 'deviceId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WelcomeEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WelcomeEvent copyWith(void Function(WelcomeEvent) updates) =>
      super.copyWith((message) => updates(message as WelcomeEvent))
          as WelcomeEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use WelcomeEvent() / WelcomeEvent.new instead')
  static WelcomeEvent create() => WelcomeEvent._();
  static $pb.GeneratedMessage $_createMessage() => WelcomeEvent._();
  @$core.override
  WelcomeEvent createEmptyInstance() => WelcomeEvent._();
  @$core.pragma('dart2js:noInline')
  static WelcomeEvent getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<WelcomeEvent>(
          WelcomeEvent.$_createMessage);
  static WelcomeEvent? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get channelId => $_getSZ(0);
  @$pb.TagNumber(1)
  set channelId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasChannelId() => $_has(0);
  @$pb.TagNumber(1)
  void clearChannelId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get deviceId => $_getSZ(1);
  @$pb.TagNumber(2)
  set deviceId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDeviceId() => $_has(1);
  @$pb.TagNumber(2)
  void clearDeviceId() => $_clearField(2);
}

/// A group's membership may need reconciling.
class GroupReconcileEvent extends $pb.GeneratedMessage {
  factory GroupReconcileEvent({
    $core.String? channelId,
  }) {
    final result = GroupReconcileEvent._();
    if (channelId != null) result.channelId = channelId;
    return result;
  }

  GroupReconcileEvent._();

  factory GroupReconcileEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GroupReconcileEvent()..mergeFromBuffer(data, registry);
  factory GroupReconcileEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GroupReconcileEvent()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GroupReconcileEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: GroupReconcileEvent.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'channelId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GroupReconcileEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GroupReconcileEvent copyWith(void Function(GroupReconcileEvent) updates) =>
      super.copyWith((message) => updates(message as GroupReconcileEvent))
          as GroupReconcileEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use GroupReconcileEvent() / GroupReconcileEvent.new instead')
  static GroupReconcileEvent create() => GroupReconcileEvent._();
  static $pb.GeneratedMessage $_createMessage() => GroupReconcileEvent._();
  @$core.override
  GroupReconcileEvent createEmptyInstance() => GroupReconcileEvent._();
  @$core.pragma('dart2js:noInline')
  static GroupReconcileEvent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GroupReconcileEvent>(
          GroupReconcileEvent.$_createMessage);
  static GroupReconcileEvent? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get channelId => $_getSZ(0);
  @$pb.TagNumber(1)
  set channelId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasChannelId() => $_has(0);
  @$pb.TagNumber(1)
  void clearChannelId() => $_clearField(1);
}

/// A device is running out of key packages.
class KeyPackagesLowEvent extends $pb.GeneratedMessage {
  factory KeyPackagesLowEvent({
    $core.String? deviceId,
    $core.int? remaining,
  }) {
    final result = KeyPackagesLowEvent._();
    if (deviceId != null) result.deviceId = deviceId;
    if (remaining != null) result.remaining = remaining;
    return result;
  }

  KeyPackagesLowEvent._();

  factory KeyPackagesLowEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      KeyPackagesLowEvent()..mergeFromBuffer(data, registry);
  factory KeyPackagesLowEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      KeyPackagesLowEvent()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'KeyPackagesLowEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: KeyPackagesLowEvent.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'deviceId')
    ..aI(2, _omitFieldNames ? '' : 'remaining')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  KeyPackagesLowEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  KeyPackagesLowEvent copyWith(void Function(KeyPackagesLowEvent) updates) =>
      super.copyWith((message) => updates(message as KeyPackagesLowEvent))
          as KeyPackagesLowEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use KeyPackagesLowEvent() / KeyPackagesLowEvent.new instead')
  static KeyPackagesLowEvent create() => KeyPackagesLowEvent._();
  static $pb.GeneratedMessage $_createMessage() => KeyPackagesLowEvent._();
  @$core.override
  KeyPackagesLowEvent createEmptyInstance() => KeyPackagesLowEvent._();
  @$core.pragma('dart2js:noInline')
  static KeyPackagesLowEvent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<KeyPackagesLowEvent>(
          KeyPackagesLowEvent.$_createMessage);
  static KeyPackagesLowEvent? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get deviceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set deviceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDeviceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearDeviceId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get remaining => $_getIZ(1);
  @$pb.TagNumber(2)
  set remaining($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRemaining() => $_has(1);
  @$pb.TagNumber(2)
  void clearRemaining() => $_clearField(2);
}

/// An event from a server plugin.
class PluginEvent extends $pb.GeneratedMessage {
  factory PluginEvent({
    $core.String? type,
    $core.List<$core.int>? data,
  }) {
    final result = PluginEvent._();
    if (type != null) result.type = type;
    if (data != null) result.data = data;
    return result;
  }

  PluginEvent._();

  factory PluginEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PluginEvent()..mergeFromBuffer(data, registry);
  factory PluginEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PluginEvent()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PluginEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: PluginEvent.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'type')
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'data', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PluginEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PluginEvent copyWith(void Function(PluginEvent) updates) =>
      super.copyWith((message) => updates(message as PluginEvent))
          as PluginEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PluginEvent() / PluginEvent.new instead')
  static PluginEvent create() => PluginEvent._();
  static $pb.GeneratedMessage $_createMessage() => PluginEvent._();
  @$core.override
  PluginEvent createEmptyInstance() => PluginEvent._();
  @$core.pragma('dart2js:noInline')
  static PluginEvent getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PluginEvent>(
          PluginEvent.$_createMessage);
  static PluginEvent? _defaultInstance;

  /// The plugin's own name for it, prefixed with the plugin's name (e.g. "polls.vote").
  @$pb.TagNumber(1)
  $core.String get type => $_getSZ(0);
  @$pb.TagNumber(1)
  set type($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  /// A protobuf message the plugin defines; clients without that plugin ignore it.
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
