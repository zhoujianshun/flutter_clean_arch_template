# Liquid Glass（液态玻璃）适配 TODO

> 记录 iOS 26 / iOS 27 液态玻璃（Liquid Glass）适配中已识别但尚未完成的工作项。
>
> 背景：Flutter 官方对 iOS 26 的 Liquid Glass 采取「暂停开发、暂不接受贡献」的立场
> （见 [flutter/flutter#170310](https://github.com/flutter/flutter/issues/170310)），
> Cupertino 组件外观停留在 iOS 18 世代，不会自动获得玻璃材质。
>
> 技术根因：Liquid Glass 是 UIKit / SwiftUI 的**系统材质**（折射、采样背景、触摸响应），
> Flutter 用自绘引擎逐像素渲染，无法直接读取该材质；`MediaQuery.displayFeatures`
> 亦仅 Android 填充。因此适配只能走「原生平台视图」或「shader 自绘」两条社区路线。

---

## P0 — 必须完成

### 1. 封装层纪律审计

- [ ] 扫描 `features/` 下是否有绕过 `shared/widgets` 封装层、直接实例化原生组件的页面
      （直接 `CupertinoButton` / `FilledButton` / `CupertinoNavigationBar` 等）
- [ ] 将此类调用收敛到 `My*` 封装组件，确保页面层不感知平台差异
- [ ] 现状：`MyButton` 等封装层已存在，但底层**写死 `CupertinoButton`**（Android 也呈现 iOS 样式），
      需确认这是否为有意为之的设计选择

### 2. 平台判断收敛

- [ ] 排查项目中散落的 `Platform.isIOS` 判断，改为 `Theme.of(context).platform`
- [ ] 原因：前者是静态值、难以在 widget test 中 mock；后者是 Flutter 推荐的 adaptive 信号
- [ ] 目标：平台判断**只出现在 `shared/widgets` 封装层内部**，不进入 `features/` 页面层

---

## P1 — 建议完成

### 3. 主题层预留玻璃材质开关

- [ ] 在 `core/theme/app_theme.dart` 预留「是否启用玻璃材质」的配置位
- [ ] 配置维度：`TargetPlatform` + iOS 版本号（iOS 26+ 才支持真玻璃）
- [ ] 未来官方/社区方案落地时，封装层只需读此开关，避免到处散落版本判断

### 4. 是否引入玻璃效果的决策

- [ ] 业务判断：玻璃需要丰富、可滚动的内容才能体现，平坦背景上看不出效果
- [ ] 业务/工具类应用当前**不引入玻璃效果仍是稳妥选择**
- [ ] 若面向 iOS 26+ 用户且在意原生观感，评估引入成本与收益

---

## P2 — 可选优化

### 5. 社区方案选型评估（若决定引入）

- [ ] [real_liquid_glass](https://pub.dev/packages/real_liquid_glass) — 宿主原生 `UIGlassEffect`，
      自动跟随 iOS 27 透明度滑块与无障碍设置
- [ ] [native_liquid_glass](https://pub.dev/packages/native_liquid_glass) — UIKit 控件平台视图
- [ ] [fresnel](https://pub.dev/packages/fresnel) — SwiftUI `glassEffect` + shader 跨平台回退
- [ ] shader 自绘方案（`liquid_glass_widgets` / `liquid_glass_renderer`）— 全平台一致但非真玻璃
- [ ] 权衡：平台视图有全屏合成开销，仅适合小面积 chrome（标签栏/导航栏/悬浮按钮），
      不建议用于列表行或大面积背景

### 6. 持续跟踪官方进展

- [ ] [flutter/flutter#170310](https://github.com/flutter/flutter/issues/170310) — Liquid Glass 支持，
      目前 P3、无实现 PR
- [ ] [cupertino_ui](https://pub.dev/packages/cupertino_ui) 1.0 — Cupertino 已解耦为独立包，玻璃材质尚未包含
- [ ] Material/Cupertino 解耦总进度 [flutter/flutter#101479](https://github.com/flutter/flutter/issues/101479)

---

## 已完成 ✅

暂无（玻璃效果适配尚未启动，本清单为首次建立）。

---

## 参考

- [Flutter on latest iOS](https://docs.flutter.dev/platform-integration/ios/ios-latest) — 官方 iOS 特性支持状态
- [Applying Liquid Glass to custom views](https://developer.apple.com/documentation/SwiftUI/Applying-Liquid-Glass-to-custom-views) — Apple 官方玻璃 API
- 关键时间节点：2026-04-28 起 App Store 强制 Xcode 26 构建；2027-04 起强制 iOS 27 SDK

---

*最后更新：2026-10-21*
