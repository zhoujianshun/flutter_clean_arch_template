# 自定义主题系统使用指南

本指南介绍了如何使用新的自定义主题扩展系统，包括颜色、字体、间距等各个方面的配置和使用。

## 概述

新的主题系统提供了以下扩展：

- **AppColors**: 完整的颜色调色板系统
- **AppTextStyles**: 标准化的字体样式系统
- **AppSpacing**: 统一的间距系统
- **AppBorderRadius**: 统一的圆角系统

## 颜色系统 (AppColors)

### 品牌色系

```dart
// 主色调 - 蓝色系
AppColors.primary50   // 最浅
AppColors.primary100
AppColors.primary200
AppColors.primary300
AppColors.primary400
AppColors.primary500  // 主色
AppColors.primary600
AppColors.primary700
AppColors.primary800
AppColors.primary900  // 最深
```

### 功能色系

```dart
// 成功色
AppColors.success50   // 浅绿背景
AppColors.success500  // 标准绿色
AppColors.success700  // 深绿色

// 警告色
AppColors.warning50   // 浅橙背景
AppColors.warning500  // 标准橙色
AppColors.warning700  // 深橙色

// 错误色
AppColors.error50     // 浅红背景
AppColors.error500    // 标准红色
AppColors.error700    // 深红色

// 信息色
AppColors.info50      // 浅青背景
AppColors.info500     // 标准青色
AppColors.info700     // 深青色
```

### 中性色系

```dart
// 从浅到深的灰色系
AppColors.neutral50   // 背景色
AppColors.neutral100  // 浅灰背景
AppColors.neutral200  // 边框色
AppColors.neutral300  // 分割线
AppColors.neutral400  // 禁用文字
AppColors.neutral500  // 次要文字
AppColors.neutral600  // 图标色
AppColors.neutral700  // 正文文字
AppColors.neutral800  // 标题文字
AppColors.neutral900  // 主要文字
```

### 养老应用专用颜色

```dart
// 健康状态
AppColors.healthGood     // 健康良好 - 绿色
AppColors.healthWarning  // 需要注意 - 黄色
AppColors.healthDanger   // 危险状态 - 红色

// 紧急情况
AppColors.emergency      // 紧急颜色 - 深红
AppColors.emergencyBg    // 紧急背景 - 浅红

// 护理服务
AppColors.careBlue       // 医疗护理 - 蓝色
AppColors.careGreen      // 生活护理 - 绿色
AppColors.carePurple     // 康复护理 - 紫色

// 高对比度（适老化）
AppColors.highContrastText   // 高对比度文字 - 纯黑
AppColors.highContrastBg     // 高对比度背景 - 纯白
AppColors.highContrastAccent // 高对比度强调 - 深蓝
```

## 字体样式系统 (AppTextStyles)

### 标题样式

```dart
AppTextStyles.h1  // 32px, 粗体, 用于页面主标题
AppTextStyles.h2  // 28px, 半粗体, 用于章节标题
AppTextStyles.h3  // 24px, 半粗体, 用于小节标题
AppTextStyles.h4  // 20px, 半粗体, 用于卡片标题
AppTextStyles.h5  // 18px, 中等, 用于组件标题
AppTextStyles.h6  // 16px, 中等, 用于小标题
```

### 正文样式

```dart
AppTextStyles.bodyLarge   // 18px, 正文大号
AppTextStyles.bodyMedium  // 16px, 正文标准
AppTextStyles.bodySmall   // 14px, 正文小号
```

### 特殊用途样式

```dart
AppTextStyles.button      // 16px, 半粗体, 按钮文字
AppTextStyles.buttonLarge // 18px, 半粗体, 大按钮文字
AppTextStyles.caption     // 12px, 说明文字
AppTextStyles.overline    // 10px, 标签文字
```

### 适老化字体样式

```dart
AppTextStyles.elderlyH1        // 36px, 适老化标题
AppTextStyles.elderlyBodyLarge // 20px, 适老化正文
AppTextStyles.elderlyButton    // 20px, 适老化按钮
```

## 间距系统 (AppSpacing)

```dart
AppSpacing.xs    // 4px  - 最小间距
AppSpacing.sm    // 8px  - 小间距
AppSpacing.md    // 16px - 标准间距
AppSpacing.lg    // 24px - 大间距
AppSpacing.xl    // 32px - 超大间距
AppSpacing.xxl   // 48px - 特大间距
AppSpacing.xxxl  // 64px - 巨大间距
```

