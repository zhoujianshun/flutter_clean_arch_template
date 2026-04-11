# 应用市场上架完整指南

> 您的应用 - Android & iOS 应用市场上架全流程文档

## 📚 文档导航

本目录包含应用市场上架的完整指导文档，按照准备流程和内容类型进行分类组织。

### 🎯 快速开始

如果您是第一次准备上架，建议按以下顺序阅读：

1. ⭐ [准备工作总览](./01-preparation-overview.md) - 了解整体流程和时间规划
2. 📋 [企业资质准备指南](./02-enterprise-qualification.md) - 准备营业执照、软著等必需资质
3. 🎨 [应用素材制作指南](./03-app-materials-guide.md) - 制作图标、截图、视频
4. ✍️ [文案撰写指南](./04-content-writing-guide.md) - 撰写应用描述、隐私政策
5. 🔧 [技术准备指南](./05-technical-preparation.md) - 构建、签名、测试

### 📱 平台专属指南

根据您要上架的平台，选择对应的详细指南：

- 📗 [Android 上架详细指南](./06-android-release-guide.md) - 华为、小米、OPPO等市场提交流程
- 📘 [iOS 上架详细指南](./07-ios-release-guide.md) - App Store 完整提交流程

### 📋 实用工具

- ✅ [审核检查清单](./08-review-checklist.md) - 提交前必查项目
- ⏰ [时间规划建议](./09-time-planning.md) - 3周详细时间表
- 💡 [常见问题与专业建议](./10-faq-and-tips.md) - 避坑指南和最佳实践

---

## 🚀 准备阶段概览

### 时间规划

**建议准备周期：2-3周**

- **Week 1**: 资质准备 + 素材制作
- **Week 2**: 应用构建 + 测试验证
- **Week 3**: 提交审核 + 应对反馈

### 关键里程碑

```mermaid
graph LR
    A[资质准备] --> B[素材制作]
    B --> C[文案撰写]
    C --> D[技术准备]
    D --> E[账号注册]
    E --> F[提交审核]
    F --> G[发布上线]
```

---

## 📊 准备清单概览

### 必须准备（P0 优先级）

- [ ] 营业执照扫描件（加盖公章）
- [ ] 软件著作权证书（华为应用市场必需）
- [ ] 应用图标（512x512、1024x1024）
- [ ] 应用截图（至少5张，Android + iOS）
- [ ] 隐私政策网页 URL
- [ ] 用户服务协议 URL
- [ ] 测试账号（iOS 审核必需）
- [ ] 开发者账号（Android 各市场 + Apple Developer）

### 建议准备（P1 优先级）

- [ ] 应用宣传视频（15-30秒）
- [ ] 应用加固（Android）
- [ ] 完整的权限使用说明文档
- [ ] 多设备兼容性测试报告

### 可选准备（P2 优先级）

- [ ] ICP 备案号（如涉及信息服务）
- [ ] 增值电信业务经营许可证（如涉及付费）
- [ ] 应用市场推广素材
- [ ] ASO（应用商店优化）策略

---

## 🎯 当前项目信息

### 应用基本信息

```yaml
应用名称: 您的应用
应用描述: 您的应用
当前版本: 1.0.0
版本代码: 1

Android 信息:
  包名: com.example.yourapp
  最低 SDK: 根据 Flutter 配置
  目标 SDK: 根据 Flutter 配置
  签名配置: ✅ 已配置（keystore/upload-keystore.jks）
  混淆加固: ✅ 已启用 ProGuard

iOS 信息:
  Bundle ID: 需要在 Xcode 中设置
  最低版本: 根据 Flutter 配置
  权限配置: ✅ 已配置相机、相册权限说明
```

### 使用的权限

**Android:**

- 网络访问（INTERNET）
- 网络状态（ACCESS_NETWORK_STATE, ACCESS_WIFI_STATE）
- 拨打电话（CALL_PHONE）
- 相机（CAMERA）
- 读取相册（READ_EXTERNAL_STORAGE, READ_MEDIA_IMAGES）
- 手机状态（READ_PHONE_STATE）

**iOS:**

- 相机（NSCameraUsageDescription）✅ 已配置
- 相册（NSPhotoLibraryUsageDescription）✅ 已配置

---

## 📞 需要帮助？

### 常见问题

1. **软件著作权需要多久？**
   - 普通申请：2-3个月
   - 加急申请：3-7天（推荐）

2. **哪些市场必须要软著？**
   - 华为应用市场：必需
   - 其他市场：建议提供，提高通过率

3. **iOS 审核通常需要多久？**
   - 首次提交：1-3天
   - 更新版本：1-2天
   - 被拒后重审：1-2天

4. **如何提高审核通过率？**
   - 提供高质量截图和描述
   - 准备有效的测试账号
   - 隐私政策完整清晰
   - 应用功能稳定无闪退

### 文档更新

- 创建日期：2025-01-29
- 最后更新：2025-01-29
- 项目版本：v1.0.0
- 文档版本：v1.0.0

---

## 📖 相关文档

- [开发指南](../development/DEVELOPMENT_GUIDE.md)
- [蒲公英发布集成指南](../tools-config/PGYER_INTEGRATION_GUIDE.md)
- [开发工具管理指南](../tools-config/DEV_TOOLS_GUIDE.md)
- [环境配置指南](../tools-config/ENV_CONFIG_GUIDE.md)

---

## 🎉 开始准备

选择下面的文档开始您的上架之旅：

1. 📋 [查看准备工作总览](./01-preparation-overview.md)
2. 📋 [查看企业资质准备指南](./02-enterprise-qualification.md)
3. 🎨 [查看应用素材制作指南](./03-app-materials-guide.md)

祝您上架顺利！🚀
