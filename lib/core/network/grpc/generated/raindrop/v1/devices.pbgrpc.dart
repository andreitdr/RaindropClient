// This is a generated file - do not edit.
//
// Generated from raindrop/v1/devices.proto.

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

import 'devices.pb.dart' as $0;

export 'devices.pb.dart';

/// End-to-end encryption's identity layer: devices, session binding, key backup and device linking.
/// The server holds public keys and opaque blobs only; every bytes field here is produced and checked
/// by the clients' Rust core (see RaindropCrypto/docs/wire-contracts.md).
@$pb.GrpcServiceName('raindrop.v1.DeviceService')
class DeviceServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  DeviceServiceClient(super.channel, {super.options, super.interceptors});

  /// Register a device from its certificate. The first one sets the user's identity key.
  $grpc.ResponseFuture<$0.RegisterDeviceResponse> registerDevice(
    $0.RegisterDeviceRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$registerDevice, request, options: options);
  }

  /// Identity keys and active devices of up to 500 users.
  $grpc.ResponseFuture<$0.ListDevicesResponse> listDevices(
    $0.ListDevicesRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listDevices, request, options: options);
  }

  /// Revoke one of your devices: needs a bound session, unless it is this one.
  $grpc.ResponseFuture<$0.RevokeDeviceResponse> revokeDevice(
    $0.RevokeDeviceRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$revokeDevice, request, options: options);
  }

  /// With the password: forget the identity key and backup, and revoke every device.
  $grpc.ResponseFuture<$0.ResetIdentityResponse> resetIdentity(
    $0.ResetIdentityRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$resetIdentity, request, options: options);
  }

  /// A one-time nonce for a device key to sign.
  $grpc.ResponseFuture<$0.CreateSessionChallengeResponse>
      createSessionChallenge(
    $0.CreateSessionChallengeRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$createSessionChallenge, request,
        options: options);
  }

  /// Bind this session to a device with that signature.
  $grpc.ResponseFuture<$0.BindSessionResponse> bindSession(
    $0.BindSessionRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$bindSession, request, options: options);
  }

  /// The sealed key backup.
  $grpc.ResponseFuture<$0.GetKeyBackupResponse> getKeyBackup(
    $0.GetKeyBackupRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getKeyBackup, request, options: options);
  }

  /// Replace the backup: needs a bound session.
  $grpc.ResponseFuture<$0.PutKeyBackupResponse> putKeyBackup(
    $0.PutKeyBackupRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$putKeyBackup, request, options: options);
  }

  /// A new device posts its link offer and gets the id its link code shows.
  $grpc.ResponseFuture<$0.StartDeviceLinkResponse> startDeviceLink(
    $0.StartDeviceLinkRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$startDeviceLink, request, options: options);
  }

  /// An existing device fetches the offer, to check it against the link code.
  $grpc.ResponseFuture<$0.GetDeviceLinkOfferResponse> getDeviceLinkOffer(
    $0.GetDeviceLinkOfferRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getDeviceLinkOffer, request, options: options);
  }

  /// An existing device posts its encrypted approval: needs a bound session.
  $grpc.ResponseFuture<$0.ApproveDeviceLinkResponse> approveDeviceLink(
    $0.ApproveDeviceLinkRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$approveDeviceLink, request, options: options);
  }

  /// The new device collects the approval once it is there.
  $grpc.ResponseFuture<$0.TakeDeviceLinkApprovalResponse>
      takeDeviceLinkApproval(
    $0.TakeDeviceLinkApprovalRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$takeDeviceLinkApproval, request,
        options: options);
  }

  /// Replace the caller's identity vault and sealed root: needs a bound session.
  $grpc.ResponseFuture<$0.PutIdentityVaultResponse> putIdentityVault(
    $0.PutIdentityVaultRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$putIdentityVault, request, options: options);
  }

  /// The caller's identity vault and sealed root: needs a bound session.
  $grpc.ResponseFuture<$0.GetIdentityVaultResponse> getIdentityVault(
    $0.GetIdentityVaultRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getIdentityVault, request, options: options);
  }

  /// The sealed root stored under a recovery lookup id, for a device that has only the recovery
  /// words. Anonymous.
  $grpc.ResponseFuture<$0.GetSealedRootResponse> getSealedRoot(
    $0.GetSealedRootRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getSealedRoot, request, options: options);
  }

  /// Set or replace the account's authenticator: needs a bound session, so any device still paired
  /// can replace a lost one.
  $grpc.ResponseFuture<$0.EnrollAuthenticatorResponse> enrollAuthenticator(
    $0.EnrollAuthenticatorRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$enrollAuthenticator, request, options: options);
  }

  /// Remove the account's authenticator: needs a bound session.
  $grpc.ResponseFuture<$0.DisableAuthenticatorResponse> disableAuthenticator(
    $0.DisableAuthenticatorRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$disableAuthenticator, request, options: options);
  }

  /// Whether the account has an authenticator, and how many backup codes are left.
  $grpc.ResponseFuture<$0.GetAuthenticatorStatusResponse>
      getAuthenticatorStatus(
    $0.GetAuthenticatorStatusRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getAuthenticatorStatus, request,
        options: options);
  }

  /// A device with no account anywhere posts its pairing offer. Anonymous.
  $grpc.ResponseFuture<$0.StartPairingResponse> startPairing(
    $0.StartPairingRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$startPairing, request, options: options);
  }

  /// A paired device fetches the offer, to check it against the pairing code: needs a bound session.
  $grpc.ResponseFuture<$0.GetPairingOfferResponse> getPairingOffer(
    $0.GetPairingOfferRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getPairingOffer, request, options: options);
  }

  /// A paired device posts its sealed approval: needs a bound session.
  $grpc.ResponseFuture<$0.ApprovePairingResponse> approvePairing(
    $0.ApprovePairingRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$approvePairing, request, options: options);
  }

  /// The new device collects the approval, once. Anonymous; needs the token StartPairing returned.
  $grpc.ResponseFuture<$0.TakePairingApprovalResponse> takePairingApproval(
    $0.TakePairingApprovalRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$takePairingApproval, request, options: options);
  }

  // method descriptors

  static final _$registerDevice =
      $grpc.ClientMethod<$0.RegisterDeviceRequest, $0.RegisterDeviceResponse>(
          '/raindrop.v1.DeviceService/RegisterDevice',
          ($0.RegisterDeviceRequest value) => value.writeToBuffer(),
          $0.RegisterDeviceResponse.fromBuffer);
  static final _$listDevices =
      $grpc.ClientMethod<$0.ListDevicesRequest, $0.ListDevicesResponse>(
          '/raindrop.v1.DeviceService/ListDevices',
          ($0.ListDevicesRequest value) => value.writeToBuffer(),
          $0.ListDevicesResponse.fromBuffer);
  static final _$revokeDevice =
      $grpc.ClientMethod<$0.RevokeDeviceRequest, $0.RevokeDeviceResponse>(
          '/raindrop.v1.DeviceService/RevokeDevice',
          ($0.RevokeDeviceRequest value) => value.writeToBuffer(),
          $0.RevokeDeviceResponse.fromBuffer);
  static final _$resetIdentity =
      $grpc.ClientMethod<$0.ResetIdentityRequest, $0.ResetIdentityResponse>(
          '/raindrop.v1.DeviceService/ResetIdentity',
          ($0.ResetIdentityRequest value) => value.writeToBuffer(),
          $0.ResetIdentityResponse.fromBuffer);
  static final _$createSessionChallenge = $grpc.ClientMethod<
          $0.CreateSessionChallengeRequest, $0.CreateSessionChallengeResponse>(
      '/raindrop.v1.DeviceService/CreateSessionChallenge',
      ($0.CreateSessionChallengeRequest value) => value.writeToBuffer(),
      $0.CreateSessionChallengeResponse.fromBuffer);
  static final _$bindSession =
      $grpc.ClientMethod<$0.BindSessionRequest, $0.BindSessionResponse>(
          '/raindrop.v1.DeviceService/BindSession',
          ($0.BindSessionRequest value) => value.writeToBuffer(),
          $0.BindSessionResponse.fromBuffer);
  static final _$getKeyBackup =
      $grpc.ClientMethod<$0.GetKeyBackupRequest, $0.GetKeyBackupResponse>(
          '/raindrop.v1.DeviceService/GetKeyBackup',
          ($0.GetKeyBackupRequest value) => value.writeToBuffer(),
          $0.GetKeyBackupResponse.fromBuffer);
  static final _$putKeyBackup =
      $grpc.ClientMethod<$0.PutKeyBackupRequest, $0.PutKeyBackupResponse>(
          '/raindrop.v1.DeviceService/PutKeyBackup',
          ($0.PutKeyBackupRequest value) => value.writeToBuffer(),
          $0.PutKeyBackupResponse.fromBuffer);
  static final _$startDeviceLink =
      $grpc.ClientMethod<$0.StartDeviceLinkRequest, $0.StartDeviceLinkResponse>(
          '/raindrop.v1.DeviceService/StartDeviceLink',
          ($0.StartDeviceLinkRequest value) => value.writeToBuffer(),
          $0.StartDeviceLinkResponse.fromBuffer);
  static final _$getDeviceLinkOffer = $grpc.ClientMethod<
          $0.GetDeviceLinkOfferRequest, $0.GetDeviceLinkOfferResponse>(
      '/raindrop.v1.DeviceService/GetDeviceLinkOffer',
      ($0.GetDeviceLinkOfferRequest value) => value.writeToBuffer(),
      $0.GetDeviceLinkOfferResponse.fromBuffer);
  static final _$approveDeviceLink = $grpc.ClientMethod<
          $0.ApproveDeviceLinkRequest, $0.ApproveDeviceLinkResponse>(
      '/raindrop.v1.DeviceService/ApproveDeviceLink',
      ($0.ApproveDeviceLinkRequest value) => value.writeToBuffer(),
      $0.ApproveDeviceLinkResponse.fromBuffer);
  static final _$takeDeviceLinkApproval = $grpc.ClientMethod<
          $0.TakeDeviceLinkApprovalRequest, $0.TakeDeviceLinkApprovalResponse>(
      '/raindrop.v1.DeviceService/TakeDeviceLinkApproval',
      ($0.TakeDeviceLinkApprovalRequest value) => value.writeToBuffer(),
      $0.TakeDeviceLinkApprovalResponse.fromBuffer);
  static final _$putIdentityVault = $grpc.ClientMethod<
          $0.PutIdentityVaultRequest, $0.PutIdentityVaultResponse>(
      '/raindrop.v1.DeviceService/PutIdentityVault',
      ($0.PutIdentityVaultRequest value) => value.writeToBuffer(),
      $0.PutIdentityVaultResponse.fromBuffer);
  static final _$getIdentityVault = $grpc.ClientMethod<
          $0.GetIdentityVaultRequest, $0.GetIdentityVaultResponse>(
      '/raindrop.v1.DeviceService/GetIdentityVault',
      ($0.GetIdentityVaultRequest value) => value.writeToBuffer(),
      $0.GetIdentityVaultResponse.fromBuffer);
  static final _$getSealedRoot =
      $grpc.ClientMethod<$0.GetSealedRootRequest, $0.GetSealedRootResponse>(
          '/raindrop.v1.DeviceService/GetSealedRoot',
          ($0.GetSealedRootRequest value) => value.writeToBuffer(),
          $0.GetSealedRootResponse.fromBuffer);
  static final _$enrollAuthenticator = $grpc.ClientMethod<
          $0.EnrollAuthenticatorRequest, $0.EnrollAuthenticatorResponse>(
      '/raindrop.v1.DeviceService/EnrollAuthenticator',
      ($0.EnrollAuthenticatorRequest value) => value.writeToBuffer(),
      $0.EnrollAuthenticatorResponse.fromBuffer);
  static final _$disableAuthenticator = $grpc.ClientMethod<
          $0.DisableAuthenticatorRequest, $0.DisableAuthenticatorResponse>(
      '/raindrop.v1.DeviceService/DisableAuthenticator',
      ($0.DisableAuthenticatorRequest value) => value.writeToBuffer(),
      $0.DisableAuthenticatorResponse.fromBuffer);
  static final _$getAuthenticatorStatus = $grpc.ClientMethod<
          $0.GetAuthenticatorStatusRequest, $0.GetAuthenticatorStatusResponse>(
      '/raindrop.v1.DeviceService/GetAuthenticatorStatus',
      ($0.GetAuthenticatorStatusRequest value) => value.writeToBuffer(),
      $0.GetAuthenticatorStatusResponse.fromBuffer);
  static final _$startPairing =
      $grpc.ClientMethod<$0.StartPairingRequest, $0.StartPairingResponse>(
          '/raindrop.v1.DeviceService/StartPairing',
          ($0.StartPairingRequest value) => value.writeToBuffer(),
          $0.StartPairingResponse.fromBuffer);
  static final _$getPairingOffer =
      $grpc.ClientMethod<$0.GetPairingOfferRequest, $0.GetPairingOfferResponse>(
          '/raindrop.v1.DeviceService/GetPairingOffer',
          ($0.GetPairingOfferRequest value) => value.writeToBuffer(),
          $0.GetPairingOfferResponse.fromBuffer);
  static final _$approvePairing =
      $grpc.ClientMethod<$0.ApprovePairingRequest, $0.ApprovePairingResponse>(
          '/raindrop.v1.DeviceService/ApprovePairing',
          ($0.ApprovePairingRequest value) => value.writeToBuffer(),
          $0.ApprovePairingResponse.fromBuffer);
  static final _$takePairingApproval = $grpc.ClientMethod<
          $0.TakePairingApprovalRequest, $0.TakePairingApprovalResponse>(
      '/raindrop.v1.DeviceService/TakePairingApproval',
      ($0.TakePairingApprovalRequest value) => value.writeToBuffer(),
      $0.TakePairingApprovalResponse.fromBuffer);
}

