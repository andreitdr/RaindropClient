import 'package:flutter/material.dart';

/// A flat, solid chrome surface — the server rail, channel sidebar, and
/// member list all wrap their content in one of these instead of a bare
/// [Container]. Wrapping the child in a transparent [Material] gives any
/// [ListTile]/[InkWell] inside a nearby ink surface to paint onto, which a
/// plain [Container] with a background color doesn't provide.
class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    required this.color,
    this.borderRadius = BorderRadius.zero,
    this.padding,
  });

  final Widget child;
  final Color color;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(color: color, borderRadius: borderRadius),
      child: Material(type: MaterialType.transparency, child: child),
    );
  }
}