## 圆角系统 (AppBorderRadius)

```dart
AppBorderRadius.xs   // 4px  - 小圆角
AppBorderRadius.sm   // 8px  - 中小圆角
AppBorderRadius.md   // 12px - 标准圆角
AppBorderRadius.lg   // 16px - 大圆角
AppBorderRadius.xl   // 24px - 超大圆角
AppBorderRadius.full // 999px - 全圆角
```

## 使用示例

### 1. 基础文本样式

```dart
Text(
  '页面标题',
  style: AppTextStyles.h1.copyWith(color: AppColors.neutral900),
)

Text(
  '正文内容',
  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral700),
)
```

### 2. 自定义容器

```dart
Container(
  padding: EdgeInsets.all(AppSpacing.md),
  margin: EdgeInsets.symmetric(vertical: AppSpacing.sm),
  decoration: BoxDecoration(
    color: AppColors.neutral50,
    borderRadius: BorderRadius.circular(AppBorderRadius.md),
    border: Border.all(color: AppColors.neutral200),
  ),
  child: Text(
    '内容',
    style: AppTextStyles.bodyMedium,
  ),
)
```

### 3. 健康状态卡片

```dart
Container(
  padding: EdgeInsets.all(AppSpacing.md),
  decoration: BoxDecoration(
    color: AppColors.success50,
    borderRadius: BorderRadius.circular(AppBorderRadius.md),
    border: Border.all(color: AppColors.success500),
  ),
  child: Row(
    children: [
      Icon(
        Icons.favorite,
        color: AppColors.success500,
      ),
      SizedBox(width: AppSpacing.sm),
      Text(
        '健康状态良好',
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.success700,
        ),
      ),
    ],
  ),
)
```

### 4. 紧急按钮

```dart
ElevatedButton(
  onPressed: () {
    // 紧急呼叫逻辑
  },
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.emergency,
    foregroundColor: Colors.white,
    padding: EdgeInsets.symmetric(
      horizontal: AppSpacing.xl,
      vertical: AppSpacing.lg,
    ),
    textStyle: AppTextStyles.elderlyButton,
  ),
  child: Text('紧急呼叫'),
)
```

### 5. 适老化界面

```dart
Scaffold(
  backgroundColor: AppColors.highContrastBg,
  body: Padding(
    padding: EdgeInsets.all(AppSpacing.lg),
    child: Column(
      children: [
        Text(
          '适老化标题',
          style: AppTextStyles.elderlyH1.copyWith(
            color: AppColors.highContrastText,
          ),
        ),
        SizedBox(height: AppSpacing.xl),
        Text(
          '适老化正文内容，使用更大的字体和更高的对比度。',
          style: AppTextStyles.elderlyBodyLarge.copyWith(
            color: AppColors.highContrastText,
          ),
        ),
      ],
    ),
  ),
)
```

## 最佳实践

### 1. 颜色使用

- 使用语义化颜色名称，如 `AppColors.success500` 而不是直接的颜色值
- 为不同状态使用对应的功能色系
- 在深浅主题间保持一致的语义

### 2. 字体使用

- 遵循字体层级，不要跳级使用
- 适老化场景优先使用 `AppTextStyles.elderly*` 系列
- 保持行高和字间距的一致性

### 3. 间距使用

- 使用统一的间距系统，避免魔法数字
- 相关元素使用较小间距，不相关元素使用较大间距
- 保持垂直和水平间距的一致性

### 4. 养老应用特殊考虑

- 优先使用高对比度颜色组合
- 为视力不佳的用户提供大字体选项
- 紧急功能使用醒目的颜色和大尺寸

## 扩展指南

如需添加新的颜色或样式：

1. 在对应的类中添加新的静态常量
2. 遵循现有的命名规范
3. 更新文档和示例
4. 考虑深浅主题的兼容性

例如，添加新的功能色：

```dart
// 在 AppColors 类中添加
static const Color info50 = Color(0xFFE1F5FE);
static const Color info500 = Color(0xFF03DAC6);
static const Color info700 = Color(0xFF00ACC1);
```

## 暗黑模式适配

### 深色主题专用颜色

新的主题系统提供了完整的深色主题颜色支持：

