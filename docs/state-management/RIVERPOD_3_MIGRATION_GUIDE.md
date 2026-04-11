# Riverpod 3.0+ 迁移指南

## 📖 概述

本指南帮助你将项目从旧版 Riverpod API 迁移到 Riverpod 3.0+ 的现代化 API。新版本引入了 `@riverpod` 注解和 `Notifier` 类，提供更好的类型安全性和开发体验。

## 🎯 主要变化

### 1. StateNotifierProvider → NotifierProvider

**旧版本 (Riverpod 2.x)**:

```dart
class CounterNotifier extends StateNotifier<int> {
  CounterNotifier() : super(0);
  
  void increment() => state++;
}

final counterProvider = StateNotifierProvider<CounterNotifier, int>(
  (ref) => CounterNotifier(),
);
```

**新版本 (Riverpod 3.0+)**:

```dart
@riverpod
class Counter extends _$Counter {
  @override
  int build() => 0;
  
  void increment() => state++;
}

// 或者使用传统方式（向后兼容）
final counterProvider = NotifierProvider<CounterNotifier, int>(
  () => CounterNotifier(),
);
```

### 2. StateProvider → @riverpod Notifier

**旧版本**:

```dart
final searchQueryProvider = StateProvider<String>((ref) => '');

// 使用
ref.read(searchQueryProvider.notifier).state = 'new value';
```

**新版本**:

```dart
@riverpod
class SearchQuery extends _$SearchQuery {
  @override
  String build() => '';
  
  void update(String value) => state = value;
}

// 使用
ref.read(searchQueryProvider.notifier).update('new value');
```

### 3. FutureProvider → @riverpod

**旧版本**:

```dart
final userProvider = FutureProvider<User>((ref) async {
  return await api.getUser();
});
```

**新版本**:

```dart
@riverpod
Future<User> user(Ref ref) async {
  return await api.getUser();
}

// 带参数
@riverpod
Future<User> userById(Ref ref, String id) async {
  return await api.getUser(id);
}
```

### 4. Provider → @riverpod

**旧版本**:

```dart
final configProvider = Provider<Config>((ref) {
  return Config.fromEnvironment();
});
```

**新版本**:

```dart
@riverpod
Config config(Ref ref) {
  return Config.fromEnvironment();
}
```

## 🔧 迁移步骤

### 步骤 1: 添加必要的依赖

```yaml
dependencies:
  flutter_riverpod: ^3.0.0
  riverpod_annotation: ^3.0.0

dev_dependencies:
  build_runner: ^2.4.0
  riverpod_generator: ^3.0.0
```

### 步骤 2: 添加代码生成配置

在需要使用 `@riverpod` 注解的文件顶部添加：

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'your_file.g.dart';
```

### 步骤 3: 运行代码生成

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 步骤 4: 逐步迁移 Provider

1. **从简单的 Provider 开始**
2. **迁移 StateProvider**
3. **迁移 StateNotifierProvider**
4. **迁移 FutureProvider**
5. **更新 UI 代码**

## 📋 迁移检查清单

### Provider 迁移

- [ ] 识别所有需要迁移的 Provider
- [ ] 添加 `@riverpod` 注解
- [ ] 更新类继承关系
- [ ] 运行代码生成
- [ ] 测试功能正常

### UI 代码更新

- [ ] 更新 Provider 引用
- [ ] 修改状态更新调用
- [ ] 测试 UI 响应正常

### 测试更新

- [ ] 更新单元测试
- [ ] 更新 Widget 测试
- [ ] 验证测试通过

## 🚨 常见问题与解决方案

### 1. "The function 'StateNotifierProvider' isn't defined"

**问题**: 使用了已废弃的 `StateNotifierProvider`

**解决方案**:

```dart
// 替换为
final provider = NotifierProvider<MyNotifier, MyState>(() => MyNotifier());
```

### 2. "The member 'state' can only be used within instance members"

**问题**: 在外部直接访问 `state` 属性

**解决方案**:

```dart
// 错误
ref.read(provider.notifier).state = newValue;

// 正确
ref.read(provider.notifier).updateValue(newValue);
```

### 3. 代码生成失败

**问题**: `part` 文件未找到或生成失败

**解决方案**:

1. 确保添加了 `part 'filename.g.dart';`
2. 运行 `dart run build_runner clean`
3. 重新运行 `dart run build_runner build`

### 4. Provider 类型推断失败

**问题**: TypeScript 风格的类型推断问题

**解决方案**: 明确指定类型

```dart
@riverpod
class MyNotifier extends _$MyNotifier {
  @override
  MyState build() => const MyState();
}
```

## 🎨 最佳实践

### 1. 使用 @riverpod 注解（推荐）

```dart
@riverpod
class UserProfile extends _$UserProfile {
  @override
  Future<User> build(String userId) async {
    return await userRepository.getUser(userId);
  }
  
  Future<void> updateName(String name) async {
    state = const AsyncValue.loading();
    try {
      final user = await userRepository.updateName(userId, name);
      state = AsyncValue.data(user);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
```

### 2. 合理使用 keepAlive

```dart
// 全局状态，需要保持活跃
@Riverpod(keepAlive: true)
class AppConfig extends _$AppConfig {
  // ...
}

// 页面级状态，可以自动销毁
@riverpod
class PageData extends _$PageData {
  // ...
}
```

### 3. 参数化 Provider

```dart
@riverpod
Future<List<Post>> userPosts(Ref ref, String userId) async {
  return await postRepository.getUserPosts(userId);
}

// 使用
final posts = ref.watch(userPostsProvider('user123'));
```

## 🔄 向后兼容性

新版本保持向后兼容，你可以：

1. **渐进式迁移**: 新代码使用新 API，旧代码保持不变
2. **混合使用**: 在同一项目中同时使用新旧 API
3. **按模块迁移**: 按功能模块逐步迁移

### 迁移完成状态

所有 Provider 已迁移到 `@riverpod` 注解方式：

| 文件 | Provider | 说明 |
|------|----------|------|
| `lib/core/theme/theme_mode_provider.dart` | `appThemeModeProvider` (`@Riverpod(keepAlive: true) class AppThemeMode`) | 主题模式管理 |
| `lib/core/l10n/language_provider.dart` | `appLanguageSettingProvider` (`@Riverpod(keepAlive: true) class AppLanguageSetting`) | 语言配置管理 |
| `lib/core/l10n/language_provider.dart` | `appLocaleProvider` (`@Riverpod(keepAlive: true) Locale appLocale(Ref ref)`) | 当前 Locale |

## 📈 迁移收益

### 性能提升

- 更好的代码生成优化
- 减少运行时开销
- 更精确的重建控制

### 开发体验

- 更好的类型安全性
- IDE 支持更完善
- 更清晰的错误信息

### 代码质量

- 更简洁的代码
- 更好的可测试性
- 更清晰的依赖关系

## 📚 相关资源

- [Riverpod 官方迁移指南](https://riverpod.dev/docs/migration)
- [代码生成文档](https://riverpod.dev/docs/concepts/about_code_generation)
- [最佳实践文档](./FLUTTER_RIVERPOD_BEST_PRACTICES.md)

## 🤝 获得帮助

如果在迁移过程中遇到问题：

1. 查看官方文档和示例
2. 检查 GitHub Issues
3. 在项目中搜索类似的迁移案例
4. 寻求团队成员帮助

---

**记住**: 迁移是一个渐进的过程，不需要一次性完成所有迁移。优先迁移新功能，然后逐步优化现有代码。
