import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_clean_arch_template/shared/widgets/pop/my_cupertino_alert_dialog.dart';
// 状态	含义	处理方式
// granted	已授权	✅ 直接使用
// denied	拒绝/首次	🔄 尝试请求
// limited	限制访问 (iOS 14+)	✅ 可以使用
// provisional	临时权限	✅ 可以使用
// restricted	设备限制	❌ 无法使用
// permanentlyDenied	永久拒绝	❌ 引导设置

/// 权限管理器
///
/// 统一管理应用的权限请求和检查
class PermissionUtil {
  /// 统一的权限请求方法
  ///
  /// 合并了 Android 和 iOS 的权限处理逻辑
  static Future<bool> _requestPermission(
    BuildContext context, {
    required Permission permission,
    required String permissionName,
    required String deniedMessage,
    required String restrictedMessage,
  }) async {
    try {
      final status = await permission.status;
      debugPrint('$permissionName 权限当前状态: $status');

      // 统一的权限状态处理逻辑 (适用于 Android 和 iOS)
      switch (status) {
        case PermissionStatus.granted:
          debugPrint('$permissionName 权限已授权');
          return true;

        case PermissionStatus.limited:
          // iOS 14+ 限制访问，但仍然可以使用
          debugPrint('$permissionName 权限受限但可用');
          return true;

        case PermissionStatus.provisional:
          // iOS 临时权限，可以使用
          debugPrint('$permissionName 权限临时授权');
          return true;

        case PermissionStatus.denied:
          // 首次访问或用户之前拒绝，尝试请求
          debugPrint('$permissionName 权限被拒绝，尝试请求...');
          final result = await permission.request();
          debugPrint('$permissionName 权限请求结果: $result');

          // 检查请求结果
          if (result.isGranted || result == PermissionStatus.limited || result == PermissionStatus.provisional) {
            return true;
          } else if (result.isPermanentlyDenied && context.mounted) {
            await _showPermissionDeniedDialog(
              context,
              title: '$permissionName 权限被拒绝',
              message: deniedMessage,
            );
          }
          return false;

        case PermissionStatus.permanentlyDenied:
          debugPrint('$permissionName 权限被永久拒绝');
          if (context.mounted) {
            await _showPermissionDeniedDialog(
              context,
              title: '$permissionName 权限被拒绝',
              message: deniedMessage,
            );
          }
          return false;

        case PermissionStatus.restricted:
          debugPrint('$permissionName 权限被设备限制');
          if (context.mounted) {
            await _showPermissionDeniedDialog(
              context,
              title: '$permissionName 权限受限',
              message: restrictedMessage,
            );
          }
          return false;
      }
    } catch (e) {
      debugPrint('$permissionName 权限检查异常: $e');
      return false;
    }
  }

  /// 检查并请求相机权限
  ///
  /// 用于拍照功能
  static Future<bool> requestCameraPermission(BuildContext context) async {
    return _requestPermission(
      context,
      permission: Permission.camera,
      permissionName: '相机',
      deniedMessage: '请在设置中开启相机权限，以便拍摄照片',
      restrictedMessage: '您的设备限制了相机访问，请检查家长控制或企业政策设置',
    );
  }

  /// 检查并请求相册权限
  ///
  /// 用于选择图片/视频功能
  static Future<bool> requestPhotosPermission(BuildContext context) async {
    Permission permission;
    var permissionName = '相册';
    var deniedMessage = '请在设置中开启相册权限，以便选择照片和视频';
    var restrictedMessage = '您的设备限制了相册访问，请检查家长控制或企业政策设置';
    if (Platform.isIOS) {
      permission = Permission.photos;
    } else {
      // Android 13+ 使用新的媒体权限
      if (await _isAndroid13OrAbove()) {
        permission = Permission.photos; // 在较新版本中会自动映射到 READ_MEDIA_IMAGES
      } else {
        permission = Permission.storage;
        permissionName = '存储';
        restrictedMessage = '您的设备限制了存储访问，请检查家长控制或企业政策设置';
        deniedMessage = '请在设置中开启存储权限，以便选择照片和视频';
      }
    }

    if (!context.mounted) {
      return false;
    }
    return _requestPermission(
      context,
      permission: permission,
      permissionName: permissionName,
      deniedMessage: deniedMessage,
      restrictedMessage: restrictedMessage,
    );
  }

