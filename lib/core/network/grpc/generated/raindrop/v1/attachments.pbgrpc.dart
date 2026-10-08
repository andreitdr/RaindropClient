// This is a generated file - do not edit.
//
// Generated from raindrop/v1/attachments.proto.

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

import 'attachments.pb.dart' as $0;

export 'attachments.pb.dart';

/// Encrypted files. The sender encrypts each file under its own key (raindrop/attachment/v1), uploads
/// the ciphertext, and names the upload in SendEncryptedMessage; the key travels inside the MLS message.
/// The server learns a file's channel, declared extension and size, nothing else.
@$pb.GrpcServiceName('raindrop.v1.AttachmentService')
class AttachmentServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  AttachmentServiceClient(super.channel, {super.options, super.interceptors});

  /// What this server accepts, so a client can refuse a file before uploading any of it.
  $grpc.ResponseFuture<$0.GetAttachmentPolicyResponse> getAttachmentPolicy(
    $0.GetAttachmentPolicyRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getAttachmentPolicy, request, options: options);
  }

  /// Start an upload: needs send_messages and attach_files in the channel, and a bound session.
  $grpc.ResponseFuture<$0.CreateUploadResponse> createUpload(
    $0.CreateUploadRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$createUpload, request, options: options);
  }

  /// Stream ciphertext into an upload: a header first, then data frames of at most the policy's
  /// upload_frame_bytes each. The header's offset must be where the upload stands
  /// (upload_offset_mismatch otherwise). A broken stream keeps what arrived; resume from
  /// GetUploadStatus.
  $grpc.ResponseFuture<$0.UploadResponse> upload(
    $async.Stream<$0.UploadRequest> request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(_$upload, request, options: options).single;
  }

  /// Where an upload stands: how many bytes have arrived, to resume.
  $grpc.ResponseFuture<$0.GetUploadStatusResponse> getUploadStatus(
    $0.GetUploadStatusRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getUploadStatus, request, options: options);
  }

  /// Finish an upload, checked against the ciphertext's SHA-256.
  $grpc.ResponseFuture<$0.CompleteUploadResponse> completeUpload(
    $0.CompleteUploadRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$completeUpload, request, options: options);
  }

  /// Throw away an upload not yet sent in a message.
  $grpc.ResponseFuture<$0.CancelUploadResponse> cancelUpload(
    $0.CancelUploadRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$cancelUpload, request, options: options);
  }

  /// Stream a file's ciphertext, from an offset, to anyone who can see its channel: a header first,
  /// then data frames. Every failure is attachment_not_found, so ids cannot be probed.
  $grpc.ResponseStream<$0.DownloadResponse> download(
    $0.DownloadRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$download, $async.Stream.fromIterable([request]),
        options: options);
  }

  // method descriptors

  static final _$getAttachmentPolicy = $grpc.ClientMethod<
          $0.GetAttachmentPolicyRequest, $0.GetAttachmentPolicyResponse>(
      '/raindrop.v1.AttachmentService/GetAttachmentPolicy',
      ($0.GetAttachmentPolicyRequest value) => value.writeToBuffer(),
      $0.GetAttachmentPolicyResponse.fromBuffer);
  static final _$createUpload =
      $grpc.ClientMethod<$0.CreateUploadRequest, $0.CreateUploadResponse>(
          '/raindrop.v1.AttachmentService/CreateUpload',
          ($0.CreateUploadRequest value) => value.writeToBuffer(),
          $0.CreateUploadResponse.fromBuffer);
  static final _$upload =
      $grpc.ClientMethod<$0.UploadRequest, $0.UploadResponse>(
          '/raindrop.v1.AttachmentService/Upload',
          ($0.UploadRequest value) => value.writeToBuffer(),
          $0.UploadResponse.fromBuffer);
  static final _$getUploadStatus =
      $grpc.ClientMethod<$0.GetUploadStatusRequest, $0.GetUploadStatusResponse>(
          '/raindrop.v1.AttachmentService/GetUploadStatus',
          ($0.GetUploadStatusRequest value) => value.writeToBuffer(),
          $0.GetUploadStatusResponse.fromBuffer);
  static final _$completeUpload =
      $grpc.ClientMethod<$0.CompleteUploadRequest, $0.CompleteUploadResponse>(
          '/raindrop.v1.AttachmentService/CompleteUpload',
          ($0.CompleteUploadRequest value) => value.writeToBuffer(),
          $0.CompleteUploadResponse.fromBuffer);
  static final _$cancelUpload =
      $grpc.ClientMethod<$0.CancelUploadRequest, $0.CancelUploadResponse>(
          '/raindrop.v1.AttachmentService/CancelUpload',
          ($0.CancelUploadRequest value) => value.writeToBuffer(),
          $0.CancelUploadResponse.fromBuffer);
  static final _$download =
      $grpc.ClientMethod<$0.DownloadRequest, $0.DownloadResponse>(
          '/raindrop.v1.AttachmentService/Download',
          ($0.DownloadRequest value) => value.writeToBuffer(),
          $0.DownloadResponse.fromBuffer);
}

