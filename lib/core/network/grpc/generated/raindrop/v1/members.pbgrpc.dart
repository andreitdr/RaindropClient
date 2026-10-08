// This is a generated file - do not edit.
//
// Generated from raindrop/v1/members.proto.

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

import 'members.pb.dart' as $0;

export 'members.pb.dart';

/// The roster: who is on this server and whether each of them is around. A member is an active user.
@$pb.GrpcServiceName('raindrop.v1.MemberService')
class MemberServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  MemberServiceClient(super.channel, {super.options, super.interceptors});

  /// Every active member, ordered by presence and then by username.
  $grpc.ResponseFuture<$0.ListMembersResponse> listMembers(
    $0.ListMembersRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listMembers, request, options: options);
  }

  // method descriptors

  static final _$listMembers =
      $grpc.ClientMethod<$0.ListMembersRequest, $0.ListMembersResponse>(
          '/raindrop.v1.MemberService/ListMembers',
          ($0.ListMembersRequest value) => value.writeToBuffer(),
          $0.ListMembersResponse.fromBuffer);
}

@$pb.GrpcServiceName('raindrop.v1.MemberService')
abstract class MemberServiceBase extends $grpc.Service {
  $core.String get $name => 'raindrop.v1.MemberService';

  MemberServiceBase() {
    $addMethod(
        $grpc.ServiceMethod<$0.ListMembersRequest, $0.ListMembersResponse>(
            'ListMembers',
            listMembers_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ListMembersRequest.fromBuffer(value),
            ($0.ListMembersResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.ListMembersResponse> listMembers_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ListMembersRequest> $request) async {
    return listMembers($call, await $request);
  }

  $async.Future<$0.ListMembersResponse> listMembers(
      $grpc.ServiceCall call, $0.ListMembersRequest request);
}
