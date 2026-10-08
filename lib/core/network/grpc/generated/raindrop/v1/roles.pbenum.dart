// This is a generated file - do not edit.
//
// Generated from raindrop/v1/roles.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// What kind of role it is. The two built-in kinds cannot be deleted.
class RoleKind extends $pb.ProtobufEnum {
  static const RoleKind ROLE_KIND_UNSPECIFIED =
      RoleKind._(0, _omitEnumNames ? '' : 'ROLE_KIND_UNSPECIFIED');
  static const RoleKind ROLE_KIND_CUSTOM =
      RoleKind._(1, _omitEnumNames ? '' : 'ROLE_KIND_CUSTOM');

  /// Every active member holds it; it is never assigned.
  static const RoleKind ROLE_KIND_EVERYONE =
      RoleKind._(2, _omitEnumNames ? '' : 'ROLE_KIND_EVERYONE');

  /// Holds administrator; neither editable nor deletable.
  static const RoleKind ROLE_KIND_OWNER =
      RoleKind._(3, _omitEnumNames ? '' : 'ROLE_KIND_OWNER');

  static const $core.List<RoleKind> values = <RoleKind>[
    ROLE_KIND_UNSPECIFIED,
    ROLE_KIND_CUSTOM,
    ROLE_KIND_EVERYONE,
    ROLE_KIND_OWNER,
  ];

  static final $core.List<RoleKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static RoleKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const RoleKind._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
