// This is a generated file - do not edit.
//
// Generated from raindrop/v1/delivery.proto.

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

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// A device, named by its owner and its own id.
class DeviceRef extends $pb.GeneratedMessage {
  factory DeviceRef({
    $core.String? userId,
    $core.String? deviceId,
  }) {
    final result = DeviceRef._();
    if (userId != null) result.userId = userId;
    if (deviceId != null) result.deviceId = deviceId;
    return result;
  }

  DeviceRef._();

  factory DeviceRef.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DeviceRef()..mergeFromBuffer(data, registry);
  factory DeviceRef.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DeviceRef()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeviceRef',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: DeviceRef.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'userId')
    ..aOS(2, _omitFieldNames ? '' : 'deviceId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeviceRef clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeviceRef copyWith(void Function(DeviceRef) updates) =>
      super.copyWith((message) => updates(message as DeviceRef)) as DeviceRef;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use DeviceRef() / DeviceRef.new instead')
  static DeviceRef create() => DeviceRef._();
  static $pb.GeneratedMessage $_createMessage() => DeviceRef._();
  @$core.override
  DeviceRef createEmptyInstance() => DeviceRef._();
  @$core.pragma('dart2js:noInline')
  static DeviceRef getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeviceRef>(DeviceRef.$_createMessage);
  static DeviceRef? _defaultInstance;

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
}

/// Where a channel's group stands.
class GroupState extends $pb.GeneratedMessage {
  factory GroupState({
    $core.String? channelId,
    $fixnum.Int64? epoch,
    $core.List<$core.int>? groupInfo,
    $fixnum.Int64? groupInfoEpoch,
    $fixnum.Int64? generation,
  }) {
    final result = GroupState._();
    if (channelId != null) result.channelId = channelId;
    if (epoch != null) result.epoch = epoch;
    if (groupInfo != null) result.groupInfo = groupInfo;
    if (groupInfoEpoch != null) result.groupInfoEpoch = groupInfoEpoch;
    if (generation != null) result.generation = generation;
    return result;
  }

  GroupState._();

  factory GroupState.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GroupState()..mergeFromBuffer(data, registry);
  factory GroupState.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GroupState()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GroupState',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: GroupState.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'channelId')
    ..aInt64(2, _omitFieldNames ? '' : 'epoch')
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'groupInfo', $pb.PbFieldType.OY)
    ..aInt64(4, _omitFieldNames ? '' : 'groupInfoEpoch')
    ..aInt64(5, _omitFieldNames ? '' : 'generation')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GroupState clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GroupState copyWith(void Function(GroupState) updates) =>
      super.copyWith((message) => updates(message as GroupState)) as GroupState;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GroupState() / GroupState.new instead')
  static GroupState create() => GroupState._();
  static $pb.GeneratedMessage $_createMessage() => GroupState._();
  @$core.override
  GroupState createEmptyInstance() => GroupState._();
  @$core.pragma('dart2js:noInline')
  static GroupState getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GroupState>(GroupState.$_createMessage);
  static GroupState? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get channelId => $_getSZ(0);
  @$pb.TagNumber(1)
  set channelId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasChannelId() => $_has(0);
  @$pb.TagNumber(1)
  void clearChannelId() => $_clearField(1);

