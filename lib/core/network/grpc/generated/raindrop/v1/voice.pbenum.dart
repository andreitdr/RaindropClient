// This is a generated file - do not edit.
//
// Generated from raindrop/v1/voice.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// What a screen share shows. A closed set: there is nothing else a share can be.
class ScreenShareKind extends $pb.ProtobufEnum {
  static const ScreenShareKind SCREEN_SHARE_KIND_UNSPECIFIED =
      ScreenShareKind._(
          0, _omitEnumNames ? '' : 'SCREEN_SHARE_KIND_UNSPECIFIED');

  /// A whole display. Never carries sound: the host's sound is never sent.
  static const ScreenShareKind SCREEN_SHARE_KIND_SCREEN =
      ScreenShareKind._(1, _omitEnumNames ? '' : 'SCREEN_SHARE_KIND_SCREEN');

  /// One window, optionally with that window's own sound.
  static const ScreenShareKind SCREEN_SHARE_KIND_WINDOW =
      ScreenShareKind._(2, _omitEnumNames ? '' : 'SCREEN_SHARE_KIND_WINDOW');

  static const $core.List<ScreenShareKind> values = <ScreenShareKind>[
    SCREEN_SHARE_KIND_UNSPECIFIED,
    SCREEN_SHARE_KIND_SCREEN,
    SCREEN_SHARE_KIND_WINDOW,
  ];

  static final $core.List<ScreenShareKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static ScreenShareKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ScreenShareKind._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
