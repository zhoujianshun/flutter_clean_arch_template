// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_cache_manager/flutter_cache_manager.dart';
// import 'package:flutter_clean_arch_template/core/cache/app_cache_managers.dart';

// /// 统一的缓存网络图片组件
// ///
// /// 封装 CachedNetworkImage，使用项目的缓存管理器
// class CachedImage extends StatelessWidget {
//   const CachedImage({
//     required this.imageUrl,
//     this.width,
//     this.height,
//     this.fit = BoxFit.cover,
//     this.placeholder,
//     this.errorWidget,
//     this.cacheType = CacheImageType.general,
//     this.fadeInDuration = const Duration(milliseconds: 300),
//     this.headers,
//     super.key,
//   });

//   final String imageUrl;
//   final double? width;
//   final double? height;
//   final BoxFit fit;
//   final Widget? placeholder;
//   final Widget? errorWidget;
//   final CacheImageType cacheType;
//   final Duration fadeInDuration;
//   final Map<String, String>? headers;

//   CacheManager get _cacheManager {
//     switch (cacheType) {
//       case CacheImageType.avatar:
//         return AppCacheManagers.avatar;
//       case CacheImageType.service:
//         return AppCacheManagers.service;
//       case CacheImageType.document:
//         return AppCacheManagers.document;
//       case CacheImageType.general:
//         return AppCacheManagers.general;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return CachedNetworkImage(
//       imageUrl: imageUrl,
//       width: width,
//       height: height,
//       fit: fit,
//       cacheManager: _cacheManager,
//       fadeInDuration: fadeInDuration,
//       httpHeaders: headers,
//       placeholder: placeholder != null
//           ? (context, url) => placeholder!
//           : (context, url) => Center(
//               child: CircularProgressIndicator(
//                 strokeWidth: 2,
//                 color: Theme.of(context).primaryColor,
//               ),
//             ),
//       errorWidget: errorWidget != null
//           ? (context, url, error) => errorWidget!
//           : (context, url, error) => Icon(
//               Icons.error_outline,
//               color: Theme.of(context).colorScheme.error,
//             ),
//     );
//   }
// }

// /// 缓存图片类型
// enum CacheImageType {
//   /// 用户头像
//   avatar,

//   /// 服务相关图片
//   service,

//   /// 文档图片
//   document,

//   /// 通用图片
//   general,
// }
