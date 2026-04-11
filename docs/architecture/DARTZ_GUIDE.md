# Dartz 使用指南

## 📖 简介

dartz 是一个为 Dart 语言提供函数式编程概念的包，它将 Haskell 和 Scala 等函数式语言的核心概念引入到 Dart 中。在我们的 Flutter 项目中，dartz 主要用于优雅地处理错误和实现类型安全的异步操作。

## 🎯 核心概念

### 1. Either<L, R>

`Either` 是 dartz 最重要的类型，它表示一个值要么是左边的类型 L（通常表示错误），要么是右边的类型 R（通常表示成功的结果）。

```dart
// 基本语法
Either<String, int> divide(int a, int b) {
  if (b == 0) {
    return Left('除数不能为零'); // 错误情况
  }
  return Right(a ~/ b); // 成功情况
}

// 使用 fold 方法处理结果
final result = divide(10, 2);
result.fold(
  (error) => print('错误: $error'),
  (value) => print('结果: $value'),
);
```

### 2. Option<T>

`Option` 类型用于处理可能为空的值，避免空指针异常。

```dart
// 使用 Option 替代可空类型
Option<String> findUserName(String id) {
  final user = users.firstWhere((u) => u.id == id, orElse: () => null);
  return optionOf(user?.name);
}

// 处理 Option
final nameOption = findUserName('123');
nameOption.fold(
  () => print('用户不存在'),
  (name) => print('用户名: $name'),
);
```

## 🔧 在项目中的应用

### 1. 错误处理架构

我们的项目使用 dartz 构建了完整的错误处理架构：

```dart
// lib/core/errors/failures.dart
abstract class Failure extends Equatable {
  final String message;
  final int? code;
  
  const Failure({
    required this.message,
    this.code,
  });
}

class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    super.code,
  });
}

class NetworkFailure extends Failure {
  const NetworkFailure({
    required super.message,
    super.code,
  });
}
```

### 2. 服务层实现

在服务层中使用 `Either<Failure, T>` 来处理所有可能的错误情况：

```dart
// lib/features/auth/domain/repositories/auth_repository.dart
abstract class AuthRepository {
  /// 手机号登录（请求体由 Provider 组装为 PhoneLoginRequest）
  Future<Either<Failure, AuthInfo>> phoneLogin(PhoneLoginRequest request);

  /// 获取当前用户信息
  Future<Either<Failure, CurrentUserInfoModel>> getCurrentUser();

  /// 登出
  Future<Either<Failure, void>> logout();
}

// lib/features/auth/data/repositories/auth_repository_impl.dart
@Singleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remoteDataSource);
  final UserRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, AuthInfo>> phoneLogin(PhoneLoginRequest request) async {
    try {
      final response = await _remoteDataSource.phoneLogin(request);
      return Right(response);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(
        message: e.message,
        code: e.code,
      ));
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        code: e.code,
      ));
    } catch (e) {
      return Left(UnknownFailure(
        message: '未知错误: ${e.toString()}',
      ));
    }
  }
}
```

## 🎨 与 Riverpod 集成

**架构约定**：Repository 方法统一返回 `Either<Failure, T>`。**Presentation 层 Provider 统一直接调用 `getIt<XxxRepository>()`**，不使用 UseCase 层。参数校验、请求组装、简单编排等业务逻辑在 Provider 中内联完成（例如登录：校验手机号与验证码后组装 `PhoneLoginRequest`，再调用 `_authRepository.phoneLogin(request)`）。

### 1. 在 Provider 中使用 Either

```dart
@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  AsyncValue<User?> build() {
    return const AsyncValue.loading();
  }

  Future<void> phoneLogin(String phonenumber, String smsCode) async {
    state = const AsyncValue.loading();

    final phone = phonenumber.trim();
    final phoneErrMsg = ValidatorsCheck.checkPhoneNumber(phone);
    if (ValidatorsCheck.hasError(phoneErrMsg)) {
      state = AsyncValue.error(phoneErrMsg!, StackTrace.current);
      return;
    }

    final code = smsCode.trim();
    final codeErrMsg = ValidatorsCheck.checkSMSCode(code);
    if (ValidatorsCheck.hasError(codeErrMsg)) {
      state = AsyncValue.error(codeErrMsg!, StackTrace.current);
      return;
    }

    final request = PhoneLoginRequest(
      clientId: AppConfig.clientId,
      grantType: 'sms',
      phonenumber: phone,
      smsCode: code,
    );

    final result = await getIt<AuthRepository>().phoneLogin(request);

    result.fold(
      (failure) {
        state = AsyncValue.error(failure, StackTrace.current);
      },
      (authInfo) {
        state = AsyncValue.data(authInfo);
      },
    );
  }
}
```

### 2. 在 UI 中使用

```dart
class LoginPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    
    return Scaffold(
      body: Column(
        children: [
          // 登录表单
          ElevatedButton(
            onPressed: () async {
              // 通过 Notifier 调用登录
              await ref.read(authProvider.notifier).phoneLogin(
                    phonenumber: phone,
                    smsCode: smsCode,
                  );
            },
            child: Text('登录'),
          ),
        ],
      ),
    );
  }
}
```

## 🔄 常用操作

### 1. 链式操作

```dart
// map - 转换成功的值
final result = await getUserById(id);
final nameResult = result.map((user) => user.name);

// flatMap - 链式异步操作
Future<Either<Failure, String>> getUserDisplayName(String id) async {
  final userResult = await getUserById(id);
  
  return userResult.fold(
    (failure) => Left(failure),
    (user) async {
      if (user.name.isNotEmpty) {
        return Right(user.name);
      } else {
        return Right('用户${user.id}');
      }
    },
  );
}
```

