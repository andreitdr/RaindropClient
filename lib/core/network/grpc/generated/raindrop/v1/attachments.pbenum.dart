// This is a generated file - do not edit.
//
// Generated from raindrop/v1/attachments.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// What an attachment is to the message that carries it.
class AttachmentKind extends $pb.ProtobufEnum {
  static const AttachmentKind ATTACHMENT_KIND_UNSPECIFIED =
      AttachmentKind._(0, _omitEnumNames ? '' : 'ATTACHMENT_KIND_UNSPECIFIED');

  /// A file the message shows. The default when creating an upload.
  static const AttachmentKind ATTACHMENT_KIND_FILE =
      AttachmentKind._(1, _omitEnumNames ? '' : 'ATTACHMENT_KIND_FILE');

  /// A sender-made preview of another file in the same message.
  static const AttachmentKind ATTACHMENT_KIND_THUMBNAIL =
      AttachmentKind._(2, _omitEnumNames ? '' : 'ATTACHMENT_KIND_THUMBNAIL');

  static const $core.List<AttachmentKind> values = <AttachmentKind>[
    ATTACHMENT_KIND_UNSPECIFIED,
    ATTACHMENT_KIND_FILE,
    ATTACHMENT_KIND_THUMBNAIL,
  ];

  static final $core.List<AttachmentKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static AttachmentKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const AttachmentKind._(super.value, super.name);
}

/// Where an upload stands.
class UploadState extends $pb.ProtobufEnum {
  static const UploadState UPLOAD_STATE_UNSPECIFIED =
      UploadState._(0, _omitEnumNames ? '' : 'UPLOAD_STATE_UNSPECIFIED');
  static const UploadState UPLOAD_STATE_UPLOADING =
      UploadState._(1, _omitEnumNames ? '' : 'UPLOAD_STATE_UPLOADING');

  /// Complete and checked; waiting to be sent in a message.
  static const UploadState UPLOAD_STATE_UPLOADED =
      UploadState._(2, _omitEnumNames ? '' : 'UPLOAD_STATE_UPLOADED');

  /// Sent in a message.
  static const UploadState UPLOAD_STATE_ATTACHED =
      UploadState._(3, _omitEnumNames ? '' : 'UPLOAD_STATE_ATTACHED');

  static const $core.List<UploadState> values = <UploadState>[
    UPLOAD_STATE_UNSPECIFIED,
    UPLOAD_STATE_UPLOADING,
    UPLOAD_STATE_UPLOADED,
    UPLOAD_STATE_ATTACHED,
  ];

  static final $core.List<UploadState?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static UploadState? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const UploadState._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