@$pb.GrpcServiceName('raindrop.v1.AttachmentService')
abstract class AttachmentServiceBase extends $grpc.Service {
  $core.String get $name => 'raindrop.v1.AttachmentService';

  AttachmentServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.GetAttachmentPolicyRequest,
            $0.GetAttachmentPolicyResponse>(
        'GetAttachmentPolicy',
        getAttachmentPolicy_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.GetAttachmentPolicyRequest.fromBuffer(value),
        ($0.GetAttachmentPolicyResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.CreateUploadRequest, $0.CreateUploadResponse>(
            'CreateUpload',
            createUpload_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.CreateUploadRequest.fromBuffer(value),
            ($0.CreateUploadResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.UploadRequest, $0.UploadResponse>(
        'Upload',
        upload,
        true,
        false,
        ($core.List<$core.int> value) => $0.UploadRequest.fromBuffer(value),
        ($0.UploadResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetUploadStatusRequest,
            $0.GetUploadStatusResponse>(
        'GetUploadStatus',
        getUploadStatus_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.GetUploadStatusRequest.fromBuffer(value),
        ($0.GetUploadStatusResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.CompleteUploadRequest,
            $0.CompleteUploadResponse>(
        'CompleteUpload',
        completeUpload_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.CompleteUploadRequest.fromBuffer(value),
        ($0.CompleteUploadResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.CancelUploadRequest, $0.CancelUploadResponse>(
            'CancelUpload',
            cancelUpload_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.CancelUploadRequest.fromBuffer(value),
            ($0.CancelUploadResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.DownloadRequest, $0.DownloadResponse>(
        'Download',
        download_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.DownloadRequest.fromBuffer(value),
        ($0.DownloadResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.GetAttachmentPolicyResponse> getAttachmentPolicy_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.GetAttachmentPolicyRequest> $request) async {
    return getAttachmentPolicy($call, await $request);
  }

  $async.Future<$0.GetAttachmentPolicyResponse> getAttachmentPolicy(
      $grpc.ServiceCall call, $0.GetAttachmentPolicyRequest request);

  $async.Future<$0.CreateUploadResponse> createUpload_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.CreateUploadRequest> $request) async {
    return createUpload($call, await $request);
  }

  $async.Future<$0.CreateUploadResponse> createUpload(
      $grpc.ServiceCall call, $0.CreateUploadRequest request);

  $async.Future<$0.UploadResponse> upload(
      $grpc.ServiceCall call, $async.Stream<$0.UploadRequest> request);

  $async.Future<$0.GetUploadStatusResponse> getUploadStatus_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.GetUploadStatusRequest> $request) async {
    return getUploadStatus($call, await $request);
  }

  $async.Future<$0.GetUploadStatusResponse> getUploadStatus(
      $grpc.ServiceCall call, $0.GetUploadStatusRequest request);

  $async.Future<$0.CompleteUploadResponse> completeUpload_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.CompleteUploadRequest> $request) async {
    return completeUpload($call, await $request);
  }

  $async.Future<$0.CompleteUploadResponse> completeUpload(
      $grpc.ServiceCall call, $0.CompleteUploadRequest request);

  $async.Future<$0.CancelUploadResponse> cancelUpload_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.CancelUploadRequest> $request) async {
    return cancelUpload($call, await $request);
  }

  $async.Future<$0.CancelUploadResponse> cancelUpload(
      $grpc.ServiceCall call, $0.CancelUploadRequest request);

  $async.Stream<$0.DownloadResponse> download_Pre($grpc.ServiceCall $call,
      $async.Future<$0.DownloadRequest> $request) async* {
    yield* download($call, await $request);
  }

  $async.Stream<$0.DownloadResponse> download(
      $grpc.ServiceCall call, $0.DownloadRequest request);
}
