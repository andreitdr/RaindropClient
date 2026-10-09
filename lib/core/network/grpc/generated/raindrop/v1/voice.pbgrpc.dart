// This is a generated file - do not edit.
//
// Generated from raindrop/v1/voice.proto.

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

import 'voice.pb.dart' as $0;

export 'voice.pb.dart';

/// Voice calls. Raindrop decides who may join, speak, show their camera, share their screen and moderate;
/// the media itself goes over the media transport a join names (LiveKit today: WebRTC, its signalling
/// relayed by this server as a WebSocket, end-to-end encrypted with a key from the channel's MLS group —
/// one key for a call, covering voice, camera and screen alike). This service is the control half only.
@$pb.GrpcServiceName('raindrop.v1.VoiceService')
class VoiceServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  VoiceServiceClient(super.channel, {super.options, super.interceptors});

  /// Whether voice works here, and who is in every call the caller can see.
  $grpc.ResponseFuture<$0.GetVoiceStatusResponse> getVoiceStatus(
    $0.GetVoiceStatusRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getVoiceStatus, request, options: options);
  }

  /// Join a call: needs connect. Returns where to connect and a short-lived token.
  $grpc.ResponseFuture<$0.JoinVoiceResponse> joinVoice(
    $0.JoinVoiceRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$joinVoice, request, options: options);
  }

  /// Leave the named call. Idempotent; only the session that joined can leave.
  $grpc.ResponseFuture<$0.LeaveVoiceResponse> leaveVoice(
    $0.LeaveVoiceRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$leaveVoice, request, options: options);
  }

  /// Self mute, deafen, camera and screen share. Mute and deafen are only everybody's icons; turning the
  /// camera on or starting a screen share is also what earns the media transport's permission to send
  /// it, so either can be refused. The camera needs video, and refuses with camera_limit_reached when
  /// every camera place in the call is taken; a screen share needs screen_share, and refuses with
  /// screen_share_limit_reached when every sharing place is taken.
  $grpc.ResponseFuture<$0.SetVoiceSelfStateResponse> setVoiceSelfState(
    $0.SetVoiceSelfStateRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$setVoiceSelfState, request, options: options);
  }

  /// Mute or unmute a member for everyone: needs mute_members server-wide.
  $grpc.ResponseFuture<$0.MuteVoiceMemberResponse> muteVoiceMember(
    $0.MuteVoiceMemberRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$muteVoiceMember, request, options: options);
  }

  // method descriptors

  static final _$getVoiceStatus =
      $grpc.ClientMethod<$0.GetVoiceStatusRequest, $0.GetVoiceStatusResponse>(
          '/raindrop.v1.VoiceService/GetVoiceStatus',
          ($0.GetVoiceStatusRequest value) => value.writeToBuffer(),
          $0.GetVoiceStatusResponse.fromBuffer);
  static final _$joinVoice =
      $grpc.ClientMethod<$0.JoinVoiceRequest, $0.JoinVoiceResponse>(
          '/raindrop.v1.VoiceService/JoinVoice',
          ($0.JoinVoiceRequest value) => value.writeToBuffer(),
          $0.JoinVoiceResponse.fromBuffer);
  static final _$leaveVoice =
      $grpc.ClientMethod<$0.LeaveVoiceRequest, $0.LeaveVoiceResponse>(
          '/raindrop.v1.VoiceService/LeaveVoice',
          ($0.LeaveVoiceRequest value) => value.writeToBuffer(),
          $0.LeaveVoiceResponse.fromBuffer);
  static final _$setVoiceSelfState = $grpc.ClientMethod<
          $0.SetVoiceSelfStateRequest, $0.SetVoiceSelfStateResponse>(
      '/raindrop.v1.VoiceService/SetVoiceSelfState',
      ($0.SetVoiceSelfStateRequest value) => value.writeToBuffer(),
      $0.SetVoiceSelfStateResponse.fromBuffer);
  static final _$muteVoiceMember =
      $grpc.ClientMethod<$0.MuteVoiceMemberRequest, $0.MuteVoiceMemberResponse>(
          '/raindrop.v1.VoiceService/MuteVoiceMember',
          ($0.MuteVoiceMemberRequest value) => value.writeToBuffer(),
          $0.MuteVoiceMemberResponse.fromBuffer);
}

@$pb.GrpcServiceName('raindrop.v1.VoiceService')
abstract class VoiceServiceBase extends $grpc.Service {
  $core.String get $name => 'raindrop.v1.VoiceService';

  VoiceServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.GetVoiceStatusRequest,
            $0.GetVoiceStatusResponse>(
        'GetVoiceStatus',
        getVoiceStatus_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.GetVoiceStatusRequest.fromBuffer(value),
        ($0.GetVoiceStatusResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.JoinVoiceRequest, $0.JoinVoiceResponse>(
        'JoinVoice',
        joinVoice_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.JoinVoiceRequest.fromBuffer(value),
        ($0.JoinVoiceResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.LeaveVoiceRequest, $0.LeaveVoiceResponse>(
        'LeaveVoice',
        leaveVoice_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.LeaveVoiceRequest.fromBuffer(value),
        ($0.LeaveVoiceResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SetVoiceSelfStateRequest,
            $0.SetVoiceSelfStateResponse>(
        'SetVoiceSelfState',
        setVoiceSelfState_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.SetVoiceSelfStateRequest.fromBuffer(value),
        ($0.SetVoiceSelfStateResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.MuteVoiceMemberRequest,
            $0.MuteVoiceMemberResponse>(
        'MuteVoiceMember',
        muteVoiceMember_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.MuteVoiceMemberRequest.fromBuffer(value),
        ($0.MuteVoiceMemberResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.GetVoiceStatusResponse> getVoiceStatus_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.GetVoiceStatusRequest> $request) async {
    return getVoiceStatus($call, await $request);
  }

  $async.Future<$0.GetVoiceStatusResponse> getVoiceStatus(
      $grpc.ServiceCall call, $0.GetVoiceStatusRequest request);

  $async.Future<$0.JoinVoiceResponse> joinVoice_Pre($grpc.ServiceCall $call,
      $async.Future<$0.JoinVoiceRequest> $request) async {
    return joinVoice($call, await $request);
  }

  $async.Future<$0.JoinVoiceResponse> joinVoice(
      $grpc.ServiceCall call, $0.JoinVoiceRequest request);

  $async.Future<$0.LeaveVoiceResponse> leaveVoice_Pre($grpc.ServiceCall $call,
      $async.Future<$0.LeaveVoiceRequest> $request) async {
    return leaveVoice($call, await $request);
  }

  $async.Future<$0.LeaveVoiceResponse> leaveVoice(
      $grpc.ServiceCall call, $0.LeaveVoiceRequest request);

  $async.Future<$0.SetVoiceSelfStateResponse> setVoiceSelfState_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.SetVoiceSelfStateRequest> $request) async {
    return setVoiceSelfState($call, await $request);
  }

  $async.Future<$0.SetVoiceSelfStateResponse> setVoiceSelfState(
      $grpc.ServiceCall call, $0.SetVoiceSelfStateRequest request);

  $async.Future<$0.MuteVoiceMemberResponse> muteVoiceMember_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.MuteVoiceMemberRequest> $request) async {
    return muteVoiceMember($call, await $request);
  }

  $async.Future<$0.MuteVoiceMemberResponse> muteVoiceMember(
      $grpc.ServiceCall call, $0.MuteVoiceMemberRequest request);
}
