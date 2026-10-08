// This is a generated file - do not edit.
//
// Generated from raindrop/v1/roles.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import 'roles.pb.dart' as $0;

export 'roles.pb.dart';

/// Roles and permissions. A role is a named set of permissions; a member holds any number of them and
/// may do the union. Reading is open to every member; writing needs manage_roles and every permission
/// involved.
@$pb.GrpcServiceName('raindrop.v1.RoleService')
class RoleServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  RoleServiceClient(super.channel, {super.options, super.interceptors});

  /// Every role on this server, highest position first.
  $grpc.ResponseFuture<$0.ListRolesResponse> listRoles(
    $0.ListRolesRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listRoles, request, options: options);
  }

  /// The caller's own roles, and what they may do server-wide.
  $grpc.ResponseFuture<$0.GetMyRolesResponse> getMyRoles(
    $0.GetMyRolesRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getMyRoles, request, options: options);
  }

  /// The permissions this build understands, for a role editor.
  $grpc.ResponseFuture<$0.ListPermissionsResponse> listPermissions(
    $0.ListPermissionsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listPermissions, request, options: options);
  }

  /// One role, and the UUIDs holding it.
  $grpc.ResponseFuture<$0.GetRoleResponse> getRole(
    $0.GetRoleRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getRole, request, options: options);
  }

  /// Create a role.
  $grpc.ResponseFuture<$0.CreateRoleResponse> createRole(
    $0.CreateRoleRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$createRole, request, options: options);
  }

  /// Rename it, replace its permissions, or move it. Absent fields are left alone.
  $grpc.ResponseFuture<$0.UpdateRoleResponse> updateRole(
    $0.UpdateRoleRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$updateRole, request, options: options);
  }

  /// Delete it and take it away from everyone holding it.
  $grpc.ResponseFuture<$0.DeleteRoleResponse> deleteRole(
    $0.DeleteRoleRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deleteRole, request, options: options);
  }

  /// Which roles one member holds, and what they add up to.
  $grpc.ResponseFuture<$0.GetMemberRolesResponse> getMemberRoles(
    $0.GetMemberRolesRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getMemberRoles, request, options: options);
  }

  /// Give a member a role.
  $grpc.ResponseFuture<$0.AssignRoleResponse> assignRole(
    $0.AssignRoleRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$assignRole, request, options: options);
  }

  /// Take a role away from a member.
  $grpc.ResponseFuture<$0.UnassignRoleResponse> unassignRole(
    $0.UnassignRoleRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$unassignRole, request, options: options);
  }

  // method descriptors

  static final _$listRoles =
      $grpc.ClientMethod<$0.ListRolesRequest, $0.ListRolesResponse>(
          '/raindrop.v1.RoleService/ListRoles',
          ($0.ListRolesRequest value) => value.writeToBuffer(),
          $0.ListRolesResponse.fromBuffer);
  static final _$getMyRoles =
      $grpc.ClientMethod<$0.GetMyRolesRequest, $0.GetMyRolesResponse>(
          '/raindrop.v1.RoleService/GetMyRoles',
          ($0.GetMyRolesRequest value) => value.writeToBuffer(),
          $0.GetMyRolesResponse.fromBuffer);
  static final _$listPermissions =
      $grpc.ClientMethod<$0.ListPermissionsRequest, $0.ListPermissionsResponse>(
          '/raindrop.v1.RoleService/ListPermissions',
          ($0.ListPermissionsRequest value) => value.writeToBuffer(),
          $0.ListPermissionsResponse.fromBuffer);
  static final _$getRole =
      $grpc.ClientMethod<$0.GetRoleRequest, $0.GetRoleResponse>(
          '/raindrop.v1.RoleService/GetRole',
          ($0.GetRoleRequest value) => value.writeToBuffer(),
          $0.GetRoleResponse.fromBuffer);
  static final _$createRole =
      $grpc.ClientMethod<$0.CreateRoleRequest, $0.CreateRoleResponse>(
          '/raindrop.v1.RoleService/CreateRole',
          ($0.CreateRoleRequest value) => value.writeToBuffer(),
          $0.CreateRoleResponse.fromBuffer);
  static final _$updateRole =
      $grpc.ClientMethod<$0.UpdateRoleRequest, $0.UpdateRoleResponse>(
          '/raindrop.v1.RoleService/UpdateRole',
          ($0.UpdateRoleRequest value) => value.writeToBuffer(),
          $0.UpdateRoleResponse.fromBuffer);
  static final _$deleteRole =
      $grpc.ClientMethod<$0.DeleteRoleRequest, $0.DeleteRoleResponse>(
          '/raindrop.v1.RoleService/DeleteRole',
          ($0.DeleteRoleRequest value) => value.writeToBuffer(),
          $0.DeleteRoleResponse.fromBuffer);
  static final _$getMemberRoles =
      $grpc.ClientMethod<$0.GetMemberRolesRequest, $0.GetMemberRolesResponse>(
          '/raindrop.v1.RoleService/GetMemberRoles',
          ($0.GetMemberRolesRequest value) => value.writeToBuffer(),
          $0.GetMemberRolesResponse.fromBuffer);
  static final _$assignRole =
      $grpc.ClientMethod<$0.AssignRoleRequest, $0.AssignRoleResponse>(
          '/raindrop.v1.RoleService/AssignRole',
          ($0.AssignRoleRequest value) => value.writeToBuffer(),
          $0.AssignRoleResponse.fromBuffer);
  static final _$unassignRole =
      $grpc.ClientMethod<$0.UnassignRoleRequest, $0.UnassignRoleResponse>(
          '/raindrop.v1.RoleService/UnassignRole',
          ($0.UnassignRoleRequest value) => value.writeToBuffer(),
          $0.UnassignRoleResponse.fromBuffer);
}