### 2. 错误转换

```dart
// 将异常转换为 Failure
Either<Failure, T> handleException<T>(T Function() operation) {
  try {
    return Right(operation());
  } on NetworkException catch (e) {
    return Left(NetworkFailure(message: e.message));
  } on ServerException catch (e) {
    return Left(ServerFailure(message: e.message));
  } catch (e) {
    return Left(UnknownFailure(message: e.toString()));
  }
}
```

### 3. 批量操作

```dart
// 处理多个异步操作
Future<Either<Failure, List<User>>> getMultipleUsers(
  List<String> userIds,
) async {
  final List<Either<Failure, User>> results = [];
  
  for (final id in userIds) {
    final result = await getUserById(id);
    results.add(result);
  }
  
  // 检查是否有任何失败
  final failures = results.where((r) => r.isLeft()).toList();
  if (failures.isNotEmpty) {
    return Left(failures.first.fold((f) => f, (_) => throw StateError('不可能')));
  }
  
  // 提取所有成功的结果
  final users = results.map((r) => r.fold((_) => throw StateError('不可能'), (u) => u)).toList();
  return Right(users);
}
```

## 🛠️ 实用扩展

创建一些有用的扩展方法来简化 dartz 的使用：

```dart
// lib/core/extensions/either_extensions.dart
extension EitherExtensions<L, R> on Either<L, R> {
  /// 获取右侧值，如果是左侧则返回 null
  R? get rightOrNull => fold((_) => null, (r) => r);
  
  /// 获取左侧值，如果是右侧则返回 null
  L? get leftOrNull => fold((l) => l, (_) => null);
  
  /// 是否是成功结果
  bool get isRight => fold((_) => false, (_) => true);
  
  /// 是否是失败结果
  bool get isLeft => fold((_) => true, (_) => false);
  
  /// 当是右侧值时执行操作
  Either<L, R> onRight(void Function(R) action) {
    return fold(
      (l) => Left(l),
      (r) {
        action(r);
        return Right(r);
      },
    );
  }
  
  /// 当是左侧值时执行操作
  Either<L, R> onLeft(void Function(L) action) {
    return fold(
      (l) {
        action(l);
        return Left(l);
      },
      (r) => Right(r),
    );
  }
}

extension FutureEitherExtensions<L, R> on Future<Either<L, R>> {
  /// 异步 map 操作
  Future<Either<L, T>> mapAsync<T>(Future<T> Function(R) mapper) async {
    final result = await this;
    return result.fold(
      (l) => Left(l),
      (r) async => Right(await mapper(r)),
    );
  }
}
```

## 📋 最佳实践

### 1. 错误类型设计

- 为不同的业务场景定义特定的 Failure 类型
- 保持 Failure 类型的层次结构清晰
- 包含足够的错误信息用于调试和用户提示

### 2. API 设计

- 所有可能失败的操作都应该返回 `Either<Failure, T>`
- 保持接口的一致性，避免混用异常和 Either
- 在领域层和应用层之间使用 Either 进行错误传递

### 3. UI 处理

- 在 UI 层将 Either 转换为用户友好的提示
- 使用 Riverpod 的 AsyncValue 来管理异步状态
- 提供加载状态和错误状态的 UI 反馈

### 4. 测试

```dart
// 测试 Either 返回值
test('should return Right when login succeeds', () async {
  // Arrange
  when(mockApiClient.post(any, data: anyNamed('data')))
      .thenAnswer((_) async => Response(
            data: {'success': true, 'data': userJson},
            statusCode: 200,
          ));

  // Act
  final result = await authRepository.phoneLogin(
    PhoneLoginRequest(
      clientId: '...',
      grantType: 'sms',
      phonenumber: '13800138000',
      smsCode: '123456',
    ),
  );

  // Assert
  expect(result.isRight, true);
  expect(result.rightOrNull, isA<AuthInfo>());
});

test('should return Left when network fails', () async {
  // Arrange
  when(mockDataSource.phoneLogin(any)).thenThrow(
    NetworkException('网络连接失败'),
  );

  // Act
  final result = await authRepository.phoneLogin(
    PhoneLoginRequest(
      clientId: '...',
      grantType: 'sms',
      phonenumber: '13800138000',
      smsCode: '123456',
    ),
  );

  // Assert
  expect(result.isLeft, true);
  expect(result.leftOrNull, isA<NetworkFailure>());
});
```

## ⚠️ 注意事项

### 1. 性能考虑

- Either 创建了额外的对象，但在大多数情况下性能影响可以忽略
- 避免在紧密循环中频繁创建 Either 对象

### 2. 学习曲线

- 团队成员需要熟悉函数式编程概念
- 初期可能会增加代码复杂度，但长期来看会提高代码质量

### 3. 与现有代码集成

- 逐步引入 dartz，不要一次性重构所有代码
- 在新功能中优先使用 Either
- 为现有的异常处理代码提供适配器

## 📚 参考资源

- [dartz 官方文档](https://pub.dev/packages/dartz)
- [函数式编程概念](https://en.wikipedia.org/wiki/Functional_programming)
- [Either 类型的数学基础](https://en.wikipedia.org/wiki/Tagged_union)

## 🔗 相关文档

- [错误处理最佳实践](./ERROR_HANDLING_GUIDE.md)
- [Riverpod 使用指南](./RIVERPOD_GUIDE.md)
- [API 设计规范](./API_DESIGN_GUIDE.md)

---

*最后更新: 2026年3月*
