// This is a generated file - do not edit.
//
// Generated from raindrop/v1/delivery.proto.

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

import 'delivery.pb.dart' as $0;

export 'delivery.pb.dart';

/// The MLS delivery service: one group per channel (group id = the channel UUID as 16 big-endian
/// bytes), one commit per epoch, key packages and Welcomes. Every MLS structure is opaque bytes the
/// server reads only the cleartext framing of. Every call needs a bound session.
@$pb.GrpcServiceName('raindrop.v1.DeliveryService')
class DeliveryServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  DeliveryServiceClient(super.channel, {super.options, super.interceptors});

  /// Start a channel's group from its first group info.
  $grpc.ResponseFuture<$0.CreateGroupResponse> createGroup(
    $0.CreateGroupRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$createGroup, request, options: options);
  }

  /// The group's epoch and latest group info, for joining by external commit.
  $grpc.ResponseFuture<$0.GetGroupStateResponse> getGroupState(
    $0.GetGroupStateRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getGroupState, request, options: options);
  }

  /// Submit a commit made in the current epoch. A second one for the same epoch is epoch_conflict.
  $grpc.ResponseFuture<$0.SubmitCommitResponse> submitCommit(
    $0.SubmitCommitRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$submitCommit, request, options: options);
  }

  /// Publish a group info for the current epoch.
  $grpc.ResponseFuture<$0.PutGroupInfoResponse> putGroupInfo(
    $0.PutGroupInfoRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$putGroupInfo, request, options: options);
  }

  /// Catch up: the commits from an epoch on.
  $grpc.ResponseFuture<$0.SyncGroupResponse> syncGroup(
    $0.SyncGroupRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$syncGroup, request, options: options);
  }

  /// Every device that should be in the channel's group right now.
  $grpc.ResponseFuture<$0.GetGroupRosterResponse> getGroupRoster(
    $0.GetGroupRosterRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getGroupRoster, request, options: options);
  }

  /// Upload key packages for this session's device.
  $grpc.ResponseFuture<$0.UploadKeyPackagesResponse> uploadKeyPackages(
    $0.UploadKeyPackagesRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$uploadKeyPackages, request, options: options);
  }

  /// Claim one key package per device, to add those devices to a group.
  $grpc.ResponseFuture<$0.ClaimKeyPackagesResponse> claimKeyPackages(
    $0.ClaimKeyPackagesRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$claimKeyPackages, request, options: options);
  }

  /// How many one-time key packages this device has left on the server.
  $grpc.ResponseFuture<$0.GetKeyPackageCountResponse> getKeyPackageCount(
    $0.GetKeyPackageCountRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getKeyPackageCount, request, options: options);
  }

  /// Welcomes waiting for this device.
  $grpc.ResponseFuture<$0.ListWelcomesResponse> listWelcomes(
    $0.ListWelcomesRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listWelcomes, request, options: options);
  }

  /// Drop Welcomes this device has processed.
  $grpc.ResponseFuture<$0.AckWelcomesResponse> ackWelcomes(
    $0.AckWelcomesRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$ackWelcomes, request, options: options);
  }

  // method descriptors

  static final _$createGroup =
      $grpc.ClientMethod<$0.CreateGroupRequest, $0.CreateGroupResponse>(
          '/raindrop.v1.DeliveryService/CreateGroup',
          ($0.CreateGroupRequest value) => value.writeToBuffer(),
          $0.CreateGroupResponse.fromBuffer);
  static final _$getGroupState =
      $grpc.ClientMethod<$0.GetGroupStateRequest, $0.GetGroupStateResponse>(
          '/raindrop.v1.DeliveryService/GetGroupState',
          ($0.GetGroupStateRequest value) => value.writeToBuffer(),
          $0.GetGroupStateResponse.fromBuffer);
  static final _$submitCommit =
      $grpc.ClientMethod<$0.SubmitCommitRequest, $0.SubmitCommitResponse>(
          '/raindrop.v1.DeliveryService/SubmitCommit',
          ($0.SubmitCommitRequest value) => value.writeToBuffer(),
          $0.SubmitCommitResponse.fromBuffer);
  static final _$putGroupInfo =
      $grpc.ClientMethod<$0.PutGroupInfoRequest, $0.PutGroupInfoResponse>(
          '/raindrop.v1.DeliveryService/PutGroupInfo',
          ($0.PutGroupInfoRequest value) => value.writeToBuffer(),
          $0.PutGroupInfoResponse.fromBuffer);
  static final _$syncGroup =
      $grpc.ClientMethod<$0.SyncGroupRequest, $0.SyncGroupResponse>(
          '/raindrop.v1.DeliveryService/SyncGroup',
          ($0.SyncGroupRequest value) => value.writeToBuffer(),
          $0.SyncGroupResponse.fromBuffer);
  static final _$getGroupRoster =
      $grpc.ClientMethod<$0.GetGroupRosterRequest, $0.GetGroupRosterResponse>(
          '/raindrop.v1.DeliveryService/GetGroupRoster',
          ($0.GetGroupRosterRequest value) => value.writeToBuffer(),
          $0.GetGroupRosterResponse.fromBuffer);
  static final _$uploadKeyPackages = $grpc.ClientMethod<
          $0.UploadKeyPackagesRequest, $0.UploadKeyPackagesResponse>(
      '/raindrop.v1.DeliveryService/UploadKeyPackages',
      ($0.UploadKeyPackagesRequest value) => value.writeToBuffer(),
      $0.UploadKeyPackagesResponse.fromBuffer);
  static final _$claimKeyPackages = $grpc.ClientMethod<
          $0.ClaimKeyPackagesRequest, $0.ClaimKeyPackagesResponse>(
      '/raindrop.v1.DeliveryService/ClaimKeyPackages',
      ($0.ClaimKeyPackagesRequest value) => value.writeToBuffer(),
      $0.ClaimKeyPackagesResponse.fromBuffer);
  static final _$getKeyPackageCount = $grpc.ClientMethod<
          $0.GetKeyPackageCountRequest, $0.GetKeyPackageCountResponse>(
      '/raindrop.v1.DeliveryService/GetKeyPackageCount',
      ($0.GetKeyPackageCountRequest value) => value.writeToBuffer(),
      $0.GetKeyPackageCountResponse.fromBuffer);
  static final _$listWelcomes =
      $grpc.ClientMethod<$0.ListWelcomesRequest, $0.ListWelcomesResponse>(
          '/raindrop.v1.DeliveryService/ListWelcomes',
          ($0.ListWelcomesRequest value) => value.writeToBuffer(),
          $0.ListWelcomesResponse.fromBuffer);
  static final _$ackWelcomes =
      $grpc.ClientMethod<$0.AckWelcomesRequest, $0.AckWelcomesResponse>(
          '/raindrop.v1.DeliveryService/AckWelcomes',
          ($0.AckWelcomesRequest value) => value.writeToBuffer(),
          $0.AckWelcomesResponse.fromBuffer);
}