  /// The epoch the next commit must be made in.
  @$pb.TagNumber(2)
  $fixnum.Int64 get epoch => $_getI64(1);
  @$pb.TagNumber(2)
  set epoch($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEpoch() => $_has(1);
  @$pb.TagNumber(2)
  void clearEpoch() => $_clearField(2);

  /// The latest published MLS GroupInfo.
  @$pb.TagNumber(3)
  $core.List<$core.int> get groupInfo => $_getN(2);
  @$pb.TagNumber(3)
  set groupInfo($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasGroupInfo() => $_has(2);
  @$pb.TagNumber(3)
  void clearGroupInfo() => $_clearField(3);

  /// The epoch group_info describes; behind epoch until a member publishes a newer one.
  @$pb.TagNumber(4)
  $fixnum.Int64 get groupInfoEpoch => $_getI64(3);
  @$pb.TagNumber(4)
  set groupInfoEpoch($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasGroupInfoEpoch() => $_has(3);
  @$pb.TagNumber(4)
  void clearGroupInfoEpoch() => $_clearField(4);

  /// The group's generation, which its MLS group id names.
  @$pb.TagNumber(5)
  $fixnum.Int64 get generation => $_getI64(4);
  @$pb.TagNumber(5)
  set generation($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasGeneration() => $_has(4);
  @$pb.TagNumber(5)
  void clearGeneration() => $_clearField(5);
}

/// One accepted commit.
class GroupCommit extends $pb.GeneratedMessage {
  factory GroupCommit({
    $fixnum.Int64? epoch,
    $core.List<$core.int>? message,
  }) {
    final result = GroupCommit._();
    if (epoch != null) result.epoch = epoch;
    if (message != null) result.message = message;
    return result;
  }

  GroupCommit._();

  factory GroupCommit.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GroupCommit()..mergeFromBuffer(data, registry);
  factory GroupCommit.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GroupCommit()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GroupCommit',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: GroupCommit.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'epoch')
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'message', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GroupCommit clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GroupCommit copyWith(void Function(GroupCommit) updates) =>
      super.copyWith((message) => updates(message as GroupCommit))
          as GroupCommit;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GroupCommit() / GroupCommit.new instead')
  static GroupCommit create() => GroupCommit._();
  static $pb.GeneratedMessage $_createMessage() => GroupCommit._();
  @$core.override
  GroupCommit createEmptyInstance() => GroupCommit._();
  @$core.pragma('dart2js:noInline')
  static GroupCommit getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GroupCommit>(
          GroupCommit.$_createMessage);
  static GroupCommit? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get epoch => $_getI64(0);
  @$pb.TagNumber(1)
  set epoch($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEpoch() => $_has(0);
  @$pb.TagNumber(1)
  void clearEpoch() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get message => $_getN(1);
  @$pb.TagNumber(2)
  set message($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);
}

/// A key package claimed for one device.
class ClaimedKeyPackage extends $pb.GeneratedMessage {
  factory ClaimedKeyPackage({
    $core.String? userId,
    $core.String? deviceId,
    $core.List<$core.int>? keyPackage,
  }) {
    final result = ClaimedKeyPackage._();
    if (userId != null) result.userId = userId;
    if (deviceId != null) result.deviceId = deviceId;
    if (keyPackage != null) result.keyPackage = keyPackage;
    return result;
  }

  ClaimedKeyPackage._();

  factory ClaimedKeyPackage.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ClaimedKeyPackage()..mergeFromBuffer(data, registry);
  factory ClaimedKeyPackage.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ClaimedKeyPackage()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ClaimedKeyPackage',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: ClaimedKeyPackage.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'userId')
    ..aOS(2, _omitFieldNames ? '' : 'deviceId')
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'keyPackage', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClaimedKeyPackage clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClaimedKeyPackage copyWith(void Function(ClaimedKeyPackage) updates) =>
      super.copyWith((message) => updates(message as ClaimedKeyPackage))
          as ClaimedKeyPackage;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ClaimedKeyPackage() / ClaimedKeyPackage.new instead')
  static ClaimedKeyPackage create() => ClaimedKeyPackage._();
  static $pb.GeneratedMessage $_createMessage() => ClaimedKeyPackage._();
  @$core.override
  ClaimedKeyPackage createEmptyInstance() => ClaimedKeyPackage._();
  @$core.pragma('dart2js:noInline')
  static ClaimedKeyPackage getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ClaimedKeyPackage>(
          ClaimedKeyPackage.$_createMessage);
  static ClaimedKeyPackage? _defaultInstance;

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
  $core.List<$core.int> get keyPackage => $_getN(2);
  @$pb.TagNumber(3)
  set keyPackage($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasKeyPackage() => $_has(2);
  @$pb.TagNumber(3)
  void clearKeyPackage() => $_clearField(3);
}

/// A Welcome waiting for this device.
class PendingWelcome extends $pb.GeneratedMessage {
  factory PendingWelcome({
    $core.String? welcomeId,
    $core.String? channelId,
    $fixnum.Int64? epoch,
    $core.List<$core.int>? welcome,
  }) {
    final result = PendingWelcome._();
    if (welcomeId != null) result.welcomeId = welcomeId;
    if (channelId != null) result.channelId = channelId;
    if (epoch != null) result.epoch = epoch;
    if (welcome != null) result.welcome = welcome;
    return result;
  }

  PendingWelcome._();

  factory PendingWelcome.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PendingWelcome()..mergeFromBuffer(data, registry);
  factory PendingWelcome.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PendingWelcome()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PendingWelcome',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: PendingWelcome.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'welcomeId')
    ..aOS(2, _omitFieldNames ? '' : 'channelId')
    ..aInt64(3, _omitFieldNames ? '' : 'epoch')
    ..a<$core.List<$core.int>>(
        4, _omitFieldNames ? '' : 'welcome', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PendingWelcome clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PendingWelcome copyWith(void Function(PendingWelcome) updates) =>
      super.copyWith((message) => updates(message as PendingWelcome))
          as PendingWelcome;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PendingWelcome() / PendingWelcome.new instead')
  static PendingWelcome create() => PendingWelcome._();
  static $pb.GeneratedMessage $_createMessage() => PendingWelcome._();
  @$core.override
  PendingWelcome createEmptyInstance() => PendingWelcome._();
  @$core.pragma('dart2js:noInline')
  static PendingWelcome getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PendingWelcome>(
          PendingWelcome.$_createMessage);
  static PendingWelcome? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get welcomeId => $_getSZ(0);
  @$pb.TagNumber(1)
  set welcomeId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasWelcomeId() => $_has(0);
  @$pb.TagNumber(1)
  void clearWelcomeId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get channelId => $_getSZ(1);
  @$pb.TagNumber(2)
  set channelId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasChannelId() => $_has(1);
  @$pb.TagNumber(2)
  void clearChannelId() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get epoch => $_getI64(2);
  @$pb.TagNumber(3)
  set epoch($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasEpoch() => $_has(2);
  @$pb.TagNumber(3)
  void clearEpoch() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.List<$core.int> get welcome => $_getN(3);
  @$pb.TagNumber(4)
  set welcome($core.List<$core.int> value) => $_setBytes(3, value);
  @$pb.TagNumber(4)
  $core.bool hasWelcome() => $_has(3);
  @$pb.TagNumber(4)
  void clearWelcome() => $_clearField(4);
}

/// Starts a group.
class CreateGroupRequest extends $pb.GeneratedMessage {
  factory CreateGroupRequest({
    $core.String? channelId,
    $core.List<$core.int>? groupInfo,
  }) {
    final result = CreateGroupRequest._();
    if (channelId != null) result.channelId = channelId;
    if (groupInfo != null) result.groupInfo = groupInfo;
    return result;
  }

  CreateGroupRequest._();

  factory CreateGroupRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreateGroupRequest()..mergeFromBuffer(data, registry);
  factory CreateGroupRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreateGroupRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateGroupRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: CreateGroupRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'channelId')
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'groupInfo', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateGroupRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateGroupRequest copyWith(void Function(CreateGroupRequest) updates) =>
      super.copyWith((message) => updates(message as CreateGroupRequest))
          as CreateGroupRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use CreateGroupRequest() / CreateGroupRequest.new instead')
  static CreateGroupRequest create() => CreateGroupRequest._();
  static $pb.GeneratedMessage $_createMessage() => CreateGroupRequest._();
  @$core.override
  CreateGroupRequest createEmptyInstance() => CreateGroupRequest._();
  @$core.pragma('dart2js:noInline')
  static CreateGroupRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateGroupRequest>(
          CreateGroupRequest.$_createMessage);
  static CreateGroupRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get channelId => $_getSZ(0);
  @$pb.TagNumber(1)
  set channelId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasChannelId() => $_has(0);
  @$pb.TagNumber(1)
  void clearChannelId() => $_clearField(1);

  /// The new group's signed MLS GroupInfo.
  @$pb.TagNumber(2)
  $core.List<$core.int> get groupInfo => $_getN(1);
  @$pb.TagNumber(2)
  set groupInfo($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasGroupInfo() => $_has(1);
  @$pb.TagNumber(2)
  void clearGroupInfo() => $_clearField(2);
}

/// The new group's state.
class CreateGroupResponse extends $pb.GeneratedMessage {
  factory CreateGroupResponse({
    GroupState? state,
  }) {
    final result = CreateGroupResponse._();
    if (state != null) result.state = state;
    return result;
  }

  CreateGroupResponse._();

  factory CreateGroupResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreateGroupResponse()..mergeFromBuffer(data, registry);
  factory CreateGroupResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreateGroupResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateGroupResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: CreateGroupResponse.$_createMessage)
    ..aOM<GroupState>(1, _omitFieldNames ? '' : 'state',
        subBuilder: GroupState.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateGroupResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateGroupResponse copyWith(void Function(CreateGroupResponse) updates) =>
      super.copyWith((message) => updates(message as CreateGroupResponse))
          as CreateGroupResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use CreateGroupResponse() / CreateGroupResponse.new instead')
  static CreateGroupResponse create() => CreateGroupResponse._();
  static $pb.GeneratedMessage $_createMessage() => CreateGroupResponse._();
  @$core.override
  CreateGroupResponse createEmptyInstance() => CreateGroupResponse._();
  @$core.pragma('dart2js:noInline')
  static CreateGroupResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateGroupResponse>(
          CreateGroupResponse.$_createMessage);
  static CreateGroupResponse? _defaultInstance;

  @$pb.TagNumber(1)
  GroupState get state => $_getN(0);
  @$pb.TagNumber(1)
  set state(GroupState value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasState() => $_has(0);
  @$pb.TagNumber(1)
  void clearState() => $_clearField(1);
  @$pb.TagNumber(1)
  GroupState ensureState() => $_ensure(0);
}

/// Asks where a group stands.
class GetGroupStateRequest extends $pb.GeneratedMessage {
  factory GetGroupStateRequest({
    $core.String? channelId,
  }) {
    final result = GetGroupStateRequest._();
    if (channelId != null) result.channelId = channelId;
    return result;
  }

  GetGroupStateRequest._();

  factory GetGroupStateRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetGroupStateRequest()..mergeFromBuffer(data, registry);
  factory GetGroupStateRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetGroupStateRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetGroupStateRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: GetGroupStateRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'channelId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetGroupStateRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetGroupStateRequest copyWith(void Function(GetGroupStateRequest) updates) =>
      super.copyWith((message) => updates(message as GetGroupStateRequest))
          as GetGroupStateRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetGroupStateRequest() / GetGroupStateRequest.new instead')
  static GetGroupStateRequest create() => GetGroupStateRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetGroupStateRequest._();
  @$core.override
  GetGroupStateRequest createEmptyInstance() => GetGroupStateRequest._();
  @$core.pragma('dart2js:noInline')
  static GetGroupStateRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetGroupStateRequest>(
          GetGroupStateRequest.$_createMessage);
  static GetGroupStateRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get channelId => $_getSZ(0);
  @$pb.TagNumber(1)
  set channelId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasChannelId() => $_has(0);
  @$pb.TagNumber(1)
  void clearChannelId() => $_clearField(1);
}

/// The group's state.
class GetGroupStateResponse extends $pb.GeneratedMessage {
  factory GetGroupStateResponse({
    GroupState? state,
  }) {
    final result = GetGroupStateResponse._();
    if (state != null) result.state = state;
    return result;
  }

  GetGroupStateResponse._();

  factory GetGroupStateResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetGroupStateResponse()..mergeFromBuffer(data, registry);
  factory GetGroupStateResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetGroupStateResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetGroupStateResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: GetGroupStateResponse.$_createMessage)
    ..aOM<GroupState>(1, _omitFieldNames ? '' : 'state',
        subBuilder: GroupState.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetGroupStateResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetGroupStateResponse copyWith(
          void Function(GetGroupStateResponse) updates) =>
      super.copyWith((message) => updates(message as GetGroupStateResponse))
          as GetGroupStateResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetGroupStateResponse() / GetGroupStateResponse.new instead')
  static GetGroupStateResponse create() => GetGroupStateResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetGroupStateResponse._();
  @$core.override
  GetGroupStateResponse createEmptyInstance() => GetGroupStateResponse._();
  @$core.pragma('dart2js:noInline')
  static GetGroupStateResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetGroupStateResponse>(
          GetGroupStateResponse.$_createMessage);
  static GetGroupStateResponse? _defaultInstance;

  @$pb.TagNumber(1)
  GroupState get state => $_getN(0);
  @$pb.TagNumber(1)
  set state(GroupState value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasState() => $_has(0);
  @$pb.TagNumber(1)
  void clearState() => $_clearField(1);
  @$pb.TagNumber(1)
  GroupState ensureState() => $_ensure(0);
}

/// Submits a commit.
class SubmitCommitRequest extends $pb.GeneratedMessage {
  factory SubmitCommitRequest({
    $core.String? channelId,
    $core.List<$core.int>? commit,
    $core.List<$core.int>? welcome,
    $core.Iterable<DeviceRef>? welcomeRecipients,
  }) {
    final result = SubmitCommitRequest._();
    if (channelId != null) result.channelId = channelId;
    if (commit != null) result.commit = commit;
    if (welcome != null) result.welcome = welcome;
    if (welcomeRecipients != null)
      result.welcomeRecipients.addAll(welcomeRecipients);
    return result;
  }

  SubmitCommitRequest._();

  factory SubmitCommitRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SubmitCommitRequest()..mergeFromBuffer(data, registry);
  factory SubmitCommitRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SubmitCommitRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SubmitCommitRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: SubmitCommitRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'channelId')
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'commit', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'welcome', $pb.PbFieldType.OY)
    ..pPM<DeviceRef>(4, _omitFieldNames ? '' : 'welcomeRecipients',
        subBuilder: DeviceRef.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubmitCommitRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubmitCommitRequest copyWith(void Function(SubmitCommitRequest) updates) =>
      super.copyWith((message) => updates(message as SubmitCommitRequest))
          as SubmitCommitRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use SubmitCommitRequest() / SubmitCommitRequest.new instead')
  static SubmitCommitRequest create() => SubmitCommitRequest._();
  static $pb.GeneratedMessage $_createMessage() => SubmitCommitRequest._();
  @$core.override
  SubmitCommitRequest createEmptyInstance() => SubmitCommitRequest._();
  @$core.pragma('dart2js:noInline')
  static SubmitCommitRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SubmitCommitRequest>(
          SubmitCommitRequest.$_createMessage);
  static SubmitCommitRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get channelId => $_getSZ(0);
  @$pb.TagNumber(1)
  set channelId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasChannelId() => $_has(0);
  @$pb.TagNumber(1)
  void clearChannelId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get commit => $_getN(1);
  @$pb.TagNumber(2)
  set commit($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCommit() => $_has(1);
  @$pb.TagNumber(2)
  void clearCommit() => $_clearField(2);

  /// For the devices the commit adds, if any.
  @$pb.TagNumber(3)
  $core.List<$core.int> get welcome => $_getN(2);
  @$pb.TagNumber(3)
  set welcome($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasWelcome() => $_has(2);
  @$pb.TagNumber(3)
  void clearWelcome() => $_clearField(3);

  /// Which devices those are: the server cannot tell from the Welcome.
  @$pb.TagNumber(4)
  $pb.PbList<DeviceRef> get welcomeRecipients => $_getList(3);
}

/// The group's epoch now that the commit is accepted.
class SubmitCommitResponse extends $pb.GeneratedMessage {
  factory SubmitCommitResponse({
    $fixnum.Int64? epoch,
  }) {
    final result = SubmitCommitResponse._();
    if (epoch != null) result.epoch = epoch;
    return result;
  }

  SubmitCommitResponse._();

  factory SubmitCommitResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SubmitCommitResponse()..mergeFromBuffer(data, registry);
  factory SubmitCommitResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SubmitCommitResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SubmitCommitResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: SubmitCommitResponse.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'epoch')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubmitCommitResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubmitCommitResponse copyWith(void Function(SubmitCommitResponse) updates) =>
      super.copyWith((message) => updates(message as SubmitCommitResponse))
          as SubmitCommitResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SubmitCommitResponse() / SubmitCommitResponse.new instead')
  static SubmitCommitResponse create() => SubmitCommitResponse._();
  static $pb.GeneratedMessage $_createMessage() => SubmitCommitResponse._();
  @$core.override
  SubmitCommitResponse createEmptyInstance() => SubmitCommitResponse._();
  @$core.pragma('dart2js:noInline')
  static SubmitCommitResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SubmitCommitResponse>(
          SubmitCommitResponse.$_createMessage);
  static SubmitCommitResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get epoch => $_getI64(0);
  @$pb.TagNumber(1)
  set epoch($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEpoch() => $_has(0);
  @$pb.TagNumber(1)
  void clearEpoch() => $_clearField(1);
}

/// Publishes a group info.
class PutGroupInfoRequest extends $pb.GeneratedMessage {
  factory PutGroupInfoRequest({
    $core.String? channelId,
    $core.List<$core.int>? groupInfo,
  }) {
    final result = PutGroupInfoRequest._();
    if (channelId != null) result.channelId = channelId;
    if (groupInfo != null) result.groupInfo = groupInfo;
    return result;
  }

  PutGroupInfoRequest._();

  factory PutGroupInfoRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PutGroupInfoRequest()..mergeFromBuffer(data, registry);
  factory PutGroupInfoRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PutGroupInfoRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PutGroupInfoRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: PutGroupInfoRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'channelId')
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'groupInfo', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PutGroupInfoRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PutGroupInfoRequest copyWith(void Function(PutGroupInfoRequest) updates) =>
      super.copyWith((message) => updates(message as PutGroupInfoRequest))
          as PutGroupInfoRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use PutGroupInfoRequest() / PutGroupInfoRequest.new instead')
  static PutGroupInfoRequest create() => PutGroupInfoRequest._();
  static $pb.GeneratedMessage $_createMessage() => PutGroupInfoRequest._();
  @$core.override
  PutGroupInfoRequest createEmptyInstance() => PutGroupInfoRequest._();
  @$core.pragma('dart2js:noInline')
  static PutGroupInfoRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PutGroupInfoRequest>(
          PutGroupInfoRequest.$_createMessage);
  static PutGroupInfoRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get channelId => $_getSZ(0);
  @$pb.TagNumber(1)
  set channelId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasChannelId() => $_has(0);
  @$pb.TagNumber(1)
  void clearChannelId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get groupInfo => $_getN(1);
  @$pb.TagNumber(2)
  set groupInfo($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasGroupInfo() => $_has(1);
  @$pb.TagNumber(2)
  void clearGroupInfo() => $_clearField(2);
}

/// The group's state.
class PutGroupInfoResponse extends $pb.GeneratedMessage {
  factory PutGroupInfoResponse({
    GroupState? state,
  }) {
    final result = PutGroupInfoResponse._();
    if (state != null) result.state = state;
    return result;
  }

  PutGroupInfoResponse._();

  factory PutGroupInfoResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PutGroupInfoResponse()..mergeFromBuffer(data, registry);
  factory PutGroupInfoResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PutGroupInfoResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PutGroupInfoResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: PutGroupInfoResponse.$_createMessage)
    ..aOM<GroupState>(1, _omitFieldNames ? '' : 'state',
        subBuilder: GroupState.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PutGroupInfoResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PutGroupInfoResponse copyWith(void Function(PutGroupInfoResponse) updates) =>
      super.copyWith((message) => updates(message as PutGroupInfoResponse))
          as PutGroupInfoResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use PutGroupInfoResponse() / PutGroupInfoResponse.new instead')
  static PutGroupInfoResponse create() => PutGroupInfoResponse._();
  static $pb.GeneratedMessage $_createMessage() => PutGroupInfoResponse._();
  @$core.override
  PutGroupInfoResponse createEmptyInstance() => PutGroupInfoResponse._();
  @$core.pragma('dart2js:noInline')
  static PutGroupInfoResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PutGroupInfoResponse>(
          PutGroupInfoResponse.$_createMessage);
  static PutGroupInfoResponse? _defaultInstance;

  @$pb.TagNumber(1)
  GroupState get state => $_getN(0);
  @$pb.TagNumber(1)
  set state(GroupState value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasState() => $_has(0);
  @$pb.TagNumber(1)
  void clearState() => $_clearField(1);
  @$pb.TagNumber(1)
  GroupState ensureState() => $_ensure(0);
}

/// Asks for commits from an epoch on.
class SyncGroupRequest extends $pb.GeneratedMessage {
  factory SyncGroupRequest({
    $core.String? channelId,
    $fixnum.Int64? fromEpoch,
    $fixnum.Int64? generation,
  }) {
    final result = SyncGroupRequest._();
    if (channelId != null) result.channelId = channelId;
    if (fromEpoch != null) result.fromEpoch = fromEpoch;
    if (generation != null) result.generation = generation;
    return result;
  }

  SyncGroupRequest._();

  factory SyncGroupRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SyncGroupRequest()..mergeFromBuffer(data, registry);
  factory SyncGroupRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SyncGroupRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SyncGroupRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: SyncGroupRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'channelId')
    ..aInt64(2, _omitFieldNames ? '' : 'fromEpoch')
    ..aInt64(3, _omitFieldNames ? '' : 'generation')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SyncGroupRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SyncGroupRequest copyWith(void Function(SyncGroupRequest) updates) =>
      super.copyWith((message) => updates(message as SyncGroupRequest))
          as SyncGroupRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SyncGroupRequest() / SyncGroupRequest.new instead')
  static SyncGroupRequest create() => SyncGroupRequest._();
  static $pb.GeneratedMessage $_createMessage() => SyncGroupRequest._();
  @$core.override
  SyncGroupRequest createEmptyInstance() => SyncGroupRequest._();
  @$core.pragma('dart2js:noInline')
  static SyncGroupRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SyncGroupRequest>(
          SyncGroupRequest.$_createMessage);
  static SyncGroupRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get channelId => $_getSZ(0);
  @$pb.TagNumber(1)
  set channelId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasChannelId() => $_has(0);
  @$pb.TagNumber(1)
  void clearChannelId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get fromEpoch => $_getI64(1);
  @$pb.TagNumber(2)
  set fromEpoch($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFromEpoch() => $_has(1);
  @$pb.TagNumber(2)
  void clearFromEpoch() => $_clearField(2);

  /// The generation this device's group is in.
  @$pb.TagNumber(3)
  $fixnum.Int64 get generation => $_getI64(2);
  @$pb.TagNumber(3)
  set generation($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasGeneration() => $_has(2);
  @$pb.TagNumber(3)
  void clearGeneration() => $_clearField(3);
}

/// Commits from the requested epoch on, oldest first — possibly one page of many.
class SyncGroupResponse extends $pb.GeneratedMessage {
  factory SyncGroupResponse({
    $fixnum.Int64? epoch,
    $core.Iterable<GroupCommit>? commits,
    $core.bool? resyncRequired,
    $fixnum.Int64? generation,
  }) {
    final result = SyncGroupResponse._();
    if (epoch != null) result.epoch = epoch;
    if (commits != null) result.commits.addAll(commits);
    if (resyncRequired != null) result.resyncRequired = resyncRequired;
    if (generation != null) result.generation = generation;
    return result;
  }

  SyncGroupResponse._();

  factory SyncGroupResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SyncGroupResponse()..mergeFromBuffer(data, registry);
  factory SyncGroupResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SyncGroupResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SyncGroupResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: SyncGroupResponse.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'epoch')
    ..pPM<GroupCommit>(2, _omitFieldNames ? '' : 'commits',
        subBuilder: GroupCommit.$_createMessage)
    ..aOB(3, _omitFieldNames ? '' : 'resyncRequired')
    ..aInt64(4, _omitFieldNames ? '' : 'generation')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SyncGroupResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SyncGroupResponse copyWith(void Function(SyncGroupResponse) updates) =>
      super.copyWith((message) => updates(message as SyncGroupResponse))
          as SyncGroupResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SyncGroupResponse() / SyncGroupResponse.new instead')
  static SyncGroupResponse create() => SyncGroupResponse._();
  static $pb.GeneratedMessage $_createMessage() => SyncGroupResponse._();
  @$core.override
  SyncGroupResponse createEmptyInstance() => SyncGroupResponse._();
  @$core.pragma('dart2js:noInline')
  static SyncGroupResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SyncGroupResponse>(
          SyncGroupResponse.$_createMessage);
  static SyncGroupResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get epoch => $_getI64(0);
  @$pb.TagNumber(1)
  set epoch($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEpoch() => $_has(0);
  @$pb.TagNumber(1)
  void clearEpoch() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<GroupCommit> get commits => $_getList(1);

  /// Commits this device needs have been pruned, or its group is of an older generation: rejoin, in
  /// the generation below.
  @$pb.TagNumber(3)
  $core.bool get resyncRequired => $_getBF(2);
  @$pb.TagNumber(3)
  set resyncRequired($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasResyncRequired() => $_has(2);
  @$pb.TagNumber(3)
  void clearResyncRequired() => $_clearField(3);

  /// The group's current generation.
  @$pb.TagNumber(4)
  $fixnum.Int64 get generation => $_getI64(3);
  @$pb.TagNumber(4)
  set generation($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasGeneration() => $_has(3);
  @$pb.TagNumber(4)
  void clearGeneration() => $_clearField(4);
}

/// Asks who belongs in a group.
class GetGroupRosterRequest extends $pb.GeneratedMessage {
  factory GetGroupRosterRequest({
    $core.String? channelId,
  }) {
    final result = GetGroupRosterRequest._();
    if (channelId != null) result.channelId = channelId;
    return result;
  }

  GetGroupRosterRequest._();

  factory GetGroupRosterRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetGroupRosterRequest()..mergeFromBuffer(data, registry);
  factory GetGroupRosterRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetGroupRosterRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetGroupRosterRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: GetGroupRosterRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'channelId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetGroupRosterRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetGroupRosterRequest copyWith(
          void Function(GetGroupRosterRequest) updates) =>
      super.copyWith((message) => updates(message as GetGroupRosterRequest))
          as GetGroupRosterRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetGroupRosterRequest() / GetGroupRosterRequest.new instead')
  static GetGroupRosterRequest create() => GetGroupRosterRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetGroupRosterRequest._();
  @$core.override
  GetGroupRosterRequest createEmptyInstance() => GetGroupRosterRequest._();
  @$core.pragma('dart2js:noInline')
  static GetGroupRosterRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetGroupRosterRequest>(
          GetGroupRosterRequest.$_createMessage);
  static GetGroupRosterRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get channelId => $_getSZ(0);
  @$pb.TagNumber(1)
  set channelId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasChannelId() => $_has(0);
  @$pb.TagNumber(1)
  void clearChannelId() => $_clearField(1);
}

/// Every device that should be in the group.
class GetGroupRosterResponse extends $pb.GeneratedMessage {
  factory GetGroupRosterResponse({
    $core.String? channelId,
    $core.Iterable<DeviceRef>? devices,
  }) {
    final result = GetGroupRosterResponse._();
    if (channelId != null) result.channelId = channelId;
    if (devices != null) result.devices.addAll(devices);
    return result;
  }

  GetGroupRosterResponse._();

  factory GetGroupRosterResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetGroupRosterResponse()..mergeFromBuffer(data, registry);
  factory GetGroupRosterResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetGroupRosterResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetGroupRosterResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: GetGroupRosterResponse.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'channelId')
    ..pPM<DeviceRef>(2, _omitFieldNames ? '' : 'devices',
        subBuilder: DeviceRef.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetGroupRosterResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetGroupRosterResponse copyWith(
          void Function(GetGroupRosterResponse) updates) =>
      super.copyWith((message) => updates(message as GetGroupRosterResponse))
          as GetGroupRosterResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetGroupRosterResponse() / GetGroupRosterResponse.new instead')
  static GetGroupRosterResponse create() => GetGroupRosterResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetGroupRosterResponse._();
  @$core.override
  GetGroupRosterResponse createEmptyInstance() => GetGroupRosterResponse._();
  @$core.pragma('dart2js:noInline')
  static GetGroupRosterResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetGroupRosterResponse>(
          GetGroupRosterResponse.$_createMessage);
  static GetGroupRosterResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get channelId => $_getSZ(0);
  @$pb.TagNumber(1)
  set channelId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasChannelId() => $_has(0);
  @$pb.TagNumber(1)
  void clearChannelId() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<DeviceRef> get devices => $_getList(1);
}

/// Uploads key packages, each an MLSMessage-wrapped KeyPackage.
class UploadKeyPackagesRequest extends $pb.GeneratedMessage {
  factory UploadKeyPackagesRequest({
    $core.Iterable<$core.List<$core.int>>? keyPackages,
    $core.List<$core.int>? lastResort,
  }) {
    final result = UploadKeyPackagesRequest._();
    if (keyPackages != null) result.keyPackages.addAll(keyPackages);
    if (lastResort != null) result.lastResort = lastResort;
    return result;
  }

  UploadKeyPackagesRequest._();

  factory UploadKeyPackagesRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UploadKeyPackagesRequest()..mergeFromBuffer(data, registry);
  factory UploadKeyPackagesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UploadKeyPackagesRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UploadKeyPackagesRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: UploadKeyPackagesRequest.$_createMessage)
    ..p<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'keyPackages', $pb.PbFieldType.PY)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'lastResort', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UploadKeyPackagesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UploadKeyPackagesRequest copyWith(
          void Function(UploadKeyPackagesRequest) updates) =>
      super.copyWith((message) => updates(message as UploadKeyPackagesRequest))
          as UploadKeyPackagesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use UploadKeyPackagesRequest() / UploadKeyPackagesRequest.new instead')
  static UploadKeyPackagesRequest create() => UploadKeyPackagesRequest._();
  static $pb.GeneratedMessage $_createMessage() => UploadKeyPackagesRequest._();
  @$core.override
  UploadKeyPackagesRequest createEmptyInstance() =>
      UploadKeyPackagesRequest._();
  @$core.pragma('dart2js:noInline')
  static UploadKeyPackagesRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UploadKeyPackagesRequest>(
          UploadKeyPackagesRequest.$_createMessage);
  static UploadKeyPackagesRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.List<$core.int>> get keyPackages => $_getList(0);

  /// A reusable package to hand out when the one-time ones run out.
  @$pb.TagNumber(2)
  $core.List<$core.int> get lastResort => $_getN(1);
  @$pb.TagNumber(2)
  set lastResort($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLastResort() => $_has(1);
  @$pb.TagNumber(2)
  void clearLastResort() => $_clearField(2);
}

/// How many one-time packages this device now has.
class UploadKeyPackagesResponse extends $pb.GeneratedMessage {
  factory UploadKeyPackagesResponse({
    $core.int? oneTime,
  }) {
    final result = UploadKeyPackagesResponse._();
    if (oneTime != null) result.oneTime = oneTime;
    return result;
  }

  UploadKeyPackagesResponse._();

  factory UploadKeyPackagesResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UploadKeyPackagesResponse()..mergeFromBuffer(data, registry);
  factory UploadKeyPackagesResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UploadKeyPackagesResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UploadKeyPackagesResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: UploadKeyPackagesResponse.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'oneTime')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UploadKeyPackagesResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UploadKeyPackagesResponse copyWith(
          void Function(UploadKeyPackagesResponse) updates) =>
      super.copyWith((message) => updates(message as UploadKeyPackagesResponse))
          as UploadKeyPackagesResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use UploadKeyPackagesResponse() / UploadKeyPackagesResponse.new instead')
  static UploadKeyPackagesResponse create() => UploadKeyPackagesResponse._();
  static $pb.GeneratedMessage $_createMessage() =>
      UploadKeyPackagesResponse._();
  @$core.override
  UploadKeyPackagesResponse createEmptyInstance() =>
      UploadKeyPackagesResponse._();
  @$core.pragma('dart2js:noInline')
  static UploadKeyPackagesResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UploadKeyPackagesResponse>(
          UploadKeyPackagesResponse.$_createMessage);
  static UploadKeyPackagesResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get oneTime => $_getIZ(0);
  @$pb.TagNumber(1)
  set oneTime($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOneTime() => $_has(0);
  @$pb.TagNumber(1)
  void clearOneTime() => $_clearField(1);
}

/// Claims key packages.
class ClaimKeyPackagesRequest extends $pb.GeneratedMessage {
  factory ClaimKeyPackagesRequest({
    $core.String? channelId,
    $core.Iterable<DeviceRef>? devices,
  }) {
    final result = ClaimKeyPackagesRequest._();
    if (channelId != null) result.channelId = channelId;
    if (devices != null) result.devices.addAll(devices);
    return result;
  }

  ClaimKeyPackagesRequest._();

  factory ClaimKeyPackagesRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ClaimKeyPackagesRequest()..mergeFromBuffer(data, registry);
  factory ClaimKeyPackagesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ClaimKeyPackagesRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ClaimKeyPackagesRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: ClaimKeyPackagesRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'channelId')
    ..pPM<DeviceRef>(2, _omitFieldNames ? '' : 'devices',
        subBuilder: DeviceRef.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClaimKeyPackagesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClaimKeyPackagesRequest copyWith(
          void Function(ClaimKeyPackagesRequest) updates) =>
      super.copyWith((message) => updates(message as ClaimKeyPackagesRequest))
          as ClaimKeyPackagesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ClaimKeyPackagesRequest() / ClaimKeyPackagesRequest.new instead')
  static ClaimKeyPackagesRequest create() => ClaimKeyPackagesRequest._();
  static $pb.GeneratedMessage $_createMessage() => ClaimKeyPackagesRequest._();
  @$core.override
  ClaimKeyPackagesRequest createEmptyInstance() => ClaimKeyPackagesRequest._();
  @$core.pragma('dart2js:noInline')
  static ClaimKeyPackagesRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ClaimKeyPackagesRequest>(
          ClaimKeyPackagesRequest.$_createMessage);
  static ClaimKeyPackagesRequest? _defaultInstance;

  /// The channel whose group the devices are being added to.
  @$pb.TagNumber(1)
  $core.String get channelId => $_getSZ(0);
  @$pb.TagNumber(1)
  set channelId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasChannelId() => $_has(0);
  @$pb.TagNumber(1)
  void clearChannelId() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<DeviceRef> get devices => $_getList(1);
}

/// One per device that had one; devices with none are left out.
class ClaimKeyPackagesResponse extends $pb.GeneratedMessage {
  factory ClaimKeyPackagesResponse({
    $core.Iterable<ClaimedKeyPackage>? keyPackages,
  }) {
    final result = ClaimKeyPackagesResponse._();
    if (keyPackages != null) result.keyPackages.addAll(keyPackages);
    return result;
  }

  ClaimKeyPackagesResponse._();

  factory ClaimKeyPackagesResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ClaimKeyPackagesResponse()..mergeFromBuffer(data, registry);
  factory ClaimKeyPackagesResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ClaimKeyPackagesResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ClaimKeyPackagesResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: ClaimKeyPackagesResponse.$_createMessage)
    ..pPM<ClaimedKeyPackage>(1, _omitFieldNames ? '' : 'keyPackages',
        subBuilder: ClaimedKeyPackage.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClaimKeyPackagesResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClaimKeyPackagesResponse copyWith(
          void Function(ClaimKeyPackagesResponse) updates) =>
      super.copyWith((message) => updates(message as ClaimKeyPackagesResponse))
          as ClaimKeyPackagesResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ClaimKeyPackagesResponse() / ClaimKeyPackagesResponse.new instead')
  static ClaimKeyPackagesResponse create() => ClaimKeyPackagesResponse._();
  static $pb.GeneratedMessage $_createMessage() => ClaimKeyPackagesResponse._();
  @$core.override
  ClaimKeyPackagesResponse createEmptyInstance() =>
      ClaimKeyPackagesResponse._();
  @$core.pragma('dart2js:noInline')
  static ClaimKeyPackagesResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ClaimKeyPackagesResponse>(
          ClaimKeyPackagesResponse.$_createMessage);
  static ClaimKeyPackagesResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<ClaimedKeyPackage> get keyPackages => $_getList(0);
}

/// Asks how many one-time packages are left.
class GetKeyPackageCountRequest extends $pb.GeneratedMessage {
  factory GetKeyPackageCountRequest() => GetKeyPackageCountRequest._();

  GetKeyPackageCountRequest._();

  factory GetKeyPackageCountRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetKeyPackageCountRequest()..mergeFromBuffer(data, registry);
  factory GetKeyPackageCountRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetKeyPackageCountRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetKeyPackageCountRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: GetKeyPackageCountRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetKeyPackageCountRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetKeyPackageCountRequest copyWith(
          void Function(GetKeyPackageCountRequest) updates) =>
      super.copyWith((message) => updates(message as GetKeyPackageCountRequest))
          as GetKeyPackageCountRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetKeyPackageCountRequest() / GetKeyPackageCountRequest.new instead')
  static GetKeyPackageCountRequest create() => GetKeyPackageCountRequest._();
  static $pb.GeneratedMessage $_createMessage() =>
      GetKeyPackageCountRequest._();
  @$core.override
  GetKeyPackageCountRequest createEmptyInstance() =>
      GetKeyPackageCountRequest._();
  @$core.pragma('dart2js:noInline')
  static GetKeyPackageCountRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetKeyPackageCountRequest>(
          GetKeyPackageCountRequest.$_createMessage);
  static GetKeyPackageCountRequest? _defaultInstance;
}

/// How many one-time packages are left.
class GetKeyPackageCountResponse extends $pb.GeneratedMessage {
  factory GetKeyPackageCountResponse({
    $core.int? oneTime,
  }) {
    final result = GetKeyPackageCountResponse._();
    if (oneTime != null) result.oneTime = oneTime;
    return result;
  }

  GetKeyPackageCountResponse._();

  factory GetKeyPackageCountResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetKeyPackageCountResponse()..mergeFromBuffer(data, registry);
  factory GetKeyPackageCountResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetKeyPackageCountResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetKeyPackageCountResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: GetKeyPackageCountResponse.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'oneTime')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetKeyPackageCountResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetKeyPackageCountResponse copyWith(
          void Function(GetKeyPackageCountResponse) updates) =>
      super.copyWith(
              (message) => updates(message as GetKeyPackageCountResponse))
          as GetKeyPackageCountResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetKeyPackageCountResponse() / GetKeyPackageCountResponse.new instead')
  static GetKeyPackageCountResponse create() => GetKeyPackageCountResponse._();
  static $pb.GeneratedMessage $_createMessage() =>
      GetKeyPackageCountResponse._();
  @$core.override
  GetKeyPackageCountResponse createEmptyInstance() =>
      GetKeyPackageCountResponse._();
  @$core.pragma('dart2js:noInline')
  static GetKeyPackageCountResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetKeyPackageCountResponse>(
          GetKeyPackageCountResponse.$_createMessage);
  static GetKeyPackageCountResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get oneTime => $_getIZ(0);
  @$pb.TagNumber(1)
  set oneTime($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOneTime() => $_has(0);
  @$pb.TagNumber(1)
  void clearOneTime() => $_clearField(1);
}

/// Asks for waiting Welcomes.
class ListWelcomesRequest extends $pb.GeneratedMessage {
  factory ListWelcomesRequest() => ListWelcomesRequest._();

  ListWelcomesRequest._();

  factory ListWelcomesRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListWelcomesRequest()..mergeFromBuffer(data, registry);
  factory ListWelcomesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListWelcomesRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListWelcomesRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: ListWelcomesRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListWelcomesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListWelcomesRequest copyWith(void Function(ListWelcomesRequest) updates) =>
      super.copyWith((message) => updates(message as ListWelcomesRequest))
          as ListWelcomesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use ListWelcomesRequest() / ListWelcomesRequest.new instead')
  static ListWelcomesRequest create() => ListWelcomesRequest._();
  static $pb.GeneratedMessage $_createMessage() => ListWelcomesRequest._();
  @$core.override
  ListWelcomesRequest createEmptyInstance() => ListWelcomesRequest._();
  @$core.pragma('dart2js:noInline')
  static ListWelcomesRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListWelcomesRequest>(
          ListWelcomesRequest.$_createMessage);
  static ListWelcomesRequest? _defaultInstance;
}

/// The waiting Welcomes.
class ListWelcomesResponse extends $pb.GeneratedMessage {
  factory ListWelcomesResponse({
    $core.Iterable<PendingWelcome>? welcomes,
  }) {
    final result = ListWelcomesResponse._();
    if (welcomes != null) result.welcomes.addAll(welcomes);
    return result;
  }

  ListWelcomesResponse._();

  factory ListWelcomesResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListWelcomesResponse()..mergeFromBuffer(data, registry);
  factory ListWelcomesResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListWelcomesResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListWelcomesResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: ListWelcomesResponse.$_createMessage)
    ..pPM<PendingWelcome>(1, _omitFieldNames ? '' : 'welcomes',
        subBuilder: PendingWelcome.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListWelcomesResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListWelcomesResponse copyWith(void Function(ListWelcomesResponse) updates) =>
      super.copyWith((message) => updates(message as ListWelcomesResponse))
          as ListWelcomesResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ListWelcomesResponse() / ListWelcomesResponse.new instead')
  static ListWelcomesResponse create() => ListWelcomesResponse._();
  static $pb.GeneratedMessage $_createMessage() => ListWelcomesResponse._();
  @$core.override
  ListWelcomesResponse createEmptyInstance() => ListWelcomesResponse._();
  @$core.pragma('dart2js:noInline')
  static ListWelcomesResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListWelcomesResponse>(
          ListWelcomesResponse.$_createMessage);
  static ListWelcomesResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<PendingWelcome> get welcomes => $_getList(0);
}

/// Acknowledges Welcomes.
class AckWelcomesRequest extends $pb.GeneratedMessage {
  factory AckWelcomesRequest({
    $core.Iterable<$core.String>? welcomeIds,
  }) {
    final result = AckWelcomesRequest._();
    if (welcomeIds != null) result.welcomeIds.addAll(welcomeIds);
    return result;
  }

  AckWelcomesRequest._();

  factory AckWelcomesRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AckWelcomesRequest()..mergeFromBuffer(data, registry);
  factory AckWelcomesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AckWelcomesRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AckWelcomesRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: AckWelcomesRequest.$_createMessage)
    ..pPS(1, _omitFieldNames ? '' : 'welcomeIds')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AckWelcomesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AckWelcomesRequest copyWith(void Function(AckWelcomesRequest) updates) =>
      super.copyWith((message) => updates(message as AckWelcomesRequest))
          as AckWelcomesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use AckWelcomesRequest() / AckWelcomesRequest.new instead')
  static AckWelcomesRequest create() => AckWelcomesRequest._();
  static $pb.GeneratedMessage $_createMessage() => AckWelcomesRequest._();
  @$core.override
  AckWelcomesRequest createEmptyInstance() => AckWelcomesRequest._();
  @$core.pragma('dart2js:noInline')
  static AckWelcomesRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AckWelcomesRequest>(
          AckWelcomesRequest.$_createMessage);
  static AckWelcomesRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get welcomeIds => $_getList(0);
}

/// A human-readable confirmation.
class AckWelcomesResponse extends $pb.GeneratedMessage {
  factory AckWelcomesResponse({
    $core.String? message,
  }) {
    final result = AckWelcomesResponse._();
    if (message != null) result.message = message;
    return result;
  }

  AckWelcomesResponse._();

  factory AckWelcomesResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AckWelcomesResponse()..mergeFromBuffer(data, registry);
  factory AckWelcomesResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AckWelcomesResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AckWelcomesResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: AckWelcomesResponse.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AckWelcomesResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AckWelcomesResponse copyWith(void Function(AckWelcomesResponse) updates) =>
      super.copyWith((message) => updates(message as AckWelcomesResponse))
          as AckWelcomesResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use AckWelcomesResponse() / AckWelcomesResponse.new instead')
  static AckWelcomesResponse create() => AckWelcomesResponse._();
  static $pb.GeneratedMessage $_createMessage() => AckWelcomesResponse._();
  @$core.override
  AckWelcomesResponse createEmptyInstance() => AckWelcomesResponse._();
  @$core.pragma('dart2js:noInline')
  static AckWelcomesResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AckWelcomesResponse>(
          AckWelcomesResponse.$_createMessage);
  static AckWelcomesResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get message => $_getSZ(0);
  @$pb.TagNumber(1)
  set message($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);
}

/// Asks which generation a channel's group is in.
class GetGroupGenerationRequest extends $pb.GeneratedMessage {
  factory GetGroupGenerationRequest({
    $core.String? channelId,
  }) {
    final result = GetGroupGenerationRequest._();
    if (channelId != null) result.channelId = channelId;
    return result;
  }

  GetGroupGenerationRequest._();

  factory GetGroupGenerationRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetGroupGenerationRequest()..mergeFromBuffer(data, registry);
  factory GetGroupGenerationRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetGroupGenerationRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetGroupGenerationRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: GetGroupGenerationRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'channelId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetGroupGenerationRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetGroupGenerationRequest copyWith(
          void Function(GetGroupGenerationRequest) updates) =>
      super.copyWith((message) => updates(message as GetGroupGenerationRequest))
          as GetGroupGenerationRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetGroupGenerationRequest() / GetGroupGenerationRequest.new instead')
  static GetGroupGenerationRequest create() => GetGroupGenerationRequest._();
  static $pb.GeneratedMessage $_createMessage() =>
      GetGroupGenerationRequest._();
  @$core.override
  GetGroupGenerationRequest createEmptyInstance() =>
      GetGroupGenerationRequest._();
  @$core.pragma('dart2js:noInline')
  static GetGroupGenerationRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetGroupGenerationRequest>(
          GetGroupGenerationRequest.$_createMessage);
  static GetGroupGenerationRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get channelId => $_getSZ(0);
  @$pb.TagNumber(1)
  set channelId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasChannelId() => $_has(0);
  @$pb.TagNumber(1)
  void clearChannelId() => $_clearField(1);
}

/// The channel group's current generation.
class GetGroupGenerationResponse extends $pb.GeneratedMessage {
  factory GetGroupGenerationResponse({
    $fixnum.Int64? generation,
  }) {
    final result = GetGroupGenerationResponse._();
    if (generation != null) result.generation = generation;
    return result;
  }

  GetGroupGenerationResponse._();

  factory GetGroupGenerationResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetGroupGenerationResponse()..mergeFromBuffer(data, registry);
  factory GetGroupGenerationResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetGroupGenerationResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetGroupGenerationResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: GetGroupGenerationResponse.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'generation')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetGroupGenerationResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetGroupGenerationResponse copyWith(
          void Function(GetGroupGenerationResponse) updates) =>
      super.copyWith(
              (message) => updates(message as GetGroupGenerationResponse))
          as GetGroupGenerationResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetGroupGenerationResponse() / GetGroupGenerationResponse.new instead')
  static GetGroupGenerationResponse create() => GetGroupGenerationResponse._();
  static $pb.GeneratedMessage $_createMessage() =>
      GetGroupGenerationResponse._();
  @$core.override
  GetGroupGenerationResponse createEmptyInstance() =>
      GetGroupGenerationResponse._();
  @$core.pragma('dart2js:noInline')
  static GetGroupGenerationResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetGroupGenerationResponse>(
          GetGroupGenerationResponse.$_createMessage);
  static GetGroupGenerationResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get generation => $_getI64(0);
  @$pb.TagNumber(1)
  set generation($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasGeneration() => $_has(0);
  @$pb.TagNumber(1)
  void clearGeneration() => $_clearField(1);
}

/// Asks for a new generation of a channel's group.
class ResetGroupRequest extends $pb.GeneratedMessage {
  factory ResetGroupRequest({
    $core.String? channelId,
    $fixnum.Int64? generation,
    $fixnum.Int64? reportedEpoch,
    $core.List<$core.int>? reportedSha256,
  }) {
    final result = ResetGroupRequest._();
    if (channelId != null) result.channelId = channelId;
    if (generation != null) result.generation = generation;
    if (reportedEpoch != null) result.reportedEpoch = reportedEpoch;
    if (reportedSha256 != null) result.reportedSha256 = reportedSha256;
    return result;
  }

  ResetGroupRequest._();

  factory ResetGroupRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResetGroupRequest()..mergeFromBuffer(data, registry);
  factory ResetGroupRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResetGroupRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResetGroupRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: ResetGroupRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'channelId')
    ..aInt64(2, _omitFieldNames ? '' : 'generation')
    ..aInt64(3, _omitFieldNames ? '' : 'reportedEpoch')
    ..a<$core.List<$core.int>>(
        4, _omitFieldNames ? '' : 'reportedSha256', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResetGroupRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResetGroupRequest copyWith(void Function(ResetGroupRequest) updates) =>
      super.copyWith((message) => updates(message as ResetGroupRequest))
          as ResetGroupRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResetGroupRequest() / ResetGroupRequest.new instead')
  static ResetGroupRequest create() => ResetGroupRequest._();
  static $pb.GeneratedMessage $_createMessage() => ResetGroupRequest._();
  @$core.override
  ResetGroupRequest createEmptyInstance() => ResetGroupRequest._();
  @$core.pragma('dart2js:noInline')
  static ResetGroupRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResetGroupRequest>(
          ResetGroupRequest.$_createMessage);
  static ResetGroupRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get channelId => $_getSZ(0);
  @$pb.TagNumber(1)
  set channelId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasChannelId() => $_has(0);
  @$pb.TagNumber(1)
  void clearChannelId() => $_clearField(1);

  /// The generation the caller found broken; behind the current one, nothing is reset.
  @$pb.TagNumber(2)
  $fixnum.Int64 get generation => $_getI64(1);
  @$pb.TagNumber(2)
  set generation($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasGeneration() => $_has(1);
  @$pb.TagNumber(2)
  void clearGeneration() => $_clearField(2);

  /// The epoch of what the caller cannot get past: a commit made in it, or the group info describing it.
  @$pb.TagNumber(3)
  $fixnum.Int64 get reportedEpoch => $_getI64(2);
  @$pb.TagNumber(3)
  set reportedEpoch($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasReportedEpoch() => $_has(2);
  @$pb.TagNumber(3)
  void clearReportedEpoch() => $_clearField(3);

  /// SHA-256 of that commit or group info, exactly as the server holds it. Empty only for a channel
  /// manager resetting without a report.
  @$pb.TagNumber(4)
  $core.List<$core.int> get reportedSha256 => $_getN(3);
  @$pb.TagNumber(4)
  set reportedSha256($core.List<$core.int> value) => $_setBytes(3, value);
  @$pb.TagNumber(4)
  $core.bool hasReportedSha256() => $_has(3);
  @$pb.TagNumber(4)
  void clearReportedSha256() => $_clearField(4);
}

/// The generation the channel's group is in now.
class ResetGroupResponse extends $pb.GeneratedMessage {
  factory ResetGroupResponse({
    $fixnum.Int64? generation,
    $core.bool? reset,
  }) {
    final result = ResetGroupResponse._();
    if (generation != null) result.generation = generation;
    if (reset != null) result.reset = reset;
    return result;
  }

  ResetGroupResponse._();

  factory ResetGroupResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResetGroupResponse()..mergeFromBuffer(data, registry);
  factory ResetGroupResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResetGroupResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResetGroupResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: ResetGroupResponse.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'generation')
    ..aOB(2, _omitFieldNames ? '' : 'reset')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResetGroupResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResetGroupResponse copyWith(void Function(ResetGroupResponse) updates) =>
      super.copyWith((message) => updates(message as ResetGroupResponse))
          as ResetGroupResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResetGroupResponse() / ResetGroupResponse.new instead')
  static ResetGroupResponse create() => ResetGroupResponse._();
  static $pb.GeneratedMessage $_createMessage() => ResetGroupResponse._();
  @$core.override
  ResetGroupResponse createEmptyInstance() => ResetGroupResponse._();
  @$core.pragma('dart2js:noInline')
  static ResetGroupResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResetGroupResponse>(
          ResetGroupResponse.$_createMessage);
  static ResetGroupResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get generation => $_getI64(0);
  @$pb.TagNumber(1)
  set generation($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasGeneration() => $_has(0);
  @$pb.TagNumber(1)
  void clearGeneration() => $_clearField(1);

  /// True when this call started it; false when another reset had already moved past the caller's.
  @$pb.TagNumber(2)
  $core.bool get reset => $_getBF(1);
  @$pb.TagNumber(2)
  set reset($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasReset() => $_has(1);
  @$pb.TagNumber(2)
  void clearReset() => $_clearField(2);
}

/// One reset of a channel's group.
class GroupReset extends $pb.GeneratedMessage {
  factory GroupReset({
    $fixnum.Int64? generation,
    $1.Timestamp? resetAt,
    $core.String? requestedByUserId,
    $core.String? requestedByDeviceId,
    $core.String? reportedKind,
    $fixnum.Int64? reportedEpoch,
    $core.List<$core.int>? reportedSha256,
    $core.String? reportedSenderUserId,
    $core.String? reportedSenderDeviceId,
  }) {
    final result = GroupReset._();
    if (generation != null) result.generation = generation;
    if (resetAt != null) result.resetAt = resetAt;
    if (requestedByUserId != null) result.requestedByUserId = requestedByUserId;
    if (requestedByDeviceId != null)
      result.requestedByDeviceId = requestedByDeviceId;
    if (reportedKind != null) result.reportedKind = reportedKind;
    if (reportedEpoch != null) result.reportedEpoch = reportedEpoch;
    if (reportedSha256 != null) result.reportedSha256 = reportedSha256;
    if (reportedSenderUserId != null)
      result.reportedSenderUserId = reportedSenderUserId;
    if (reportedSenderDeviceId != null)
      result.reportedSenderDeviceId = reportedSenderDeviceId;
    return result;
  }

  GroupReset._();

  factory GroupReset.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GroupReset()..mergeFromBuffer(data, registry);
  factory GroupReset.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GroupReset()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GroupReset',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: GroupReset.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'generation')
    ..aOM<$1.Timestamp>(2, _omitFieldNames ? '' : 'resetAt',
        subBuilder: $1.Timestamp.$_createMessage)
    ..aOS(3, _omitFieldNames ? '' : 'requestedByUserId')
    ..aOS(4, _omitFieldNames ? '' : 'requestedByDeviceId')
    ..aOS(5, _omitFieldNames ? '' : 'reportedKind')
    ..aInt64(6, _omitFieldNames ? '' : 'reportedEpoch')
    ..a<$core.List<$core.int>>(
        7, _omitFieldNames ? '' : 'reportedSha256', $pb.PbFieldType.OY)
    ..aOS(8, _omitFieldNames ? '' : 'reportedSenderUserId')
    ..aOS(9, _omitFieldNames ? '' : 'reportedSenderDeviceId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GroupReset clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GroupReset copyWith(void Function(GroupReset) updates) =>
      super.copyWith((message) => updates(message as GroupReset)) as GroupReset;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GroupReset() / GroupReset.new instead')
  static GroupReset create() => GroupReset._();
  static $pb.GeneratedMessage $_createMessage() => GroupReset._();
  @$core.override
  GroupReset createEmptyInstance() => GroupReset._();
  @$core.pragma('dart2js:noInline')
  static GroupReset getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GroupReset>(GroupReset.$_createMessage);
  static GroupReset? _defaultInstance;

  /// The generation it started.
  @$pb.TagNumber(1)
  $fixnum.Int64 get generation => $_getI64(0);
  @$pb.TagNumber(1)
  set generation($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasGeneration() => $_has(0);
  @$pb.TagNumber(1)
  void clearGeneration() => $_clearField(1);

  @$pb.TagNumber(2)
  $1.Timestamp get resetAt => $_getN(1);
  @$pb.TagNumber(2)
  set resetAt($1.Timestamp value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasResetAt() => $_has(1);
  @$pb.TagNumber(2)
  void clearResetAt() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.Timestamp ensureResetAt() => $_ensure(1);

  /// Who asked, from which device.
  @$pb.TagNumber(3)
  $core.String get requestedByUserId => $_getSZ(2);
  @$pb.TagNumber(3)
  set requestedByUserId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRequestedByUserId() => $_has(2);
  @$pb.TagNumber(3)
  void clearRequestedByUserId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get requestedByDeviceId => $_getSZ(3);
  @$pb.TagNumber(4)
  set requestedByDeviceId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasRequestedByDeviceId() => $_has(3);
  @$pb.TagNumber(4)
  void clearRequestedByDeviceId() => $_clearField(4);

  /// What they reported: "commit", "group_info", or empty for a manager's reset without a report.
  /// An open set.
  @$pb.TagNumber(5)
  $core.String get reportedKind => $_getSZ(4);
  @$pb.TagNumber(5)
  set reportedKind($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasReportedKind() => $_has(4);
  @$pb.TagNumber(5)
  void clearReportedKind() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get reportedEpoch => $_getI64(5);
  @$pb.TagNumber(6)
  set reportedEpoch($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasReportedEpoch() => $_has(5);
  @$pb.TagNumber(6)
  void clearReportedEpoch() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.List<$core.int> get reportedSha256 => $_getN(6);
  @$pb.TagNumber(7)
  set reportedSha256($core.List<$core.int> value) => $_setBytes(6, value);
  @$pb.TagNumber(7)
  $core.bool hasReportedSha256() => $_has(6);
  @$pb.TagNumber(7)
  void clearReportedSha256() => $_clearField(7);

  /// For a reported commit: the account and device that submitted it, as the server recorded them.
  /// Empty when unknown.
  @$pb.TagNumber(8)
  $core.String get reportedSenderUserId => $_getSZ(7);
  @$pb.TagNumber(8)
  set reportedSenderUserId($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasReportedSenderUserId() => $_has(7);
  @$pb.TagNumber(8)
  void clearReportedSenderUserId() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get reportedSenderDeviceId => $_getSZ(8);
  @$pb.TagNumber(9)
  set reportedSenderDeviceId($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasReportedSenderDeviceId() => $_has(8);
  @$pb.TagNumber(9)
  void clearReportedSenderDeviceId() => $_clearField(9);
}

/// Asks for a channel group's resets.
class ListGroupResetsRequest extends $pb.GeneratedMessage {
  factory ListGroupResetsRequest({
    $core.String? channelId,
  }) {
    final result = ListGroupResetsRequest._();
    if (channelId != null) result.channelId = channelId;
    return result;
  }

  ListGroupResetsRequest._();

  factory ListGroupResetsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListGroupResetsRequest()..mergeFromBuffer(data, registry);
  factory ListGroupResetsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListGroupResetsRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListGroupResetsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: ListGroupResetsRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'channelId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListGroupResetsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListGroupResetsRequest copyWith(
          void Function(ListGroupResetsRequest) updates) =>
      super.copyWith((message) => updates(message as ListGroupResetsRequest))
          as ListGroupResetsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ListGroupResetsRequest() / ListGroupResetsRequest.new instead')
  static ListGroupResetsRequest create() => ListGroupResetsRequest._();
  static $pb.GeneratedMessage $_createMessage() => ListGroupResetsRequest._();
  @$core.override
  ListGroupResetsRequest createEmptyInstance() => ListGroupResetsRequest._();
  @$core.pragma('dart2js:noInline')
  static ListGroupResetsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListGroupResetsRequest>(
          ListGroupResetsRequest.$_createMessage);
  static ListGroupResetsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get channelId => $_getSZ(0);
  @$pb.TagNumber(1)
  set channelId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasChannelId() => $_has(0);
  @$pb.TagNumber(1)
  void clearChannelId() => $_clearField(1);
}

/// The resets, newest first.
class ListGroupResetsResponse extends $pb.GeneratedMessage {
  factory ListGroupResetsResponse({
    $core.Iterable<GroupReset>? resets,
  }) {
    final result = ListGroupResetsResponse._();
    if (resets != null) result.resets.addAll(resets);
    return result;
  }

  ListGroupResetsResponse._();

  factory ListGroupResetsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListGroupResetsResponse()..mergeFromBuffer(data, registry);
  factory ListGroupResetsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListGroupResetsResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListGroupResetsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: ListGroupResetsResponse.$_createMessage)
    ..pPM<GroupReset>(1, _omitFieldNames ? '' : 'resets',
        subBuilder: GroupReset.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListGroupResetsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListGroupResetsResponse copyWith(
          void Function(ListGroupResetsResponse) updates) =>
      super.copyWith((message) => updates(message as ListGroupResetsResponse))
          as ListGroupResetsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ListGroupResetsResponse() / ListGroupResetsResponse.new instead')
  static ListGroupResetsResponse create() => ListGroupResetsResponse._();
  static $pb.GeneratedMessage $_createMessage() => ListGroupResetsResponse._();
  @$core.override
  ListGroupResetsResponse createEmptyInstance() => ListGroupResetsResponse._();
  @$core.pragma('dart2js:noInline')
  static ListGroupResetsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListGroupResetsResponse>(
          ListGroupResetsResponse.$_createMessage);
  static ListGroupResetsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<GroupReset> get resets => $_getList(0);
}

/// A device, or every device of an account, kept out of a channel's group.
class GroupBan extends $pb.GeneratedMessage {
  factory GroupBan({
    $core.String? userId,
    $core.String? deviceId,
    $core.String? bannedByUserId,
    $1.Timestamp? bannedAt,
  }) {
    final result = GroupBan._();
    if (userId != null) result.userId = userId;
    if (deviceId != null) result.deviceId = deviceId;
    if (bannedByUserId != null) result.bannedByUserId = bannedByUserId;
    if (bannedAt != null) result.bannedAt = bannedAt;
    return result;
  }

  GroupBan._();

  factory GroupBan.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GroupBan()..mergeFromBuffer(data, registry);
  factory GroupBan.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GroupBan()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GroupBan',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: GroupBan.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'userId')
    ..aOS(2, _omitFieldNames ? '' : 'deviceId')
    ..aOS(3, _omitFieldNames ? '' : 'bannedByUserId')
    ..aOM<$1.Timestamp>(4, _omitFieldNames ? '' : 'bannedAt',
        subBuilder: $1.Timestamp.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GroupBan clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GroupBan copyWith(void Function(GroupBan) updates) =>
      super.copyWith((message) => updates(message as GroupBan)) as GroupBan;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GroupBan() / GroupBan.new instead')
  static GroupBan create() => GroupBan._();
  static $pb.GeneratedMessage $_createMessage() => GroupBan._();
  @$core.override
  GroupBan createEmptyInstance() => GroupBan._();
  @$core.pragma('dart2js:noInline')
  static GroupBan getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GroupBan>(GroupBan.$_createMessage);
  static GroupBan? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get userId => $_getSZ(0);
  @$pb.TagNumber(1)
  set userId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => $_clearField(1);

  /// Empty for every device of the account.
  @$pb.TagNumber(2)
  $core.String get deviceId => $_getSZ(1);
  @$pb.TagNumber(2)
  set deviceId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDeviceId() => $_has(1);
  @$pb.TagNumber(2)
  void clearDeviceId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get bannedByUserId => $_getSZ(2);
  @$pb.TagNumber(3)
  set bannedByUserId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasBannedByUserId() => $_has(2);
  @$pb.TagNumber(3)
  void clearBannedByUserId() => $_clearField(3);

  @$pb.TagNumber(4)
  $1.Timestamp get bannedAt => $_getN(3);
  @$pb.TagNumber(4)
  set bannedAt($1.Timestamp value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasBannedAt() => $_has(3);
  @$pb.TagNumber(4)
  void clearBannedAt() => $_clearField(4);
  @$pb.TagNumber(4)
  $1.Timestamp ensureBannedAt() => $_ensure(3);
}

/// Bans a device, or an account, from a channel's group.
class BanFromGroupRequest extends $pb.GeneratedMessage {
  factory BanFromGroupRequest({
    $core.String? channelId,
    $core.String? userId,
    $core.String? deviceId,
  }) {
    final result = BanFromGroupRequest._();
    if (channelId != null) result.channelId = channelId;
    if (userId != null) result.userId = userId;
    if (deviceId != null) result.deviceId = deviceId;
    return result;
  }

  BanFromGroupRequest._();

  factory BanFromGroupRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BanFromGroupRequest()..mergeFromBuffer(data, registry);
  factory BanFromGroupRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BanFromGroupRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BanFromGroupRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: BanFromGroupRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'channelId')
    ..aOS(2, _omitFieldNames ? '' : 'userId')
    ..aOS(3, _omitFieldNames ? '' : 'deviceId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BanFromGroupRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BanFromGroupRequest copyWith(void Function(BanFromGroupRequest) updates) =>
      super.copyWith((message) => updates(message as BanFromGroupRequest))
          as BanFromGroupRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use BanFromGroupRequest() / BanFromGroupRequest.new instead')
  static BanFromGroupRequest create() => BanFromGroupRequest._();
  static $pb.GeneratedMessage $_createMessage() => BanFromGroupRequest._();
  @$core.override
  BanFromGroupRequest createEmptyInstance() => BanFromGroupRequest._();
  @$core.pragma('dart2js:noInline')
  static BanFromGroupRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BanFromGroupRequest>(
          BanFromGroupRequest.$_createMessage);
  static BanFromGroupRequest? _defaultInstance;

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

  /// Empty for every device of the account.
  @$pb.TagNumber(3)
  $core.String get deviceId => $_getSZ(2);
  @$pb.TagNumber(3)
  set deviceId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDeviceId() => $_has(2);
  @$pb.TagNumber(3)
  void clearDeviceId() => $_clearField(3);
}

/// Whether anything changed (false when the ban was already there).
class BanFromGroupResponse extends $pb.GeneratedMessage {
  factory BanFromGroupResponse({
    $core.bool? changed,
  }) {
    final result = BanFromGroupResponse._();
    if (changed != null) result.changed = changed;
    return result;
  }

  BanFromGroupResponse._();

  factory BanFromGroupResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BanFromGroupResponse()..mergeFromBuffer(data, registry);
  factory BanFromGroupResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BanFromGroupResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BanFromGroupResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: BanFromGroupResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'changed')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BanFromGroupResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BanFromGroupResponse copyWith(void Function(BanFromGroupResponse) updates) =>
      super.copyWith((message) => updates(message as BanFromGroupResponse))
          as BanFromGroupResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use BanFromGroupResponse() / BanFromGroupResponse.new instead')
  static BanFromGroupResponse create() => BanFromGroupResponse._();
  static $pb.GeneratedMessage $_createMessage() => BanFromGroupResponse._();
  @$core.override
  BanFromGroupResponse createEmptyInstance() => BanFromGroupResponse._();
  @$core.pragma('dart2js:noInline')
  static BanFromGroupResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BanFromGroupResponse>(
          BanFromGroupResponse.$_createMessage);
  static BanFromGroupResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get changed => $_getBF(0);
  @$pb.TagNumber(1)
  set changed($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasChanged() => $_has(0);
  @$pb.TagNumber(1)
  void clearChanged() => $_clearField(1);
}

/// Lifts a ban.
class UnbanFromGroupRequest extends $pb.GeneratedMessage {
  factory UnbanFromGroupRequest({
    $core.String? channelId,
    $core.String? userId,
    $core.String? deviceId,
  }) {
    final result = UnbanFromGroupRequest._();
    if (channelId != null) result.channelId = channelId;
    if (userId != null) result.userId = userId;
    if (deviceId != null) result.deviceId = deviceId;
    return result;
  }

  UnbanFromGroupRequest._();

  factory UnbanFromGroupRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UnbanFromGroupRequest()..mergeFromBuffer(data, registry);
  factory UnbanFromGroupRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UnbanFromGroupRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UnbanFromGroupRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: UnbanFromGroupRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'channelId')
    ..aOS(2, _omitFieldNames ? '' : 'userId')
    ..aOS(3, _omitFieldNames ? '' : 'deviceId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UnbanFromGroupRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UnbanFromGroupRequest copyWith(
          void Function(UnbanFromGroupRequest) updates) =>
      super.copyWith((message) => updates(message as UnbanFromGroupRequest))
          as UnbanFromGroupRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use UnbanFromGroupRequest() / UnbanFromGroupRequest.new instead')
  static UnbanFromGroupRequest create() => UnbanFromGroupRequest._();
  static $pb.GeneratedMessage $_createMessage() => UnbanFromGroupRequest._();
  @$core.override
  UnbanFromGroupRequest createEmptyInstance() => UnbanFromGroupRequest._();
  @$core.pragma('dart2js:noInline')
  static UnbanFromGroupRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UnbanFromGroupRequest>(
          UnbanFromGroupRequest.$_createMessage);
  static UnbanFromGroupRequest? _defaultInstance;

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

  /// Empty for the ban on every device of the account.
  @$pb.TagNumber(3)
  $core.String get deviceId => $_getSZ(2);
  @$pb.TagNumber(3)
  set deviceId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDeviceId() => $_has(2);
  @$pb.TagNumber(3)
  void clearDeviceId() => $_clearField(3);
}

/// Whether anything changed (false when there was no such ban).
class UnbanFromGroupResponse extends $pb.GeneratedMessage {
  factory UnbanFromGroupResponse({
    $core.bool? changed,
  }) {
    final result = UnbanFromGroupResponse._();
    if (changed != null) result.changed = changed;
    return result;
  }

  UnbanFromGroupResponse._();

  factory UnbanFromGroupResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UnbanFromGroupResponse()..mergeFromBuffer(data, registry);
  factory UnbanFromGroupResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UnbanFromGroupResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UnbanFromGroupResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: UnbanFromGroupResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'changed')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UnbanFromGroupResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UnbanFromGroupResponse copyWith(
          void Function(UnbanFromGroupResponse) updates) =>
      super.copyWith((message) => updates(message as UnbanFromGroupResponse))
          as UnbanFromGroupResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use UnbanFromGroupResponse() / UnbanFromGroupResponse.new instead')
  static UnbanFromGroupResponse create() => UnbanFromGroupResponse._();
  static $pb.GeneratedMessage $_createMessage() => UnbanFromGroupResponse._();
  @$core.override
  UnbanFromGroupResponse createEmptyInstance() => UnbanFromGroupResponse._();
  @$core.pragma('dart2js:noInline')
  static UnbanFromGroupResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UnbanFromGroupResponse>(
          UnbanFromGroupResponse.$_createMessage);
  static UnbanFromGroupResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get changed => $_getBF(0);
  @$pb.TagNumber(1)
  set changed($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasChanged() => $_has(0);
  @$pb.TagNumber(1)
  void clearChanged() => $_clearField(1);
}

/// Asks for a channel group's bans.
class ListGroupBansRequest extends $pb.GeneratedMessage {
  factory ListGroupBansRequest({
    $core.String? channelId,
  }) {
    final result = ListGroupBansRequest._();
    if (channelId != null) result.channelId = channelId;
    return result;
  }

  ListGroupBansRequest._();

  factory ListGroupBansRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListGroupBansRequest()..mergeFromBuffer(data, registry);
  factory ListGroupBansRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListGroupBansRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListGroupBansRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: ListGroupBansRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'channelId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListGroupBansRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListGroupBansRequest copyWith(void Function(ListGroupBansRequest) updates) =>
      super.copyWith((message) => updates(message as ListGroupBansRequest))
          as ListGroupBansRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ListGroupBansRequest() / ListGroupBansRequest.new instead')
  static ListGroupBansRequest create() => ListGroupBansRequest._();
  static $pb.GeneratedMessage $_createMessage() => ListGroupBansRequest._();
  @$core.override
  ListGroupBansRequest createEmptyInstance() => ListGroupBansRequest._();
  @$core.pragma('dart2js:noInline')
  static ListGroupBansRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListGroupBansRequest>(
          ListGroupBansRequest.$_createMessage);
  static ListGroupBansRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get channelId => $_getSZ(0);
  @$pb.TagNumber(1)
  set channelId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasChannelId() => $_has(0);
  @$pb.TagNumber(1)
  void clearChannelId() => $_clearField(1);
}

/// The bans.
class ListGroupBansResponse extends $pb.GeneratedMessage {
  factory ListGroupBansResponse({
    $core.Iterable<GroupBan>? bans,
  }) {
    final result = ListGroupBansResponse._();
    if (bans != null) result.bans.addAll(bans);
    return result;
  }

  ListGroupBansResponse._();

  factory ListGroupBansResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListGroupBansResponse()..mergeFromBuffer(data, registry);
  factory ListGroupBansResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListGroupBansResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListGroupBansResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: ListGroupBansResponse.$_createMessage)
    ..pPM<GroupBan>(1, _omitFieldNames ? '' : 'bans',
        subBuilder: GroupBan.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListGroupBansResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListGroupBansResponse copyWith(
          void Function(ListGroupBansResponse) updates) =>
      super.copyWith((message) => updates(message as ListGroupBansResponse))
          as ListGroupBansResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ListGroupBansResponse() / ListGroupBansResponse.new instead')
  static ListGroupBansResponse create() => ListGroupBansResponse._();
  static $pb.GeneratedMessage $_createMessage() => ListGroupBansResponse._();
  @$core.override
  ListGroupBansResponse createEmptyInstance() => ListGroupBansResponse._();
  @$core.pragma('dart2js:noInline')
  static ListGroupBansResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListGroupBansResponse>(
          ListGroupBansResponse.$_createMessage);
  static ListGroupBansResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<GroupBan> get bans => $_getList(0);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
