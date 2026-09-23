import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Makes a live pane inert inside the layout editor — clicks, scrolls and
/// hovers stop here — except over a [LayoutHitThrough], which is how the
/// slots inside the pane stay draggable while the channel list around them
/// cannot be clicked into.
///
/// An `IgnorePointer` cannot do this: nothing below it can opt back in.
class LayoutEditBarrier extends SingleChildRenderObjectWidget {
  const LayoutEditBarrier({super.key, super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderEditBarrier();
}

class _RenderEditBarrier extends RenderProxyBox {
  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!size.contains(position)) return false;
    // Look first, on a scratch result: only a pointer over a slot is let
    // through, and then by a real hit test so every entry's transform is
    // the right one.
    final probe = BoxHitTestResult();
    hitTestChildren(probe, position: position);
    if (probe.path.any((entry) => entry.target is _RenderHitThrough)) {
      return super.hitTest(result, position: position);
    }
    result.add(BoxHitTestEntry(this, position));
    return true;
  }
}

/// A region a [LayoutEditBarrier] above it lets pointer events reach.
class LayoutHitThrough extends SingleChildRenderObjectWidget {
  const LayoutHitThrough({super.key, super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderHitThrough();
}

class _RenderHitThrough extends RenderProxyBox {
  // Hit over its whole area, gaps between chips included: a drop target
  // there adds itself without claiming the hit, and would otherwise leave
  // nothing for the barrier to find.
  @override
  bool hitTestSelf(Offset position) => true;
}
