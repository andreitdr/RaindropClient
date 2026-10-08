// This is a generated file - do not edit.
//
// Generated from raindrop/v1/users.proto.

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

import 'users.pb.dart' as $0;

export 'users.pb.dart';

/// Accounts and sessions. A client holds its own UUID per server; the first login with it is
/// registration. Every call but the first six needs a session: send its token as
/// `authorization: Bearer <token>` metadata.
@$pb.GrpcServiceName('raindrop.v1.UserService')
class UserServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  UserServiceClient(super.channel, {super.options, super.interceptors});

  /// What this UUID means here, so a client knows which flow to show. Anonymous.
  $grpc.ResponseFuture<$0.GetUserStatusResponse> getUserStatus(
    $0.GetUserStatusRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getUserStatus, request, options: options);
  }

  /// Whether a username can be claimed right now, for the registration screen. Anonymous.
  $grpc.ResponseFuture<$0.CheckUsernameResponse> checkUsername(
    $0.CheckUsernameRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$checkUsername, request, options: options);
  }

  /// First login: claim a username and set a password for this UUID, and get a session. Anonymous.
  $grpc.ResponseFuture<$0.RegisterResponse> register(
    $0.RegisterRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$register, request, options: options);
  }

  /// UUID (or username) and password to a session. Anonymous.
  $grpc.ResponseFuture<$0.LoginResponse> login(
    $0.LoginRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$login, request, options: options);
  }

  /// Restore an account that left with its data preserved. Anonymous.
  $grpc.ResponseFuture<$0.RejoinResponse> rejoin(
    $0.RejoinRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$rejoin, request, options: options);
  }

  /// End this session.
  $grpc.ResponseFuture<$0.LogoutResponse> logout(
    $0.LogoutRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$logout, request, options: options);
  }

  /// The caller's own account.
  $grpc.ResponseFuture<$0.GetMeResponse> getMe(
    $0.GetMeRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getMe, request, options: options);
  }

  /// What another member is allowed to see about a UUID, e.g. to name a message's author.
  $grpc.ResponseFuture<$0.LookupUserResponse> lookupUser(
    $0.LookupUserRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$lookupUser, request, options: options);
  }

  /// Change the password. Ends every session, this one included, and returns a new one.
  $grpc.ResponseFuture<$0.ChangePasswordResponse> changePassword(
    $0.ChangePasswordRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$changePassword, request, options: options);
  }

  /// Claim a different username.
  $grpc.ResponseFuture<$0.ChangeUsernameResponse> changeUsername(
    $0.ChangeUsernameRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$changeUsername, request, options: options);
  }

  /// Leave the server, preserving the account for a possible return or erasing it now.
  $grpc.ResponseFuture<$0.LeaveServerResponse> leaveServer(
    $0.LeaveServerRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$leaveServer, request, options: options);
  }

  // method descriptors

  static final _$getUserStatus =
      $grpc.ClientMethod<$0.GetUserStatusRequest, $0.GetUserStatusResponse>(
          '/raindrop.v1.UserService/GetUserStatus',
          ($0.GetUserStatusRequest value) => value.writeToBuffer(),
          $0.GetUserStatusResponse.fromBuffer);
  static final _$checkUsername =
      $grpc.ClientMethod<$0.CheckUsernameRequest, $0.CheckUsernameResponse>(
          '/raindrop.v1.UserService/CheckUsername',
          ($0.CheckUsernameRequest value) => value.writeToBuffer(),
          $0.CheckUsernameResponse.fromBuffer);
  static final _$register =
      $grpc.ClientMethod<$0.RegisterRequest, $0.RegisterResponse>(
          '/raindrop.v1.UserService/Register',
          ($0.RegisterRequest value) => value.writeToBuffer(),
          $0.RegisterResponse.fromBuffer);
  static final _$login = $grpc.ClientMethod<$0.LoginRequest, $0.LoginResponse>(
      '/raindrop.v1.UserService/Login',
      ($0.LoginRequest value) => value.writeToBuffer(),
      $0.LoginResponse.fromBuffer);
  static final _$rejoin =
      $grpc.ClientMethod<$0.RejoinRequest, $0.RejoinResponse>(
          '/raindrop.v1.UserService/Rejoin',
          ($0.RejoinRequest value) => value.writeToBuffer(),
          $0.RejoinResponse.fromBuffer);
  static final _$logout =
      $grpc.ClientMethod<$0.LogoutRequest, $0.LogoutResponse>(
          '/raindrop.v1.UserService/Logout',
          ($0.LogoutRequest value) => value.writeToBuffer(),
          $0.LogoutResponse.fromBuffer);
  static final _$getMe = $grpc.ClientMethod<$0.GetMeRequest, $0.GetMeResponse>(
      '/raindrop.v1.UserService/GetMe',
      ($0.GetMeRequest value) => value.writeToBuffer(),
      $0.GetMeResponse.fromBuffer);
  static final _$lookupUser =
      $grpc.ClientMethod<$0.LookupUserRequest, $0.LookupUserResponse>(
          '/raindrop.v1.UserService/LookupUser',
          ($0.LookupUserRequest value) => value.writeToBuffer(),
          $0.LookupUserResponse.fromBuffer);
  static final _$changePassword =
      $grpc.ClientMethod<$0.ChangePasswordRequest, $0.ChangePasswordResponse>(
          '/raindrop.v1.UserService/ChangePassword',
          ($0.ChangePasswordRequest value) => value.writeToBuffer(),
          $0.ChangePasswordResponse.fromBuffer);
  static final _$changeUsername =
      $grpc.ClientMethod<$0.ChangeUsernameRequest, $0.ChangeUsernameResponse>(
          '/raindrop.v1.UserService/ChangeUsername',
          ($0.ChangeUsernameRequest value) => value.writeToBuffer(),
          $0.ChangeUsernameResponse.fromBuffer);
  static final _$leaveServer =
      $grpc.ClientMethod<$0.LeaveServerRequest, $0.LeaveServerResponse>(
          '/raindrop.v1.UserService/LeaveServer',
          ($0.LeaveServerRequest value) => value.writeToBuffer(),
          $0.LeaveServerResponse.fromBuffer);
}

