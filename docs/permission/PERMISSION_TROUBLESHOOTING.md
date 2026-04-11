# Flutter 权限管理问题排查指南

## 🚨 常见问题快速定位

### 问题1：iOS 设备权限状态返回错误

**现象：**

```dart
final status = await Permission.camera.status;
// 明明已授权，却返回 PermissionStatus.denied
```

**排查步骤：**

1. **检查 Podfile 配置**

```bash
# 查看是否启用了权限
cat ios/Podfile | grep "PERMISSION_CAMERA"
```

2. **检查 Info.plist 配置**

```bash
# 查看权限描述是否存在
grep -A1 "NSCameraUsageDescription" ios/Runner/Info.plist
```

3. **重新构建项目**

```bash
flutter clean
cd ios && rm -rf Pods Podfile.lock && pod install
flutter build ios
```

### 问题2：Android 13+ 设备无法访问相册

**现象：**

```dart
// Android 13+ 设备上相册权限申请失败
final status = await Permission.storage.status;
// 返回 PermissionStatus.denied
```

**解决方案：**

```xml
<!-- 确保 AndroidManifest.xml 包含新权限 -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />

<!-- 同时保留旧权限以兼容低版本 -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" 
                 android:maxSdkVersion="32" />
```

### 问题3：权限申请对话框不显示

**可能原因：**

1. **Context 失效**：在异步操作后 context 已经 unmounted
2. **权限已被永久拒绝**：需要引导用户到设置页面

**解决方案：**

```dart
// 检查 context 状态
if (context.mounted) {
  await showDialog(...);
}

// 处理永久拒绝
if (status.isPermanentlyDenied) {
  await openAppSettings();
}
```

## 🔧 高级配置

### 自定义权限申请流程

```dart
class CustomPermissionFlow {
  static Future<bool> requestWithEducation(
    BuildContext context,
    Permission permission,
    String educationMessage,
  ) async {
    // 1. 先显示教育性说明
    final shouldProceed = await _showEducationDialog(context, educationMessage);
    if (!shouldProceed) return false;

    // 2. 再申请权限
    final result = await permission.request();
    return result.isGranted;
  }

  static Future<bool> _showEducationDialog(
    BuildContext context, 
    String message,
  ) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('权限说明'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('我知道了'),
          ),
        ],
      ),
    ) ?? false;
  }
}
```

### 权限状态监听

```dart
class PermissionListener extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPermissionChanged;

  const PermissionListener({
    Key? key,
    required this.child,
    this.onPermissionChanged,
  }) : super(key: key);

  @override
  State<PermissionListener> createState() => _PermissionListenerState();
}

class _PermissionListenerState extends State<PermissionListener> 
    with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 应用从后台返回时，检查权限状态变化
      widget.onPermissionChanged?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
```

## 📊 性能优化

### 权限缓存机制

```dart
class PermissionCache {
  static final Map<Permission, PermissionStatus> _cache = {};
  static DateTime? _lastUpdateTime;
  static const Duration _cacheTimeout = Duration(minutes: 5);

  /// 获取缓存的权限状态
  static Future<PermissionStatus?> getCachedStatus(Permission permission) async {
    final now = DateTime.now();
    
    if (_lastUpdateTime == null || 
        now.difference(_lastUpdateTime!) > _cacheTimeout) {
      // 缓存过期，清空缓存
      _cache.clear();
      return null;
    }
    
    return _cache[permission];
  }

  /// 更新权限状态缓存
  static void updateCache(Permission permission, PermissionStatus status) {
    _cache[permission] = status;
    _lastUpdateTime = DateTime.now();
  }
}
```

## 📱 平台特定配置

### Android 混淆配置

如果你的应用启用了代码混淆，需要在 `android/app/proguard-rules.pro` 中添加：

```proguard
# Permission Handler
-keep class com.baseflow.permissionhandler.** { *; }
-keep interface com.baseflow.permissionhandler.** { *; }

# Device Info Plus
-keep class io.flutter.plugins.deviceinfo.** { *; }
```

### iOS 隐私清单配置

iOS 17+ 需要在应用中包含隐私清单。创建 `ios/Runner/PrivacyInfo.xcprivacy`：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSPrivacyCollectedDataTypes</key>
    <array>
        <dict>
            <key>NSPrivacyCollectedDataType</key>
            <string>NSPrivacyCollectedDataTypePhotosorVideos</string>
            <key>NSPrivacyCollectedDataTypeLinked</key>
            <false/>
            <key>NSPrivacyCollectedDataTypeTracking</key>
            <false/>
            <key>NSPrivacyCollectedDataTypePurposes</key>
            <array>
                <string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
```

## 🧪 自动化测试

### 权限测试用例

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:permission_handler/permission_handler.dart';

class MockPermissionHandler extends Mock implements PermissionHandler {}

void main() {
  group('PermissionManager Tests', () {
    late PermissionManager permissionManager;
    late MockPermissionHandler mockPermissionHandler;

    setUp(() {
      permissionManager = PermissionManager.instance;
      mockPermissionHandler = MockPermissionHandler();
    });

    testWidgets('相机权限申请成功', (WidgetTester tester) async {
      // 模拟权限授予
      when(mockPermissionHandler.checkPermissionStatus(Permission.camera))
          .thenAnswer((_) async => PermissionStatus.granted);

      // 构建测试 Widget
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  final result = await permissionManager.requestCameraPermission(context);
                  expect(result, true);
                },
                child: Text('测试相机权限'),
              );
            },
          ),
        ),
      );

      // 点击按钮触发权限申请
      await tester.tap(find.text('测试相机权限'));
      await tester.pumpAndSettle();
    });

    test('Android 版本检测', () async {
      // 测试 Android 13+ 检测逻辑
      final isAndroid13Plus = await permissionManager._isAndroid13OrAbove();
      expect(isAndroid13Plus, isA<bool>());
    });
  });
}
```

## 📚 扩展阅读

- [Flutter 官方权限指南](https://docs.flutter.dev/development/data-and-backend/state-mgmt/options#riverpod)
- [Android 权限最佳实践](https://developer.android.com/training/permissions/requesting)
- [iOS 隐私和权限](https://developer.apple.com/documentation/uikit/protecting_the_user_s_privacy)
- [permission_handler 插件文档](https://pub.dev/packages/permission_handler)

---

*本文基于实际项目开发经验总结，涵盖了 Flutter 权限管理的完整解决方案。如有问题或建议，欢迎交流讨论。*
