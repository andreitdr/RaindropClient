/// The scalar conversions every API wrapper needs between `raindrop.v1`
/// messages and this app's models: times, bytes, and the closed sets that are
/// enums on the wire but names in the app (`active`, `online`, `owner`, …).
///
/// The app keeps the names on purpose: they are what the UI and the local
/// models were written against, and an enum value this build does not know
/// still becomes a name it can fall back on, rather than an error.
library;

import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart';

import 'protocol.dart' as pb;

abstract final class Wire {
  // ── Times ──────────────────────────────────────────────────────────────

  /// A wire time, as UTC.
  static DateTime time(Timestamp value) => value.toDateTime(toLocal: false);

  /// An optional wire time: null when [present] is false.
  static DateTime? optionalTime(bool present, Timestamp value) =>
      present ? time(value) : null;

  // ── Numbers and bytes ──────────────────────────────────────────────────

  static Int64 int64(int value) => Int64(value);

  static Uint8List bytes(List<int> value) => Uint8List.fromList(value);

  static Uint8List? optionalBytes(bool present, List<int> value) =>
      present ? Uint8List.fromList(value) : null;

  // ── Closed sets ────────────────────────────────────────────────────────

  /// `unregistered`, `active`, `left_preserved`, `erased`; `unknown` for a
  /// value newer than this build.
  static String userState(pb.UserState state) => switch (state) {
    pb.UserState.USER_STATE_UNREGISTERED => 'unregistered',
    pb.UserState.USER_STATE_ACTIVE => 'active',
    pb.UserState.USER_STATE_LEFT_PRESERVED => 'left_preserved',
    pb.UserState.USER_STATE_ERASED => 'erased',
    _ => 'unknown',
  };

  /// `online` or `offline` — and, for a value newer than this build,
  /// `unknown`, which the roster files under offline.
  static String presence(pb.Presence presence) => switch (presence) {
    pb.Presence.PRESENCE_ONLINE => 'online',
    pb.Presence.PRESENCE_OFFLINE => 'offline',
    _ => 'unknown',
  };

  /// `custom`, `everyone` or `owner`.
  static String roleKind(pb.RoleKind kind) => switch (kind) {
    pb.RoleKind.ROLE_KIND_EVERYONE => 'everyone',
    pb.RoleKind.ROLE_KIND_OWNER => 'owner',
    _ => 'custom',
  };

  /// `file` or `thumbnail`.
  static String attachmentKind(pb.AttachmentKind kind) => switch (kind) {
    pb.AttachmentKind.ATTACHMENT_KIND_THUMBNAIL => 'thumbnail',
    _ => 'file',
  };

  static pb.AttachmentKind attachmentKindOf(String kind) => switch (kind) {
    'thumbnail' => pb.AttachmentKind.ATTACHMENT_KIND_THUMBNAIL,
    _ => pb.AttachmentKind.ATTACHMENT_KIND_FILE,
  };

  /// `screen` or `window` — or null for none, which is what a participant who
  /// is not sharing carries, and what a value newer than this build reads as.
  static String? screenShareKind(pb.ScreenShareKind kind) => switch (kind) {
    pb.ScreenShareKind.SCREEN_SHARE_KIND_SCREEN => 'screen',
    pb.ScreenShareKind.SCREEN_SHARE_KIND_WINDOW => 'window',
    _ => null,
  };

  static pb.ScreenShareKind screenShareKindOf(String? kind) => switch (kind) {
    'screen' => pb.ScreenShareKind.SCREEN_SHARE_KIND_SCREEN,
    'window' => pb.ScreenShareKind.SCREEN_SHARE_KIND_WINDOW,
    _ => pb.ScreenShareKind.SCREEN_SHARE_KIND_UNSPECIFIED,
  };

  /// `uploading`, `uploaded` or `attached`.
  static String uploadState(pb.UploadState state) => switch (state) {
    pb.UploadState.UPLOAD_STATE_UPLOADING => 'uploading',
    pb.UploadState.UPLOAD_STATE_UPLOADED => 'uploaded',
    pb.UploadState.UPLOAD_STATE_ATTACHED => 'attached',
    _ => 'unknown',
  };
}