@$pb.GrpcServiceName('raindrop.v1.UserService')
abstract class UserServiceBase extends $grpc.Service {
  $core.String get $name => 'raindrop.v1.UserService';

  UserServiceBase() {
    $addMethod(
        $grpc.ServiceMethod<$0.GetUserStatusRequest, $0.GetUserStatusResponse>(
            'GetUserStatus',
            getUserStatus_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.GetUserStatusRequest.fromBuffer(value),
            ($0.GetUserStatusResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.CheckUsernameRequest, $0.CheckUsernameResponse>(
            'CheckUsername',
            checkUsername_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.CheckUsernameRequest.fromBuffer(value),
            ($0.CheckUsernameResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.RegisterRequest, $0.RegisterResponse>(
        'Register',
        register_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.RegisterRequest.fromBuffer(value),
        ($0.RegisterResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.LoginRequest, $0.LoginResponse>(
        'Login',
        login_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.LoginRequest.fromBuffer(value),
        ($0.LoginResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.RejoinRequest, $0.RejoinResponse>(
        'Rejoin',
        rejoin_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.RejoinRequest.fromBuffer(value),
        ($0.RejoinResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.LogoutRequest, $0.LogoutResponse>(
        'Logout',
        logout_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.LogoutRequest.fromBuffer(value),
        ($0.LogoutResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetMeRequest, $0.GetMeResponse>(
        'GetMe',
        getMe_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.GetMeRequest.fromBuffer(value),
        ($0.GetMeResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.LookupUserRequest, $0.LookupUserResponse>(
        'LookupUser',
        lookupUser_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.LookupUserRequest.fromBuffer(value),
        ($0.LookupUserResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ChangePasswordRequest,
            $0.ChangePasswordResponse>(
        'ChangePassword',
        changePassword_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ChangePasswordRequest.fromBuffer(value),
        ($0.ChangePasswordResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ChangeUsernameRequest,
            $0.ChangeUsernameResponse>(
        'ChangeUsername',
        changeUsername_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ChangeUsernameRequest.fromBuffer(value),
        ($0.ChangeUsernameResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.LeaveServerRequest, $0.LeaveServerResponse>(
            'LeaveServer',
            leaveServer_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.LeaveServerRequest.fromBuffer(value),
            ($0.LeaveServerResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.GetUserStatusResponse> getUserStatus_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.GetUserStatusRequest> $request) async {
    return getUserStatus($call, await $request);
  }

  $async.Future<$0.GetUserStatusResponse> getUserStatus(
      $grpc.ServiceCall call, $0.GetUserStatusRequest request);

  $async.Future<$0.CheckUsernameResponse> checkUsername_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.CheckUsernameRequest> $request) async {
    return checkUsername($call, await $request);
  }

  $async.Future<$0.CheckUsernameResponse> checkUsername(
      $grpc.ServiceCall call, $0.CheckUsernameRequest request);

  $async.Future<$0.RegisterResponse> register_Pre($grpc.ServiceCall $call,
      $async.Future<$0.RegisterRequest> $request) async {
    return register($call, await $request);
  }

  $async.Future<$0.RegisterResponse> register(
      $grpc.ServiceCall call, $0.RegisterRequest request);

  $async.Future<$0.LoginResponse> login_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.LoginRequest> $request) async {
    return login($call, await $request);
  }

  $async.Future<$0.LoginResponse> login(
      $grpc.ServiceCall call, $0.LoginRequest request);

  $async.Future<$0.RejoinResponse> rejoin_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.RejoinRequest> $request) async {
    return rejoin($call, await $request);
  }

  $async.Future<$0.RejoinResponse> rejoin(
      $grpc.ServiceCall call, $0.RejoinRequest request);

  $async.Future<$0.LogoutResponse> logout_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.LogoutRequest> $request) async {
    return logout($call, await $request);
  }

  $async.Future<$0.LogoutResponse> logout(
      $grpc.ServiceCall call, $0.LogoutRequest request);

  $async.Future<$0.GetMeResponse> getMe_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.GetMeRequest> $request) async {
    return getMe($call, await $request);
  }

  $async.Future<$0.GetMeResponse> getMe(
      $grpc.ServiceCall call, $0.GetMeRequest request);

  $async.Future<$0.LookupUserResponse> lookupUser_Pre($grpc.ServiceCall $call,
      $async.Future<$0.LookupUserRequest> $request) async {
    return lookupUser($call, await $request);
  }

  $async.Future<$0.LookupUserResponse> lookupUser(
      $grpc.ServiceCall call, $0.LookupUserRequest request);

  $async.Future<$0.ChangePasswordResponse> changePassword_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ChangePasswordRequest> $request) async {
    return changePassword($call, await $request);
  }

  $async.Future<$0.ChangePasswordResponse> changePassword(
      $grpc.ServiceCall call, $0.ChangePasswordRequest request);

  $async.Future<$0.ChangeUsernameResponse> changeUsername_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ChangeUsernameRequest> $request) async {
    return changeUsername($call, await $request);
  }

  $async.Future<$0.ChangeUsernameResponse> changeUsername(
      $grpc.ServiceCall call, $0.ChangeUsernameRequest request);

  $async.Future<$0.LeaveServerResponse> leaveServer_Pre($grpc.ServiceCall $call,
      $async.Future<$0.LeaveServerRequest> $request) async {
    return leaveServer($call, await $request);
  }

  $async.Future<$0.LeaveServerResponse> leaveServer(
      $grpc.ServiceCall call, $0.LeaveServerRequest request);
}