@$pb.GrpcServiceName('raindrop.v1.DeviceService')
abstract class DeviceServiceBase extends $grpc.Service {
  $core.String get $name => 'raindrop.v1.DeviceService';

  DeviceServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.RegisterDeviceRequest,
            $0.RegisterDeviceResponse>(
        'RegisterDevice',
        registerDevice_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.RegisterDeviceRequest.fromBuffer(value),
        ($0.RegisterDeviceResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.ListDevicesRequest, $0.ListDevicesResponse>(
            'ListDevices',
            listDevices_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ListDevicesRequest.fromBuffer(value),
            ($0.ListDevicesResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.RevokeDeviceRequest, $0.RevokeDeviceResponse>(
            'RevokeDevice',
            revokeDevice_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.RevokeDeviceRequest.fromBuffer(value),
            ($0.RevokeDeviceResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.ResetIdentityRequest, $0.ResetIdentityResponse>(
            'ResetIdentity',
            resetIdentity_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ResetIdentityRequest.fromBuffer(value),
            ($0.ResetIdentityResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.CreateSessionChallengeRequest,
            $0.CreateSessionChallengeResponse>(
        'CreateSessionChallenge',
        createSessionChallenge_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.CreateSessionChallengeRequest.fromBuffer(value),
        ($0.CreateSessionChallengeResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.BindSessionRequest, $0.BindSessionResponse>(
            'BindSession',
            bindSession_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.BindSessionRequest.fromBuffer(value),
            ($0.BindSessionResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.GetKeyBackupRequest, $0.GetKeyBackupResponse>(
            'GetKeyBackup',
            getKeyBackup_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.GetKeyBackupRequest.fromBuffer(value),
            ($0.GetKeyBackupResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.PutKeyBackupRequest, $0.PutKeyBackupResponse>(
            'PutKeyBackup',
            putKeyBackup_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.PutKeyBackupRequest.fromBuffer(value),
            ($0.PutKeyBackupResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.StartDeviceLinkRequest,
            $0.StartDeviceLinkResponse>(
        'StartDeviceLink',
        startDeviceLink_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.StartDeviceLinkRequest.fromBuffer(value),
        ($0.StartDeviceLinkResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetDeviceLinkOfferRequest,
            $0.GetDeviceLinkOfferResponse>(
        'GetDeviceLinkOffer',
        getDeviceLinkOffer_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.GetDeviceLinkOfferRequest.fromBuffer(value),
        ($0.GetDeviceLinkOfferResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ApproveDeviceLinkRequest,
            $0.ApproveDeviceLinkResponse>(
        'ApproveDeviceLink',
        approveDeviceLink_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ApproveDeviceLinkRequest.fromBuffer(value),
        ($0.ApproveDeviceLinkResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.TakeDeviceLinkApprovalRequest,
            $0.TakeDeviceLinkApprovalResponse>(
        'TakeDeviceLinkApproval',
        takeDeviceLinkApproval_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.TakeDeviceLinkApprovalRequest.fromBuffer(value),
        ($0.TakeDeviceLinkApprovalResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.PutIdentityVaultRequest,
            $0.PutIdentityVaultResponse>(
        'PutIdentityVault',
        putIdentityVault_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.PutIdentityVaultRequest.fromBuffer(value),
        ($0.PutIdentityVaultResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetIdentityVaultRequest,
            $0.GetIdentityVaultResponse>(
        'GetIdentityVault',
        getIdentityVault_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.GetIdentityVaultRequest.fromBuffer(value),
        ($0.GetIdentityVaultResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.GetSealedRootRequest, $0.GetSealedRootResponse>(
            'GetSealedRoot',
            getSealedRoot_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.GetSealedRootRequest.fromBuffer(value),
            ($0.GetSealedRootResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.EnrollAuthenticatorRequest,
            $0.EnrollAuthenticatorResponse>(
        'EnrollAuthenticator',
        enrollAuthenticator_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.EnrollAuthenticatorRequest.fromBuffer(value),
        ($0.EnrollAuthenticatorResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.DisableAuthenticatorRequest,
            $0.DisableAuthenticatorResponse>(
        'DisableAuthenticator',
        disableAuthenticator_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.DisableAuthenticatorRequest.fromBuffer(value),
        ($0.DisableAuthenticatorResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetAuthenticatorStatusRequest,
            $0.GetAuthenticatorStatusResponse>(
        'GetAuthenticatorStatus',
        getAuthenticatorStatus_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.GetAuthenticatorStatusRequest.fromBuffer(value),
        ($0.GetAuthenticatorStatusResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.StartPairingRequest, $0.StartPairingResponse>(
            'StartPairing',
            startPairing_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.StartPairingRequest.fromBuffer(value),
            ($0.StartPairingResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetPairingOfferRequest,
            $0.GetPairingOfferResponse>(
        'GetPairingOffer',
        getPairingOffer_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.GetPairingOfferRequest.fromBuffer(value),
        ($0.GetPairingOfferResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ApprovePairingRequest,
            $0.ApprovePairingResponse>(
        'ApprovePairing',
        approvePairing_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ApprovePairingRequest.fromBuffer(value),
        ($0.ApprovePairingResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.TakePairingApprovalRequest,
            $0.TakePairingApprovalResponse>(
        'TakePairingApproval',
        takePairingApproval_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.TakePairingApprovalRequest.fromBuffer(value),
        ($0.TakePairingApprovalResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.RegisterDeviceResponse> registerDevice_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.RegisterDeviceRequest> $request) async {
    return registerDevice($call, await $request);
  }

  $async.Future<$0.RegisterDeviceResponse> registerDevice(
      $grpc.ServiceCall call, $0.RegisterDeviceRequest request);

  $async.Future<$0.ListDevicesResponse> listDevices_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ListDevicesRequest> $request) async {
    return listDevices($call, await $request);
  }

  $async.Future<$0.ListDevicesResponse> listDevices(
      $grpc.ServiceCall call, $0.ListDevicesRequest request);

  $async.Future<$0.RevokeDeviceResponse> revokeDevice_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.RevokeDeviceRequest> $request) async {
    return revokeDevice($call, await $request);
  }

  $async.Future<$0.RevokeDeviceResponse> revokeDevice(
      $grpc.ServiceCall call, $0.RevokeDeviceRequest request);

  $async.Future<$0.ResetIdentityResponse> resetIdentity_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ResetIdentityRequest> $request) async {
    return resetIdentity($call, await $request);
  }

  $async.Future<$0.ResetIdentityResponse> resetIdentity(
      $grpc.ServiceCall call, $0.ResetIdentityRequest request);

  $async.Future<$0.CreateSessionChallengeResponse> createSessionChallenge_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.CreateSessionChallengeRequest> $request) async {
    return createSessionChallenge($call, await $request);
  }

  $async.Future<$0.CreateSessionChallengeResponse> createSessionChallenge(
      $grpc.ServiceCall call, $0.CreateSessionChallengeRequest request);

  $async.Future<$0.BindSessionResponse> bindSession_Pre($grpc.ServiceCall $call,
      $async.Future<$0.BindSessionRequest> $request) async {
    return bindSession($call, await $request);
  }

  $async.Future<$0.BindSessionResponse> bindSession(
      $grpc.ServiceCall call, $0.BindSessionRequest request);

  $async.Future<$0.GetKeyBackupResponse> getKeyBackup_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.GetKeyBackupRequest> $request) async {
    return getKeyBackup($call, await $request);
  }

  $async.Future<$0.GetKeyBackupResponse> getKeyBackup(
      $grpc.ServiceCall call, $0.GetKeyBackupRequest request);

  $async.Future<$0.PutKeyBackupResponse> putKeyBackup_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.PutKeyBackupRequest> $request) async {
    return putKeyBackup($call, await $request);
  }

  $async.Future<$0.PutKeyBackupResponse> putKeyBackup(
      $grpc.ServiceCall call, $0.PutKeyBackupRequest request);

  $async.Future<$0.StartDeviceLinkResponse> startDeviceLink_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.StartDeviceLinkRequest> $request) async {
    return startDeviceLink($call, await $request);
  }

  $async.Future<$0.StartDeviceLinkResponse> startDeviceLink(
      $grpc.ServiceCall call, $0.StartDeviceLinkRequest request);

  $async.Future<$0.GetDeviceLinkOfferResponse> getDeviceLinkOffer_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.GetDeviceLinkOfferRequest> $request) async {
    return getDeviceLinkOffer($call, await $request);
  }

  $async.Future<$0.GetDeviceLinkOfferResponse> getDeviceLinkOffer(
      $grpc.ServiceCall call, $0.GetDeviceLinkOfferRequest request);

  $async.Future<$0.ApproveDeviceLinkResponse> approveDeviceLink_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ApproveDeviceLinkRequest> $request) async {
    return approveDeviceLink($call, await $request);
  }

  $async.Future<$0.ApproveDeviceLinkResponse> approveDeviceLink(
      $grpc.ServiceCall call, $0.ApproveDeviceLinkRequest request);

  $async.Future<$0.TakeDeviceLinkApprovalResponse> takeDeviceLinkApproval_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.TakeDeviceLinkApprovalRequest> $request) async {
    return takeDeviceLinkApproval($call, await $request);
  }

  $async.Future<$0.TakeDeviceLinkApprovalResponse> takeDeviceLinkApproval(
      $grpc.ServiceCall call, $0.TakeDeviceLinkApprovalRequest request);

  $async.Future<$0.PutIdentityVaultResponse> putIdentityVault_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.PutIdentityVaultRequest> $request) async {
    return putIdentityVault($call, await $request);
  }

  $async.Future<$0.PutIdentityVaultResponse> putIdentityVault(
      $grpc.ServiceCall call, $0.PutIdentityVaultRequest request);

  $async.Future<$0.GetIdentityVaultResponse> getIdentityVault_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.GetIdentityVaultRequest> $request) async {
    return getIdentityVault($call, await $request);
  }

  $async.Future<$0.GetIdentityVaultResponse> getIdentityVault(
      $grpc.ServiceCall call, $0.GetIdentityVaultRequest request);

  $async.Future<$0.GetSealedRootResponse> getSealedRoot_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.GetSealedRootRequest> $request) async {
    return getSealedRoot($call, await $request);
  }

  $async.Future<$0.GetSealedRootResponse> getSealedRoot(
      $grpc.ServiceCall call, $0.GetSealedRootRequest request);

  $async.Future<$0.EnrollAuthenticatorResponse> enrollAuthenticator_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.EnrollAuthenticatorRequest> $request) async {
    return enrollAuthenticator($call, await $request);
  }

  $async.Future<$0.EnrollAuthenticatorResponse> enrollAuthenticator(
      $grpc.ServiceCall call, $0.EnrollAuthenticatorRequest request);

  $async.Future<$0.DisableAuthenticatorResponse> disableAuthenticator_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.DisableAuthenticatorRequest> $request) async {
    return disableAuthenticator($call, await $request);
  }

  $async.Future<$0.DisableAuthenticatorResponse> disableAuthenticator(
      $grpc.ServiceCall call, $0.DisableAuthenticatorRequest request);

  $async.Future<$0.GetAuthenticatorStatusResponse> getAuthenticatorStatus_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.GetAuthenticatorStatusRequest> $request) async {
    return getAuthenticatorStatus($call, await $request);
  }

  $async.Future<$0.GetAuthenticatorStatusResponse> getAuthenticatorStatus(
      $grpc.ServiceCall call, $0.GetAuthenticatorStatusRequest request);

  $async.Future<$0.StartPairingResponse> startPairing_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.StartPairingRequest> $request) async {
    return startPairing($call, await $request);
  }

  $async.Future<$0.StartPairingResponse> startPairing(
      $grpc.ServiceCall call, $0.StartPairingRequest request);

  $async.Future<$0.GetPairingOfferResponse> getPairingOffer_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.GetPairingOfferRequest> $request) async {
    return getPairingOffer($call, await $request);
  }

  $async.Future<$0.GetPairingOfferResponse> getPairingOffer(
      $grpc.ServiceCall call, $0.GetPairingOfferRequest request);

  $async.Future<$0.ApprovePairingResponse> approvePairing_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ApprovePairingRequest> $request) async {
    return approvePairing($call, await $request);
  }

  $async.Future<$0.ApprovePairingResponse> approvePairing(
      $grpc.ServiceCall call, $0.ApprovePairingRequest request);

  $async.Future<$0.TakePairingApprovalResponse> takePairingApproval_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.TakePairingApprovalRequest> $request) async {
    return takePairingApproval($call, await $request);
  }

  $async.Future<$0.TakePairingApprovalResponse> takePairingApproval(
      $grpc.ServiceCall call, $0.TakePairingApprovalRequest request);
}
