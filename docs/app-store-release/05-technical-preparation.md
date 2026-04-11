# 技术准备指南

> Android 和 iOS 应用构建、签名、测试详细指南

## 📋 目录

- [Android 技术准备](#android-技术准备)
- [iOS 技术准备](#ios-技术准备)
- [应用测试](#应用测试)
- [常见问题处理](#常见问题处理)

---

## 🤖 Android 技术准备

### 当前配置检查

根据您的项目配置,以下内容已就绪:

```yaml
✅ 已配置项:
- 包名: com.example.yourapp
- 版本号: 1.1.0
- 版本代码: 1
- 签名配置: keystore/upload-keystore.jks
- 混淆开启: isMinifyEnabled = true
- ProGuard 规则: proguard-rules.pro
```

### 构建 Release APK

**方式1: 使用项目工具链(推荐)**

```bash
# 使用 Makefile
make android-build-release

# 或使用 Just
just android-build-release

# 输出位置:
# build/app/outputs/flutter-apk/app-arm64-v8a-release.apk (推荐提交此版本)
# build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
# build/app/outputs/flutter-apk/app-x86_64-release.apk
```

**方式2: 使用 Flutter 命令**

```bash
# 1. 清理项目
flutter clean

# 2. 获取依赖
flutter pub get

# 3. 生成代码
dart run build_runner build --delete-conflicting-outputs

# 4. 构建 APK (分架构)
flutter build apk --release --split-per-abi

# 5. 构建单个 APK (包含所有架构,体积较大)
flutter build apk --release

# 6. 构建 AAB (Google Play 和部分国内市场支持)
flutter build appbundle --release
```

**推荐提交版本:**

```
app-arm64-v8a-release.apk
- 适用于 95% 以上的 Android 设备
- 体积适中 (约 20-50MB)
- 兼容性最好
```

### 检查构建结果

```bash
# 查看 APK 信息
aapt dump badging build/app/outputs/flutter-apk/app-arm64-v8a-release.apk

# 查看 APK 大小
ls -lh build/app/outputs/flutter-apk/

# 安装到设备测试
adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk

# 查看签名信息
keytool -printcert -jarfile build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

### APK 加固 (可选但推荐)

**为什么需要加固?**

```
✅ 提高安全性:
- 防止反编译
- 防止代码篡改
- 保护敏感数据

✅ 提高审核通过率:
- 部分应用市场建议加固
- 华为应用市场推荐加固
```

**加固方式:**

**1. 360加固 (推荐)**

```
官网: https://jiagu.360.cn/

步骤:
1. 注册账号并登录
2. 上传 APK
3. 选择加固类型 (免费基础加固即可)
4. 等待加固完成 (约 5-10分钟)
5. 下载加固后的 APK
6. 重新签名 (加固会去除原签名)

重新签名命令:
jarsigner -verbose -keystore keystore/upload-keystore.jks \
  -signedjar app-release-signed.apk \
  app-release-jiagu.apk \
  key_alias

# 对齐 APK
zipalign -v 4 app-release-signed.apk app-release-final.apk
```

**2. 腾讯乐固**

```
官网: https://legu.qcloud.com/

步骤类似 360加固
价格: 免费版功能已足够
```

**3. 爱加密**

```
官网: https://www.ijiami.cn/

适合企业用户
功能更强大
价格较高
```

### 版本号管理

**版本号规则:**

```yaml
# pubspec.yaml
version: 1.0.0+1
         ↑     ↑
    versionName versionCode
```

**更新规则:**

```
首次发布: 1.0.0+1

小版本更新 (bugfix): 1.1.1+2
中版本更新 (新功能): 1.2.0+3  
大版本更新 (重大更新): 2.0.0+4

重要:
- versionName (1.1.0) 用于展示给用户
- versionCode (+1) 用于版本控制, 必须递增
- 每次提交都要更新 versionCode
```

---

## 🍎 iOS 技术准备

### Apple Developer 账号

**账号类型选择:**

| 类型 | 费用 | 适用场景 | 推荐度 |
|------|------|---------|--------|
| 个人账号 | $99/年 | 个人开发者 | ⭐⭐⭐ |
| 企业账号 | $299/年 | 企业应用,内部分发 | ⭐⭐⭐⭐⭐ |

**建议: 使用企业账号**

- 更专业
- 可以企业内部分发
- 用户信任度更高

**注册流程:**

```
1. 访问: https://developer.apple.com/programs/
2. 选择账号类型 (Apple Developer Program)
3. 使用 Apple ID 登录或注册
4. 填写企业信息 (企业账号需要邓白氏编码)
5. 支付费用 ($99 或 $299)
6. 等待审核 (通常 1-2个工作日)
7. 审核通过后激活账号
```

### 配置 Bundle ID

**Bundle ID 命名建议:**

```
推荐格式: com.example.yourapp

命名规则:
- 反向域名格式
- 全小写
- 使用点号分隔
- 与 Android 包名对应
- 全球唯一, 一旦创建不可修改

当前 Android 包名:
com.example.yourapp

建议iOS Bundle ID:
com.example.yourapp
```

**在 Xcode 中配置:**

```
1. 打开项目
open ios/Runner.xcworkspace

2. 选择 Runner target
3. General 标签页
4. Bundle Identifier: com.example.yourapp
5. Display Name: 您的应用
6. Version: 1.1.0
7. Build: 1

重要:
- Display Name 是用户看到的应用名称
- Version 对应 versionName
- Build 对应 versionCode, 必须递增
```

### 配置证书和描述文件

**Step 1: 创建 App ID**

```
1. 登录 Apple Developer Portal
   https://developer.apple.com/account/

2. Certificates, IDs & Profiles → Identifiers → +

3. 选择 App IDs → Continue

4. 填写信息:
   - Description: Flutter Clean Architecture Template
   - Bundle ID: Explicit - com.example.yourapp

5. Capabilities (根据应用功能选择):
   ☑ Push Notifications (如需推送)
   ☐ In-App Purchase (如需内购)
   ☑ Associated Domains (如有)

6. Continue → Register
```

**Step 2: 创建 Distribution Certificate**

```
1. Certificates → + → Apple Distribution

2. 在 Mac 上创建 CSR 文件:
   - 打开 Keychain Access (钥匙串访问)
   - 证书助理 → 从证书颁发机构请求证书
   - 用户电子邮件: 您的邮箱
   - 常用名称: 公司名称
   - 选择: 存储到磁盘

3. 上传 CSR 文件

4. 下载证书 (.cer 文件)

5. 双击安装到 Keychain Access
```

**Step 3: 创建 Provisioning Profile**

```
1. Profiles → + → App Store

2. 选择 App ID (刚才创建的)

3. 选择 Certificate (刚才创建的)

4. Profile Name: Flutter Clean Architecture Template Distribution

5. Generate → Download

6. 双击安装
```

**在 Xcode 中配置签名:**

```
1. 打开项目: open ios/Runner.xcworkspace

2. 选择 Runner target → Signing & Capabilities

3. 取消勾选 Automatically manage signing

4. 配置 Release:
   - Provisioning Profile: 选择刚才创建的 Profile
   - Signing Certificate: 选择 Apple Distribution 证书

5. Team: 选择您的开发团队
```

### 完善 Info.plist

**检查当前配置:**

```xml
<!-- ios/Runner/Info.plist -->

✅ 已配置:
<key>CFBundleDisplayName</key>
<string>$(INFOPLIST_KEY_CFBundleDisplayName)</string>

<key>NSCameraUsageDescription</key>
<string>您的应用需要访问您的相机来拍摄照片，用于记录服务过程或签到</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>您的应用需要访问您的相册来选择服务相关的照片</string>
```

**需要补充配置 (在 Xcode 中设置):**

```
1. 打开 Xcode: open ios/Runner.xcworkspace

2. 选择 Runner target → Info

3. 设置 Display Name:
   - 删除 $(INFOPLIST_KEY_CFBundleDisplayName)
   - 直接填写: 您的应用

4. 检查其他权限描述是否清晰
```

### 构建 iOS IPA

**前置准备:**

```bash
# 1. 清理项目
flutter clean

# 2. 安装 iOS 依赖
cd ios
pod install
pod update
cd ..

# 3. 获取 Flutter 依赖
flutter pub get

# 4. 生成代码
dart run build_runner build --delete-conflicting-outputs
```

**方式1: 使用 Flutter 命令构建**

```bash
# 构建 iOS Release 版本
flutter build ios --release

# 输出位置: build/ios/iphoneos/Runner.app
```

**方式2: 使用 Xcode Archive (推荐)**

```
1. 打开项目
open ios/Runner.xcworkspace

2. 选择真机设备或 Any iOS Device

3. Product → Clean Build Folder (Cmd+Shift+K)

4. Product → Archive (Cmd+B 确保编译通过后再 Archive)

5. 等待 Archive 完成 (约 5-10分钟)

6. 自动打开 Organizer 窗口

7. 选择刚才的 Archive → Distribute App

8. 选择发布方式:
   - App Store Connect (提交到 App Store)
   - Ad Hoc (内部测试)
   - Development (开发测试)

9. 选择 App Store Connect → Next

10. Upload → Next

11. 选择签名方式:
    - Automatically manage signing (推荐)
    - Manually manage signing (手动选择证书)

12. Next → Upload

13. 等待上传完成

14. 检查上传状态:
    - 登录 App Store Connect
    - 我的 App → Flutter Clean Architecture Template
    - TestFlight 或 App Store
    - 查看构建版本
```

**方式3: 使用命令行导出 IPA**

```bash
# 1. 先用 Xcode Archive

# 2. 导出 IPA
xcodebuild -exportArchive \
  -archivePath ~/Library/Developer/Xcode/Archives/Runner.xcarchive \
  -exportPath ./build/ios/ipa \
  -exportOptionsPlist ios/ExportOptions.plist

# 输出位置: build/ios/ipa/Runner.ipa
```

### 版本号管理

**iOS 版本号规则:**

```
CFBundleShortVersionString (Version): 1.1.0
CFBundleVersion (Build): 1

更新规则:
- 每次提交 App Store, Build 号必须递增
- Version 更新规则与 Android 相同
- Build 号可以独立于 Android versionCode
```

**在 Xcode 中更新:**

```
1. 选择 Runner target → General

2. Version: 1.1.0
   Build: 1

每次提交前:
- 小更新: Build +1 (如 1→2)
- 版本更新: Version 也更新 (如 1.1.0 → 1.2.0)
```

---

## 🧪 应用测试

### 测试账号准备

**为什么需要测试账号?**

```
✅ iOS 审核必需:
- Apple 审核人员需要测试账号登录应用
- 如果没有测试账号, 100% 被拒审

✅ 提高审核效率:
- 有效的测试账号能加快审核速度
- 减少因测试账号问题被拒的风险
```

**创建测试账号:**

```
要求:
□ 功能完整可用
□ 有真实的订单数据
□ 可以正常接收验证码
□ 不会因为使用频繁被锁定

建议创建 2个测试账号:
1. 主测试账号
   - 手机号: __________
   - 密码/验证码获取方式: __________
   - 说明: 正常服务人员账号

2. 备用测试账号
   - 手机号: __________
   - 密码/验证码获取方式: __________
   - 说明: 新注册账号, 无订单数据
```

**测试账号说明文档:**

```markdown
# 测试账号说明

## 主测试账号

**手机号:** 138****8888

**登录方式:** 
1. 输入手机号: 138****8888
2. 点击"获取验证码"
3. 验证码将发送到此手机
4. 如需验证码, 请联系客服: __________

**账号状态:**
- 账号类型: 正常服务人员
- 认证状态: 已认证
- 订单数据: 有历史订单约 20条
- 余额: 0元 (不涉及提现功能)

**可测试功能:**
✅ 登录注册
✅ 订单列表查看
✅ 订单详情查看
✅ 工作台统计
✅ 服务记录上传
✅ 消息中心查看
✅ 个人中心设置

**注意事项:**
- 请不要修改个人信息
- 请不要删除历史订单
- 测试完成后请退出登录

## 备用测试账号

**手机号:** 139****9999

**说明:** 新注册账号, 无历史数据, 用于测试注册流程

---

**如有问题, 请联系:**
客服电话: __________
客服邮箱: __________
工作时间: 24/7 (审核期间)
```

### 功能测试清单

**核心功能测试:**

```
登录注册:
□ 手机号格式验证
□ 验证码发送和验证
□ 登录成功跳转
□ 记住登录状态
□ 退出登录功能

订单管理:
□ 订单列表加载
□ 订单筛选功能
□ 订单搜索功能
□ 订单详情查看
□ 订单状态展示
□ 上拉加载更多
□ 下拉刷新

工作台:
□ 今日统计展示
□ 本周统计展示
□ 本月统计展示
□ 数据准确性

服务记录:
□ 拍照上传
□ 相册选择
□ 多图上传
□ 图片预览
□ 护理记录填写

消息中心:
□ 消息列表展示
□ 消息详情查看
□ 未读消息标记
□ 消息分类

个人中心:
□ 个人信息展示
□ 个人信息修改
□ 主题切换
□ 语言切换
□ 关于我们
□ 隐私政策查看
□ 退出登录
```

**兼容性测试:**

```
Android 设备:
□ 华为 (EMUI/HarmonyOS)
□ 小米 (MIUI)
□ OPPO (ColorOS)
□ vivo (OriginOS)
□ 三星 (OneUI)
□ 其他品牌

Android 版本:
□ Android 10
□ Android 11
□ Android 12
□ Android 13
□ Android 14

iOS 设备:
□ iPhone SE (小屏)
□ iPhone 11/12/13 (标准屏)
□ iPhone 14/15 Pro Max (大屏)
□ iPad (如支持)

iOS 版本:
□ iOS 14
□ iOS 15
□ iOS 16
□ iOS 17
```

**异常情况测试:**

```
网络异常:
□ 无网络时的提示
□ 弱网络时的加载
□ 网络切换时的处理

数据异常:
□ 空列表展示
□ 加载失败提示
□ 图片加载失败

操作异常:
□ 频繁点击防抖
□ 返回键处理
□ 应用切换
□ 内存不足
```

### 性能测试

```
启动速度:
□ 冷启动时间 < 3秒
□ 热启动时间 < 1秒

页面加载:
□ 列表首屏加载 < 1秒
□ 详情页加载 < 1秒
□ 图片加载使用骨架屏

内存占用:
□ 应用运行时内存 < 200MB
□ 长时间使用无内存泄漏

APK/IPA 大小:
□ Android APK < 50MB (arm64)
□ iOS IPA < 100MB
```

### 安全测试

```
数据安全:
□ 敏感数据加密存储
□ 网络传输 HTTPS
□ Token 安全存储
□ 登录过期处理

权限安全:
□ 权限申请时机合理
□ 权限拒绝不影响其他功能
□ 权限说明清晰

代码安全:
□ 无明文密钥
□ 无调试代码
□ 无敏感日志输出
```

---

## 🔧 常见问题处理

### Android 构建问题

**问题1: 构建失败 - 依赖冲突**

```bash
# 错误信息
FAILURE: Build failed with an exception.
* What went wrong:
Execution failed for task ':app:checkDebugDuplicateClasses'.
> A failure occurred while executing com.android.build.gradle.internal.tasks.CheckDuplicatesRunnable
   > Duplicate class...

# 解决方案
1. 清理项目
flutter clean
cd android
./gradlew clean
cd ..

2. 删除构建缓存
rm -rf ~/.gradle/caches
rm -rf build/

3. 重新获取依赖
flutter pub get
cd android
./gradlew --refresh-dependencies
cd ..

4. 重新构建
flutter build apk --release
```

**问题2: 签名错误**

```bash
# 错误信息
Execution failed for task ':app:validateSigningRelease'.
> Keystore file not found...

# 解决方案
1. 检查 key.properties 文件
cat android/key.properties

2. 确认内容正确:
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=your_key_alias
storeFile=../keystore/upload-keystore.jks

3. 检查 keystore 文件存在
ls -l keystore/upload-keystore.jks

4. 如果丢失, 使用备份恢复或重新生成 (不推荐, 会导致无法更新已发布应用)
```

**问题3: ProGuard 混淆导致崩溃**

```bash
# 现象: Release 版本崩溃, Debug 版本正常

# 解决方案: 添加 ProGuard 规则
# android/app/proguard-rules.pro

# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Gson (如使用)
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.** { *; }

# 保留项目特定类
-keep class com.example.yourapp.** { *; }
```

### iOS 构建问题

**问题1: Pod install 失败**

```bash
# 错误信息
[!] CocoaPods could not find compatible versions for pod...

# 解决方案
cd ios

# 1. 更新 CocoaPods
sudo gem install cocoapods

# 2. 更新本地 Pod 仓库
pod repo update

# 3. 清理 Pod 缓存
rm -rf Pods/
rm Podfile.lock

# 4. 重新安装
pod install --repo-update

cd ..
```

**问题2: Archive 失败 - 签名问题**

```bash
# 错误信息
Code Signing Error: No signing certificate "iOS Distribution" found...

# 解决方案
1. 检查证书安装:
   - 打开 Keychain Access
   - 搜索 "Apple Distribution"
   - 确认证书存在且有效

2. 在 Xcode 中重新配置:
   - Runner target → Signing & Capabilities
   - 取消勾选 Automatically manage signing
   - 手动选择 Team 和 Provisioning Profile

3. 如果证书过期:
   - 在 Apple Developer Portal 重新创建
   - 下载并安装新证书
   - 更新 Provisioning Profile
```

**问题3: 上传 App Store Connect 失败**

```bash
# 错误信息
ERROR ITMS-90xxx: Invalid Bundle...

# 常见原因和解决方案

# 1. Bundle ID 不匹配
检查 Xcode 中的 Bundle ID 与 App Store Connect 中创建的 App ID 是否一致

# 2. 版本号问题
- Build 号必须大于已上传的版本
- 在 Xcode 中递增 Build 号

# 3. 权限描述缺失
检查 Info.plist 中所有使用的权限都有描述

# 4. 不支持的架构
确保构建设置中:
- Build Active Architecture Only: NO (Release)
- Valid Architectures: arm64
```

### 测试问题

**问题1: 应用闪退**

```bash
# Android 查看崩溃日志
adb logcat | grep -i flutter

# iOS 查看崩溃日志
# Xcode → Window → Devices and Simulators
# 选择设备 → View Device Logs

# 常见原因:
1. 空指针异常
2. 数据类型错误
3. 网络请求失败未处理
4. 图片加载失败
5. ProGuard 混淆问题 (Android)
```

**问题2: 功能异常**

```bash
# 调试步骤:
1. 检查网络请求是否成功
2. 检查数据格式是否正确
3. 检查权限是否授予
4. 查看应用日志

# 使用 Talker 日志 (项目已集成)
# 在应用中查看实时日志
# lib/core/logger/app_logger.dart
```

---

## ✅ 技术准备检查清单

完成本指南后,确认以下所有项目:

### Android

- [ ] APK 构建成功 (arm64-v8a-release.apk)
- [ ] APK 已签名
- [ ] APK 已加固 (可选)
- [ ] APK 大小合理 (< 50MB)
- [ ] 已测试安装和运行
- [ ] 版本号正确 (versionCode 递增)

### iOS

- [ ] Apple Developer 账号已激活
- [ ] Bundle ID 已创建
- [ ] 证书和描述文件已配置
- [ ] IPA 构建成功
- [ ] 已上传到 App Store Connect
- [ ] 版本号正确 (Build 递增)
- [ ] Info.plist 配置完整

### 测试

- [ ] 测试账号已创建 (至少2个)
- [ ] 测试说明文档已准备
- [ ] 核心功能测试通过
- [ ] 兼容性测试通过
- [ ] 异常情况测试通过
- [ ] 性能测试通过

---

## 📞 下一步

完成技术准备后,请继续:

1. 📗 [查看 Android 上架详细指南](./06-android-release-guide.md)
2. 📘 [查看 iOS 上架详细指南](./07-ios-release-guide.md)
3. ✅ [查看审核检查清单](./08-review-checklist.md)

---

**文档版本:** v1.0.0  
**最后更新:** 2025-01-29  
**项目版本:** v1.0.0
