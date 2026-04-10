import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_clean_arch_template/core/theme/app_theme.dart';

/// 封装的cached_network_image
class MyCachedNetworkImage extends StatelessWidget {
  const MyCachedNetworkImage({
    required this.imageUrl,
    super.key,
    this.placeholder,
    this.errorWidget,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    // this.progressIndicatorBuilder,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;

  /// Widget displayed while the target [imageUrl] is loading.
  final PlaceholderWidgetBuilder? placeholder;

  // /// Widget displayed while the target [imageUrl] is loading.
  // final ProgressIndicatorBuilder? progressIndicatorBuilder;

  /// Widget displayed while the target [imageUrl] failed loading.
  final LoadingErrorWidgetBuilder? errorWidget;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      // progressIndicatorBuilder: progressIndicatorBuilder ?? _buildDefaultloading,
      placeholder: placeholder ?? _buildDefaultPlaceholder,
      errorWidget: errorWidget ?? _buildDefaultError,
    );
  }

  /// 默认的加载中组件
  // Widget _buildDefaultloading(
  //   BuildContext context,
  //   String url,
  //   DownloadProgress loadingProgress,
  // ) {
  //   return ColoredBox(
  //     color: AppAdaptiveColors.neutral200(context),
  //     child: Center(
  //       child: CircularProgressIndicator(
  //         value: loadingProgress.progress,
  //         strokeWidth: 2.w,
  //       ),
  //     ),
  //   );
  // }

  /// 默认的错误组件
  Widget _buildDefaultError(BuildContext context, String url, Object error) {
    return Container(color: AppAdaptiveColors.neutral200(context));
  }

  /// 默认的占位组件
  Widget _buildDefaultPlaceholder(BuildContext context, String url) {
    return Container(color: AppAdaptiveColors.neutral200(context));
  }
}