@$pb.GrpcServiceName('raindrop.v1.RoleService')
abstract class RoleServiceBase extends $grpc.Service {
  $core.String get $name => 'raindrop.v1.RoleService';

  RoleServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.ListRolesRequest, $0.ListRolesResponse>(
        'ListRoles',
        listRoles_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ListRolesRequest.fromBuffer(value),
        ($0.ListRolesResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetMyRolesRequest, $0.GetMyRolesResponse>(
        'GetMyRoles',
        getMyRoles_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.GetMyRolesRequest.fromBuffer(value),
        ($0.GetMyRolesResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ListPermissionsRequest,
            $0.ListPermissionsResponse>(
        'ListPermissions',
        listPermissions_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ListPermissionsRequest.fromBuffer(value),
        ($0.ListPermissionsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetRoleRequest, $0.GetRoleResponse>(
        'GetRole',
        getRole_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.GetRoleRequest.fromBuffer(value),
        ($0.GetRoleResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.CreateRoleRequest, $0.CreateRoleResponse>(
        'CreateRole',
        createRole_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.CreateRoleRequest.fromBuffer(value),
        ($0.CreateRoleResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.UpdateRoleRequest, $0.UpdateRoleResponse>(
        'UpdateRole',
        updateRole_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.UpdateRoleRequest.fromBuffer(value),
        ($0.UpdateRoleResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.DeleteRoleRequest, $0.DeleteRoleResponse>(
        'DeleteRole',
        deleteRole_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.DeleteRoleRequest.fromBuffer(value),
        ($0.DeleteRoleResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetMemberRolesRequest,
            $0.GetMemberRolesResponse>(
        'GetMemberRoles',
        getMemberRoles_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.GetMemberRolesRequest.fromBuffer(value),
        ($0.GetMemberRolesResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.AssignRoleRequest, $0.AssignRoleResponse>(
        'AssignRole',
        assignRole_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.AssignRoleRequest.fromBuffer(value),
        ($0.AssignRoleResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.UnassignRoleRequest, $0.UnassignRoleResponse>(
            'UnassignRole',
            unassignRole_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.UnassignRoleRequest.fromBuffer(value),
            ($0.UnassignRoleResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.ListRolesResponse> listRoles_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ListRolesRequest> $request) async {
    return listRoles($call, await $request);
  }

  $async.Future<$0.ListRolesResponse> listRoles(
      $grpc.ServiceCall call, $0.ListRolesRequest request);

  $async.Future<$0.GetMyRolesResponse> getMyRoles_Pre($grpc.ServiceCall $call,
      $async.Future<$0.GetMyRolesRequest> $request) async {
    return getMyRoles($call, await $request);
  }

  $async.Future<$0.GetMyRolesResponse> getMyRoles(
      $grpc.ServiceCall call, $0.GetMyRolesRequest request);

  $async.Future<$0.ListPermissionsResponse> listPermissions_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ListPermissionsRequest> $request) async {
    return listPermissions($call, await $request);
  }

  $async.Future<$0.ListPermissionsResponse> listPermissions(
      $grpc.ServiceCall call, $0.ListPermissionsRequest request);

  $async.Future<$0.GetRoleResponse> getRole_Pre($grpc.ServiceCall $call,
      $async.Future<$0.GetRoleRequest> $request) async {
    return getRole($call, await $request);
  }

  $async.Future<$0.GetRoleResponse> getRole(
      $grpc.ServiceCall call, $0.GetRoleRequest request);

  $async.Future<$0.CreateRoleResponse> createRole_Pre($grpc.ServiceCall $call,
      $async.Future<$0.CreateRoleRequest> $request) async {
    return createRole($call, await $request);
  }

  $async.Future<$0.CreateRoleResponse> createRole(
      $grpc.ServiceCall call, $0.CreateRoleRequest request);

  $async.Future<$0.UpdateRoleResponse> updateRole_Pre($grpc.ServiceCall $call,
      $async.Future<$0.UpdateRoleRequest> $request) async {
    return updateRole($call, await $request);
  }

  $async.Future<$0.UpdateRoleResponse> updateRole(
      $grpc.ServiceCall call, $0.UpdateRoleRequest request);

  $async.Future<$0.DeleteRoleResponse> deleteRole_Pre($grpc.ServiceCall $call,
      $async.Future<$0.DeleteRoleRequest> $request) async {
    return deleteRole($call, await $request);
  }

  $async.Future<$0.DeleteRoleResponse> deleteRole(
      $grpc.ServiceCall call, $0.DeleteRoleRequest request);

  $async.Future<$0.GetMemberRolesResponse> getMemberRoles_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.GetMemberRolesRequest> $request) async {
    return getMemberRoles($call, await $request);
  }

  $async.Future<$0.GetMemberRolesResponse> getMemberRoles(
      $grpc.ServiceCall call, $0.GetMemberRolesRequest request);

  $async.Future<$0.AssignRoleResponse> assignRole_Pre($grpc.ServiceCall $call,
      $async.Future<$0.AssignRoleRequest> $request) async {
    return assignRole($call, await $request);
  }

  $async.Future<$0.AssignRoleResponse> assignRole(
      $grpc.ServiceCall call, $0.AssignRoleRequest request);

  $async.Future<$0.UnassignRoleResponse> unassignRole_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.UnassignRoleRequest> $request) async {
    return unassignRole($call, await $request);
  }

  $async.Future<$0.UnassignRoleResponse> unassignRole(
      $grpc.ServiceCall call, $0.UnassignRoleRequest request);
}
