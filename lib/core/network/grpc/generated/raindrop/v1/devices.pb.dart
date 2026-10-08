// This is a generated file - do not edit.
//
// Generated from raindrop/v1/devices.proto.

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

/// One device.
class Device extends $pb.GeneratedMessage {
  factory Device({
    $core.String? deviceId,
    $core.List<$core.int>? certificate,
    $1.Timestamp? createdAt,
  }) {
    final result = Device._();
    if (deviceId != null) result.deviceId = deviceId;
    if (certificate != null) result.certificate = certificate;
    if (createdAt != null) result.createdAt = createdAt;
    return result;
  }

  Device._();

  factory Device.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Device()..mergeFromBuffer(data, registry);
  factory Device.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Device()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Device',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: Device.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'deviceId')
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'certificate', $pb.PbFieldType.OY)
    ..aOM<$1.Timestamp>(3, _omitFieldNames ? '' : 'createdAt',
        subBuilder: $1.Timestamp.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Device clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Device copyWith(void Function(Device) updates) =>
      super.copyWith((message) => updates(message as Device)) as Device;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Device() / Device.new instead')
  static Device create() => Device._();
  static $pb.GeneratedMessage $_createMessage() => Device._();
  @$core.override
  Device createEmptyInstance() => Device._();
  @$core.pragma('dart2js:noInline')
  static Device getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Device>(Device.$_createMessage);
  static Device? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get deviceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set deviceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDeviceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearDeviceId() => $_clearField(1);

  /// Exactly as uploaded; clients verify it themselves.
  @$pb.TagNumber(2)
  $core.List<$core.int> get certificate => $_getN(1);
  @$pb.TagNumber(2)
  set certificate($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCertificate() => $_has(1);
  @$pb.TagNumber(2)
  void clearCertificate() => $_clearField(2);

  @$pb.TagNumber(3)
  $1.Timestamp get createdAt => $_getN(2);
  @$pb.TagNumber(3)
  set createdAt($1.Timestamp value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasCreatedAt() => $_has(2);
  @$pb.TagNumber(3)
  void clearCreatedAt() => $_clearField(3);
  @$pb.TagNumber(3)
  $1.Timestamp ensureCreatedAt() => $_ensure(2);
}

/// One user's identity key and active devices.
class UserDevices extends $pb.GeneratedMessage {
  factory UserDevices({
    $core.String? userId,
    $core.List<$core.int>? identityKey,
    $core.Iterable<Device>? devices,
  }) {
    final result = UserDevices._();
    if (userId != null) result.userId = userId;
    if (identityKey != null) result.identityKey = identityKey;
    if (devices != null) result.devices.addAll(devices);
    return result;
  }

  UserDevices._();

  factory UserDevices.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UserDevices()..mergeFromBuffer(data, registry);
  factory UserDevices.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UserDevices()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UserDevices',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: UserDevices.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'userId')
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'identityKey', $pb.PbFieldType.OY)
    ..pPM<Device>(3, _omitFieldNames ? '' : 'devices',
        subBuilder: Device.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UserDevices clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UserDevices copyWith(void Function(UserDevices) updates) =>
      super.copyWith((message) => updates(message as UserDevices))
          as UserDevices;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use UserDevices() / UserDevices.new instead')
  static UserDevices create() => UserDevices._();
  static $pb.GeneratedMessage $_createMessage() => UserDevices._();
  @$core.override
  UserDevices createEmptyInstance() => UserDevices._();
  @$core.pragma('dart2js:noInline')
  static UserDevices getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UserDevices>(
          UserDevices.$_createMessage);
  static UserDevices? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get userId => $_getSZ(0);
  @$pb.TagNumber(1)
  set userId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => $_clearField(1);

  /// Absent before their first device is registered.
  @$pb.TagNumber(2)
  $core.List<$core.int> get identityKey => $_getN(1);
  @$pb.TagNumber(2)
  set identityKey($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasIdentityKey() => $_has(1);
  @$pb.TagNumber(2)
  void clearIdentityKey() => $_clearField(2);

  /// Oldest first.
  @$pb.TagNumber(3)
  $pb.PbList<Device> get devices => $_getList(2);
}

/// Registers a device.
class RegisterDeviceRequest extends $pb.GeneratedMessage {
  factory RegisterDeviceRequest({
    $core.List<$core.int>? certificate,
  }) {
    final result = RegisterDeviceRequest._();
    if (certificate != null) result.certificate = certificate;
    return result;
  }

  RegisterDeviceRequest._();

  factory RegisterDeviceRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RegisterDeviceRequest()..mergeFromBuffer(data, registry);
  factory RegisterDeviceRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RegisterDeviceRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RegisterDeviceRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: RegisterDeviceRequest.$_createMessage)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'certificate', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RegisterDeviceRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RegisterDeviceRequest copyWith(
          void Function(RegisterDeviceRequest) updates) =>
      super.copyWith((message) => updates(message as RegisterDeviceRequest))
          as RegisterDeviceRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use RegisterDeviceRequest() / RegisterDeviceRequest.new instead')
  static RegisterDeviceRequest create() => RegisterDeviceRequest._();
  static $pb.GeneratedMessage $_createMessage() => RegisterDeviceRequest._();
  @$core.override
  RegisterDeviceRequest createEmptyInstance() => RegisterDeviceRequest._();
  @$core.pragma('dart2js:noInline')
  static RegisterDeviceRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RegisterDeviceRequest>(
          RegisterDeviceRequest.$_createMessage);
  static RegisterDeviceRequest? _defaultInstance;

  /// The device certificate, signed by the user's identity key.
  @$pb.TagNumber(1)
  $core.List<$core.int> get certificate => $_getN(0);
  @$pb.TagNumber(1)
  set certificate($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCertificate() => $_has(0);
  @$pb.TagNumber(1)
  void clearCertificate() => $_clearField(1);
}

/// The registered device.
class RegisterDeviceResponse extends $pb.GeneratedMessage {
  factory RegisterDeviceResponse({
    Device? device,
  }) {
    final result = RegisterDeviceResponse._();
    if (device != null) result.device = device;
    return result;
  }

  RegisterDeviceResponse._();

  factory RegisterDeviceResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RegisterDeviceResponse()..mergeFromBuffer(data, registry);
  factory RegisterDeviceResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RegisterDeviceResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RegisterDeviceResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: RegisterDeviceResponse.$_createMessage)
    ..aOM<Device>(1, _omitFieldNames ? '' : 'device',
        subBuilder: Device.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RegisterDeviceResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RegisterDeviceResponse copyWith(
          void Function(RegisterDeviceResponse) updates) =>
      super.copyWith((message) => updates(message as RegisterDeviceResponse))
          as RegisterDeviceResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use RegisterDeviceResponse() / RegisterDeviceResponse.new instead')
  static RegisterDeviceResponse create() => RegisterDeviceResponse._();
  static $pb.GeneratedMessage $_createMessage() => RegisterDeviceResponse._();
  @$core.override
  RegisterDeviceResponse createEmptyInstance() => RegisterDeviceResponse._();
  @$core.pragma('dart2js:noInline')
  static RegisterDeviceResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RegisterDeviceResponse>(
          RegisterDeviceResponse.$_createMessage);
  static RegisterDeviceResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Device get device => $_getN(0);
  @$pb.TagNumber(1)
  set device(Device value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasDevice() => $_has(0);
  @$pb.TagNumber(1)
  void clearDevice() => $_clearField(1);
  @$pb.TagNumber(1)
  Device ensureDevice() => $_ensure(0);
}

/// Asks for users' identity keys and devices.
class ListDevicesRequest extends $pb.GeneratedMessage {
  factory ListDevicesRequest({
    $core.Iterable<$core.String>? userIds,
  }) {
    final result = ListDevicesRequest._();
    if (userIds != null) result.userIds.addAll(userIds);
    return result;
  }

  ListDevicesRequest._();

  factory ListDevicesRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListDevicesRequest()..mergeFromBuffer(data, registry);
  factory ListDevicesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListDevicesRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListDevicesRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: ListDevicesRequest.$_createMessage)
    ..pPS(1, _omitFieldNames ? '' : 'userIds')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListDevicesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListDevicesRequest copyWith(void Function(ListDevicesRequest) updates) =>
      super.copyWith((message) => updates(message as ListDevicesRequest))
          as ListDevicesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ListDevicesRequest() / ListDevicesRequest.new instead')
  static ListDevicesRequest create() => ListDevicesRequest._();
  static $pb.GeneratedMessage $_createMessage() => ListDevicesRequest._();
  @$core.override
  ListDevicesRequest createEmptyInstance() => ListDevicesRequest._();
  @$core.pragma('dart2js:noInline')
  static ListDevicesRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListDevicesRequest>(
          ListDevicesRequest.$_createMessage);
  static ListDevicesRequest? _defaultInstance;

  /// At most 500.
  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get userIds => $_getList(0);
}

/// One entry per user asked about.
class ListDevicesResponse extends $pb.GeneratedMessage {
  factory ListDevicesResponse({
    $core.Iterable<UserDevices>? users,
  }) {
    final result = ListDevicesResponse._();
    if (users != null) result.users.addAll(users);
    return result;
  }

  ListDevicesResponse._();

  factory ListDevicesResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListDevicesResponse()..mergeFromBuffer(data, registry);
  factory ListDevicesResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListDevicesResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListDevicesResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: ListDevicesResponse.$_createMessage)
    ..pPM<UserDevices>(1, _omitFieldNames ? '' : 'users',
        subBuilder: UserDevices.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListDevicesResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListDevicesResponse copyWith(void Function(ListDevicesResponse) updates) =>
      super.copyWith((message) => updates(message as ListDevicesResponse))
          as ListDevicesResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use ListDevicesResponse() / ListDevicesResponse.new instead')
  static ListDevicesResponse create() => ListDevicesResponse._();
  static $pb.GeneratedMessage $_createMessage() => ListDevicesResponse._();
  @$core.override
  ListDevicesResponse createEmptyInstance() => ListDevicesResponse._();
  @$core.pragma('dart2js:noInline')
  static ListDevicesResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListDevicesResponse>(
          ListDevicesResponse.$_createMessage);
  static ListDevicesResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<UserDevices> get users => $_getList(0);
}

/// Revokes a device.
class RevokeDeviceRequest extends $pb.GeneratedMessage {
  factory RevokeDeviceRequest({
    $core.String? deviceId,
  }) {
    final result = RevokeDeviceRequest._();
    if (deviceId != null) result.deviceId = deviceId;
    return result;
  }

  RevokeDeviceRequest._();

  factory RevokeDeviceRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RevokeDeviceRequest()..mergeFromBuffer(data, registry);
  factory RevokeDeviceRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RevokeDeviceRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RevokeDeviceRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: RevokeDeviceRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'deviceId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RevokeDeviceRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RevokeDeviceRequest copyWith(void Function(RevokeDeviceRequest) updates) =>
      super.copyWith((message) => updates(message as RevokeDeviceRequest))
          as RevokeDeviceRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use RevokeDeviceRequest() / RevokeDeviceRequest.new instead')
  static RevokeDeviceRequest create() => RevokeDeviceRequest._();
  static $pb.GeneratedMessage $_createMessage() => RevokeDeviceRequest._();
  @$core.override
  RevokeDeviceRequest createEmptyInstance() => RevokeDeviceRequest._();
  @$core.pragma('dart2js:noInline')
  static RevokeDeviceRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RevokeDeviceRequest>(
          RevokeDeviceRequest.$_createMessage);
  static RevokeDeviceRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get deviceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set deviceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDeviceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearDeviceId() => $_clearField(1);
}

/// A human-readable confirmation.
class RevokeDeviceResponse extends $pb.GeneratedMessage {
  factory RevokeDeviceResponse({
    $core.String? message,
  }) {
    final result = RevokeDeviceResponse._();
    if (message != null) result.message = message;
    return result;
  }

  RevokeDeviceResponse._();

  factory RevokeDeviceResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RevokeDeviceResponse()..mergeFromBuffer(data, registry);
  factory RevokeDeviceResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RevokeDeviceResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RevokeDeviceResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: RevokeDeviceResponse.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RevokeDeviceResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RevokeDeviceResponse copyWith(void Function(RevokeDeviceResponse) updates) =>
      super.copyWith((message) => updates(message as RevokeDeviceResponse))
          as RevokeDeviceResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use RevokeDeviceResponse() / RevokeDeviceResponse.new instead')
  static RevokeDeviceResponse create() => RevokeDeviceResponse._();
  static $pb.GeneratedMessage $_createMessage() => RevokeDeviceResponse._();
  @$core.override
  RevokeDeviceResponse createEmptyInstance() => RevokeDeviceResponse._();
  @$core.pragma('dart2js:noInline')
  static RevokeDeviceResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RevokeDeviceResponse>(
          RevokeDeviceResponse.$_createMessage);
  static RevokeDeviceResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get message => $_getSZ(0);
  @$pb.TagNumber(1)
  set message($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);
}

/// Resets the user's identity.
class ResetIdentityRequest extends $pb.GeneratedMessage {
  factory ResetIdentityRequest({
    $core.String? password,
  }) {
    final result = ResetIdentityRequest._();
    if (password != null) result.password = password;
    return result;
  }

  ResetIdentityRequest._();

  factory ResetIdentityRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResetIdentityRequest()..mergeFromBuffer(data, registry);
  factory ResetIdentityRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResetIdentityRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResetIdentityRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: ResetIdentityRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'password')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResetIdentityRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResetIdentityRequest copyWith(void Function(ResetIdentityRequest) updates) =>
      super.copyWith((message) => updates(message as ResetIdentityRequest))
          as ResetIdentityRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ResetIdentityRequest() / ResetIdentityRequest.new instead')
  static ResetIdentityRequest create() => ResetIdentityRequest._();
  static $pb.GeneratedMessage $_createMessage() => ResetIdentityRequest._();
  @$core.override
  ResetIdentityRequest createEmptyInstance() => ResetIdentityRequest._();
  @$core.pragma('dart2js:noInline')
  static ResetIdentityRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResetIdentityRequest>(
          ResetIdentityRequest.$_createMessage);
  static ResetIdentityRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get password => $_getSZ(0);
  @$pb.TagNumber(1)
  set password($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPassword() => $_has(0);
  @$pb.TagNumber(1)
  void clearPassword() => $_clearField(1);
}

/// A human-readable confirmation.
class ResetIdentityResponse extends $pb.GeneratedMessage {
  factory ResetIdentityResponse({
    $core.String? message,
  }) {
    final result = ResetIdentityResponse._();
    if (message != null) result.message = message;
    return result;
  }

  ResetIdentityResponse._();

  factory ResetIdentityResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResetIdentityResponse()..mergeFromBuffer(data, registry);
  factory ResetIdentityResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResetIdentityResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResetIdentityResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: ResetIdentityResponse.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResetIdentityResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResetIdentityResponse copyWith(
          void Function(ResetIdentityResponse) updates) =>
      super.copyWith((message) => updates(message as ResetIdentityResponse))
          as ResetIdentityResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ResetIdentityResponse() / ResetIdentityResponse.new instead')
  static ResetIdentityResponse create() => ResetIdentityResponse._();
  static $pb.GeneratedMessage $_createMessage() => ResetIdentityResponse._();
  @$core.override
  ResetIdentityResponse createEmptyInstance() => ResetIdentityResponse._();
  @$core.pragma('dart2js:noInline')
  static ResetIdentityResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResetIdentityResponse>(
          ResetIdentityResponse.$_createMessage);
  static ResetIdentityResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get message => $_getSZ(0);
  @$pb.TagNumber(1)
  set message($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);
}

/// Asks for a binding challenge.
class CreateSessionChallengeRequest extends $pb.GeneratedMessage {
  factory CreateSessionChallengeRequest() => CreateSessionChallengeRequest._();

  CreateSessionChallengeRequest._();

  factory CreateSessionChallengeRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreateSessionChallengeRequest()..mergeFromBuffer(data, registry);
  factory CreateSessionChallengeRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreateSessionChallengeRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateSessionChallengeRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: CreateSessionChallengeRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateSessionChallengeRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateSessionChallengeRequest copyWith(
          void Function(CreateSessionChallengeRequest) updates) =>
      super.copyWith(
              (message) => updates(message as CreateSessionChallengeRequest))
          as CreateSessionChallengeRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use CreateSessionChallengeRequest() / CreateSessionChallengeRequest.new instead')
  static CreateSessionChallengeRequest create() =>
      CreateSessionChallengeRequest._();
  static $pb.GeneratedMessage $_createMessage() =>
      CreateSessionChallengeRequest._();
  @$core.override
  CreateSessionChallengeRequest createEmptyInstance() =>
      CreateSessionChallengeRequest._();
  @$core.pragma('dart2js:noInline')
  static CreateSessionChallengeRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateSessionChallengeRequest>(
          CreateSessionChallengeRequest.$_createMessage);
  static CreateSessionChallengeRequest? _defaultInstance;
}

/// The challenge to sign.
class CreateSessionChallengeResponse extends $pb.GeneratedMessage {
  factory CreateSessionChallengeResponse({
    $core.List<$core.int>? nonce,
    $1.Timestamp? expiresAt,
  }) {
    final result = CreateSessionChallengeResponse._();
    if (nonce != null) result.nonce = nonce;
    if (expiresAt != null) result.expiresAt = expiresAt;
    return result;
  }

  CreateSessionChallengeResponse._();

  factory CreateSessionChallengeResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreateSessionChallengeResponse()..mergeFromBuffer(data, registry);
  factory CreateSessionChallengeResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreateSessionChallengeResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateSessionChallengeResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: CreateSessionChallengeResponse.$_createMessage)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'nonce', $pb.PbFieldType.OY)
    ..aOM<$1.Timestamp>(2, _omitFieldNames ? '' : 'expiresAt',
        subBuilder: $1.Timestamp.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateSessionChallengeResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateSessionChallengeResponse copyWith(
          void Function(CreateSessionChallengeResponse) updates) =>
      super.copyWith(
              (message) => updates(message as CreateSessionChallengeResponse))
          as CreateSessionChallengeResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use CreateSessionChallengeResponse() / CreateSessionChallengeResponse.new instead')
  static CreateSessionChallengeResponse create() =>
      CreateSessionChallengeResponse._();
  static $pb.GeneratedMessage $_createMessage() =>
      CreateSessionChallengeResponse._();
  @$core.override
  CreateSessionChallengeResponse createEmptyInstance() =>
      CreateSessionChallengeResponse._();
  @$core.pragma('dart2js:noInline')
  static CreateSessionChallengeResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateSessionChallengeResponse>(
          CreateSessionChallengeResponse.$_createMessage);
  static CreateSessionChallengeResponse? _defaultInstance;

  /// 32 random bytes, usable once.
  @$pb.TagNumber(1)
  $core.List<$core.int> get nonce => $_getN(0);
  @$pb.TagNumber(1)
  set nonce($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasNonce() => $_has(0);
  @$pb.TagNumber(1)
  void clearNonce() => $_clearField(1);

  @$pb.TagNumber(2)
  $1.Timestamp get expiresAt => $_getN(1);
  @$pb.TagNumber(2)
  set expiresAt($1.Timestamp value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasExpiresAt() => $_has(1);
  @$pb.TagNumber(2)
  void clearExpiresAt() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.Timestamp ensureExpiresAt() => $_ensure(1);
}

/// Binds the session to a device.
class BindSessionRequest extends $pb.GeneratedMessage {
  factory BindSessionRequest({
    $core.String? deviceId,
    $core.List<$core.int>? signature,
  }) {
    final result = BindSessionRequest._();
    if (deviceId != null) result.deviceId = deviceId;
    if (signature != null) result.signature = signature;
    return result;
  }

  BindSessionRequest._();

  factory BindSessionRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BindSessionRequest()..mergeFromBuffer(data, registry);
  factory BindSessionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BindSessionRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BindSessionRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: BindSessionRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'deviceId')
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'signature', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BindSessionRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BindSessionRequest copyWith(void Function(BindSessionRequest) updates) =>
      super.copyWith((message) => updates(message as BindSessionRequest))
          as BindSessionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use BindSessionRequest() / BindSessionRequest.new instead')
  static BindSessionRequest create() => BindSessionRequest._();
  static $pb.GeneratedMessage $_createMessage() => BindSessionRequest._();
  @$core.override
  BindSessionRequest createEmptyInstance() => BindSessionRequest._();
  @$core.pragma('dart2js:noInline')
  static BindSessionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BindSessionRequest>(
          BindSessionRequest.$_createMessage);
  static BindSessionRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get deviceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set deviceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDeviceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearDeviceId() => $_clearField(1);

  /// Ed25519 over "raindrop/session-binding/v1\n" ‖ nonce, by the device's signature key.
  @$pb.TagNumber(2)
  $core.List<$core.int> get signature => $_getN(1);
  @$pb.TagNumber(2)
  set signature($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSignature() => $_has(1);
  @$pb.TagNumber(2)
  void clearSignature() => $_clearField(2);
}

/// A human-readable confirmation.
class BindSessionResponse extends $pb.GeneratedMessage {
  factory BindSessionResponse({
    $core.String? message,
  }) {
    final result = BindSessionResponse._();
    if (message != null) result.message = message;
    return result;
  }

  BindSessionResponse._();

  factory BindSessionResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BindSessionResponse()..mergeFromBuffer(data, registry);
  factory BindSessionResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BindSessionResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BindSessionResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: BindSessionResponse.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BindSessionResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BindSessionResponse copyWith(void Function(BindSessionResponse) updates) =>
      super.copyWith((message) => updates(message as BindSessionResponse))
          as BindSessionResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use BindSessionResponse() / BindSessionResponse.new instead')
  static BindSessionResponse create() => BindSessionResponse._();
  static $pb.GeneratedMessage $_createMessage() => BindSessionResponse._();
  @$core.override
  BindSessionResponse createEmptyInstance() => BindSessionResponse._();
  @$core.pragma('dart2js:noInline')
  static BindSessionResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BindSessionResponse>(
          BindSessionResponse.$_createMessage);
  static BindSessionResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get message => $_getSZ(0);
  @$pb.TagNumber(1)
  set message($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);
}

/// Asks for the key backup.
class GetKeyBackupRequest extends $pb.GeneratedMessage {
  factory GetKeyBackupRequest() => GetKeyBackupRequest._();

  GetKeyBackupRequest._();

  factory GetKeyBackupRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetKeyBackupRequest()..mergeFromBuffer(data, registry);
  factory GetKeyBackupRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetKeyBackupRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetKeyBackupRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: GetKeyBackupRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetKeyBackupRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetKeyBackupRequest copyWith(void Function(GetKeyBackupRequest) updates) =>
      super.copyWith((message) => updates(message as GetKeyBackupRequest))
          as GetKeyBackupRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use GetKeyBackupRequest() / GetKeyBackupRequest.new instead')
  static GetKeyBackupRequest create() => GetKeyBackupRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetKeyBackupRequest._();
  @$core.override
  GetKeyBackupRequest createEmptyInstance() => GetKeyBackupRequest._();
  @$core.pragma('dart2js:noInline')
  static GetKeyBackupRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetKeyBackupRequest>(
          GetKeyBackupRequest.$_createMessage);
  static GetKeyBackupRequest? _defaultInstance;
}

/// The backup, if there is one.
class GetKeyBackupResponse extends $pb.GeneratedMessage {
  factory GetKeyBackupResponse({
    $core.List<$core.int>? blob,
    $1.Timestamp? updatedAt,
  }) {
    final result = GetKeyBackupResponse._();
    if (blob != null) result.blob = blob;
    if (updatedAt != null) result.updatedAt = updatedAt;
    return result;
  }

  GetKeyBackupResponse._();

  factory GetKeyBackupResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetKeyBackupResponse()..mergeFromBuffer(data, registry);
  factory GetKeyBackupResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetKeyBackupResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetKeyBackupResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: GetKeyBackupResponse.$_createMessage)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'blob', $pb.PbFieldType.OY)
    ..aOM<$1.Timestamp>(2, _omitFieldNames ? '' : 'updatedAt',
        subBuilder: $1.Timestamp.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetKeyBackupResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetKeyBackupResponse copyWith(void Function(GetKeyBackupResponse) updates) =>
      super.copyWith((message) => updates(message as GetKeyBackupResponse))
          as GetKeyBackupResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetKeyBackupResponse() / GetKeyBackupResponse.new instead')
  static GetKeyBackupResponse create() => GetKeyBackupResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetKeyBackupResponse._();
  @$core.override
  GetKeyBackupResponse createEmptyInstance() => GetKeyBackupResponse._();
  @$core.pragma('dart2js:noInline')
  static GetKeyBackupResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetKeyBackupResponse>(
          GetKeyBackupResponse.$_createMessage);
  static GetKeyBackupResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get blob => $_getN(0);
  @$pb.TagNumber(1)
  set blob($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBlob() => $_has(0);
  @$pb.TagNumber(1)
  void clearBlob() => $_clearField(1);

  @$pb.TagNumber(2)
  $1.Timestamp get updatedAt => $_getN(1);
  @$pb.TagNumber(2)
  set updatedAt($1.Timestamp value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasUpdatedAt() => $_has(1);
  @$pb.TagNumber(2)
  void clearUpdatedAt() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.Timestamp ensureUpdatedAt() => $_ensure(1);
}

/// Replaces the key backup.
class PutKeyBackupRequest extends $pb.GeneratedMessage {
  factory PutKeyBackupRequest({
    $core.List<$core.int>? blob,
  }) {
    final result = PutKeyBackupRequest._();
    if (blob != null) result.blob = blob;
    return result;
  }

  PutKeyBackupRequest._();

  factory PutKeyBackupRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PutKeyBackupRequest()..mergeFromBuffer(data, registry);
  factory PutKeyBackupRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PutKeyBackupRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PutKeyBackupRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: PutKeyBackupRequest.$_createMessage)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'blob', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PutKeyBackupRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PutKeyBackupRequest copyWith(void Function(PutKeyBackupRequest) updates) =>
      super.copyWith((message) => updates(message as PutKeyBackupRequest))
          as PutKeyBackupRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use PutKeyBackupRequest() / PutKeyBackupRequest.new instead')
  static PutKeyBackupRequest create() => PutKeyBackupRequest._();
  static $pb.GeneratedMessage $_createMessage() => PutKeyBackupRequest._();
  @$core.override
  PutKeyBackupRequest createEmptyInstance() => PutKeyBackupRequest._();
  @$core.pragma('dart2js:noInline')
  static PutKeyBackupRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PutKeyBackupRequest>(
          PutKeyBackupRequest.$_createMessage);
  static PutKeyBackupRequest? _defaultInstance;

  /// The sealed backup, at most 64 KiB.
  @$pb.TagNumber(1)
  $core.List<$core.int> get blob => $_getN(0);
  @$pb.TagNumber(1)
  set blob($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBlob() => $_has(0);
  @$pb.TagNumber(1)
  void clearBlob() => $_clearField(1);
}

/// The backup as stored.
class PutKeyBackupResponse extends $pb.GeneratedMessage {
  factory PutKeyBackupResponse({
    $core.List<$core.int>? blob,
    $1.Timestamp? updatedAt,
  }) {
    final result = PutKeyBackupResponse._();
    if (blob != null) result.blob = blob;
    if (updatedAt != null) result.updatedAt = updatedAt;
    return result;
  }

  PutKeyBackupResponse._();

  factory PutKeyBackupResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PutKeyBackupResponse()..mergeFromBuffer(data, registry);
  factory PutKeyBackupResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PutKeyBackupResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PutKeyBackupResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: PutKeyBackupResponse.$_createMessage)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'blob', $pb.PbFieldType.OY)
    ..aOM<$1.Timestamp>(2, _omitFieldNames ? '' : 'updatedAt',
        subBuilder: $1.Timestamp.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PutKeyBackupResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PutKeyBackupResponse copyWith(void Function(PutKeyBackupResponse) updates) =>
      super.copyWith((message) => updates(message as PutKeyBackupResponse))
          as PutKeyBackupResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use PutKeyBackupResponse() / PutKeyBackupResponse.new instead')
  static PutKeyBackupResponse create() => PutKeyBackupResponse._();
  static $pb.GeneratedMessage $_createMessage() => PutKeyBackupResponse._();
  @$core.override
  PutKeyBackupResponse createEmptyInstance() => PutKeyBackupResponse._();
  @$core.pragma('dart2js:noInline')
  static PutKeyBackupResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PutKeyBackupResponse>(
          PutKeyBackupResponse.$_createMessage);
  static PutKeyBackupResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get blob => $_getN(0);
  @$pb.TagNumber(1)
  set blob($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBlob() => $_has(0);
  @$pb.TagNumber(1)
  void clearBlob() => $_clearField(1);

  @$pb.TagNumber(2)
  $1.Timestamp get updatedAt => $_getN(1);
  @$pb.TagNumber(2)
  set updatedAt($1.Timestamp value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasUpdatedAt() => $_has(1);
  @$pb.TagNumber(2)
  void clearUpdatedAt() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.Timestamp ensureUpdatedAt() => $_ensure(1);
}

/// Starts a device link.
class StartDeviceLinkRequest extends $pb.GeneratedMessage {
  factory StartDeviceLinkRequest({
    $core.List<$core.int>? offer,
  }) {
    final result = StartDeviceLinkRequest._();
    if (offer != null) result.offer = offer;
    return result;
  }

  StartDeviceLinkRequest._();

  factory StartDeviceLinkRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StartDeviceLinkRequest()..mergeFromBuffer(data, registry);
  factory StartDeviceLinkRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StartDeviceLinkRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StartDeviceLinkRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: StartDeviceLinkRequest.$_createMessage)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'offer', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartDeviceLinkRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartDeviceLinkRequest copyWith(
          void Function(StartDeviceLinkRequest) updates) =>
      super.copyWith((message) => updates(message as StartDeviceLinkRequest))
          as StartDeviceLinkRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use StartDeviceLinkRequest() / StartDeviceLinkRequest.new instead')
  static StartDeviceLinkRequest create() => StartDeviceLinkRequest._();
  static $pb.GeneratedMessage $_createMessage() => StartDeviceLinkRequest._();
  @$core.override
  StartDeviceLinkRequest createEmptyInstance() => StartDeviceLinkRequest._();
  @$core.pragma('dart2js:noInline')
  static StartDeviceLinkRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StartDeviceLinkRequest>(
          StartDeviceLinkRequest.$_createMessage);
  static StartDeviceLinkRequest? _defaultInstance;

  /// The new device's offer: opaque, at most 4 KiB.
  @$pb.TagNumber(1)
  $core.List<$core.int> get offer => $_getN(0);
  @$pb.TagNumber(1)
  set offer($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOffer() => $_has(0);
  @$pb.TagNumber(1)
  void clearOffer() => $_clearField(1);
}

/// The link to show in the link code.
class StartDeviceLinkResponse extends $pb.GeneratedMessage {
  factory StartDeviceLinkResponse({
    $core.String? linkId,
    $1.Timestamp? expiresAt,
  }) {
    final result = StartDeviceLinkResponse._();
    if (linkId != null) result.linkId = linkId;
    if (expiresAt != null) result.expiresAt = expiresAt;
    return result;
  }

  StartDeviceLinkResponse._();

  factory StartDeviceLinkResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StartDeviceLinkResponse()..mergeFromBuffer(data, registry);
  factory StartDeviceLinkResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StartDeviceLinkResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StartDeviceLinkResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: StartDeviceLinkResponse.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'linkId')
    ..aOM<$1.Timestamp>(2, _omitFieldNames ? '' : 'expiresAt',
        subBuilder: $1.Timestamp.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartDeviceLinkResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartDeviceLinkResponse copyWith(
          void Function(StartDeviceLinkResponse) updates) =>
      super.copyWith((message) => updates(message as StartDeviceLinkResponse))
          as StartDeviceLinkResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use StartDeviceLinkResponse() / StartDeviceLinkResponse.new instead')
  static StartDeviceLinkResponse create() => StartDeviceLinkResponse._();
  static $pb.GeneratedMessage $_createMessage() => StartDeviceLinkResponse._();
  @$core.override
  StartDeviceLinkResponse createEmptyInstance() => StartDeviceLinkResponse._();
  @$core.pragma('dart2js:noInline')
  static StartDeviceLinkResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StartDeviceLinkResponse>(
          StartDeviceLinkResponse.$_createMessage);
  static StartDeviceLinkResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get linkId => $_getSZ(0);
  @$pb.TagNumber(1)
  set linkId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLinkId() => $_has(0);
  @$pb.TagNumber(1)
  void clearLinkId() => $_clearField(1);

  @$pb.TagNumber(2)
  $1.Timestamp get expiresAt => $_getN(1);
  @$pb.TagNumber(2)
  set expiresAt($1.Timestamp value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasExpiresAt() => $_has(1);
  @$pb.TagNumber(2)
  void clearExpiresAt() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.Timestamp ensureExpiresAt() => $_ensure(1);
}

/// Fetches a link's offer.
class GetDeviceLinkOfferRequest extends $pb.GeneratedMessage {
  factory GetDeviceLinkOfferRequest({
    $core.String? linkId,
  }) {
    final result = GetDeviceLinkOfferRequest._();
    if (linkId != null) result.linkId = linkId;
    return result;
  }

  GetDeviceLinkOfferRequest._();

  factory GetDeviceLinkOfferRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetDeviceLinkOfferRequest()..mergeFromBuffer(data, registry);
  factory GetDeviceLinkOfferRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetDeviceLinkOfferRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetDeviceLinkOfferRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: GetDeviceLinkOfferRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'linkId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetDeviceLinkOfferRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetDeviceLinkOfferRequest copyWith(
          void Function(GetDeviceLinkOfferRequest) updates) =>
      super.copyWith((message) => updates(message as GetDeviceLinkOfferRequest))
          as GetDeviceLinkOfferRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetDeviceLinkOfferRequest() / GetDeviceLinkOfferRequest.new instead')
  static GetDeviceLinkOfferRequest create() => GetDeviceLinkOfferRequest._();
  static $pb.GeneratedMessage $_createMessage() =>
      GetDeviceLinkOfferRequest._();
  @$core.override
  GetDeviceLinkOfferRequest createEmptyInstance() =>
      GetDeviceLinkOfferRequest._();
  @$core.pragma('dart2js:noInline')
  static GetDeviceLinkOfferRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetDeviceLinkOfferRequest>(
          GetDeviceLinkOfferRequest.$_createMessage);
  static GetDeviceLinkOfferRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get linkId => $_getSZ(0);
  @$pb.TagNumber(1)
  set linkId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLinkId() => $_has(0);
  @$pb.TagNumber(1)
  void clearLinkId() => $_clearField(1);
}

/// The offer, for checking against the link code's commitment.
class GetDeviceLinkOfferResponse extends $pb.GeneratedMessage {
  factory GetDeviceLinkOfferResponse({
    $core.List<$core.int>? offer,
  }) {
    final result = GetDeviceLinkOfferResponse._();
    if (offer != null) result.offer = offer;
    return result;
  }

  GetDeviceLinkOfferResponse._();

  factory GetDeviceLinkOfferResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetDeviceLinkOfferResponse()..mergeFromBuffer(data, registry);
  factory GetDeviceLinkOfferResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetDeviceLinkOfferResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetDeviceLinkOfferResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: GetDeviceLinkOfferResponse.$_createMessage)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'offer', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetDeviceLinkOfferResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetDeviceLinkOfferResponse copyWith(
          void Function(GetDeviceLinkOfferResponse) updates) =>
      super.copyWith(
              (message) => updates(message as GetDeviceLinkOfferResponse))
          as GetDeviceLinkOfferResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetDeviceLinkOfferResponse() / GetDeviceLinkOfferResponse.new instead')
  static GetDeviceLinkOfferResponse create() => GetDeviceLinkOfferResponse._();
  static $pb.GeneratedMessage $_createMessage() =>
      GetDeviceLinkOfferResponse._();
  @$core.override
  GetDeviceLinkOfferResponse createEmptyInstance() =>
      GetDeviceLinkOfferResponse._();
  @$core.pragma('dart2js:noInline')
  static GetDeviceLinkOfferResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetDeviceLinkOfferResponse>(
          GetDeviceLinkOfferResponse.$_createMessage);
  static GetDeviceLinkOfferResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get offer => $_getN(0);
  @$pb.TagNumber(1)
  set offer($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOffer() => $_has(0);
  @$pb.TagNumber(1)
  void clearOffer() => $_clearField(1);
}

/// Approves a link.
class ApproveDeviceLinkRequest extends $pb.GeneratedMessage {
  factory ApproveDeviceLinkRequest({
    $core.String? linkId,
    $core.List<$core.int>? approval,
  }) {
    final result = ApproveDeviceLinkRequest._();
    if (linkId != null) result.linkId = linkId;
    if (approval != null) result.approval = approval;
    return result;
  }

  ApproveDeviceLinkRequest._();

  factory ApproveDeviceLinkRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ApproveDeviceLinkRequest()..mergeFromBuffer(data, registry);
  factory ApproveDeviceLinkRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ApproveDeviceLinkRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ApproveDeviceLinkRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: ApproveDeviceLinkRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'linkId')
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'approval', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ApproveDeviceLinkRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ApproveDeviceLinkRequest copyWith(
          void Function(ApproveDeviceLinkRequest) updates) =>
      super.copyWith((message) => updates(message as ApproveDeviceLinkRequest))
          as ApproveDeviceLinkRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ApproveDeviceLinkRequest() / ApproveDeviceLinkRequest.new instead')
  static ApproveDeviceLinkRequest create() => ApproveDeviceLinkRequest._();
  static $pb.GeneratedMessage $_createMessage() => ApproveDeviceLinkRequest._();
  @$core.override
  ApproveDeviceLinkRequest createEmptyInstance() =>
      ApproveDeviceLinkRequest._();
  @$core.pragma('dart2js:noInline')
  static ApproveDeviceLinkRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ApproveDeviceLinkRequest>(
          ApproveDeviceLinkRequest.$_createMessage);
  static ApproveDeviceLinkRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get linkId => $_getSZ(0);
  @$pb.TagNumber(1)
  set linkId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLinkId() => $_has(0);
  @$pb.TagNumber(1)
  void clearLinkId() => $_clearField(1);

  /// Encrypted to the new device; at most 8 KiB.
  @$pb.TagNumber(2)
  $core.List<$core.int> get approval => $_getN(1);
  @$pb.TagNumber(2)
  set approval($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasApproval() => $_has(1);
  @$pb.TagNumber(2)
  void clearApproval() => $_clearField(2);
}

/// A human-readable confirmation.
class ApproveDeviceLinkResponse extends $pb.GeneratedMessage {
  factory ApproveDeviceLinkResponse({
    $core.String? message,
  }) {
    final result = ApproveDeviceLinkResponse._();
    if (message != null) result.message = message;
    return result;
  }

  ApproveDeviceLinkResponse._();

  factory ApproveDeviceLinkResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ApproveDeviceLinkResponse()..mergeFromBuffer(data, registry);
  factory ApproveDeviceLinkResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ApproveDeviceLinkResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ApproveDeviceLinkResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: ApproveDeviceLinkResponse.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ApproveDeviceLinkResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ApproveDeviceLinkResponse copyWith(
          void Function(ApproveDeviceLinkResponse) updates) =>
      super.copyWith((message) => updates(message as ApproveDeviceLinkResponse))
          as ApproveDeviceLinkResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ApproveDeviceLinkResponse() / ApproveDeviceLinkResponse.new instead')
  static ApproveDeviceLinkResponse create() => ApproveDeviceLinkResponse._();
  static $pb.GeneratedMessage $_createMessage() =>
      ApproveDeviceLinkResponse._();
  @$core.override
  ApproveDeviceLinkResponse createEmptyInstance() =>
      ApproveDeviceLinkResponse._();
  @$core.pragma('dart2js:noInline')
  static ApproveDeviceLinkResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ApproveDeviceLinkResponse>(
          ApproveDeviceLinkResponse.$_createMessage);
  static ApproveDeviceLinkResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get message => $_getSZ(0);
  @$pb.TagNumber(1)
  set message($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);
}

/// Collects a link's approval.
class TakeDeviceLinkApprovalRequest extends $pb.GeneratedMessage {
  factory TakeDeviceLinkApprovalRequest({
    $core.String? linkId,
  }) {
    final result = TakeDeviceLinkApprovalRequest._();
    if (linkId != null) result.linkId = linkId;
    return result;
  }

  TakeDeviceLinkApprovalRequest._();

  factory TakeDeviceLinkApprovalRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TakeDeviceLinkApprovalRequest()..mergeFromBuffer(data, registry);
  factory TakeDeviceLinkApprovalRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TakeDeviceLinkApprovalRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TakeDeviceLinkApprovalRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: TakeDeviceLinkApprovalRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'linkId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TakeDeviceLinkApprovalRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TakeDeviceLinkApprovalRequest copyWith(
          void Function(TakeDeviceLinkApprovalRequest) updates) =>
      super.copyWith(
              (message) => updates(message as TakeDeviceLinkApprovalRequest))
          as TakeDeviceLinkApprovalRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use TakeDeviceLinkApprovalRequest() / TakeDeviceLinkApprovalRequest.new instead')
  static TakeDeviceLinkApprovalRequest create() =>
      TakeDeviceLinkApprovalRequest._();
  static $pb.GeneratedMessage $_createMessage() =>
      TakeDeviceLinkApprovalRequest._();
  @$core.override
  TakeDeviceLinkApprovalRequest createEmptyInstance() =>
      TakeDeviceLinkApprovalRequest._();
  @$core.pragma('dart2js:noInline')
  static TakeDeviceLinkApprovalRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TakeDeviceLinkApprovalRequest>(
          TakeDeviceLinkApprovalRequest.$_createMessage);
  static TakeDeviceLinkApprovalRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get linkId => $_getSZ(0);
  @$pb.TagNumber(1)
  set linkId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLinkId() => $_has(0);
  @$pb.TagNumber(1)
  void clearLinkId() => $_clearField(1);
}

/// The approval, once an existing device has given it.
class TakeDeviceLinkApprovalResponse extends $pb.GeneratedMessage {
  factory TakeDeviceLinkApprovalResponse({
    $core.List<$core.int>? approval,
  }) {
    final result = TakeDeviceLinkApprovalResponse._();
    if (approval != null) result.approval = approval;
    return result;
  }

  TakeDeviceLinkApprovalResponse._();

  factory TakeDeviceLinkApprovalResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TakeDeviceLinkApprovalResponse()..mergeFromBuffer(data, registry);
  factory TakeDeviceLinkApprovalResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TakeDeviceLinkApprovalResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TakeDeviceLinkApprovalResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: TakeDeviceLinkApprovalResponse.$_createMessage)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'approval', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TakeDeviceLinkApprovalResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TakeDeviceLinkApprovalResponse copyWith(
          void Function(TakeDeviceLinkApprovalResponse) updates) =>
      super.copyWith(
              (message) => updates(message as TakeDeviceLinkApprovalResponse))
          as TakeDeviceLinkApprovalResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use TakeDeviceLinkApprovalResponse() / TakeDeviceLinkApprovalResponse.new instead')
  static TakeDeviceLinkApprovalResponse create() =>
      TakeDeviceLinkApprovalResponse._();
  static $pb.GeneratedMessage $_createMessage() =>
      TakeDeviceLinkApprovalResponse._();
  @$core.override
  TakeDeviceLinkApprovalResponse createEmptyInstance() =>
      TakeDeviceLinkApprovalResponse._();
  @$core.pragma('dart2js:noInline')
  static TakeDeviceLinkApprovalResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TakeDeviceLinkApprovalResponse>(
          TakeDeviceLinkApprovalResponse.$_createMessage);
  static TakeDeviceLinkApprovalResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get approval => $_getN(0);
  @$pb.TagNumber(1)
  set approval($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasApproval() => $_has(0);
  @$pb.TagNumber(1)
  void clearApproval() => $_clearField(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
