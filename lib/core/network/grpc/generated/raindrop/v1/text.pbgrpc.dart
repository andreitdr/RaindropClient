// This is a generated file - do not edit.
//
// Generated from raindrop/v1/text.proto.

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

import 'text.pb.dart' as $0;

export 'text.pb.dart';

/// Messages in text channels. Posting and reading are calls; everything that changes afterwards
/// arrives on the event stream.
@$pb.GrpcServiceName('raindrop.v1.TextChannelService')
class TextChannelServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  TextChannelServiceClient(super.channel, {super.options, super.interceptors});

  /// Post a plaintext message. Refused with encryption_required unless the server allows plaintext.
  $grpc.ResponseFuture<$0.SendMessageResponse> sendMessage(
    $0.SendMessageRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$sendMessage, request, options: options);
  }

  /// Post an end-to-end encrypted message: needs send_messages, a bound session, and attach_files for
  /// any attachment_ids.
  $grpc.ResponseFuture<$0.SendEncryptedMessageResponse> sendEncryptedMessage(
    $0.SendEncryptedMessageRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$sendEncryptedMessage, request, options: options);
  }

  /// One page of history, newest page first; follow next_cursor further into the past.
  $grpc.ResponseFuture<$0.GetHistoryResponse> getHistory(
    $0.GetHistoryRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getHistory, request, options: options);
  }

  /// Delete a message: your own always, anyone else's with manage_messages. The row stays as a tombstone.
  $grpc.ResponseFuture<$0.DeleteMessageResponse> deleteMessage(
    $0.DeleteMessageRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deleteMessage, request, options: options);
  }

  /// Report an encrypted message, revealing its text together with the author device's attestation.
  $grpc.ResponseFuture<$0.ReportMessageResponse> reportMessage(
    $0.ReportMessageRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$reportMessage, request, options: options);
  }

  /// A channel's reports: needs manage_messages.
  $grpc.ResponseFuture<$0.ListReportsResponse> listReports(
    $0.ListReportsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listReports, request, options: options);
  }

  // method descriptors

  static final _$sendMessage =
      $grpc.ClientMethod<$0.SendMessageRequest, $0.SendMessageResponse>(
          '/raindrop.v1.TextChannelService/SendMessage',
          ($0.SendMessageRequest value) => value.writeToBuffer(),
          $0.SendMessageResponse.fromBuffer);
  static final _$sendEncryptedMessage = $grpc.ClientMethod<
          $0.SendEncryptedMessageRequest, $0.SendEncryptedMessageResponse>(
      '/raindrop.v1.TextChannelService/SendEncryptedMessage',
      ($0.SendEncryptedMessageRequest value) => value.writeToBuffer(),
      $0.SendEncryptedMessageResponse.fromBuffer);
  static final _$getHistory =
      $grpc.ClientMethod<$0.GetHistoryRequest, $0.GetHistoryResponse>(
          '/raindrop.v1.TextChannelService/GetHistory',
          ($0.GetHistoryRequest value) => value.writeToBuffer(),
          $0.GetHistoryResponse.fromBuffer);
  static final _$deleteMessage =
      $grpc.ClientMethod<$0.DeleteMessageRequest, $0.DeleteMessageResponse>(
          '/raindrop.v1.TextChannelService/DeleteMessage',
          ($0.DeleteMessageRequest value) => value.writeToBuffer(),
          $0.DeleteMessageResponse.fromBuffer);
  static final _$reportMessage =
      $grpc.ClientMethod<$0.ReportMessageRequest, $0.ReportMessageResponse>(
          '/raindrop.v1.TextChannelService/ReportMessage',
          ($0.ReportMessageRequest value) => value.writeToBuffer(),
          $0.ReportMessageResponse.fromBuffer);
  static final _$listReports =
      $grpc.ClientMethod<$0.ListReportsRequest, $0.ListReportsResponse>(
          '/raindrop.v1.TextChannelService/ListReports',
          ($0.ListReportsRequest value) => value.writeToBuffer(),
          $0.ListReportsResponse.fromBuffer);
}

@$pb.GrpcServiceName('raindrop.v1.TextChannelService')
abstract class TextChannelServiceBase extends $grpc.Service {
  $core.String get $name => 'raindrop.v1.TextChannelService';

  TextChannelServiceBase() {
    $addMethod(
        $grpc.ServiceMethod<$0.SendMessageRequest, $0.SendMessageResponse>(
            'SendMessage',
            sendMessage_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.SendMessageRequest.fromBuffer(value),
            ($0.SendMessageResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SendEncryptedMessageRequest,
            $0.SendEncryptedMessageResponse>(
        'SendEncryptedMessage',
        sendEncryptedMessage_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.SendEncryptedMessageRequest.fromBuffer(value),
        ($0.SendEncryptedMessageResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetHistoryRequest, $0.GetHistoryResponse>(
        'GetHistory',
        getHistory_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.GetHistoryRequest.fromBuffer(value),
        ($0.GetHistoryResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.DeleteMessageRequest, $0.DeleteMessageResponse>(
            'DeleteMessage',
            deleteMessage_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.DeleteMessageRequest.fromBuffer(value),
            ($0.DeleteMessageResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.ReportMessageRequest, $0.ReportMessageResponse>(
            'ReportMessage',
            reportMessage_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ReportMessageRequest.fromBuffer(value),
            ($0.ReportMessageResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.ListReportsRequest, $0.ListReportsResponse>(
            'ListReports',
            listReports_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ListReportsRequest.fromBuffer(value),
            ($0.ListReportsResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.SendMessageResponse> sendMessage_Pre($grpc.ServiceCall $call,
      $async.Future<$0.SendMessageRequest> $request) async {
    return sendMessage($call, await $request);
  }

  $async.Future<$0.SendMessageResponse> sendMessage(
      $grpc.ServiceCall call, $0.SendMessageRequest request);

  $async.Future<$0.SendEncryptedMessageResponse> sendEncryptedMessage_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.SendEncryptedMessageRequest> $request) async {
    return sendEncryptedMessage($call, await $request);
  }

  $async.Future<$0.SendEncryptedMessageResponse> sendEncryptedMessage(
      $grpc.ServiceCall call, $0.SendEncryptedMessageRequest request);

  $async.Future<$0.GetHistoryResponse> getHistory_Pre($grpc.ServiceCall $call,
      $async.Future<$0.GetHistoryRequest> $request) async {
    return getHistory($call, await $request);
  }

  $async.Future<$0.GetHistoryResponse> getHistory(
      $grpc.ServiceCall call, $0.GetHistoryRequest request);

  $async.Future<$0.DeleteMessageResponse> deleteMessage_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.DeleteMessageRequest> $request) async {
    return deleteMessage($call, await $request);
  }

  $async.Future<$0.DeleteMessageResponse> deleteMessage(
      $grpc.ServiceCall call, $0.DeleteMessageRequest request);

  $async.Future<$0.ReportMessageResponse> reportMessage_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ReportMessageRequest> $request) async {
    return reportMessage($call, await $request);
  }

  $async.Future<$0.ReportMessageResponse> reportMessage(
      $grpc.ServiceCall call, $0.ReportMessageRequest request);

  $async.Future<$0.ListReportsResponse> listReports_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ListReportsRequest> $request) async {
    return listReports($call, await $request);
  }

  $async.Future<$0.ListReportsResponse> listReports(
      $grpc.ServiceCall call, $0.ListReportsRequest request);
}