  /// 检查并请求麦克风权限
  ///
  /// 用于录制视频音频
  static Future<bool> requestMicrophonePermission(BuildContext context) async {
    return _requestPermission(
      context,
      permission: Permission.microphone,
      permissionName: '麦克风',
      deniedMessage: '请在设置中开启麦克风权限，以便录制视频音频',
      restrictedMessage: '您的设备限制了麦克风访问，请检查家长控制或企业政策设置',
    );
  }

  /// 批量请求媒体相关权限
  ///
  /// 用于 wechat_assets_picker 等媒体选择器
  static Future<bool> requestMediaPermissions(BuildContext context) async {
    try {
      // 逐个请求权限，避免 iOS 批量请求的问题
      final cameraGranted = await requestCameraPermission(context);
      final photosGranted = await requestPhotosPermission(context);

      // 麦克风权限是可选的，只在需要录制视频时才必需
      try {
        final micStatus = await Permission.microphone.status;
        if (micStatus.isDenied) {
          await Permission.microphone.request();
        }
      } catch (e) {
        debugPrint('麦克风权限检查失败: $e');
        // 麦克风权限失败不影响图片选择功能
      }

      final basicPermissionsGranted = cameraGranted && photosGranted;

      if (!basicPermissionsGranted && context.mounted) {
        final deniedPermissions = <String>[];
        if (!cameraGranted) deniedPermissions.add('相机');
        if (!photosGranted) deniedPermissions.add('相册');

        await _showPermissionDeniedDialog(
          context,
          title: '权限申请失败',
          message: '以下权限被拒绝：${deniedPermissions.join('、')}\n\n请在设置中手动开启这些权限',
        );
      }

      // 返回基础权限状态，麦克风权限失败不影响整体功能
      return basicPermissionsGranted;
    } catch (e) {
      debugPrint('批量权限请求异常: $e');
      return false;
    }
  }

  /// 检查是否为 Android 13 或以上版本
  static Future<bool> _isAndroid13OrAbove() async {
    if (!Platform.isAndroid) return false;
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    return androidInfo.version.sdkInt >= 33;
  }

  /// 调试方法：打印所有权限状态
  ///
  /// 用于调试权限问题
  Future<void> debugPrintAllPermissions() async {
    debugPrint('=== 权限状态调试 ===');
    debugPrint('平台: ${Platform.isIOS ? "iOS" : "Android"}');

    try {
      final cameraStatus = await Permission.camera.status;
      debugPrint('相机权限状态: $cameraStatus');

      final photosStatus = await Permission.photos.status;
      debugPrint('相册权限状态: $photosStatus');

      final microphoneStatus = await Permission.microphone.status;
      debugPrint('麦克风权限状态: $microphoneStatus');

      if (Platform.isAndroid) {
        final storageStatus = await Permission.storage.status;
        debugPrint('存储权限状态: $storageStatus');

        if (await _isAndroid13OrAbove()) {
          final mediaImagesStatus = await Permission.photos.status;
          debugPrint('媒体图片权限状态: $mediaImagesStatus');
        }
      }
    } catch (e) {
      debugPrint('权限状态检查异常: $e');
    }

    debugPrint('=== 权限状态调试结束 ===');
  }

  /// 显示权限被拒绝的对话框
  static Future<void> _showPermissionDeniedDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => MyCupertinoAlertDialog(
        title: title,
        content: message,
        actionTitles: [
          MyTextAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            title: '取消',
          ),
          MyTextAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              openAppSettings();
            },
            title: '去设置',
          ),
        ],
      ),
    );
  }
}
