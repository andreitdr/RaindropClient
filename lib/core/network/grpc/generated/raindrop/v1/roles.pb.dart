// This is a generated file - do not edit.
//
// Generated from raindrop/v1/roles.proto.

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

import 'roles.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'roles.pbenum.dart';

/// A role. Permissions travel as names (view_channel, manage_roles, …), never as a bitfield: a client
/// too old to know one ignores it.
class Role extends $pb.GeneratedMessage {
  factory Role({
    $core.String? roleId,
    $core.String? name,
    RoleKind? kind,
    $core.int? position,
    $core.Iterable<$core.String>? permissions,
    $1.Timestamp? createdAt,
  }) {
    final result = Role._();
    if (roleId != null) result.roleId = roleId;
    if (name != null) result.name = name;
    if (kind != null) result.kind = kind;
    if (position != null) result.position = position;
    if (permissions != null) result.permissions.addAll(permissions);
    if (createdAt != null) result.createdAt = createdAt;
    return result;
  }

  Role._();

  factory Role.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Role()..mergeFromBuffer(data, registry);
  factory Role.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Role()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Role',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: Role.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'roleId')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aE<RoleKind>(3, _omitFieldNames ? '' : 'kind',
        enumValues: RoleKind.values)
    ..aI(4, _omitFieldNames ? '' : 'position')
    ..pPS(5, _omitFieldNames ? '' : 'permissions')
    ..aOM<$1.Timestamp>(6, _omitFieldNames ? '' : 'createdAt',
        subBuilder: $1.Timestamp.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Role clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Role copyWith(void Function(Role) updates) =>
      super.copyWith((message) => updates(message as Role)) as Role;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Role() / Role.new instead')
  static Role create() => Role._();
  static $pb.GeneratedMessage $_createMessage() => Role._();
  @$core.override
  Role createEmptyInstance() => Role._();
  @$core.pragma('dart2js:noInline')
  static Role getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Role>(Role.$_createMessage);
  static Role? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get roleId => $_getSZ(0);
  @$pb.TagNumber(1)
  set roleId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRoleId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRoleId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  RoleKind get kind => $_getN(2);
  @$pb.TagNumber(3)
  set kind(RoleKind value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasKind() => $_has(2);
  @$pb.TagNumber(3)
  void clearKind() => $_clearField(3);

  /// Presentation order, highest first.
  @$pb.TagNumber(4)
  $core.int get position => $_getIZ(3);
  @$pb.TagNumber(4)
  set position($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPosition() => $_has(3);
  @$pb.TagNumber(4)
  void clearPosition() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbList<$core.String> get permissions => $_getList(4);

  @$pb.TagNumber(6)
  $1.Timestamp get createdAt => $_getN(5);
  @$pb.TagNumber(6)
  set createdAt($1.Timestamp value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasCreatedAt() => $_has(5);
  @$pb.TagNumber(6)
  void clearCreatedAt() => $_clearField(6);
  @$pb.TagNumber(6)
  $1.Timestamp ensureCreatedAt() => $_ensure(5);
}

/// One permission this build understands.
class PermissionDescription extends $pb.GeneratedMessage {
  factory PermissionDescription({
    $core.String? name,
    $core.String? summary,
  }) {
    final result = PermissionDescription._();
    if (name != null) result.name = name;
    if (summary != null) result.summary = summary;
    return result;
  }

  PermissionDescription._();

  factory PermissionDescription.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PermissionDescription()..mergeFromBuffer(data, registry);
  factory PermissionDescription.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PermissionDescription()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PermissionDescription',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: PermissionDescription.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'summary')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PermissionDescription clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PermissionDescription copyWith(
          void Function(PermissionDescription) updates) =>
      super.copyWith((message) => updates(message as PermissionDescription))
          as PermissionDescription;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use PermissionDescription() / PermissionDescription.new instead')
  static PermissionDescription create() => PermissionDescription._();
  static $pb.GeneratedMessage $_createMessage() => PermissionDescription._();
  @$core.override
  PermissionDescription createEmptyInstance() => PermissionDescription._();
  @$core.pragma('dart2js:noInline')
  static PermissionDescription getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PermissionDescription>(
          PermissionDescription.$_createMessage);
  static PermissionDescription? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get summary => $_getSZ(1);
  @$pb.TagNumber(2)
  set summary($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSummary() => $_has(1);
  @$pb.TagNumber(2)
  void clearSummary() => $_clearField(2);
}

/// A permission set whose presence means something: absent leaves a role's permissions alone, present
/// and empty clears them.
class PermissionSet extends $pb.GeneratedMessage {
  factory PermissionSet({
    $core.Iterable<$core.String>? permissions,
  }) {
    final result = PermissionSet._();
    if (permissions != null) result.permissions.addAll(permissions);
    return result;
  }

  PermissionSet._();

  factory PermissionSet.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PermissionSet()..mergeFromBuffer(data, registry);
  factory PermissionSet.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PermissionSet()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PermissionSet',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: PermissionSet.$_createMessage)
    ..pPS(1, _omitFieldNames ? '' : 'permissions')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PermissionSet clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PermissionSet copyWith(void Function(PermissionSet) updates) =>
      super.copyWith((message) => updates(message as PermissionSet))
          as PermissionSet;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PermissionSet() / PermissionSet.new instead')
  static PermissionSet create() => PermissionSet._();
  static $pb.GeneratedMessage $_createMessage() => PermissionSet._();
  @$core.override
  PermissionSet createEmptyInstance() => PermissionSet._();
  @$core.pragma('dart2js:noInline')
  static PermissionSet getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PermissionSet>(
          PermissionSet.$_createMessage);
  static PermissionSet? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get permissions => $_getList(0);
}

/// Asks for every role.
class ListRolesRequest extends $pb.GeneratedMessage {
  factory ListRolesRequest() => ListRolesRequest._();

  ListRolesRequest._();

  factory ListRolesRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListRolesRequest()..mergeFromBuffer(data, registry);
  factory ListRolesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListRolesRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListRolesRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: ListRolesRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListRolesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListRolesRequest copyWith(void Function(ListRolesRequest) updates) =>
      super.copyWith((message) => updates(message as ListRolesRequest))
          as ListRolesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ListRolesRequest() / ListRolesRequest.new instead')
  static ListRolesRequest create() => ListRolesRequest._();
  static $pb.GeneratedMessage $_createMessage() => ListRolesRequest._();
  @$core.override
  ListRolesRequest createEmptyInstance() => ListRolesRequest._();
  @$core.pragma('dart2js:noInline')
  static ListRolesRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ListRolesRequest>(
          ListRolesRequest.$_createMessage);
  static ListRolesRequest? _defaultInstance;
}

/// Every role, highest position first.
class ListRolesResponse extends $pb.GeneratedMessage {
  factory ListRolesResponse({
    $core.Iterable<Role>? roles,
  }) {
    final result = ListRolesResponse._();
    if (roles != null) result.roles.addAll(roles);
    return result;
  }

  ListRolesResponse._();

  factory ListRolesResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListRolesResponse()..mergeFromBuffer(data, registry);
  factory ListRolesResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListRolesResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListRolesResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: ListRolesResponse.$_createMessage)
    ..pPM<Role>(1, _omitFieldNames ? '' : 'roles',
        subBuilder: Role.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListRolesResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListRolesResponse copyWith(void Function(ListRolesResponse) updates) =>
      super.copyWith((message) => updates(message as ListRolesResponse))
          as ListRolesResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ListRolesResponse() / ListRolesResponse.new instead')
  static ListRolesResponse create() => ListRolesResponse._();
  static $pb.GeneratedMessage $_createMessage() => ListRolesResponse._();
  @$core.override
  ListRolesResponse createEmptyInstance() => ListRolesResponse._();
  @$core.pragma('dart2js:noInline')
  static ListRolesResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ListRolesResponse>(
          ListRolesResponse.$_createMessage);
  static ListRolesResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Role> get roles => $_getList(0);
}

/// Asks what the caller holds.
class GetMyRolesRequest extends $pb.GeneratedMessage {
  factory GetMyRolesRequest() => GetMyRolesRequest._();

  GetMyRolesRequest._();

  factory GetMyRolesRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetMyRolesRequest()..mergeFromBuffer(data, registry);
  factory GetMyRolesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetMyRolesRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetMyRolesRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: GetMyRolesRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetMyRolesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetMyRolesRequest copyWith(void Function(GetMyRolesRequest) updates) =>
      super.copyWith((message) => updates(message as GetMyRolesRequest))
          as GetMyRolesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetMyRolesRequest() / GetMyRolesRequest.new instead')
  static GetMyRolesRequest create() => GetMyRolesRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetMyRolesRequest._();
  @$core.override
  GetMyRolesRequest createEmptyInstance() => GetMyRolesRequest._();
  @$core.pragma('dart2js:noInline')
  static GetMyRolesRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetMyRolesRequest>(
          GetMyRolesRequest.$_createMessage);
  static GetMyRolesRequest? _defaultInstance;
}

/// The caller's roles (everyone first) and the expanded union of what they grant.
class GetMyRolesResponse extends $pb.GeneratedMessage {
  factory GetMyRolesResponse({
    $core.String? userId,
    $core.Iterable<Role>? roles,
    $core.Iterable<$core.String>? permissions,
  }) {
    final result = GetMyRolesResponse._();
    if (userId != null) result.userId = userId;
    if (roles != null) result.roles.addAll(roles);
    if (permissions != null) result.permissions.addAll(permissions);
    return result;
  }

  GetMyRolesResponse._();

  factory GetMyRolesResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetMyRolesResponse()..mergeFromBuffer(data, registry);
  factory GetMyRolesResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetMyRolesResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetMyRolesResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: GetMyRolesResponse.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'userId')
    ..pPM<Role>(2, _omitFieldNames ? '' : 'roles',
        subBuilder: Role.$_createMessage)
    ..pPS(3, _omitFieldNames ? '' : 'permissions')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetMyRolesResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetMyRolesResponse copyWith(void Function(GetMyRolesResponse) updates) =>
      super.copyWith((message) => updates(message as GetMyRolesResponse))
          as GetMyRolesResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetMyRolesResponse() / GetMyRolesResponse.new instead')
  static GetMyRolesResponse create() => GetMyRolesResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetMyRolesResponse._();
  @$core.override
  GetMyRolesResponse createEmptyInstance() => GetMyRolesResponse._();
  @$core.pragma('dart2js:noInline')
  static GetMyRolesResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetMyRolesResponse>(
          GetMyRolesResponse.$_createMessage);
  static GetMyRolesResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get userId => $_getSZ(0);
  @$pb.TagNumber(1)
  set userId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<Role> get roles => $_getList(1);

  @$pb.TagNumber(3)
  $pb.PbList<$core.String> get permissions => $_getList(2);
}

/// Asks for the permission catalogue.
class ListPermissionsRequest extends $pb.GeneratedMessage {
  factory ListPermissionsRequest() => ListPermissionsRequest._();

  ListPermissionsRequest._();

  factory ListPermissionsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListPermissionsRequest()..mergeFromBuffer(data, registry);
  factory ListPermissionsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListPermissionsRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListPermissionsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: ListPermissionsRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListPermissionsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListPermissionsRequest copyWith(
          void Function(ListPermissionsRequest) updates) =>
      super.copyWith((message) => updates(message as ListPermissionsRequest))
          as ListPermissionsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ListPermissionsRequest() / ListPermissionsRequest.new instead')
  static ListPermissionsRequest create() => ListPermissionsRequest._();
  static $pb.GeneratedMessage $_createMessage() => ListPermissionsRequest._();
  @$core.override
  ListPermissionsRequest createEmptyInstance() => ListPermissionsRequest._();
  @$core.pragma('dart2js:noInline')
  static ListPermissionsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListPermissionsRequest>(
          ListPermissionsRequest.$_createMessage);
  static ListPermissionsRequest? _defaultInstance;
}

/// Every permission, in the order an editor lists them.
class ListPermissionsResponse extends $pb.GeneratedMessage {
  factory ListPermissionsResponse({
    $core.Iterable<PermissionDescription>? permissions,
  }) {
    final result = ListPermissionsResponse._();
    if (permissions != null) result.permissions.addAll(permissions);
    return result;
  }

  ListPermissionsResponse._();

  factory ListPermissionsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListPermissionsResponse()..mergeFromBuffer(data, registry);
  factory ListPermissionsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListPermissionsResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListPermissionsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: ListPermissionsResponse.$_createMessage)
    ..pPM<PermissionDescription>(1, _omitFieldNames ? '' : 'permissions',
        subBuilder: PermissionDescription.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListPermissionsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListPermissionsResponse copyWith(
          void Function(ListPermissionsResponse) updates) =>
      super.copyWith((message) => updates(message as ListPermissionsResponse))
          as ListPermissionsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ListPermissionsResponse() / ListPermissionsResponse.new instead')
  static ListPermissionsResponse create() => ListPermissionsResponse._();
  static $pb.GeneratedMessage $_createMessage() => ListPermissionsResponse._();
  @$core.override
  ListPermissionsResponse createEmptyInstance() => ListPermissionsResponse._();
  @$core.pragma('dart2js:noInline')
  static ListPermissionsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListPermissionsResponse>(
          ListPermissionsResponse.$_createMessage);
  static ListPermissionsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<PermissionDescription> get permissions => $_getList(0);
}

/// Asks about one role.
class GetRoleRequest extends $pb.GeneratedMessage {
  factory GetRoleRequest({
    $core.String? roleId,
  }) {
    final result = GetRoleRequest._();
    if (roleId != null) result.roleId = roleId;
    return result;
  }

  GetRoleRequest._();

  factory GetRoleRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetRoleRequest()..mergeFromBuffer(data, registry);
  factory GetRoleRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetRoleRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetRoleRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: GetRoleRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'roleId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetRoleRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetRoleRequest copyWith(void Function(GetRoleRequest) updates) =>
      super.copyWith((message) => updates(message as GetRoleRequest))
          as GetRoleRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetRoleRequest() / GetRoleRequest.new instead')
  static GetRoleRequest create() => GetRoleRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetRoleRequest._();
  @$core.override
  GetRoleRequest createEmptyInstance() => GetRoleRequest._();
  @$core.pragma('dart2js:noInline')
  static GetRoleRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetRoleRequest>(
          GetRoleRequest.$_createMessage);
  static GetRoleRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get roleId => $_getSZ(0);
  @$pb.TagNumber(1)
  set roleId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRoleId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRoleId() => $_clearField(1);
}

/// The role and who holds it, in the order they were granted it.
class GetRoleResponse extends $pb.GeneratedMessage {
  factory GetRoleResponse({
    Role? role,
    $core.Iterable<$core.String>? memberIds,
  }) {
    final result = GetRoleResponse._();
    if (role != null) result.role = role;
    if (memberIds != null) result.memberIds.addAll(memberIds);
    return result;
  }

  GetRoleResponse._();

  factory GetRoleResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetRoleResponse()..mergeFromBuffer(data, registry);
  factory GetRoleResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetRoleResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetRoleResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: GetRoleResponse.$_createMessage)
    ..aOM<Role>(1, _omitFieldNames ? '' : 'role',
        subBuilder: Role.$_createMessage)
    ..pPS(2, _omitFieldNames ? '' : 'memberIds')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetRoleResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetRoleResponse copyWith(void Function(GetRoleResponse) updates) =>
      super.copyWith((message) => updates(message as GetRoleResponse))
          as GetRoleResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetRoleResponse() / GetRoleResponse.new instead')
  static GetRoleResponse create() => GetRoleResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetRoleResponse._();
  @$core.override
  GetRoleResponse createEmptyInstance() => GetRoleResponse._();
  @$core.pragma('dart2js:noInline')
  static GetRoleResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetRoleResponse>(
          GetRoleResponse.$_createMessage);
  static GetRoleResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Role get role => $_getN(0);
  @$pb.TagNumber(1)
  set role(Role value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasRole() => $_has(0);
  @$pb.TagNumber(1)
  void clearRole() => $_clearField(1);
  @$pb.TagNumber(1)
  Role ensureRole() => $_ensure(0);

  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get memberIds => $_getList(1);
}

/// Creates a role.
class CreateRoleRequest extends $pb.GeneratedMessage {
  factory CreateRoleRequest({
    $core.String? name,
    $core.Iterable<$core.String>? permissions,
    $core.int? position,
  }) {
    final result = CreateRoleRequest._();
    if (name != null) result.name = name;
    if (permissions != null) result.permissions.addAll(permissions);
    if (position != null) result.position = position;
    return result;
  }

  CreateRoleRequest._();

  factory CreateRoleRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreateRoleRequest()..mergeFromBuffer(data, registry);
  factory CreateRoleRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreateRoleRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateRoleRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: CreateRoleRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..pPS(2, _omitFieldNames ? '' : 'permissions')
    ..aI(3, _omitFieldNames ? '' : 'position')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateRoleRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateRoleRequest copyWith(void Function(CreateRoleRequest) updates) =>
      super.copyWith((message) => updates(message as CreateRoleRequest))
          as CreateRoleRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use CreateRoleRequest() / CreateRoleRequest.new instead')
  static CreateRoleRequest create() => CreateRoleRequest._();
  static $pb.GeneratedMessage $_createMessage() => CreateRoleRequest._();
  @$core.override
  CreateRoleRequest createEmptyInstance() => CreateRoleRequest._();
  @$core.pragma('dart2js:noInline')
  static CreateRoleRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CreateRoleRequest>(
          CreateRoleRequest.$_createMessage);
  static CreateRoleRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  /// Empty: the role grants nothing until somebody edits it.
  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get permissions => $_getList(1);

  /// Absent: above every other custom role.
  @$pb.TagNumber(3)
  $core.int get position => $_getIZ(2);
  @$pb.TagNumber(3)
  set position($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPosition() => $_has(2);
  @$pb.TagNumber(3)
  void clearPosition() => $_clearField(3);
}

/// The new role.
class CreateRoleResponse extends $pb.GeneratedMessage {
  factory CreateRoleResponse({
    Role? role,
  }) {
    final result = CreateRoleResponse._();
    if (role != null) result.role = role;
    return result;
  }

  CreateRoleResponse._();

  factory CreateRoleResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreateRoleResponse()..mergeFromBuffer(data, registry);
  factory CreateRoleResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreateRoleResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateRoleResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: CreateRoleResponse.$_createMessage)
    ..aOM<Role>(1, _omitFieldNames ? '' : 'role',
        subBuilder: Role.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateRoleResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateRoleResponse copyWith(void Function(CreateRoleResponse) updates) =>
      super.copyWith((message) => updates(message as CreateRoleResponse))
          as CreateRoleResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use CreateRoleResponse() / CreateRoleResponse.new instead')
  static CreateRoleResponse create() => CreateRoleResponse._();
  static $pb.GeneratedMessage $_createMessage() => CreateRoleResponse._();
  @$core.override
  CreateRoleResponse createEmptyInstance() => CreateRoleResponse._();
  @$core.pragma('dart2js:noInline')
  static CreateRoleResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateRoleResponse>(
          CreateRoleResponse.$_createMessage);
  static CreateRoleResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Role get role => $_getN(0);
  @$pb.TagNumber(1)
  set role(Role value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasRole() => $_has(0);
  @$pb.TagNumber(1)
  void clearRole() => $_clearField(1);
  @$pb.TagNumber(1)
  Role ensureRole() => $_ensure(0);
}

/// Edits a role. Every field but the id means "leave this alone" when absent.
class UpdateRoleRequest extends $pb.GeneratedMessage {
  factory UpdateRoleRequest({
    $core.String? roleId,
    $core.String? name,
    PermissionSet? permissions,
    $core.int? position,
  }) {
    final result = UpdateRoleRequest._();
    if (roleId != null) result.roleId = roleId;
    if (name != null) result.name = name;
    if (permissions != null) result.permissions = permissions;
    if (position != null) result.position = position;
    return result;
  }

  UpdateRoleRequest._();

  factory UpdateRoleRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UpdateRoleRequest()..mergeFromBuffer(data, registry);
  factory UpdateRoleRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UpdateRoleRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateRoleRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: UpdateRoleRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'roleId')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOM<PermissionSet>(3, _omitFieldNames ? '' : 'permissions',
        subBuilder: PermissionSet.$_createMessage)
    ..aI(4, _omitFieldNames ? '' : 'position')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateRoleRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateRoleRequest copyWith(void Function(UpdateRoleRequest) updates) =>
      super.copyWith((message) => updates(message as UpdateRoleRequest))
          as UpdateRoleRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use UpdateRoleRequest() / UpdateRoleRequest.new instead')
  static UpdateRoleRequest create() => UpdateRoleRequest._();
  static $pb.GeneratedMessage $_createMessage() => UpdateRoleRequest._();
  @$core.override
  UpdateRoleRequest createEmptyInstance() => UpdateRoleRequest._();
  @$core.pragma('dart2js:noInline')
  static UpdateRoleRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UpdateRoleRequest>(
          UpdateRoleRequest.$_createMessage);
  static UpdateRoleRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get roleId => $_getSZ(0);
  @$pb.TagNumber(1)
  set roleId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRoleId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRoleId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  PermissionSet get permissions => $_getN(2);
  @$pb.TagNumber(3)
  set permissions(PermissionSet value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasPermissions() => $_has(2);
  @$pb.TagNumber(3)
  void clearPermissions() => $_clearField(3);
  @$pb.TagNumber(3)
  PermissionSet ensurePermissions() => $_ensure(2);

  @$pb.TagNumber(4)
  $core.int get position => $_getIZ(3);
  @$pb.TagNumber(4)
  set position($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPosition() => $_has(3);
  @$pb.TagNumber(4)
  void clearPosition() => $_clearField(4);
}

/// The role as it is now.
class UpdateRoleResponse extends $pb.GeneratedMessage {
  factory UpdateRoleResponse({
    Role? role,
  }) {
    final result = UpdateRoleResponse._();
    if (role != null) result.role = role;
    return result;
  }

  UpdateRoleResponse._();

  factory UpdateRoleResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UpdateRoleResponse()..mergeFromBuffer(data, registry);
  factory UpdateRoleResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UpdateRoleResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateRoleResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: UpdateRoleResponse.$_createMessage)
    ..aOM<Role>(1, _omitFieldNames ? '' : 'role',
        subBuilder: Role.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateRoleResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateRoleResponse copyWith(void Function(UpdateRoleResponse) updates) =>
      super.copyWith((message) => updates(message as UpdateRoleResponse))
          as UpdateRoleResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use UpdateRoleResponse() / UpdateRoleResponse.new instead')
  static UpdateRoleResponse create() => UpdateRoleResponse._();
  static $pb.GeneratedMessage $_createMessage() => UpdateRoleResponse._();
  @$core.override
  UpdateRoleResponse createEmptyInstance() => UpdateRoleResponse._();
  @$core.pragma('dart2js:noInline')
  static UpdateRoleResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateRoleResponse>(
          UpdateRoleResponse.$_createMessage);
  static UpdateRoleResponse? _defaultInstance;

  @$pb.TagNumber(1)
  Role get role => $_getN(0);
  @$pb.TagNumber(1)
  set role(Role value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasRole() => $_has(0);
  @$pb.TagNumber(1)
  void clearRole() => $_clearField(1);
  @$pb.TagNumber(1)
  Role ensureRole() => $_ensure(0);
}

/// Deletes a role.
class DeleteRoleRequest extends $pb.GeneratedMessage {
  factory DeleteRoleRequest({
    $core.String? roleId,
  }) {
    final result = DeleteRoleRequest._();
    if (roleId != null) result.roleId = roleId;
    return result;
  }

  DeleteRoleRequest._();

  factory DeleteRoleRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DeleteRoleRequest()..mergeFromBuffer(data, registry);
  factory DeleteRoleRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DeleteRoleRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteRoleRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: DeleteRoleRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'roleId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteRoleRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteRoleRequest copyWith(void Function(DeleteRoleRequest) updates) =>
      super.copyWith((message) => updates(message as DeleteRoleRequest))
          as DeleteRoleRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use DeleteRoleRequest() / DeleteRoleRequest.new instead')
  static DeleteRoleRequest create() => DeleteRoleRequest._();
  static $pb.GeneratedMessage $_createMessage() => DeleteRoleRequest._();
  @$core.override
  DeleteRoleRequest createEmptyInstance() => DeleteRoleRequest._();
  @$core.pragma('dart2js:noInline')
  static DeleteRoleRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DeleteRoleRequest>(
          DeleteRoleRequest.$_createMessage);
  static DeleteRoleRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get roleId => $_getSZ(0);
  @$pb.TagNumber(1)
  set roleId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRoleId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRoleId() => $_clearField(1);
}

/// What went with it.
class DeleteRoleResponse extends $pb.GeneratedMessage {
  factory DeleteRoleResponse({
    $core.String? roleId,
    $core.String? message,
  }) {
    final result = DeleteRoleResponse._();
    if (roleId != null) result.roleId = roleId;
    if (message != null) result.message = message;
    return result;
  }

  DeleteRoleResponse._();

  factory DeleteRoleResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DeleteRoleResponse()..mergeFromBuffer(data, registry);
  factory DeleteRoleResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DeleteRoleResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteRoleResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: DeleteRoleResponse.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'roleId')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteRoleResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteRoleResponse copyWith(void Function(DeleteRoleResponse) updates) =>
      super.copyWith((message) => updates(message as DeleteRoleResponse))
          as DeleteRoleResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use DeleteRoleResponse() / DeleteRoleResponse.new instead')
  static DeleteRoleResponse create() => DeleteRoleResponse._();
  static $pb.GeneratedMessage $_createMessage() => DeleteRoleResponse._();
  @$core.override
  DeleteRoleResponse createEmptyInstance() => DeleteRoleResponse._();
  @$core.pragma('dart2js:noInline')
  static DeleteRoleResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteRoleResponse>(
          DeleteRoleResponse.$_createMessage);
  static DeleteRoleResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get roleId => $_getSZ(0);
  @$pb.TagNumber(1)
  set roleId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRoleId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRoleId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);
}

/// Asks what one member holds.
class GetMemberRolesRequest extends $pb.GeneratedMessage {
  factory GetMemberRolesRequest({
    $core.String? userId,
  }) {
    final result = GetMemberRolesRequest._();
    if (userId != null) result.userId = userId;
    return result;
  }

  GetMemberRolesRequest._();

  factory GetMemberRolesRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetMemberRolesRequest()..mergeFromBuffer(data, registry);
  factory GetMemberRolesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetMemberRolesRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetMemberRolesRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: GetMemberRolesRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'userId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetMemberRolesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetMemberRolesRequest copyWith(
          void Function(GetMemberRolesRequest) updates) =>
      super.copyWith((message) => updates(message as GetMemberRolesRequest))
          as GetMemberRolesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetMemberRolesRequest() / GetMemberRolesRequest.new instead')
  static GetMemberRolesRequest create() => GetMemberRolesRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetMemberRolesRequest._();
  @$core.override
  GetMemberRolesRequest createEmptyInstance() => GetMemberRolesRequest._();
  @$core.pragma('dart2js:noInline')
  static GetMemberRolesRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetMemberRolesRequest>(
          GetMemberRolesRequest.$_createMessage);
  static GetMemberRolesRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get userId => $_getSZ(0);
  @$pb.TagNumber(1)
  set userId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => $_clearField(1);
}

/// That member's roles (everyone first) and the expanded union of what they grant.
class GetMemberRolesResponse extends $pb.GeneratedMessage {
  factory GetMemberRolesResponse({
    $core.String? userId,
    $core.Iterable<Role>? roles,
    $core.Iterable<$core.String>? permissions,
  }) {
    final result = GetMemberRolesResponse._();
    if (userId != null) result.userId = userId;
    if (roles != null) result.roles.addAll(roles);
    if (permissions != null) result.permissions.addAll(permissions);
    return result;
  }

  GetMemberRolesResponse._();

  factory GetMemberRolesResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetMemberRolesResponse()..mergeFromBuffer(data, registry);
  factory GetMemberRolesResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetMemberRolesResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetMemberRolesResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: GetMemberRolesResponse.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'userId')
    ..pPM<Role>(2, _omitFieldNames ? '' : 'roles',
        subBuilder: Role.$_createMessage)
    ..pPS(3, _omitFieldNames ? '' : 'permissions')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetMemberRolesResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetMemberRolesResponse copyWith(
          void Function(GetMemberRolesResponse) updates) =>
      super.copyWith((message) => updates(message as GetMemberRolesResponse))
          as GetMemberRolesResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetMemberRolesResponse() / GetMemberRolesResponse.new instead')
  static GetMemberRolesResponse create() => GetMemberRolesResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetMemberRolesResponse._();
  @$core.override
  GetMemberRolesResponse createEmptyInstance() => GetMemberRolesResponse._();
  @$core.pragma('dart2js:noInline')
  static GetMemberRolesResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetMemberRolesResponse>(
          GetMemberRolesResponse.$_createMessage);
  static GetMemberRolesResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get userId => $_getSZ(0);
  @$pb.TagNumber(1)
  set userId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<Role> get roles => $_getList(1);

  @$pb.TagNumber(3)
  $pb.PbList<$core.String> get permissions => $_getList(2);
}

/// Gives a member a role.
class AssignRoleRequest extends $pb.GeneratedMessage {
  factory AssignRoleRequest({
    $core.String? userId,
    $core.String? roleId,
  }) {
    final result = AssignRoleRequest._();
    if (userId != null) result.userId = userId;
    if (roleId != null) result.roleId = roleId;
    return result;
  }

  AssignRoleRequest._();

  factory AssignRoleRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AssignRoleRequest()..mergeFromBuffer(data, registry);
  factory AssignRoleRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AssignRoleRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AssignRoleRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: AssignRoleRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'userId')
    ..aOS(2, _omitFieldNames ? '' : 'roleId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AssignRoleRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AssignRoleRequest copyWith(void Function(AssignRoleRequest) updates) =>
      super.copyWith((message) => updates(message as AssignRoleRequest))
          as AssignRoleRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use AssignRoleRequest() / AssignRoleRequest.new instead')
  static AssignRoleRequest create() => AssignRoleRequest._();
  static $pb.GeneratedMessage $_createMessage() => AssignRoleRequest._();
  @$core.override
  AssignRoleRequest createEmptyInstance() => AssignRoleRequest._();
  @$core.pragma('dart2js:noInline')
  static AssignRoleRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AssignRoleRequest>(
          AssignRoleRequest.$_createMessage);
  static AssignRoleRequest? _defaultInstance;

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
}

/// changed is false when they already held it — not an error.
class AssignRoleResponse extends $pb.GeneratedMessage {
  factory AssignRoleResponse({
    $core.String? userId,
    $core.String? roleId,
    $core.bool? changed,
    $core.String? message,
  }) {
    final result = AssignRoleResponse._();
    if (userId != null) result.userId = userId;
    if (roleId != null) result.roleId = roleId;
    if (changed != null) result.changed = changed;
    if (message != null) result.message = message;
    return result;
  }

  AssignRoleResponse._();

  factory AssignRoleResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AssignRoleResponse()..mergeFromBuffer(data, registry);
  factory AssignRoleResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AssignRoleResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AssignRoleResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: AssignRoleResponse.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'userId')
    ..aOS(2, _omitFieldNames ? '' : 'roleId')
    ..aOB(3, _omitFieldNames ? '' : 'changed')
    ..aOS(4, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AssignRoleResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AssignRoleResponse copyWith(void Function(AssignRoleResponse) updates) =>
      super.copyWith((message) => updates(message as AssignRoleResponse))
          as AssignRoleResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use AssignRoleResponse() / AssignRoleResponse.new instead')
  static AssignRoleResponse create() => AssignRoleResponse._();
  static $pb.GeneratedMessage $_createMessage() => AssignRoleResponse._();
  @$core.override
  AssignRoleResponse createEmptyInstance() => AssignRoleResponse._();
  @$core.pragma('dart2js:noInline')
  static AssignRoleResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AssignRoleResponse>(
          AssignRoleResponse.$_createMessage);
  static AssignRoleResponse? _defaultInstance;

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

  @$pb.TagNumber(3)
  $core.bool get changed => $_getBF(2);
  @$pb.TagNumber(3)
  set changed($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasChanged() => $_has(2);
  @$pb.TagNumber(3)
  void clearChanged() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get message => $_getSZ(3);
  @$pb.TagNumber(4)
  set message($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasMessage() => $_has(3);
  @$pb.TagNumber(4)
  void clearMessage() => $_clearField(4);
}

/// Takes a role away from a member.
class UnassignRoleRequest extends $pb.GeneratedMessage {
  factory UnassignRoleRequest({
    $core.String? userId,
    $core.String? roleId,
  }) {
    final result = UnassignRoleRequest._();
    if (userId != null) result.userId = userId;
    if (roleId != null) result.roleId = roleId;
    return result;
  }

  UnassignRoleRequest._();

  factory UnassignRoleRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UnassignRoleRequest()..mergeFromBuffer(data, registry);
  factory UnassignRoleRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UnassignRoleRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UnassignRoleRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: UnassignRoleRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'userId')
    ..aOS(2, _omitFieldNames ? '' : 'roleId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UnassignRoleRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UnassignRoleRequest copyWith(void Function(UnassignRoleRequest) updates) =>
      super.copyWith((message) => updates(message as UnassignRoleRequest))
          as UnassignRoleRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use UnassignRoleRequest() / UnassignRoleRequest.new instead')
  static UnassignRoleRequest create() => UnassignRoleRequest._();
  static $pb.GeneratedMessage $_createMessage() => UnassignRoleRequest._();
  @$core.override
  UnassignRoleRequest createEmptyInstance() => UnassignRoleRequest._();
  @$core.pragma('dart2js:noInline')
  static UnassignRoleRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UnassignRoleRequest>(
          UnassignRoleRequest.$_createMessage);
  static UnassignRoleRequest? _defaultInstance;

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
}

/// changed is false when they already did not hold it — not an error.
class UnassignRoleResponse extends $pb.GeneratedMessage {
  factory UnassignRoleResponse({
    $core.String? userId,
    $core.String? roleId,
    $core.bool? changed,
    $core.String? message,
  }) {
    final result = UnassignRoleResponse._();
    if (userId != null) result.userId = userId;
    if (roleId != null) result.roleId = roleId;
    if (changed != null) result.changed = changed;
    if (message != null) result.message = message;
    return result;
  }

  UnassignRoleResponse._();

  factory UnassignRoleResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UnassignRoleResponse()..mergeFromBuffer(data, registry);
  factory UnassignRoleResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UnassignRoleResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UnassignRoleResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'raindrop.v1'),
      createEmptyInstance: UnassignRoleResponse.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'userId')
    ..aOS(2, _omitFieldNames ? '' : 'roleId')
    ..aOB(3, _omitFieldNames ? '' : 'changed')
    ..aOS(4, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UnassignRoleResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UnassignRoleResponse copyWith(void Function(UnassignRoleResponse) updates) =>
      super.copyWith((message) => updates(message as UnassignRoleResponse))
          as UnassignRoleResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use UnassignRoleResponse() / UnassignRoleResponse.new instead')
  static UnassignRoleResponse create() => UnassignRoleResponse._();
  static $pb.GeneratedMessage $_createMessage() => UnassignRoleResponse._();
  @$core.override
  UnassignRoleResponse createEmptyInstance() => UnassignRoleResponse._();
  @$core.pragma('dart2js:noInline')
  static UnassignRoleResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UnassignRoleResponse>(
          UnassignRoleResponse.$_createMessage);
  static UnassignRoleResponse? _defaultInstance;

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

  @$pb.TagNumber(3)
  $core.bool get changed => $_getBF(2);
  @$pb.TagNumber(3)
  set changed($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasChanged() => $_has(2);
  @$pb.TagNumber(3)
  void clearChanged() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get message => $_getSZ(3);
  @$pb.TagNumber(4)
  set message($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasMessage() => $_has(3);
  @$pb.TagNumber(4)
  void clearMessage() => $_clearField(4);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
