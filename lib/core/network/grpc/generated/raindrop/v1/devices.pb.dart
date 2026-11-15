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

/// Replaces the identity vault.
class PutIdentityVaultRequest extends $pb.GeneratedMessage {
  factory PutIdentityVaultRequest({
    $core.String? lookupId,
    $core.List<$core.int>? sealedRoot,
    $core.List<$core.int>? vault,
  }) {
    final result = PutIdentityVaultRequest._();
    if (lookupId != null) result.lookupId = lookupId;
    if (sealedRoot != null) result.sealedRoot = sealedRoot;
    if (vault != null) result.vault = vault;
    return result;
  }

  PutIdentityVaultRequest._();

  factory PutIdentityVaultRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PutIdentityVaultRequest()..mergeFromBuffer(data, registry);
  factory PutIdentityVaultRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PutIdentityVaultRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PutIdentityVaultRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: PutIdentityVaultRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'lookupId')
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'sealedRoot', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'vault', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PutIdentityVaultRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PutIdentityVaultRequest copyWith(
          void Function(PutIdentityVaultRequest) updates) =>
      super.copyWith((message) => updates(message as PutIdentityVaultRequest))
          as PutIdentityVaultRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use PutIdentityVaultRequest() / PutIdentityVaultRequest.new instead')
  static PutIdentityVaultRequest create() => PutIdentityVaultRequest._();
  static $pb.GeneratedMessage $_createMessage() => PutIdentityVaultRequest._();
  @$core.override
  PutIdentityVaultRequest createEmptyInstance() => PutIdentityVaultRequest._();
  @$core.pragma('dart2js:noInline')
  static PutIdentityVaultRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PutIdentityVaultRequest>(
          PutIdentityVaultRequest.$_createMessage);
  static PutIdentityVaultRequest? _defaultInstance;

  /// 32 lower-case hex characters, derived from the recovery key and this server's identity key.
  @$pb.TagNumber(1)
  $core.String get lookupId => $_getSZ(0);
  @$pb.TagNumber(1)
  set lookupId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLookupId() => $_has(0);
  @$pb.TagNumber(1)
  void clearLookupId() => $_clearField(1);

  /// The root secret sealed under the recovery key. Opaque.
  @$pb.TagNumber(2)
  $core.List<$core.int> get sealedRoot => $_getN(1);
  @$pb.TagNumber(2)
  set sealedRoot($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSealedRoot() => $_has(1);
  @$pb.TagNumber(2)
  void clearSealedRoot() => $_clearField(2);

  /// The vault, sealed under the root. Opaque.
  @$pb.TagNumber(3)
  $core.List<$core.int> get vault => $_getN(2);
  @$pb.TagNumber(3)
  set vault($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasVault() => $_has(2);
  @$pb.TagNumber(3)
  void clearVault() => $_clearField(3);
}

/// When it was stored.
class PutIdentityVaultResponse extends $pb.GeneratedMessage {
  factory PutIdentityVaultResponse({
    $1.Timestamp? updatedAt,
  }) {
    final result = PutIdentityVaultResponse._();
    if (updatedAt != null) result.updatedAt = updatedAt;
    return result;
  }

  PutIdentityVaultResponse._();

  factory PutIdentityVaultResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PutIdentityVaultResponse()..mergeFromBuffer(data, registry);
  factory PutIdentityVaultResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PutIdentityVaultResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PutIdentityVaultResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: PutIdentityVaultResponse.$_createMessage)
    ..aOM<$1.Timestamp>(1, _omitFieldNames ? '' : 'updatedAt',
        subBuilder: $1.Timestamp.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PutIdentityVaultResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PutIdentityVaultResponse copyWith(
          void Function(PutIdentityVaultResponse) updates) =>
      super.copyWith((message) => updates(message as PutIdentityVaultResponse))
          as PutIdentityVaultResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use PutIdentityVaultResponse() / PutIdentityVaultResponse.new instead')
  static PutIdentityVaultResponse create() => PutIdentityVaultResponse._();
  static $pb.GeneratedMessage $_createMessage() => PutIdentityVaultResponse._();
  @$core.override
  PutIdentityVaultResponse createEmptyInstance() =>
      PutIdentityVaultResponse._();
  @$core.pragma('dart2js:noInline')
  static PutIdentityVaultResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PutIdentityVaultResponse>(
          PutIdentityVaultResponse.$_createMessage);
  static PutIdentityVaultResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $1.Timestamp get updatedAt => $_getN(0);
  @$pb.TagNumber(1)
  set updatedAt($1.Timestamp value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasUpdatedAt() => $_has(0);
  @$pb.TagNumber(1)
  void clearUpdatedAt() => $_clearField(1);
  @$pb.TagNumber(1)
  $1.Timestamp ensureUpdatedAt() => $_ensure(0);
}

/// Asks for the caller's identity vault.
class GetIdentityVaultRequest extends $pb.GeneratedMessage {
  factory GetIdentityVaultRequest() => GetIdentityVaultRequest._();

  GetIdentityVaultRequest._();

  factory GetIdentityVaultRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetIdentityVaultRequest()..mergeFromBuffer(data, registry);
  factory GetIdentityVaultRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetIdentityVaultRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetIdentityVaultRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: GetIdentityVaultRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetIdentityVaultRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetIdentityVaultRequest copyWith(
          void Function(GetIdentityVaultRequest) updates) =>
      super.copyWith((message) => updates(message as GetIdentityVaultRequest))
          as GetIdentityVaultRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetIdentityVaultRequest() / GetIdentityVaultRequest.new instead')
  static GetIdentityVaultRequest create() => GetIdentityVaultRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetIdentityVaultRequest._();
  @$core.override
  GetIdentityVaultRequest createEmptyInstance() => GetIdentityVaultRequest._();
  @$core.pragma('dart2js:noInline')
  static GetIdentityVaultRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetIdentityVaultRequest>(
          GetIdentityVaultRequest.$_createMessage);
  static GetIdentityVaultRequest? _defaultInstance;
}

/// The vault, if there is one.
class GetIdentityVaultResponse extends $pb.GeneratedMessage {
  factory GetIdentityVaultResponse({
    $core.String? lookupId,
    $core.List<$core.int>? sealedRoot,
    $core.List<$core.int>? vault,
    $1.Timestamp? updatedAt,
  }) {
    final result = GetIdentityVaultResponse._();
    if (lookupId != null) result.lookupId = lookupId;
    if (sealedRoot != null) result.sealedRoot = sealedRoot;
    if (vault != null) result.vault = vault;
    if (updatedAt != null) result.updatedAt = updatedAt;
    return result;
  }

  GetIdentityVaultResponse._();

  factory GetIdentityVaultResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetIdentityVaultResponse()..mergeFromBuffer(data, registry);
  factory GetIdentityVaultResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetIdentityVaultResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetIdentityVaultResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: GetIdentityVaultResponse.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'lookupId')
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'sealedRoot', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'vault', $pb.PbFieldType.OY)
    ..aOM<$1.Timestamp>(4, _omitFieldNames ? '' : 'updatedAt',
        subBuilder: $1.Timestamp.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetIdentityVaultResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetIdentityVaultResponse copyWith(
          void Function(GetIdentityVaultResponse) updates) =>
      super.copyWith((message) => updates(message as GetIdentityVaultResponse))
          as GetIdentityVaultResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetIdentityVaultResponse() / GetIdentityVaultResponse.new instead')
  static GetIdentityVaultResponse create() => GetIdentityVaultResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetIdentityVaultResponse._();
  @$core.override
  GetIdentityVaultResponse createEmptyInstance() =>
      GetIdentityVaultResponse._();
  @$core.pragma('dart2js:noInline')
  static GetIdentityVaultResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetIdentityVaultResponse>(
          GetIdentityVaultResponse.$_createMessage);
  static GetIdentityVaultResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get lookupId => $_getSZ(0);
  @$pb.TagNumber(1)
  set lookupId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLookupId() => $_has(0);
  @$pb.TagNumber(1)
  void clearLookupId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get sealedRoot => $_getN(1);
  @$pb.TagNumber(2)
  set sealedRoot($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSealedRoot() => $_has(1);
  @$pb.TagNumber(2)
  void clearSealedRoot() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get vault => $_getN(2);
  @$pb.TagNumber(3)
  set vault($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasVault() => $_has(2);
  @$pb.TagNumber(3)
  void clearVault() => $_clearField(3);

  @$pb.TagNumber(4)
  $1.Timestamp get updatedAt => $_getN(3);
  @$pb.TagNumber(4)
  set updatedAt($1.Timestamp value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasUpdatedAt() => $_has(3);
  @$pb.TagNumber(4)
  void clearUpdatedAt() => $_clearField(4);
  @$pb.TagNumber(4)
  $1.Timestamp ensureUpdatedAt() => $_ensure(3);
}

/// Asks for a sealed root by its lookup id.
class GetSealedRootRequest extends $pb.GeneratedMessage {
  factory GetSealedRootRequest({
    $core.String? lookupId,
  }) {
    final result = GetSealedRootRequest._();
    if (lookupId != null) result.lookupId = lookupId;
    return result;
  }

  GetSealedRootRequest._();

  factory GetSealedRootRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetSealedRootRequest()..mergeFromBuffer(data, registry);
  factory GetSealedRootRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetSealedRootRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetSealedRootRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: GetSealedRootRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'lookupId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSealedRootRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSealedRootRequest copyWith(void Function(GetSealedRootRequest) updates) =>
      super.copyWith((message) => updates(message as GetSealedRootRequest))
          as GetSealedRootRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetSealedRootRequest() / GetSealedRootRequest.new instead')
  static GetSealedRootRequest create() => GetSealedRootRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetSealedRootRequest._();
  @$core.override
  GetSealedRootRequest createEmptyInstance() => GetSealedRootRequest._();
  @$core.pragma('dart2js:noInline')
  static GetSealedRootRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetSealedRootRequest>(
          GetSealedRootRequest.$_createMessage);
  static GetSealedRootRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get lookupId => $_getSZ(0);
  @$pb.TagNumber(1)
  set lookupId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLookupId() => $_has(0);
  @$pb.TagNumber(1)
  void clearLookupId() => $_clearField(1);
}

/// The sealed root.
class GetSealedRootResponse extends $pb.GeneratedMessage {
  factory GetSealedRootResponse({
    $core.List<$core.int>? sealedRoot,
  }) {
    final result = GetSealedRootResponse._();
    if (sealedRoot != null) result.sealedRoot = sealedRoot;
    return result;
  }

  GetSealedRootResponse._();

  factory GetSealedRootResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetSealedRootResponse()..mergeFromBuffer(data, registry);
  factory GetSealedRootResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetSealedRootResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetSealedRootResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: GetSealedRootResponse.$_createMessage)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'sealedRoot', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSealedRootResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSealedRootResponse copyWith(
          void Function(GetSealedRootResponse) updates) =>
      super.copyWith((message) => updates(message as GetSealedRootResponse))
          as GetSealedRootResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetSealedRootResponse() / GetSealedRootResponse.new instead')
  static GetSealedRootResponse create() => GetSealedRootResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetSealedRootResponse._();
  @$core.override
  GetSealedRootResponse createEmptyInstance() => GetSealedRootResponse._();
  @$core.pragma('dart2js:noInline')
  static GetSealedRootResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetSealedRootResponse>(
          GetSealedRootResponse.$_createMessage);
  static GetSealedRootResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get sealedRoot => $_getN(0);
  @$pb.TagNumber(1)
  set sealedRoot($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSealedRoot() => $_has(0);
  @$pb.TagNumber(1)
  void clearSealedRoot() => $_clearField(1);
}

/// Sets the account's authenticator.
class EnrollAuthenticatorRequest extends $pb.GeneratedMessage {
  factory EnrollAuthenticatorRequest({
    $core.List<$core.int>? secret,
    $core.String? code,
    $core.Iterable<$core.String>? backupCodes,
  }) {
    final result = EnrollAuthenticatorRequest._();
    if (secret != null) result.secret = secret;
    if (code != null) result.code = code;
    if (backupCodes != null) result.backupCodes.addAll(backupCodes);
    return result;
  }

  EnrollAuthenticatorRequest._();

  factory EnrollAuthenticatorRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EnrollAuthenticatorRequest()..mergeFromBuffer(data, registry);
  factory EnrollAuthenticatorRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EnrollAuthenticatorRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EnrollAuthenticatorRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: EnrollAuthenticatorRequest.$_createMessage)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'secret', $pb.PbFieldType.OY)
    ..aOS(2, _omitFieldNames ? '' : 'code')
    ..pPS(3, _omitFieldNames ? '' : 'backupCodes')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EnrollAuthenticatorRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EnrollAuthenticatorRequest copyWith(
          void Function(EnrollAuthenticatorRequest) updates) =>
      super.copyWith(
              (message) => updates(message as EnrollAuthenticatorRequest))
          as EnrollAuthenticatorRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use EnrollAuthenticatorRequest() / EnrollAuthenticatorRequest.new instead')
  static EnrollAuthenticatorRequest create() => EnrollAuthenticatorRequest._();
  static $pb.GeneratedMessage $_createMessage() =>
      EnrollAuthenticatorRequest._();
  @$core.override
  EnrollAuthenticatorRequest createEmptyInstance() =>
      EnrollAuthenticatorRequest._();
  @$core.pragma('dart2js:noInline')
  static EnrollAuthenticatorRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EnrollAuthenticatorRequest>(
          EnrollAuthenticatorRequest.$_createMessage);
  static EnrollAuthenticatorRequest? _defaultInstance;

  /// The TOTP secret (RFC 6238: SHA-1, 30 seconds, 6 digits), 20 to 64 bytes.
  @$pb.TagNumber(1)
  $core.List<$core.int> get secret => $_getN(0);
  @$pb.TagNumber(1)
  set secret($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSecret() => $_has(0);
  @$pb.TagNumber(1)
  void clearSecret() => $_clearField(1);

  /// A current code from that secret, proving the authenticator app holds it.
  @$pb.TagNumber(2)
  $core.String get code => $_getSZ(1);
  @$pb.TagNumber(2)
  set code($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCode() => $_has(1);
  @$pb.TagNumber(2)
  void clearCode() => $_clearField(2);

  /// One-time backup codes, at most 10, each 8 to 32 characters. Stored hashed.
  @$pb.TagNumber(3)
  $pb.PbList<$core.String> get backupCodes => $_getList(2);
}

/// A human-readable confirmation.
class EnrollAuthenticatorResponse extends $pb.GeneratedMessage {
  factory EnrollAuthenticatorResponse({
    $core.String? message,
  }) {
    final result = EnrollAuthenticatorResponse._();
    if (message != null) result.message = message;
    return result;
  }

  EnrollAuthenticatorResponse._();

  factory EnrollAuthenticatorResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EnrollAuthenticatorResponse()..mergeFromBuffer(data, registry);
  factory EnrollAuthenticatorResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EnrollAuthenticatorResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EnrollAuthenticatorResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: EnrollAuthenticatorResponse.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EnrollAuthenticatorResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EnrollAuthenticatorResponse copyWith(
          void Function(EnrollAuthenticatorResponse) updates) =>
      super.copyWith(
              (message) => updates(message as EnrollAuthenticatorResponse))
          as EnrollAuthenticatorResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use EnrollAuthenticatorResponse() / EnrollAuthenticatorResponse.new instead')
  static EnrollAuthenticatorResponse create() =>
      EnrollAuthenticatorResponse._();
  static $pb.GeneratedMessage $_createMessage() =>
      EnrollAuthenticatorResponse._();
  @$core.override
  EnrollAuthenticatorResponse createEmptyInstance() =>
      EnrollAuthenticatorResponse._();
  @$core.pragma('dart2js:noInline')
  static EnrollAuthenticatorResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EnrollAuthenticatorResponse>(
          EnrollAuthenticatorResponse.$_createMessage);
  static EnrollAuthenticatorResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get message => $_getSZ(0);
  @$pb.TagNumber(1)
  set message($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);
}

/// Removes the account's authenticator.
class DisableAuthenticatorRequest extends $pb.GeneratedMessage {
  factory DisableAuthenticatorRequest() => DisableAuthenticatorRequest._();

  DisableAuthenticatorRequest._();

  factory DisableAuthenticatorRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DisableAuthenticatorRequest()..mergeFromBuffer(data, registry);
  factory DisableAuthenticatorRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DisableAuthenticatorRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DisableAuthenticatorRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: DisableAuthenticatorRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DisableAuthenticatorRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DisableAuthenticatorRequest copyWith(
          void Function(DisableAuthenticatorRequest) updates) =>
      super.copyWith(
              (message) => updates(message as DisableAuthenticatorRequest))
          as DisableAuthenticatorRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use DisableAuthenticatorRequest() / DisableAuthenticatorRequest.new instead')
  static DisableAuthenticatorRequest create() =>
      DisableAuthenticatorRequest._();
  static $pb.GeneratedMessage $_createMessage() =>
      DisableAuthenticatorRequest._();
  @$core.override
  DisableAuthenticatorRequest createEmptyInstance() =>
      DisableAuthenticatorRequest._();
  @$core.pragma('dart2js:noInline')
  static DisableAuthenticatorRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DisableAuthenticatorRequest>(
          DisableAuthenticatorRequest.$_createMessage);
  static DisableAuthenticatorRequest? _defaultInstance;
}

/// A human-readable confirmation.
class DisableAuthenticatorResponse extends $pb.GeneratedMessage {
  factory DisableAuthenticatorResponse({
    $core.String? message,
  }) {
    final result = DisableAuthenticatorResponse._();
    if (message != null) result.message = message;
    return result;
  }

  DisableAuthenticatorResponse._();

  factory DisableAuthenticatorResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DisableAuthenticatorResponse()..mergeFromBuffer(data, registry);
  factory DisableAuthenticatorResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DisableAuthenticatorResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DisableAuthenticatorResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: DisableAuthenticatorResponse.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DisableAuthenticatorResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DisableAuthenticatorResponse copyWith(
          void Function(DisableAuthenticatorResponse) updates) =>
      super.copyWith(
              (message) => updates(message as DisableAuthenticatorResponse))
          as DisableAuthenticatorResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use DisableAuthenticatorResponse() / DisableAuthenticatorResponse.new instead')
  static DisableAuthenticatorResponse create() =>
      DisableAuthenticatorResponse._();
  static $pb.GeneratedMessage $_createMessage() =>
      DisableAuthenticatorResponse._();
  @$core.override
  DisableAuthenticatorResponse createEmptyInstance() =>
      DisableAuthenticatorResponse._();
  @$core.pragma('dart2js:noInline')
  static DisableAuthenticatorResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DisableAuthenticatorResponse>(
          DisableAuthenticatorResponse.$_createMessage);
  static DisableAuthenticatorResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get message => $_getSZ(0);
  @$pb.TagNumber(1)
  set message($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);
}

/// Asks about the account's authenticator.
class GetAuthenticatorStatusRequest extends $pb.GeneratedMessage {
  factory GetAuthenticatorStatusRequest() => GetAuthenticatorStatusRequest._();

  GetAuthenticatorStatusRequest._();

  factory GetAuthenticatorStatusRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetAuthenticatorStatusRequest()..mergeFromBuffer(data, registry);
  factory GetAuthenticatorStatusRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetAuthenticatorStatusRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetAuthenticatorStatusRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: GetAuthenticatorStatusRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetAuthenticatorStatusRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetAuthenticatorStatusRequest copyWith(
          void Function(GetAuthenticatorStatusRequest) updates) =>
      super.copyWith(
              (message) => updates(message as GetAuthenticatorStatusRequest))
          as GetAuthenticatorStatusRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetAuthenticatorStatusRequest() / GetAuthenticatorStatusRequest.new instead')
  static GetAuthenticatorStatusRequest create() =>
      GetAuthenticatorStatusRequest._();
  static $pb.GeneratedMessage $_createMessage() =>
      GetAuthenticatorStatusRequest._();
  @$core.override
  GetAuthenticatorStatusRequest createEmptyInstance() =>
      GetAuthenticatorStatusRequest._();
  @$core.pragma('dart2js:noInline')
  static GetAuthenticatorStatusRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetAuthenticatorStatusRequest>(
          GetAuthenticatorStatusRequest.$_createMessage);
  static GetAuthenticatorStatusRequest? _defaultInstance;
}

/// Whether there is one.
class GetAuthenticatorStatusResponse extends $pb.GeneratedMessage {
  factory GetAuthenticatorStatusResponse({
    $core.bool? enabled,
    $core.int? backupCodesLeft,
  }) {
    final result = GetAuthenticatorStatusResponse._();
    if (enabled != null) result.enabled = enabled;
    if (backupCodesLeft != null) result.backupCodesLeft = backupCodesLeft;
    return result;
  }

  GetAuthenticatorStatusResponse._();

  factory GetAuthenticatorStatusResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetAuthenticatorStatusResponse()..mergeFromBuffer(data, registry);
  factory GetAuthenticatorStatusResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetAuthenticatorStatusResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetAuthenticatorStatusResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: GetAuthenticatorStatusResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'enabled')
    ..aI(2, _omitFieldNames ? '' : 'backupCodesLeft')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetAuthenticatorStatusResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetAuthenticatorStatusResponse copyWith(
          void Function(GetAuthenticatorStatusResponse) updates) =>
      super.copyWith(
              (message) => updates(message as GetAuthenticatorStatusResponse))
          as GetAuthenticatorStatusResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetAuthenticatorStatusResponse() / GetAuthenticatorStatusResponse.new instead')
  static GetAuthenticatorStatusResponse create() =>
      GetAuthenticatorStatusResponse._();
  static $pb.GeneratedMessage $_createMessage() =>
      GetAuthenticatorStatusResponse._();
  @$core.override
  GetAuthenticatorStatusResponse createEmptyInstance() =>
      GetAuthenticatorStatusResponse._();
  @$core.pragma('dart2js:noInline')
  static GetAuthenticatorStatusResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetAuthenticatorStatusResponse>(
          GetAuthenticatorStatusResponse.$_createMessage);
  static GetAuthenticatorStatusResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get enabled => $_getBF(0);
  @$pb.TagNumber(1)
  set enabled($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEnabled() => $_has(0);
  @$pb.TagNumber(1)
  void clearEnabled() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get backupCodesLeft => $_getIZ(1);
  @$pb.TagNumber(2)
  set backupCodesLeft($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasBackupCodesLeft() => $_has(1);
  @$pb.TagNumber(2)
  void clearBackupCodesLeft() => $_clearField(2);
}

/// Starts a pairing.
class StartPairingRequest extends $pb.GeneratedMessage {
  factory StartPairingRequest({
    $core.List<$core.int>? offer,
  }) {
    final result = StartPairingRequest._();
    if (offer != null) result.offer = offer;
    return result;
  }

  StartPairingRequest._();

  factory StartPairingRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StartPairingRequest()..mergeFromBuffer(data, registry);
  factory StartPairingRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StartPairingRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StartPairingRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: StartPairingRequest.$_createMessage)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'offer', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartPairingRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartPairingRequest copyWith(void Function(StartPairingRequest) updates) =>
      super.copyWith((message) => updates(message as StartPairingRequest))
          as StartPairingRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use StartPairingRequest() / StartPairingRequest.new instead')
  static StartPairingRequest create() => StartPairingRequest._();
  static $pb.GeneratedMessage $_createMessage() => StartPairingRequest._();
  @$core.override
  StartPairingRequest createEmptyInstance() => StartPairingRequest._();
  @$core.pragma('dart2js:noInline')
  static StartPairingRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StartPairingRequest>(
          StartPairingRequest.$_createMessage);
  static StartPairingRequest? _defaultInstance;

  /// The new device's pairing offer: opaque, at most 1 KiB.
  @$pb.TagNumber(1)
  $core.List<$core.int> get offer => $_getN(0);
  @$pb.TagNumber(1)
  set offer($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOffer() => $_has(0);
  @$pb.TagNumber(1)
  void clearOffer() => $_clearField(1);
}

/// The pairing to show in the pairing code.
class StartPairingResponse extends $pb.GeneratedMessage {
  factory StartPairingResponse({
    $core.String? pairingId,
    $core.String? takeToken,
    $1.Timestamp? expiresAt,
  }) {
    final result = StartPairingResponse._();
    if (pairingId != null) result.pairingId = pairingId;
    if (takeToken != null) result.takeToken = takeToken;
    if (expiresAt != null) result.expiresAt = expiresAt;
    return result;
  }

  StartPairingResponse._();

  factory StartPairingResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StartPairingResponse()..mergeFromBuffer(data, registry);
  factory StartPairingResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StartPairingResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StartPairingResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: StartPairingResponse.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'pairingId')
    ..aOS(2, _omitFieldNames ? '' : 'takeToken')
    ..aOM<$1.Timestamp>(3, _omitFieldNames ? '' : 'expiresAt',
        subBuilder: $1.Timestamp.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartPairingResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartPairingResponse copyWith(void Function(StartPairingResponse) updates) =>
      super.copyWith((message) => updates(message as StartPairingResponse))
          as StartPairingResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use StartPairingResponse() / StartPairingResponse.new instead')
  static StartPairingResponse create() => StartPairingResponse._();
  static $pb.GeneratedMessage $_createMessage() => StartPairingResponse._();
  @$core.override
  StartPairingResponse createEmptyInstance() => StartPairingResponse._();
  @$core.pragma('dart2js:noInline')
  static StartPairingResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StartPairingResponse>(
          StartPairingResponse.$_createMessage);
  static StartPairingResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get pairingId => $_getSZ(0);
  @$pb.TagNumber(1)
  set pairingId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPairingId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPairingId() => $_clearField(1);

  /// Kept by the new device and sent back to collect the approval.
  @$pb.TagNumber(2)
  $core.String get takeToken => $_getSZ(1);
  @$pb.TagNumber(2)
  set takeToken($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTakeToken() => $_has(1);
  @$pb.TagNumber(2)
  void clearTakeToken() => $_clearField(2);

  @$pb.TagNumber(3)
  $1.Timestamp get expiresAt => $_getN(2);
  @$pb.TagNumber(3)
  set expiresAt($1.Timestamp value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasExpiresAt() => $_has(2);
  @$pb.TagNumber(3)
  void clearExpiresAt() => $_clearField(3);
  @$pb.TagNumber(3)
  $1.Timestamp ensureExpiresAt() => $_ensure(2);
}

/// Fetches a pairing's offer.
class GetPairingOfferRequest extends $pb.GeneratedMessage {
  factory GetPairingOfferRequest({
    $core.String? pairingId,
  }) {
    final result = GetPairingOfferRequest._();
    if (pairingId != null) result.pairingId = pairingId;
    return result;
  }

  GetPairingOfferRequest._();

  factory GetPairingOfferRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetPairingOfferRequest()..mergeFromBuffer(data, registry);
  factory GetPairingOfferRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetPairingOfferRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetPairingOfferRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: GetPairingOfferRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'pairingId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetPairingOfferRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetPairingOfferRequest copyWith(
          void Function(GetPairingOfferRequest) updates) =>
      super.copyWith((message) => updates(message as GetPairingOfferRequest))
          as GetPairingOfferRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetPairingOfferRequest() / GetPairingOfferRequest.new instead')
  static GetPairingOfferRequest create() => GetPairingOfferRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetPairingOfferRequest._();
  @$core.override
  GetPairingOfferRequest createEmptyInstance() => GetPairingOfferRequest._();
  @$core.pragma('dart2js:noInline')
  static GetPairingOfferRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetPairingOfferRequest>(
          GetPairingOfferRequest.$_createMessage);
  static GetPairingOfferRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get pairingId => $_getSZ(0);
  @$pb.TagNumber(1)
  set pairingId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPairingId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPairingId() => $_clearField(1);
}

/// The offer, for checking against the pairing code's commitment.
class GetPairingOfferResponse extends $pb.GeneratedMessage {
  factory GetPairingOfferResponse({
    $core.List<$core.int>? offer,
  }) {
    final result = GetPairingOfferResponse._();
    if (offer != null) result.offer = offer;
    return result;
  }

  GetPairingOfferResponse._();

  factory GetPairingOfferResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetPairingOfferResponse()..mergeFromBuffer(data, registry);
  factory GetPairingOfferResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetPairingOfferResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetPairingOfferResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: GetPairingOfferResponse.$_createMessage)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'offer', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetPairingOfferResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetPairingOfferResponse copyWith(
          void Function(GetPairingOfferResponse) updates) =>
      super.copyWith((message) => updates(message as GetPairingOfferResponse))
          as GetPairingOfferResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetPairingOfferResponse() / GetPairingOfferResponse.new instead')
  static GetPairingOfferResponse create() => GetPairingOfferResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetPairingOfferResponse._();
  @$core.override
  GetPairingOfferResponse createEmptyInstance() => GetPairingOfferResponse._();
  @$core.pragma('dart2js:noInline')
  static GetPairingOfferResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetPairingOfferResponse>(
          GetPairingOfferResponse.$_createMessage);
  static GetPairingOfferResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get offer => $_getN(0);
  @$pb.TagNumber(1)
  set offer($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOffer() => $_has(0);
  @$pb.TagNumber(1)
  void clearOffer() => $_clearField(1);
}

/// Approves a pairing.
class ApprovePairingRequest extends $pb.GeneratedMessage {
  factory ApprovePairingRequest({
    $core.String? pairingId,
    $core.List<$core.int>? approval,
  }) {
    final result = ApprovePairingRequest._();
    if (pairingId != null) result.pairingId = pairingId;
    if (approval != null) result.approval = approval;
    return result;
  }

  ApprovePairingRequest._();

  factory ApprovePairingRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ApprovePairingRequest()..mergeFromBuffer(data, registry);
  factory ApprovePairingRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ApprovePairingRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ApprovePairingRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: ApprovePairingRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'pairingId')
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'approval', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ApprovePairingRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ApprovePairingRequest copyWith(
          void Function(ApprovePairingRequest) updates) =>
      super.copyWith((message) => updates(message as ApprovePairingRequest))
          as ApprovePairingRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ApprovePairingRequest() / ApprovePairingRequest.new instead')
  static ApprovePairingRequest create() => ApprovePairingRequest._();
  static $pb.GeneratedMessage $_createMessage() => ApprovePairingRequest._();
  @$core.override
  ApprovePairingRequest createEmptyInstance() => ApprovePairingRequest._();
  @$core.pragma('dart2js:noInline')
  static ApprovePairingRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ApprovePairingRequest>(
          ApprovePairingRequest.$_createMessage);
  static ApprovePairingRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get pairingId => $_getSZ(0);
  @$pb.TagNumber(1)
  set pairingId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPairingId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPairingId() => $_clearField(1);

  /// Sealed to the new device; at most 512 KiB.
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
class ApprovePairingResponse extends $pb.GeneratedMessage {
  factory ApprovePairingResponse({
    $core.String? message,
  }) {
    final result = ApprovePairingResponse._();
    if (message != null) result.message = message;
    return result;
  }

  ApprovePairingResponse._();

  factory ApprovePairingResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ApprovePairingResponse()..mergeFromBuffer(data, registry);
  factory ApprovePairingResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ApprovePairingResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ApprovePairingResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: ApprovePairingResponse.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ApprovePairingResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ApprovePairingResponse copyWith(
          void Function(ApprovePairingResponse) updates) =>
      super.copyWith((message) => updates(message as ApprovePairingResponse))
          as ApprovePairingResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ApprovePairingResponse() / ApprovePairingResponse.new instead')
  static ApprovePairingResponse create() => ApprovePairingResponse._();
  static $pb.GeneratedMessage $_createMessage() => ApprovePairingResponse._();
  @$core.override
  ApprovePairingResponse createEmptyInstance() => ApprovePairingResponse._();
  @$core.pragma('dart2js:noInline')
  static ApprovePairingResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ApprovePairingResponse>(
          ApprovePairingResponse.$_createMessage);
  static ApprovePairingResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get message => $_getSZ(0);
  @$pb.TagNumber(1)
  set message($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);
}

/// Collects a pairing's approval.
class TakePairingApprovalRequest extends $pb.GeneratedMessage {
  factory TakePairingApprovalRequest({
    $core.String? pairingId,
    $core.String? takeToken,
  }) {
    final result = TakePairingApprovalRequest._();
    if (pairingId != null) result.pairingId = pairingId;
    if (takeToken != null) result.takeToken = takeToken;
    return result;
  }

  TakePairingApprovalRequest._();

  factory TakePairingApprovalRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TakePairingApprovalRequest()..mergeFromBuffer(data, registry);
  factory TakePairingApprovalRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TakePairingApprovalRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TakePairingApprovalRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: TakePairingApprovalRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'pairingId')
    ..aOS(2, _omitFieldNames ? '' : 'takeToken')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TakePairingApprovalRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TakePairingApprovalRequest copyWith(
          void Function(TakePairingApprovalRequest) updates) =>
      super.copyWith(
              (message) => updates(message as TakePairingApprovalRequest))
          as TakePairingApprovalRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use TakePairingApprovalRequest() / TakePairingApprovalRequest.new instead')
  static TakePairingApprovalRequest create() => TakePairingApprovalRequest._();
  static $pb.GeneratedMessage $_createMessage() =>
      TakePairingApprovalRequest._();
  @$core.override
  TakePairingApprovalRequest createEmptyInstance() =>
      TakePairingApprovalRequest._();
  @$core.pragma('dart2js:noInline')
  static TakePairingApprovalRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TakePairingApprovalRequest>(
          TakePairingApprovalRequest.$_createMessage);
  static TakePairingApprovalRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get pairingId => $_getSZ(0);
  @$pb.TagNumber(1)
  set pairingId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPairingId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPairingId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get takeToken => $_getSZ(1);
  @$pb.TagNumber(2)
  set takeToken($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTakeToken() => $_has(1);
  @$pb.TagNumber(2)
  void clearTakeToken() => $_clearField(2);
}

/// The approval, once a paired device has given it.
class TakePairingApprovalResponse extends $pb.GeneratedMessage {
  factory TakePairingApprovalResponse({
    $core.List<$core.int>? approval,
  }) {
    final result = TakePairingApprovalResponse._();
    if (approval != null) result.approval = approval;
    return result;
  }

  TakePairingApprovalResponse._();

  factory TakePairingApprovalResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TakePairingApprovalResponse()..mergeFromBuffer(data, registry);
  factory TakePairingApprovalResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TakePairingApprovalResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TakePairingApprovalResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: TakePairingApprovalResponse.$_createMessage)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'approval', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TakePairingApprovalResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TakePairingApprovalResponse copyWith(
          void Function(TakePairingApprovalResponse) updates) =>
      super.copyWith(
              (message) => updates(message as TakePairingApprovalResponse))
          as TakePairingApprovalResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use TakePairingApprovalResponse() / TakePairingApprovalResponse.new instead')
  static TakePairingApprovalResponse create() =>
      TakePairingApprovalResponse._();
  static $pb.GeneratedMessage $_createMessage() =>
      TakePairingApprovalResponse._();
  @$core.override
  TakePairingApprovalResponse createEmptyInstance() =>
      TakePairingApprovalResponse._();
  @$core.pragma('dart2js:noInline')
  static TakePairingApprovalResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TakePairingApprovalResponse>(
          TakePairingApprovalResponse.$_createMessage);
  static TakePairingApprovalResponse? _defaultInstance;

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
