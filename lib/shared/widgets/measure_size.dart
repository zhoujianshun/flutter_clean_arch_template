import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// 用于测量子组件尺寸的 Widget
///
/// 使用示例：
/// ```dart
/// MeasureSize(
///   onChange: (Size size) {
///     print('组件尺寸: $size');
///   },
///   child: YourWidget(),
/// )
/// ```
class MeasureSize extends SingleChildRenderObjectWidget {
  const MeasureSize({
    required this.onChange,
    super.key,
    super.child,
  });

  /// 尺寸变化时的回调
  final ValueChanged<Size> onChange;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _MeasureSizeRenderObject(onChange);
  }

  @override
  void updateRenderObject(BuildContext context, covariant _MeasureSizeRenderObject renderObject) {
    renderObject.onChange = onChange;
  }
}

class _MeasureSizeRenderObject extends RenderProxyBox {
  _MeasureSizeRenderObject(this.onChange);

  ValueChanged<Size> onChange;
  Size? _oldSize;

  @override
  void performLayout() {
    super.performLayout();

    // 检查尺寸是否发生变化
    if (_oldSize != size) {
      _oldSize = size;
      // 在下一帧回调，避免在 layout 期间触发 setState
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onChange(size);
      });
    }
  }
}
