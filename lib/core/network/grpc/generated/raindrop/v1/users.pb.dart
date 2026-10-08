// This is a generated file - do not edit.
//
// Generated from raindrop/v1/users.proto.

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

import 'users.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'users.pbenum.dart';

/// The caller's own account.
class UserProfile extends $pb.GeneratedMessage {
  factory UserProfile({
    $core.String? userId,
    $core.String? username,
    UserState? state,
    $1.Timestamp? createdAt,
    $1.Timestamp? lastLoginAt,
  }) {
    final result = UserProfile._();
    if (userId != null) result.userId = userId;
    if (username != null) result.username = username;
    if (state != null) result.state = state;
    if (createdAt != null) result.createdAt = createdAt;
    if (lastLoginAt != null) result.lastLoginAt = lastLoginAt;
    return result;
  }

  UserProfile._();

  factory UserProfile.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UserProfile()..mergeFromBuffer(data, registry);
  factory UserProfile.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UserProfile()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UserProfile',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: UserProfile.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'userId')
    ..aOS(2, _omitFieldNames ? '' : 'username')
    ..aE<UserState>(3, _omitFieldNames ? '' : 'state',
        enumValues: UserState.values)
    ..aOM<$1.Timestamp>(4, _omitFieldNames ? '' : 'createdAt',
        subBuilder: $1.Timestamp.$_createMessage)
    ..aOM<$1.Timestamp>(5, _omitFieldNames ? '' : 'lastLoginAt',
        subBuilder: $1.Timestamp.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UserProfile clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UserProfile copyWith(void Function(UserProfile) updates) =>
      super.copyWith((message) => updates(message as UserProfile))
          as UserProfile;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use UserProfile() / UserProfile.new instead')
  static UserProfile create() => UserProfile._();
  static $pb.GeneratedMessage $_createMessage() => UserProfile._();
  @$core.override
  UserProfile createEmptyInstance() => UserProfile._();
  @$core.pragma('dart2js:noInline')
  static UserProfile getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UserProfile>(
          UserProfile.$_createMessage);
  static UserProfile? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get userId => $_getSZ(0);
  @$pb.TagNumber(1)
  set userId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get username => $_getSZ(1);
  @$pb.TagNumber(2)
  set username($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUsername() => $_has(1);
  @$pb.TagNumber(2)
  void clearUsername() => $_clearField(2);

  @$pb.TagNumber(3)
  UserState get state => $_getN(2);
  @$pb.TagNumber(3)
  set state(UserState value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasState() => $_has(2);
  @$pb.TagNumber(3)
  void clearState() => $_clearField(3);

  @$pb.TagNumber(4)
  $1.Timestamp get createdAt => $_getN(3);
  @$pb.TagNumber(4)
  set createdAt($1.Timestamp value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasCreatedAt() => $_has(3);
  @$pb.TagNumber(4)
  void clearCreatedAt() => $_clearField(4);
  @$pb.TagNumber(4)
  $1.Timestamp ensureCreatedAt() => $_ensure(3);

  @$pb.TagNumber(5)
  $1.Timestamp get lastLoginAt => $_getN(4);
  @$pb.TagNumber(5)
  set lastLoginAt($1.Timestamp value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasLastLoginAt() => $_has(4);
  @$pb.TagNumber(5)
  void clearLastLoginAt() => $_clearField(5);
  @$pb.TagNumber(5)
  $1.Timestamp ensureLastLoginAt() => $_ensure(4);
}

/// What any member may see about a UUID.
class PublicUserProfile extends $pb.GeneratedMessage {
  factory PublicUserProfile({
    $core.String? userId,
    $core.String? username,
    UserState? state,
  }) {
    final result = PublicUserProfile._();
    if (userId != null) result.userId = userId;
    if (username != null) result.username = username;
    if (state != null) result.state = state;
    return result;
  }

  PublicUserProfile._();

  factory PublicUserProfile.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PublicUserProfile()..mergeFromBuffer(data, registry);
  factory PublicUserProfile.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PublicUserProfile()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PublicUserProfile',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: PublicUserProfile.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'userId')
    ..aOS(2, _omitFieldNames ? '' : 'username')
    ..aE<UserState>(3, _omitFieldNames ? '' : 'state',
        enumValues: UserState.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PublicUserProfile clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PublicUserProfile copyWith(void Function(PublicUserProfile) updates) =>
      super.copyWith((message) => updates(message as PublicUserProfile))
          as PublicUserProfile;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PublicUserProfile() / PublicUserProfile.new instead')
  static PublicUserProfile create() => PublicUserProfile._();
  static $pb.GeneratedMessage $_createMessage() => PublicUserProfile._();
  @$core.override
  PublicUserProfile createEmptyInstance() => PublicUserProfile._();
  @$core.pragma('dart2js:noInline')
  static PublicUserProfile getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PublicUserProfile>(
          PublicUserProfile.$_createMessage);
  static PublicUserProfile? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get userId => $_getSZ(0);
  @$pb.TagNumber(1)
  set userId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => $_clearField(1);

  /// Absent once the account has been erased.
  @$pb.TagNumber(2)
  $core.String get username => $_getSZ(1);
  @$pb.TagNumber(2)
  set username($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUsername() => $_has(1);
  @$pb.TagNumber(2)
  void clearUsername() => $_clearField(2);

  @$pb.TagNumber(3)
  UserState get state => $_getN(2);
  @$pb.TagNumber(3)
  set state(UserState value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasState() => $_has(2);
  @$pb.TagNumber(3)
  void clearState() => $_clearField(3);
}

/// A freshly opened session and the account it belongs to.
class Session extends $pb.GeneratedMessage {
  factory Session({
    UserProfile? user,
    $core.String? token,
    $1.Timestamp? expiresAt,
  }) {
    final result = Session._();
    if (user != null) result.user = user;
    if (token != null) result.token = token;
    if (expiresAt != null) result.expiresAt = expiresAt;
    return result;
  }

  Session._();

  factory Session.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Session()..mergeFromBuffer(data, registry);
  factory Session.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Session()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Session',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: Session.$_createMessage)
    ..aOM<UserProfile>(1, _omitFieldNames ? '' : 'user',
        subBuilder: UserProfile.$_createMessage)
    ..aOS(2, _omitFieldNames ? '' : 'token')
    ..aOM<$1.Timestamp>(3, _omitFieldNames ? '' : 'expiresAt',
        subBuilder: $1.Timestamp.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Session clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Session copyWith(void Function(Session) updates) =>
      super.copyWith((message) => updates(message as Session)) as Session;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Session() / Session.new instead')
  static Session create() => Session._();
  static $pb.GeneratedMessage $_createMessage() => Session._();
  @$core.override
  Session createEmptyInstance() => Session._();
  @$core.pragma('dart2js:noInline')
  static Session getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Session>(Session.$_createMessage);
  static Session? _defaultInstance;

  @$pb.TagNumber(1)
  UserProfile get user => $_getN(0);
  @$pb.TagNumber(1)
  set user(UserProfile value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasUser() => $_has(0);
  @$pb.TagNumber(1)
  void clearUser() => $_clearField(1);
  @$pb.TagNumber(1)
  UserProfile ensureUser() => $_ensure(0);

  /// Sent as `authorization: Bearer <token>` metadata on every authenticated call.
  @$pb.TagNumber(2)
  $core.String get token => $_getSZ(1);
  @$pb.TagNumber(2)
  set token($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasToken() => $_has(1);
  @$pb.TagNumber(2)
  void clearToken() => $_clearField(2);

  /// When the session lapses if the client goes idle; the event stream's heartbeat keeps it alive.
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

/// Asks what a UUID means here.
class GetUserStatusRequest extends $pb.GeneratedMessage {
  factory GetUserStatusRequest({
    $core.String? userId,
  }) {
    final result = GetUserStatusRequest._();
    if (userId != null) result.userId = userId;
    return result;
  }

  GetUserStatusRequest._();

  factory GetUserStatusRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetUserStatusRequest()..mergeFromBuffer(data, registry);
  factory GetUserStatusRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetUserStatusRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetUserStatusRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: GetUserStatusRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'userId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetUserStatusRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetUserStatusRequest copyWith(void Function(GetUserStatusRequest) updates) =>
      super.copyWith((message) => updates(message as GetUserStatusRequest))
          as GetUserStatusRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetUserStatusRequest() / GetUserStatusRequest.new instead')
  static GetUserStatusRequest create() => GetUserStatusRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetUserStatusRequest._();
  @$core.override
  GetUserStatusRequest createEmptyInstance() => GetUserStatusRequest._();
  @$core.pragma('dart2js:noInline')
  static GetUserStatusRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetUserStatusRequest>(
          GetUserStatusRequest.$_createMessage);
  static GetUserStatusRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get userId => $_getSZ(0);
  @$pb.TagNumber(1)
  set userId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => $_clearField(1);
}

/// unregistered or erased: register; active: ask for the password; left_preserved: offer to rejoin.
class GetUserStatusResponse extends $pb.GeneratedMessage {
  factory GetUserStatusResponse({
    $core.String? userId,
    UserState? state,
    $core.String? username,
    $1.Timestamp? dataExpiresAt,
  }) {
    final result = GetUserStatusResponse._();
    if (userId != null) result.userId = userId;
    if (state != null) result.state = state;
    if (username != null) result.username = username;
    if (dataExpiresAt != null) result.dataExpiresAt = dataExpiresAt;
    return result;
  }

  GetUserStatusResponse._();

  factory GetUserStatusResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetUserStatusResponse()..mergeFromBuffer(data, registry);
  factory GetUserStatusResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetUserStatusResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetUserStatusResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: GetUserStatusResponse.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'userId')
    ..aE<UserState>(2, _omitFieldNames ? '' : 'state',
        enumValues: UserState.values)
    ..aOS(3, _omitFieldNames ? '' : 'username')
    ..aOM<$1.Timestamp>(4, _omitFieldNames ? '' : 'dataExpiresAt',
        subBuilder: $1.Timestamp.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetUserStatusResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetUserStatusResponse copyWith(
          void Function(GetUserStatusResponse) updates) =>
      super.copyWith((message) => updates(message as GetUserStatusResponse))
          as GetUserStatusResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetUserStatusResponse() / GetUserStatusResponse.new instead')
  static GetUserStatusResponse create() => GetUserStatusResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetUserStatusResponse._();
  @$core.override
  GetUserStatusResponse createEmptyInstance() => GetUserStatusResponse._();
  @$core.pragma('dart2js:noInline')
  static GetUserStatusResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetUserStatusResponse>(
          GetUserStatusResponse.$_createMessage);
  static GetUserStatusResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get userId => $_getSZ(0);
  @$pb.TagNumber(1)
  set userId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => $_clearField(1);

  @$pb.TagNumber(2)
  UserState get state => $_getN(1);
  @$pb.TagNumber(2)
  set state(UserState value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasState() => $_has(1);
  @$pb.TagNumber(2)
  void clearState() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get username => $_getSZ(2);
  @$pb.TagNumber(3)
  set username($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasUsername() => $_has(2);
  @$pb.TagNumber(3)
  void clearUsername() => $_clearField(3);

  /// When a preserved account will be erased.
  @$pb.TagNumber(4)
  $1.Timestamp get dataExpiresAt => $_getN(3);
  @$pb.TagNumber(4)
  set dataExpiresAt($1.Timestamp value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasDataExpiresAt() => $_has(3);
  @$pb.TagNumber(4)
  void clearDataExpiresAt() => $_clearField(4);
  @$pb.TagNumber(4)
  $1.Timestamp ensureDataExpiresAt() => $_ensure(3);
}

/// Asks whether a username is free.
class CheckUsernameRequest extends $pb.GeneratedMessage {
  factory CheckUsernameRequest({
    $core.String? username,
  }) {
    final result = CheckUsernameRequest._();
    if (username != null) result.username = username;
    return result;
  }

  CheckUsernameRequest._();

  factory CheckUsernameRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CheckUsernameRequest()..mergeFromBuffer(data, registry);
  factory CheckUsernameRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CheckUsernameRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CheckUsernameRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: CheckUsernameRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'username')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CheckUsernameRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CheckUsernameRequest copyWith(void Function(CheckUsernameRequest) updates) =>
      super.copyWith((message) => updates(message as CheckUsernameRequest))
          as CheckUsernameRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use CheckUsernameRequest() / CheckUsernameRequest.new instead')
  static CheckUsernameRequest create() => CheckUsernameRequest._();
  static $pb.GeneratedMessage $_createMessage() => CheckUsernameRequest._();
  @$core.override
  CheckUsernameRequest createEmptyInstance() => CheckUsernameRequest._();
  @$core.pragma('dart2js:noInline')
  static CheckUsernameRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CheckUsernameRequest>(
          CheckUsernameRequest.$_createMessage);
  static CheckUsernameRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get username => $_getSZ(0);
  @$pb.TagNumber(1)
  set username($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUsername() => $_has(0);
  @$pb.TagNumber(1)
  void clearUsername() => $_clearField(1);
}

/// Whether the username is free, and why not when it is not.
class CheckUsernameResponse extends $pb.GeneratedMessage {
  factory CheckUsernameResponse({
    $core.String? username,
    $core.bool? available,
    $core.String? reason,
  }) {
    final result = CheckUsernameResponse._();
    if (username != null) result.username = username;
    if (available != null) result.available = available;
    if (reason != null) result.reason = reason;
    return result;
  }

  CheckUsernameResponse._();

  factory CheckUsernameResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CheckUsernameResponse()..mergeFromBuffer(data, registry);
  factory CheckUsernameResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CheckUsernameResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CheckUsernameResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: CheckUsernameResponse.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'username')
    ..aOB(2, _omitFieldNames ? '' : 'available')
    ..aOS(3, _omitFieldNames ? '' : 'reason')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CheckUsernameResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CheckUsernameResponse copyWith(
          void Function(CheckUsernameResponse) updates) =>
      super.copyWith((message) => updates(message as CheckUsernameResponse))
          as CheckUsernameResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use CheckUsernameResponse() / CheckUsernameResponse.new instead')
  static CheckUsernameResponse create() => CheckUsernameResponse._();
  static $pb.GeneratedMessage $_createMessage() => CheckUsernameResponse._();
  @$core.override
  CheckUsernameResponse createEmptyInstance() => CheckUsernameResponse._();
  @$core.pragma('dart2js:noInline')
  static CheckUsernameResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CheckUsernameResponse>(
          CheckUsernameResponse.$_createMessage);
  static CheckUsernameResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get username => $_getSZ(0);
  @$pb.TagNumber(1)
  set username($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUsername() => $_has(0);
  @$pb.TagNumber(1)
  void clearUsername() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get available => $_getBF(1);
  @$pb.TagNumber(2)
  set available($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAvailable() => $_has(1);
  @$pb.TagNumber(2)
  void clearAvailable() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get reason => $_getSZ(2);
  @$pb.TagNumber(3)
  set reason($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasReason() => $_has(2);
  @$pb.TagNumber(3)
  void clearReason() => $_clearField(3);
}

/// Claims a username and password for the client's own UUID.
class RegisterRequest extends $pb.GeneratedMessage {
  factory RegisterRequest({
    $core.String? userId,
    $core.String? username,
    $core.String? password,
  }) {
    final result = RegisterRequest._();
    if (userId != null) result.userId = userId;
    if (username != null) result.username = username;
    if (password != null) result.password = password;
    return result;
  }

  RegisterRequest._();

  factory RegisterRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RegisterRequest()..mergeFromBuffer(data, registry);
  factory RegisterRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RegisterRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RegisterRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: RegisterRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'userId')
    ..aOS(2, _omitFieldNames ? '' : 'username')
    ..aOS(3, _omitFieldNames ? '' : 'password')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RegisterRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RegisterRequest copyWith(void Function(RegisterRequest) updates) =>
      super.copyWith((message) => updates(message as RegisterRequest))
          as RegisterRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RegisterRequest() / RegisterRequest.new instead')
  static RegisterRequest create() => RegisterRequest._();
  static $pb.GeneratedMessage $_createMessage() => RegisterRequest._();
  @$core.override
  RegisterRequest createEmptyInstance() => RegisterRequest._();
  @$core.pragma('dart2js:noInline')
  static RegisterRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RegisterRequest>(
          RegisterRequest.$_createMessage);
  static RegisterRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get userId => $_getSZ(0);
  @$pb.TagNumber(1)
  set userId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get username => $_getSZ(1);
  @$pb.TagNumber(2)
  set username($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUsername() => $_has(1);
  @$pb.TagNumber(2)
  void clearUsername() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get password => $_getSZ(2);
  @$pb.TagNumber(3)
  set password($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPassword() => $_has(2);
  @$pb.TagNumber(3)
  void clearPassword() => $_clearField(3);
}

/// The new account's first session.
class RegisterResponse extends $pb.GeneratedMessage {
  factory RegisterResponse({
    Session? session,
  }) {
    final result = RegisterResponse._();
    if (session != null) result.session = session;
    return result;
  }

  RegisterResponse._();

  factory RegisterResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RegisterResponse()..mergeFromBuffer(data, registry);
  factory RegisterResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RegisterResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RegisterResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: RegisterResponse.$_createMessage)
    ..aOM<Session>(1, _omitFieldNames ? '' : 'session',
        subBuilder: Session.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RegisterResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RegisterResponse copyWith(void Function(RegisterResponse) updates) =>
      super.copyWith((message) => updates(message as RegisterResponse))
          as RegisterResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RegisterResponse() / RegisterResponse.new instead')
  static RegisterResponse create() => RegisterResponse._();
  static $pb.GeneratedMessage $_createMessage() => RegisterResponse._();
  @$core.override
  RegisterResponse createEmptyInstance() => RegisterResponse._();
  @$core.pragma('dart2js:noInline')
  static RegisterResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RegisterResponse>(
          RegisterResponse.$_createMessage);
  static RegisterResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Session get session => $_getN(0);
  @$pb.TagNumber(1)
  set session(Session value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSession() => $_has(0);
  @$pb.TagNumber(1)
  void clearSession() => $_clearField(1);
  @$pb.TagNumber(1)
  Session ensureSession() => $_ensure(0);
}

/// Logs in by UUID, or by username for a client that lost its UUID.
class LoginRequest extends $pb.GeneratedMessage {
  factory LoginRequest({
    $core.String? userId,
    $core.String? username,
    $core.String? password,
  }) {
    final result = LoginRequest._();
    if (userId != null) result.userId = userId;
    if (username != null) result.username = username;
    if (password != null) result.password = password;
    return result;
  }

  LoginRequest._();

  factory LoginRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LoginRequest()..mergeFromBuffer(data, registry);
  factory LoginRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LoginRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LoginRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: LoginRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'userId')
    ..aOS(2, _omitFieldNames ? '' : 'username')
    ..aOS(3, _omitFieldNames ? '' : 'password')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LoginRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LoginRequest copyWith(void Function(LoginRequest) updates) =>
      super.copyWith((message) => updates(message as LoginRequest))
          as LoginRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use LoginRequest() / LoginRequest.new instead')
  static LoginRequest create() => LoginRequest._();
  static $pb.GeneratedMessage $_createMessage() => LoginRequest._();
  @$core.override
  LoginRequest createEmptyInstance() => LoginRequest._();
  @$core.pragma('dart2js:noInline')
  static LoginRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LoginRequest>(
          LoginRequest.$_createMessage);
  static LoginRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get userId => $_getSZ(0);
  @$pb.TagNumber(1)
  set userId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get username => $_getSZ(1);
  @$pb.TagNumber(2)
  set username($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUsername() => $_has(1);
  @$pb.TagNumber(2)
  void clearUsername() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get password => $_getSZ(2);
  @$pb.TagNumber(3)
  set password($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPassword() => $_has(2);
  @$pb.TagNumber(3)
  void clearPassword() => $_clearField(3);
}

/// The new session.
class LoginResponse extends $pb.GeneratedMessage {
  factory LoginResponse({
    Session? session,
  }) {
    final result = LoginResponse._();
    if (session != null) result.session = session;
    return result;
  }

  LoginResponse._();

  factory LoginResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LoginResponse()..mergeFromBuffer(data, registry);
  factory LoginResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LoginResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LoginResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: LoginResponse.$_createMessage)
    ..aOM<Session>(1, _omitFieldNames ? '' : 'session',
        subBuilder: Session.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LoginResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LoginResponse copyWith(void Function(LoginResponse) updates) =>
      super.copyWith((message) => updates(message as LoginResponse))
          as LoginResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use LoginResponse() / LoginResponse.new instead')
  static LoginResponse create() => LoginResponse._();
  static $pb.GeneratedMessage $_createMessage() => LoginResponse._();
  @$core.override
  LoginResponse createEmptyInstance() => LoginResponse._();
  @$core.pragma('dart2js:noInline')
  static LoginResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LoginResponse>(
          LoginResponse.$_createMessage);
  static LoginResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Session get session => $_getN(0);
  @$pb.TagNumber(1)
  set session(Session value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSession() => $_has(0);
  @$pb.TagNumber(1)
  void clearSession() => $_clearField(1);
  @$pb.TagNumber(1)
  Session ensureSession() => $_ensure(0);
}

/// Restores a preserved account, by UUID or by its still-reserved username.
class RejoinRequest extends $pb.GeneratedMessage {
  factory RejoinRequest({
    $core.String? userId,
    $core.String? username,
    $core.String? password,
  }) {
    final result = RejoinRequest._();
    if (userId != null) result.userId = userId;
    if (username != null) result.username = username;
    if (password != null) result.password = password;
    return result;
  }

  RejoinRequest._();

  factory RejoinRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RejoinRequest()..mergeFromBuffer(data, registry);
  factory RejoinRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RejoinRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RejoinRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: RejoinRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'userId')
    ..aOS(2, _omitFieldNames ? '' : 'username')
    ..aOS(3, _omitFieldNames ? '' : 'password')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RejoinRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RejoinRequest copyWith(void Function(RejoinRequest) updates) =>
      super.copyWith((message) => updates(message as RejoinRequest))
          as RejoinRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RejoinRequest() / RejoinRequest.new instead')
  static RejoinRequest create() => RejoinRequest._();
  static $pb.GeneratedMessage $_createMessage() => RejoinRequest._();
  @$core.override
  RejoinRequest createEmptyInstance() => RejoinRequest._();
  @$core.pragma('dart2js:noInline')
  static RejoinRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RejoinRequest>(
          RejoinRequest.$_createMessage);
  static RejoinRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get userId => $_getSZ(0);
  @$pb.TagNumber(1)
  set userId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get username => $_getSZ(1);
  @$pb.TagNumber(2)
  set username($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUsername() => $_has(1);
  @$pb.TagNumber(2)
  void clearUsername() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get password => $_getSZ(2);
  @$pb.TagNumber(3)
  set password($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPassword() => $_has(2);
  @$pb.TagNumber(3)
  void clearPassword() => $_clearField(3);
}

/// The restored account's session.
class RejoinResponse extends $pb.GeneratedMessage {
  factory RejoinResponse({
    Session? session,
  }) {
    final result = RejoinResponse._();
    if (session != null) result.session = session;
    return result;
  }

  RejoinResponse._();

  factory RejoinResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RejoinResponse()..mergeFromBuffer(data, registry);
  factory RejoinResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RejoinResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RejoinResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: RejoinResponse.$_createMessage)
    ..aOM<Session>(1, _omitFieldNames ? '' : 'session',
        subBuilder: Session.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RejoinResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RejoinResponse copyWith(void Function(RejoinResponse) updates) =>
      super.copyWith((message) => updates(message as RejoinResponse))
          as RejoinResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RejoinResponse() / RejoinResponse.new instead')
  static RejoinResponse create() => RejoinResponse._();
  static $pb.GeneratedMessage $_createMessage() => RejoinResponse._();
  @$core.override
  RejoinResponse createEmptyInstance() => RejoinResponse._();
  @$core.pragma('dart2js:noInline')
  static RejoinResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RejoinResponse>(
          RejoinResponse.$_createMessage);
  static RejoinResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Session get session => $_getN(0);
  @$pb.TagNumber(1)
  set session(Session value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSession() => $_has(0);
  @$pb.TagNumber(1)
  void clearSession() => $_clearField(1);
  @$pb.TagNumber(1)
  Session ensureSession() => $_ensure(0);
}

/// Ends the calling session.
class LogoutRequest extends $pb.GeneratedMessage {
  factory LogoutRequest() => LogoutRequest._();

  LogoutRequest._();

  factory LogoutRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LogoutRequest()..mergeFromBuffer(data, registry);
  factory LogoutRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LogoutRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LogoutRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: LogoutRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LogoutRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LogoutRequest copyWith(void Function(LogoutRequest) updates) =>
      super.copyWith((message) => updates(message as LogoutRequest))
          as LogoutRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use LogoutRequest() / LogoutRequest.new instead')
  static LogoutRequest create() => LogoutRequest._();
  static $pb.GeneratedMessage $_createMessage() => LogoutRequest._();
  @$core.override
  LogoutRequest createEmptyInstance() => LogoutRequest._();
  @$core.pragma('dart2js:noInline')
  static LogoutRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LogoutRequest>(
          LogoutRequest.$_createMessage);
  static LogoutRequest? _defaultInstance;
}

/// A human-readable confirmation.
class LogoutResponse extends $pb.GeneratedMessage {
  factory LogoutResponse({
    $core.String? message,
  }) {
    final result = LogoutResponse._();
    if (message != null) result.message = message;
    return result;
  }

  LogoutResponse._();

  factory LogoutResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LogoutResponse()..mergeFromBuffer(data, registry);
  factory LogoutResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LogoutResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LogoutResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: LogoutResponse.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LogoutResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LogoutResponse copyWith(void Function(LogoutResponse) updates) =>
      super.copyWith((message) => updates(message as LogoutResponse))
          as LogoutResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use LogoutResponse() / LogoutResponse.new instead')
  static LogoutResponse create() => LogoutResponse._();
  static $pb.GeneratedMessage $_createMessage() => LogoutResponse._();
  @$core.override
  LogoutResponse createEmptyInstance() => LogoutResponse._();
  @$core.pragma('dart2js:noInline')
  static LogoutResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LogoutResponse>(
          LogoutResponse.$_createMessage);
  static LogoutResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get message => $_getSZ(0);
  @$pb.TagNumber(1)
  set message($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);
}

/// Asks for the caller's own account.
class GetMeRequest extends $pb.GeneratedMessage {
  factory GetMeRequest() => GetMeRequest._();

  GetMeRequest._();

  factory GetMeRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetMeRequest()..mergeFromBuffer(data, registry);
  factory GetMeRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetMeRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetMeRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: GetMeRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetMeRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetMeRequest copyWith(void Function(GetMeRequest) updates) =>
      super.copyWith((message) => updates(message as GetMeRequest))
          as GetMeRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetMeRequest() / GetMeRequest.new instead')
  static GetMeRequest create() => GetMeRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetMeRequest._();
  @$core.override
  GetMeRequest createEmptyInstance() => GetMeRequest._();
  @$core.pragma('dart2js:noInline')
  static GetMeRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetMeRequest>(
          GetMeRequest.$_createMessage);
  static GetMeRequest? _defaultInstance;
}

/// The caller's own account.
class GetMeResponse extends $pb.GeneratedMessage {
  factory GetMeResponse({
    UserProfile? user,
  }) {
    final result = GetMeResponse._();
    if (user != null) result.user = user;
    return result;
  }

  GetMeResponse._();

  factory GetMeResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetMeResponse()..mergeFromBuffer(data, registry);
  factory GetMeResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetMeResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetMeResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: GetMeResponse.$_createMessage)
    ..aOM<UserProfile>(1, _omitFieldNames ? '' : 'user',
        subBuilder: UserProfile.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetMeResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetMeResponse copyWith(void Function(GetMeResponse) updates) =>
      super.copyWith((message) => updates(message as GetMeResponse))
          as GetMeResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetMeResponse() / GetMeResponse.new instead')
  static GetMeResponse create() => GetMeResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetMeResponse._();
  @$core.override
  GetMeResponse createEmptyInstance() => GetMeResponse._();
  @$core.pragma('dart2js:noInline')
  static GetMeResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetMeResponse>(
          GetMeResponse.$_createMessage);
  static GetMeResponse? _defaultInstance;

  @$pb.TagNumber(1)
  UserProfile get user => $_getN(0);
  @$pb.TagNumber(1)
  set user(UserProfile value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasUser() => $_has(0);
  @$pb.TagNumber(1)
  void clearUser() => $_clearField(1);
  @$pb.TagNumber(1)
  UserProfile ensureUser() => $_ensure(0);
}

/// Asks what a UUID's name is.
class LookupUserRequest extends $pb.GeneratedMessage {
  factory LookupUserRequest({
    $core.String? userId,
  }) {
    final result = LookupUserRequest._();
    if (userId != null) result.userId = userId;
    return result;
  }

  LookupUserRequest._();

  factory LookupUserRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LookupUserRequest()..mergeFromBuffer(data, registry);
  factory LookupUserRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LookupUserRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LookupUserRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: LookupUserRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'userId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LookupUserRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LookupUserRequest copyWith(void Function(LookupUserRequest) updates) =>
      super.copyWith((message) => updates(message as LookupUserRequest))
          as LookupUserRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use LookupUserRequest() / LookupUserRequest.new instead')
  static LookupUserRequest create() => LookupUserRequest._();
  static $pb.GeneratedMessage $_createMessage() => LookupUserRequest._();
  @$core.override
  LookupUserRequest createEmptyInstance() => LookupUserRequest._();
  @$core.pragma('dart2js:noInline')
  static LookupUserRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LookupUserRequest>(
          LookupUserRequest.$_createMessage);
  static LookupUserRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get userId => $_getSZ(0);
  @$pb.TagNumber(1)
  set userId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => $_clearField(1);
}

/// What any member may see about that UUID.
class LookupUserResponse extends $pb.GeneratedMessage {
  factory LookupUserResponse({
    PublicUserProfile? user,
  }) {
    final result = LookupUserResponse._();
    if (user != null) result.user = user;
    return result;
  }

  LookupUserResponse._();

  factory LookupUserResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LookupUserResponse()..mergeFromBuffer(data, registry);
  factory LookupUserResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LookupUserResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LookupUserResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: LookupUserResponse.$_createMessage)
    ..aOM<PublicUserProfile>(1, _omitFieldNames ? '' : 'user',
        subBuilder: PublicUserProfile.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LookupUserResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LookupUserResponse copyWith(void Function(LookupUserResponse) updates) =>
      super.copyWith((message) => updates(message as LookupUserResponse))
          as LookupUserResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use LookupUserResponse() / LookupUserResponse.new instead')
  static LookupUserResponse create() => LookupUserResponse._();
  static $pb.GeneratedMessage $_createMessage() => LookupUserResponse._();
  @$core.override
  LookupUserResponse createEmptyInstance() => LookupUserResponse._();
  @$core.pragma('dart2js:noInline')
  static LookupUserResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LookupUserResponse>(
          LookupUserResponse.$_createMessage);
  static LookupUserResponse? _defaultInstance;

  @$pb.TagNumber(1)
  PublicUserProfile get user => $_getN(0);
  @$pb.TagNumber(1)
  set user(PublicUserProfile value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasUser() => $_has(0);
  @$pb.TagNumber(1)
  void clearUser() => $_clearField(1);
  @$pb.TagNumber(1)
  PublicUserProfile ensureUser() => $_ensure(0);
}

/// Replaces the password, confirming the current one.
class ChangePasswordRequest extends $pb.GeneratedMessage {
  factory ChangePasswordRequest({
    $core.String? currentPassword,
    $core.String? newPassword,
  }) {
    final result = ChangePasswordRequest._();
    if (currentPassword != null) result.currentPassword = currentPassword;
    if (newPassword != null) result.newPassword = newPassword;
    return result;
  }

  ChangePasswordRequest._();

  factory ChangePasswordRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ChangePasswordRequest()..mergeFromBuffer(data, registry);
  factory ChangePasswordRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ChangePasswordRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ChangePasswordRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: ChangePasswordRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'currentPassword')
    ..aOS(2, _omitFieldNames ? '' : 'newPassword')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChangePasswordRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChangePasswordRequest copyWith(
          void Function(ChangePasswordRequest) updates) =>
      super.copyWith((message) => updates(message as ChangePasswordRequest))
          as ChangePasswordRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ChangePasswordRequest() / ChangePasswordRequest.new instead')
  static ChangePasswordRequest create() => ChangePasswordRequest._();
  static $pb.GeneratedMessage $_createMessage() => ChangePasswordRequest._();
  @$core.override
  ChangePasswordRequest createEmptyInstance() => ChangePasswordRequest._();
  @$core.pragma('dart2js:noInline')
  static ChangePasswordRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ChangePasswordRequest>(
          ChangePasswordRequest.$_createMessage);
  static ChangePasswordRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get currentPassword => $_getSZ(0);
  @$pb.TagNumber(1)
  set currentPassword($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCurrentPassword() => $_has(0);
  @$pb.TagNumber(1)
  void clearCurrentPassword() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get newPassword => $_getSZ(1);
  @$pb.TagNumber(2)
  set newPassword($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNewPassword() => $_has(1);
  @$pb.TagNumber(2)
  void clearNewPassword() => $_clearField(2);
}

/// The session that replaces every one the change ended.
class ChangePasswordResponse extends $pb.GeneratedMessage {
  factory ChangePasswordResponse({
    Session? session,
  }) {
    final result = ChangePasswordResponse._();
    if (session != null) result.session = session;
    return result;
  }

  ChangePasswordResponse._();

  factory ChangePasswordResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ChangePasswordResponse()..mergeFromBuffer(data, registry);
  factory ChangePasswordResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ChangePasswordResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ChangePasswordResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: ChangePasswordResponse.$_createMessage)
    ..aOM<Session>(1, _omitFieldNames ? '' : 'session',
        subBuilder: Session.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChangePasswordResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChangePasswordResponse copyWith(
          void Function(ChangePasswordResponse) updates) =>
      super.copyWith((message) => updates(message as ChangePasswordResponse))
          as ChangePasswordResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ChangePasswordResponse() / ChangePasswordResponse.new instead')
  static ChangePasswordResponse create() => ChangePasswordResponse._();
  static $pb.GeneratedMessage $_createMessage() => ChangePasswordResponse._();
  @$core.override
  ChangePasswordResponse createEmptyInstance() => ChangePasswordResponse._();
  @$core.pragma('dart2js:noInline')
  static ChangePasswordResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ChangePasswordResponse>(
          ChangePasswordResponse.$_createMessage);
  static ChangePasswordResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Session get session => $_getN(0);
  @$pb.TagNumber(1)
  set session(Session value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSession() => $_has(0);
  @$pb.TagNumber(1)
  void clearSession() => $_clearField(1);
  @$pb.TagNumber(1)
  Session ensureSession() => $_ensure(0);
}

/// Claims a different username.
class ChangeUsernameRequest extends $pb.GeneratedMessage {
  factory ChangeUsernameRequest({
    $core.String? username,
  }) {
    final result = ChangeUsernameRequest._();
    if (username != null) result.username = username;
    return result;
  }

  ChangeUsernameRequest._();

  factory ChangeUsernameRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ChangeUsernameRequest()..mergeFromBuffer(data, registry);
  factory ChangeUsernameRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ChangeUsernameRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ChangeUsernameRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: ChangeUsernameRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'username')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChangeUsernameRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChangeUsernameRequest copyWith(
          void Function(ChangeUsernameRequest) updates) =>
      super.copyWith((message) => updates(message as ChangeUsernameRequest))
          as ChangeUsernameRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ChangeUsernameRequest() / ChangeUsernameRequest.new instead')
  static ChangeUsernameRequest create() => ChangeUsernameRequest._();
  static $pb.GeneratedMessage $_createMessage() => ChangeUsernameRequest._();
  @$core.override
  ChangeUsernameRequest createEmptyInstance() => ChangeUsernameRequest._();
  @$core.pragma('dart2js:noInline')
  static ChangeUsernameRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ChangeUsernameRequest>(
          ChangeUsernameRequest.$_createMessage);
  static ChangeUsernameRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get username => $_getSZ(0);
  @$pb.TagNumber(1)
  set username($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUsername() => $_has(0);
  @$pb.TagNumber(1)
  void clearUsername() => $_clearField(1);
}

/// The account under its new name.
class ChangeUsernameResponse extends $pb.GeneratedMessage {
  factory ChangeUsernameResponse({
    UserProfile? user,
  }) {
    final result = ChangeUsernameResponse._();
    if (user != null) result.user = user;
    return result;
  }

  ChangeUsernameResponse._();

  factory ChangeUsernameResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ChangeUsernameResponse()..mergeFromBuffer(data, registry);
  factory ChangeUsernameResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ChangeUsernameResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ChangeUsernameResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: ChangeUsernameResponse.$_createMessage)
    ..aOM<UserProfile>(1, _omitFieldNames ? '' : 'user',
        subBuilder: UserProfile.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChangeUsernameResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChangeUsernameResponse copyWith(
          void Function(ChangeUsernameResponse) updates) =>
      super.copyWith((message) => updates(message as ChangeUsernameResponse))
          as ChangeUsernameResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ChangeUsernameResponse() / ChangeUsernameResponse.new instead')
  static ChangeUsernameResponse create() => ChangeUsernameResponse._();
  static $pb.GeneratedMessage $_createMessage() => ChangeUsernameResponse._();
  @$core.override
  ChangeUsernameResponse createEmptyInstance() => ChangeUsernameResponse._();
  @$core.pragma('dart2js:noInline')
  static ChangeUsernameResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ChangeUsernameResponse>(
          ChangeUsernameResponse.$_createMessage);
  static ChangeUsernameResponse? _defaultInstance;

  @$pb.TagNumber(1)
  UserProfile get user => $_getN(0);
  @$pb.TagNumber(1)
  set user(UserProfile value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasUser() => $_has(0);
  @$pb.TagNumber(1)
  void clearUser() => $_clearField(1);
  @$pb.TagNumber(1)
  UserProfile ensureUser() => $_ensure(0);
}

/// Leaves the server.
class LeaveServerRequest extends $pb.GeneratedMessage {
  factory LeaveServerRequest({
    $core.String? password,
    $core.bool? preserveData,
  }) {
    final result = LeaveServerRequest._();
    if (password != null) result.password = password;
    if (preserveData != null) result.preserveData = preserveData;
    return result;
  }

  LeaveServerRequest._();

  factory LeaveServerRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LeaveServerRequest()..mergeFromBuffer(data, registry);
  factory LeaveServerRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LeaveServerRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LeaveServerRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: LeaveServerRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'password')
    ..aOB(2, _omitFieldNames ? '' : 'preserveData')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LeaveServerRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LeaveServerRequest copyWith(void Function(LeaveServerRequest) updates) =>
      super.copyWith((message) => updates(message as LeaveServerRequest))
          as LeaveServerRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use LeaveServerRequest() / LeaveServerRequest.new instead')
  static LeaveServerRequest create() => LeaveServerRequest._();
  static $pb.GeneratedMessage $_createMessage() => LeaveServerRequest._();
  @$core.override
  LeaveServerRequest createEmptyInstance() => LeaveServerRequest._();
  @$core.pragma('dart2js:noInline')
  static LeaveServerRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LeaveServerRequest>(
          LeaveServerRequest.$_createMessage);
  static LeaveServerRequest? _defaultInstance;

  /// Confirms an irreversible request.
  @$pb.TagNumber(1)
  $core.String get password => $_getSZ(0);
  @$pb.TagNumber(1)
  set password($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPassword() => $_has(0);
  @$pb.TagNumber(1)
  void clearPassword() => $_clearField(1);

  /// True keeps the username and password for a possible return; false erases them now. Messages
  /// stay either way: they belong to the UUID, not the account.
  @$pb.TagNumber(2)
  $core.bool get preserveData => $_getBF(1);
  @$pb.TagNumber(2)
  set preserveData($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPreserveData() => $_has(1);
  @$pb.TagNumber(2)
  void clearPreserveData() => $_clearField(2);
}

/// What was kept and what was deleted.
class LeaveServerResponse extends $pb.GeneratedMessage {
  factory LeaveServerResponse({
    UserState? state,
    $1.Timestamp? dataExpiresAt,
    $core.String? message,
  }) {
    final result = LeaveServerResponse._();
    if (state != null) result.state = state;
    if (dataExpiresAt != null) result.dataExpiresAt = dataExpiresAt;
    if (message != null) result.message = message;
    return result;
  }

  LeaveServerResponse._();

  factory LeaveServerResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LeaveServerResponse()..mergeFromBuffer(data, registry);
  factory LeaveServerResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LeaveServerResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LeaveServerResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: LeaveServerResponse.$_createMessage)
    ..aE<UserState>(1, _omitFieldNames ? '' : 'state',
        enumValues: UserState.values)
    ..aOM<$1.Timestamp>(2, _omitFieldNames ? '' : 'dataExpiresAt',
        subBuilder: $1.Timestamp.$_createMessage)
    ..aOS(3, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LeaveServerResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LeaveServerResponse copyWith(void Function(LeaveServerResponse) updates) =>
      super.copyWith((message) => updates(message as LeaveServerResponse))
          as LeaveServerResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use LeaveServerResponse() / LeaveServerResponse.new instead')
  static LeaveServerResponse create() => LeaveServerResponse._();
  static $pb.GeneratedMessage $_createMessage() => LeaveServerResponse._();
  @$core.override
  LeaveServerResponse createEmptyInstance() => LeaveServerResponse._();
  @$core.pragma('dart2js:noInline')
  static LeaveServerResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LeaveServerResponse>(
          LeaveServerResponse.$_createMessage);
  static LeaveServerResponse? _defaultInstance;

  /// left_preserved or erased.
  @$pb.TagNumber(1)
  UserState get state => $_getN(0);
  @$pb.TagNumber(1)
  set state(UserState value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasState() => $_has(0);
  @$pb.TagNumber(1)
  void clearState() => $_clearField(1);

  @$pb.TagNumber(2)
  $1.Timestamp get dataExpiresAt => $_getN(1);
  @$pb.TagNumber(2)
  set dataExpiresAt($1.Timestamp value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasDataExpiresAt() => $_has(1);
  @$pb.TagNumber(2)
  void clearDataExpiresAt() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.Timestamp ensureDataExpiresAt() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.String get message => $_getSZ(2);
  @$pb.TagNumber(3)
  set message($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMessage() => $_has(2);
  @$pb.TagNumber(3)
  void clearMessage() => $_clearField(3);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
