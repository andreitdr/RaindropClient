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
  }) {
    final result = GroupState._();
    if (channelId != null) result.channelId = channelId;
    if (epoch != null) result.epoch = epoch;
    if (groupInfo != null) result.groupInfo = groupInfo;
    if (groupInfoEpoch != null) result.groupInfoEpoch = groupInfoEpoch;
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
  }) {
    final result = SyncGroupRequest._();
    if (channelId != null) result.channelId = channelId;
    if (fromEpoch != null) result.fromEpoch = fromEpoch;
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
}

/// Commits from the requested epoch on, oldest first — possibly one page of many.
class SyncGroupResponse extends $pb.GeneratedMessage {
  factory SyncGroupResponse({
    $fixnum.Int64? epoch,
    $core.Iterable<GroupCommit>? commits,
    $core.bool? resyncRequired,
  }) {
    final result = SyncGroupResponse._();
    if (epoch != null) result.epoch = epoch;
    if (commits != null) result.commits.addAll(commits);
    if (resyncRequired != null) result.resyncRequired = resyncRequired;
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

  /// Commits this device needs have been pruned: rejoin by external commit.
  @$pb.TagNumber(3)
  $core.bool get resyncRequired => $_getBF(2);
  @$pb.TagNumber(3)
  set resyncRequired($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasResyncRequired() => $_has(2);
  @$pb.TagNumber(3)
  void clearResyncRequired() => $_clearField(3);
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

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
