# iOS Info.plist 地图应用查询配置

为了在iOS上正确检测和启动地图应用，需要在 `ios/Runner/Info.plist` 文件中添加 URL Schemes 查询配置。

## 在 Info.plist 中添加配置

在 `<dict>` 标签内添加以下配置：

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <!-- 高德地图 -->
    <string>iosamap</string>
    <string>amapuri</string>
    
    <!-- 百度地图 -->
    <string>baidumap</string>
    
    <!-- 腾讯地图 -->
    <string>qqmap</string>
    
    <!-- 其他可能用到的schemes -->
    <string>maps</string>
</array>
```

## 完整的 Info.plist 配置示例

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    
    <key>CFBundleDisplayName</key>
    <string>Your App Name</string>
    
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    
    <key>CFBundleName</key>
    <string>flutter_clean_arch_template</string>
    
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    
    <key>CFBundleShortVersionString</key>
    <string>$(FLUTTER_BUILD_NAME)</string>
    
    <key>CFBundleSignature</key>
    <string>????</string>
    
    <key>CFBundleVersion</key>
    <string>$(FLUTTER_BUILD_NUMBER)</string>
    
    <!-- 地图应用URL Schemes查询配置 -->
    <key>LSApplicationQueriesSchemes</key>
    <array>
        <string>iosamap</string>
        <string>amapuri</string>
        <string>baidumap</string>
        <string>qqmap</string>
        <string>maps</string>
    </array>
    
    <!-- 位置权限配置 -->
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>此应用需要位置权限来为您提供导航服务</string>
    
    <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
    <string>此应用需要位置权限来为您提供导航服务</string>
    
    <!-- 其他必要配置 -->
    <key>LSRequiresIPhoneOS</key>
    <true/>
    
    <key>UILaunchStoryboardName</key>
    <string>LaunchScreen</string>
    
    <key>UIMainStoryboardFile</key>
    <string>Main</string>
    
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
    
    <key>UISupportedInterfaceOrientations~ipad</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationPortraitUpsideDown</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
    
    <key>CADisableMinimumFrameDurationOnPhone</key>
    <true/>
    
    <key>UIApplicationSupportsIndirectInputEvents</key>
    <true/>
</dict>
</plist>
```

## 重要说明

### 1. LSApplicationQueriesSchemes 的作用

- iOS 9+ 要求应用明确声明要查询的URL schemes
- 不声明的话，`canOpenURL` 会返回 `false`，即使目标应用已安装
- 每个应用最多可以声明50个URL schemes

### 2. 各地图应用的URL Schemes

- **高德地图**: `iosamap://` (iOS专用) 和 `amapuri://` (通用)
- **百度地图**: `baidumap://`
- **腾讯地图**: `qqmap://`
- **苹果地图**: `maps://` (系统自带，无需声明但建议添加)

### 3. 配置位置

- 文件路径: `ios/Runner/Info.plist`
- 在 `<dict>` 标签内添加配置
- 确保XML格式正确

### 4. 测试验证

1. 配置完成后重新编译应用
2. 在iOS设备上安装对应的地图应用
3. 使用测试页面验证检测功能
4. 查看应用日志确认检测结果

## 故障排除

如果地图应用仍无法检测到：

1. 检查Info.plist语法是否正确
2. 确认URL scheme拼写无误
3. 重新编译并安装应用
4. 确认目标地图应用已正确安装
5. 查看Xcode控制台的错误信息
