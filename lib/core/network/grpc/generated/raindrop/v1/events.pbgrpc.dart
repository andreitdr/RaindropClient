// This is a generated file - do not edit.
//
// Generated from raindrop/v1/events.proto.

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

import 'events.pb.dart' as $0;

export 'events.pb.dart';

/// The push channel: one long-lived stream per signed-in client, carrying every change the caller is
/// allowed to see. Events are notifications, not a source of truth: each carries the full current state
/// of what it is about, nothing is replayed, and a client re-reads after every ready.
@$pb.GrpcServiceName('raindrop.v1.EventService')
class EventServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  EventServiceClient(super.channel, {super.options, super.interceptors});

  /// Open the stream. The server sends ready first, then events; the client sends a heartbeat every
  /// ready.heartbeat_interval. The stream ends with an error whose ErrorInfo.reason says why:
  /// session_ended (log in again), too_slow (reconnect), server_stopping, connection_lost (no
  /// heartbeat arrived in time).
  $grpc.ResponseStream<$0.ConnectResponse> connect(
    $async.Stream<$0.ConnectRequest> request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(_$connect, request, options: options);
  }

  // method descriptors

  static final _$connect =
      $grpc.ClientMethod<$0.ConnectRequest, $0.ConnectResponse>(
          '/raindrop.v1.EventService/Connect',
          ($0.ConnectRequest value) => value.writeToBuffer(),
          $0.ConnectResponse.fromBuffer);
}

@$pb.GrpcServiceName('raindrop.v1.EventService')
abstract class EventServiceBase extends $grpc.Service {
  $core.String get $name => 'raindrop.v1.EventService';

  EventServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.ConnectRequest, $0.ConnectResponse>(
        'Connect',
        connect,
        true,
        true,
        ($core.List<$core.int> value) => $0.ConnectRequest.fromBuffer(value),
        ($0.ConnectResponse value) => value.writeToBuffer()));
  }

  $async.Stream<$0.ConnectResponse> connect(
      $grpc.ServiceCall call, $async.Stream<$0.ConnectRequest> request);
}