@$pb.GrpcServiceName('raindrop.v1.DeliveryService')
abstract class DeliveryServiceBase extends $grpc.Service {
  $core.String get $name => 'raindrop.v1.DeliveryService';

  DeliveryServiceBase() {
    $addMethod(
        $grpc.ServiceMethod<$0.CreateGroupRequest, $0.CreateGroupResponse>(
            'CreateGroup',
            createGroup_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.CreateGroupRequest.fromBuffer(value),
            ($0.CreateGroupResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.GetGroupStateRequest, $0.GetGroupStateResponse>(
            'GetGroupState',
            getGroupState_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.GetGroupStateRequest.fromBuffer(value),
            ($0.GetGroupStateResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.SubmitCommitRequest, $0.SubmitCommitResponse>(
            'SubmitCommit',
            submitCommit_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.SubmitCommitRequest.fromBuffer(value),
            ($0.SubmitCommitResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.PutGroupInfoRequest, $0.PutGroupInfoResponse>(
            'PutGroupInfo',
            putGroupInfo_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.PutGroupInfoRequest.fromBuffer(value),
            ($0.PutGroupInfoResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SyncGroupRequest, $0.SyncGroupResponse>(
        'SyncGroup',
        syncGroup_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.SyncGroupRequest.fromBuffer(value),
        ($0.SyncGroupResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetGroupRosterRequest,
            $0.GetGroupRosterResponse>(
        'GetGroupRoster',
        getGroupRoster_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.GetGroupRosterRequest.fromBuffer(value),
        ($0.GetGroupRosterResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.UploadKeyPackagesRequest,
            $0.UploadKeyPackagesResponse>(
        'UploadKeyPackages',
        uploadKeyPackages_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.UploadKeyPackagesRequest.fromBuffer(value),
        ($0.UploadKeyPackagesResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ClaimKeyPackagesRequest,
            $0.ClaimKeyPackagesResponse>(
        'ClaimKeyPackages',
        claimKeyPackages_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ClaimKeyPackagesRequest.fromBuffer(value),
        ($0.ClaimKeyPackagesResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetKeyPackageCountRequest,
            $0.GetKeyPackageCountResponse>(
        'GetKeyPackageCount',
        getKeyPackageCount_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.GetKeyPackageCountRequest.fromBuffer(value),
        ($0.GetKeyPackageCountResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.ListWelcomesRequest, $0.ListWelcomesResponse>(
            'ListWelcomes',
            listWelcomes_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ListWelcomesRequest.fromBuffer(value),
            ($0.ListWelcomesResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.AckWelcomesRequest, $0.AckWelcomesResponse>(
            'AckWelcomes',
            ackWelcomes_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.AckWelcomesRequest.fromBuffer(value),
            ($0.AckWelcomesResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.CreateGroupResponse> createGroup_Pre($grpc.ServiceCall $call,
      $async.Future<$0.CreateGroupRequest> $request) async {
    return createGroup($call, await $request);
  }

  $async.Future<$0.CreateGroupResponse> createGroup(
      $grpc.ServiceCall call, $0.CreateGroupRequest request);

  $async.Future<$0.GetGroupStateResponse> getGroupState_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.GetGroupStateRequest> $request) async {
    return getGroupState($call, await $request);
  }

  $async.Future<$0.GetGroupStateResponse> getGroupState(
      $grpc.ServiceCall call, $0.GetGroupStateRequest request);

  $async.Future<$0.SubmitCommitResponse> submitCommit_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.SubmitCommitRequest> $request) async {
    return submitCommit($call, await $request);
  }

  $async.Future<$0.SubmitCommitResponse> submitCommit(
      $grpc.ServiceCall call, $0.SubmitCommitRequest request);

  $async.Future<$0.PutGroupInfoResponse> putGroupInfo_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.PutGroupInfoRequest> $request) async {
    return putGroupInfo($call, await $request);
  }

  $async.Future<$0.PutGroupInfoResponse> putGroupInfo(
      $grpc.ServiceCall call, $0.PutGroupInfoRequest request);

  $async.Future<$0.SyncGroupResponse> syncGroup_Pre($grpc.ServiceCall $call,
      $async.Future<$0.SyncGroupRequest> $request) async {
    return syncGroup($call, await $request);
  }

  $async.Future<$0.SyncGroupResponse> syncGroup(
      $grpc.ServiceCall call, $0.SyncGroupRequest request);

  $async.Future<$0.GetGroupRosterResponse> getGroupRoster_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.GetGroupRosterRequest> $request) async {
    return getGroupRoster($call, await $request);
  }

  $async.Future<$0.GetGroupRosterResponse> getGroupRoster(
      $grpc.ServiceCall call, $0.GetGroupRosterRequest request);

  $async.Future<$0.UploadKeyPackagesResponse> uploadKeyPackages_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.UploadKeyPackagesRequest> $request) async {
    return uploadKeyPackages($call, await $request);
  }

  $async.Future<$0.UploadKeyPackagesResponse> uploadKeyPackages(
      $grpc.ServiceCall call, $0.UploadKeyPackagesRequest request);

  $async.Future<$0.ClaimKeyPackagesResponse> claimKeyPackages_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ClaimKeyPackagesRequest> $request) async {
    return claimKeyPackages($call, await $request);
  }

  $async.Future<$0.ClaimKeyPackagesResponse> claimKeyPackages(
      $grpc.ServiceCall call, $0.ClaimKeyPackagesRequest request);

  $async.Future<$0.GetKeyPackageCountResponse> getKeyPackageCount_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.GetKeyPackageCountRequest> $request) async {
    return getKeyPackageCount($call, await $request);
  }

  $async.Future<$0.GetKeyPackageCountResponse> getKeyPackageCount(
      $grpc.ServiceCall call, $0.GetKeyPackageCountRequest request);

  $async.Future<$0.ListWelcomesResponse> listWelcomes_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ListWelcomesRequest> $request) async {
    return listWelcomes($call, await $request);
  }

  $async.Future<$0.ListWelcomesResponse> listWelcomes(
      $grpc.ServiceCall call, $0.ListWelcomesRequest request);

  $async.Future<$0.AckWelcomesResponse> ackWelcomes_Pre($grpc.ServiceCall $call,
      $async.Future<$0.AckWelcomesRequest> $request) async {
    return ackWelcomes($call, await $request);
  }

  $async.Future<$0.AckWelcomesResponse> ackWelcomes(
      $grpc.ServiceCall call, $0.AckWelcomesRequest request);
}
