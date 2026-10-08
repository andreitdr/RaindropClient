// This is a generated file - do not edit.
//
// Generated from raindrop/v1/users.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// Where a UUID stands on this server.
class UserState extends $pb.ProtobufEnum {
  static const UserState USER_STATE_UNSPECIFIED =
      UserState._(0, _omitEnumNames ? '' : 'USER_STATE_UNSPECIFIED');

  /// Never registered here.
  static const UserState USER_STATE_UNREGISTERED =
      UserState._(1, _omitEnumNames ? '' : 'USER_STATE_UNREGISTERED');
  static const UserState USER_STATE_ACTIVE =
      UserState._(2, _omitEnumNames ? '' : 'USER_STATE_ACTIVE');

  /// Left, keeping username and password until the retention window closes.
  static const UserState USER_STATE_LEFT_PRESERVED =
      UserState._(3, _omitEnumNames ? '' : 'USER_STATE_LEFT_PRESERVED');

  /// Left and erased; the UUID may register again from scratch.
  static const UserState USER_STATE_ERASED =
      UserState._(4, _omitEnumNames ? '' : 'USER_STATE_ERASED');

  static const $core.List<UserState> values = <UserState>[
    USER_STATE_UNSPECIFIED,
    USER_STATE_UNREGISTERED,
    USER_STATE_ACTIVE,
    USER_STATE_LEFT_PRESERVED,
    USER_STATE_ERASED,
  ];

  static final $core.List<UserState?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static UserState? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const UserState._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
