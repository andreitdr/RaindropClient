// This is a generated file - do not edit.
//
// Generated from raindrop/v1/channels.proto.

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

import 'channels.pb.dart' as $0;

export 'channels.pb.dart';

/// What every channel has in common: create, list, read, rename, delete. A channel the caller may not
/// see is reported as channel_not_found, never as forbidden.
@$pb.GrpcServiceName('raindrop.v1.ChannelService')
class ChannelServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  ChannelServiceClient(super.channel, {super.options, super.interceptors});

  /// Every channel the caller may see, ordered by name, with what they may do in each.
  $grpc.ResponseFuture<$0.ListChannelsResponse> listChannels(
    $0.ListChannelsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listChannels, request, options: options);
  }

  /// One channel, and what the caller may do in it.
  $grpc.ResponseFuture<$0.GetChannelResponse> getChannel(
    $0.GetChannelRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getChannel, request, options: options);
  }

  /// Create a channel of a given type.
  $grpc.ResponseFuture<$0.CreateChannelResponse> createChannel(
    $0.CreateChannelRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$createChannel, request, options: options);
  }

  /// Rename it: needs rename_channels, or having created it.
  $grpc.ResponseFuture<$0.RenameChannelResponse> renameChannel(
    $0.RenameChannelRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$renameChannel, request, options: options);
  }

  /// Delete it and everything in it: needs delete_channels, or having created it.
  $grpc.ResponseFuture<$0.DeleteChannelResponse> deleteChannel(
    $0.DeleteChannelRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deleteChannel, request, options: options);
  }

  // method descriptors

  static final _$listChannels =
      $grpc.ClientMethod<$0.ListChannelsRequest, $0.ListChannelsResponse>(
          '/raindrop.v1.ChannelService/ListChannels',
          ($0.ListChannelsRequest value) => value.writeToBuffer(),
          $0.ListChannelsResponse.fromBuffer);
  static final _$getChannel =
      $grpc.ClientMethod<$0.GetChannelRequest, $0.GetChannelResponse>(
          '/raindrop.v1.ChannelService/GetChannel',
          ($0.GetChannelRequest value) => value.writeToBuffer(),
          $0.GetChannelResponse.fromBuffer);
  static final _$createChannel =
      $grpc.ClientMethod<$0.CreateChannelRequest, $0.CreateChannelResponse>(
          '/raindrop.v1.ChannelService/CreateChannel',
          ($0.CreateChannelRequest value) => value.writeToBuffer(),
          $0.CreateChannelResponse.fromBuffer);
  static final _$renameChannel =
      $grpc.ClientMethod<$0.RenameChannelRequest, $0.RenameChannelResponse>(
          '/raindrop.v1.ChannelService/RenameChannel',
          ($0.RenameChannelRequest value) => value.writeToBuffer(),
          $0.RenameChannelResponse.fromBuffer);
  static final _$deleteChannel =
      $grpc.ClientMethod<$0.DeleteChannelRequest, $0.DeleteChannelResponse>(
          '/raindrop.v1.ChannelService/DeleteChannel',
          ($0.DeleteChannelRequest value) => value.writeToBuffer(),
          $0.DeleteChannelResponse.fromBuffer);
}

@$pb.GrpcServiceName('raindrop.v1.ChannelService')
abstract class ChannelServiceBase extends $grpc.Service {
  $core.String get $name => 'raindrop.v1.ChannelService';

  ChannelServiceBase() {
    $addMethod(
        $grpc.ServiceMethod<$0.ListChannelsRequest, $0.ListChannelsResponse>(
            'ListChannels',
            listChannels_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ListChannelsRequest.fromBuffer(value),
            ($0.ListChannelsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetChannelRequest, $0.GetChannelResponse>(
        'GetChannel',
        getChannel_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.GetChannelRequest.fromBuffer(value),
        ($0.GetChannelResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.CreateChannelRequest, $0.CreateChannelResponse>(
            'CreateChannel',
            createChannel_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.CreateChannelRequest.fromBuffer(value),
            ($0.CreateChannelResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.RenameChannelRequest, $0.RenameChannelResponse>(
            'RenameChannel',
            renameChannel_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.RenameChannelRequest.fromBuffer(value),
            ($0.RenameChannelResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.DeleteChannelRequest, $0.DeleteChannelResponse>(
            'DeleteChannel',
            deleteChannel_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.DeleteChannelRequest.fromBuffer(value),
            ($0.DeleteChannelResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.ListChannelsResponse> listChannels_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ListChannelsRequest> $request) async {
    return listChannels($call, await $request);
  }

  $async.Future<$0.ListChannelsResponse> listChannels(
      $grpc.ServiceCall call, $0.ListChannelsRequest request);

  $async.Future<$0.GetChannelResponse> getChannel_Pre($grpc.ServiceCall $call,
      $async.Future<$0.GetChannelRequest> $request) async {
    return getChannel($call, await $request);
  }

  $async.Future<$0.GetChannelResponse> getChannel(
      $grpc.ServiceCall call, $0.GetChannelRequest request);

  $async.Future<$0.CreateChannelResponse> createChannel_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.CreateChannelRequest> $request) async {
    return createChannel($call, await $request);
  }

  $async.Future<$0.CreateChannelResponse> createChannel(
      $grpc.ServiceCall call, $0.CreateChannelRequest request);

  $async.Future<$0.RenameChannelResponse> renameChannel_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.RenameChannelRequest> $request) async {
    return renameChannel($call, await $request);
  }

  $async.Future<$0.RenameChannelResponse> renameChannel(
      $grpc.ServiceCall call, $0.RenameChannelRequest request);

  $async.Future<$0.DeleteChannelResponse> deleteChannel_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.DeleteChannelRequest> $request) async {
    return deleteChannel($call, await $request);
  }

  $async.Future<$0.DeleteChannelResponse> deleteChannel(
      $grpc.ServiceCall call, $0.DeleteChannelRequest request);
}
