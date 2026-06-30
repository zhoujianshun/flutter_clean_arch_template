import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/shared/utils/responsive_utils.dart';

/// 内容宽度约束组件
///
/// 在大屏设备（平板、桌面）上限制子组件的最大宽度并居中显示。
/// 在手机上（宽度 < [maxWidth]）无视觉影响，子组件正常铺满。
///
/// 使用场景：
/// - 表单页面（登录、注册等）在平板上居中显示
/// - 详情页面在大屏上限制阅读宽度
/// - 设置/Profile 等列表页面在大屏上避免过度拉伸
///
/// ```dart
/// // 登录页 —— 使用语义化常量
/// ContentConstraint(
///   maxWidth: ResponsiveUtils.maxWidthForm,    // 480dp
///   child: LoginForm(),
/// )
///
/// // 详情页 —— 限制最大阅读宽度
/// ContentConstraint(
///   maxWidth: ResponsiveUtils.maxWidthDetail,  // 680dp
///   child: ArticleContent(),
/// )
/// ```
class ContentConstraint extends StatelessWidget {
  const ContentConstraint({
    required this.child,
    super.key,
    this.maxWidth = 600,
    this.alignment = Alignment.topCenter,
    this.padding,
  });

  /// 子组件
  final Widget child;

  /// 最大宽度限制（逻辑像素），默认 [ResponsiveUtils.maxWidthList]（600dp）
  ///
  /// 推荐使用 [ResponsiveUtils] 中的语义化常量：
  /// - [ResponsiveUtils.maxWidthFormNarrow]：420dp，窄表单（登录表单右侧）
  /// - [ResponsiveUtils.maxWidthForm]：480dp，标准表单（登录、注册页）
  /// - [ResponsiveUtils.maxWidthList]：600dp，列表/设置页
  /// - [ResponsiveUtils.maxWidthDetail]：680dp，详情/文章页
  final double maxWidth;

  /// 对齐方式，默认顶部居中
  final Alignment alignment;

  /// 可选的外边距
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    Widget result = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    );

    if (padding != null) {
      result = Padding(padding: padding!, child: result);
    }

    return Align(alignment: alignment, child: result);
  }
}