```dart
// 深色主题品牌色（反转层级，更亮更饱和）
AppColors.darkPrimary50   // 最深
AppColors.darkPrimary500  // 深色主题主色（更亮）
AppColors.darkPrimary900  // 最浅

// 深色主题功能色（增强可见性）
AppColors.darkSuccess500  // 深色主题成功色
AppColors.darkWarning500  // 深色主题警告色
AppColors.darkError500    // 深色主题错误色

// 深色主题中性色（优化对比度）
AppColors.darkNeutral50   // 深色背景 (#121212)
AppColors.darkNeutral100  // 卡片背景 (#1E1E1E)
AppColors.darkNeutral900  // 主要文字 (#FAFAFA)

// 深色主题养老应用专用色
AppColors.darkHealthGood     // 深色主题健康良好
AppColors.darkEmergency      // 深色主题紧急颜色
AppColors.darkEmergencyBg    // 深色主题紧急背景
```

### 自适应颜色系统

使用 `AppAdaptiveColors` 类可以自动根据当前主题选择合适的颜色：

```dart
// 自适应颜色会根据当前主题自动选择
Container(
  color: AppAdaptiveColors.surface(context),  // 浅色模式用浅色，深色模式用深色
  child: Text(
    '自适应文字',
    style: TextStyle(
      color: AppAdaptiveColors.onSurface(context),  // 自动选择对比色
    ),
  ),
)

// 功能色自适应
Container(
  decoration: BoxDecoration(
    color: AppAdaptiveColors.success50(context),
    border: Border.all(
      color: AppAdaptiveColors.success500(context),
    ),
  ),
  child: Icon(
    Icons.check,
    color: AppAdaptiveColors.success500(context),
  ),
)
```

### 养老应用暗黑模式特色

```dart
// 健康状态在暗黑模式下的使用
Container(
  color: AppAdaptiveColors.healthGood(context),  // 自动适配深浅模式
  child: Text(
    '健康状态良好',
    style: TextStyle(color: Colors.white),
  ),
)

// 紧急按钮在暗黑模式下保持高可见性
ElevatedButton(
  onPressed: emergencyCall,
  style: ElevatedButton.styleFrom(
    backgroundColor: AppAdaptiveColors.emergency(context),
    foregroundColor: Colors.white,
  ),
  child: Text('紧急呼叫'),
)

// 高对比度适老化界面
Container(
  color: AppAdaptiveColors.highContrastBg(context),
  child: Text(
    '高对比度文字',
    style: AppTextStyles.elderlyH1.copyWith(
      color: AppAdaptiveColors.highContrastText(context),
    ),
  ),
)
```

### 暗黑模式最佳实践

1. **使用自适应颜色**
   - 优先使用 `AppAdaptiveColors` 而不是固定颜色
   - 避免硬编码颜色值

2. **保持对比度**
   - 深色主题中使用更亮的颜色确保可见性
   - 养老应用特别注意文字和背景的对比度

3. **测试两种模式**
   - 确保UI在浅色和深色模式下都表现良好
   - 特别测试紧急功能的可见性

4. **适老化考虑**
   - 深色模式下提供更高对比度选项
   - 保持大字体的清晰度

### 暗黑模式示例

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      // 使用自适应背景色
      color: AppAdaptiveColors.surface(context),
      padding: EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          // 标题使用自适应文字色
          Text(
            '标题',
            style: AppTextStyles.h3.copyWith(
              color: AppAdaptiveColors.onSurface(context),
            ),
          ),
          
          // 健康状态卡片
          Container(
            decoration: BoxDecoration(
              color: AppAdaptiveColors.healthGood(context).withOpacity(0.1),
              border: Border.all(
                color: AppAdaptiveColors.healthGood(context),
              ),
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
            ),
            child: ListTile(
              leading: Icon(
                Icons.favorite,
                color: AppAdaptiveColors.healthGood(context),
              ),
              title: Text(
                '健康状态良好',
                style: TextStyle(
                  color: AppAdaptiveColors.healthGood(context),
                ),
              ),
            ),
          ),
          
          // 紧急按钮
          Container(
            width: double.infinity,
            margin: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: ElevatedButton(
              onPressed: () => _handleEmergency(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppAdaptiveColors.emergency(context),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                textStyle: AppTextStyles.elderlyButton,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emergency, size: 24),
                  SizedBox(width: AppSpacing.sm),
                  Text('紧急呼叫'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _handleEmergency() {
    // 紧急呼叫逻辑
  }
}
```
