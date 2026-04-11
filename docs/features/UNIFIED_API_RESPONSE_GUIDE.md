# 统一API响应处理使用指南

## 概述

本项目实现了统一的API响应处理机制，通过`BaseAPI`抽象类和`ApiResponseHandler`工具类，大幅简化了API调用代码，提高了代码的一致性和可维护性。

## 核心组件

### 1. BaseAPI 抽象类

`BaseAPI`是所有API类的基类，提供了统一的响应处理方法：

- `handleApiCall<T>()` - 处理返回单个对象的API调用
- `handleApiListCall<T>()` - 处理返回列表数据的API调用  
- `handleApiVoidCall()` - 处理无返回数据的API调用
- `handlePaginatedApiCall<T>()` - 处理分页数据的API调用

### 2. ApiResponseHandler 工具类

提供专门的响应处理方法：

- `handleBooleanResponse()` - 处理布尔响应
- `handleStringResponse()` - 处理字符串响应
- `handleIntResponse()` - 处理数字响应
- `handleRawResponse<T>()` - 处理原始响应数据
- `handleFileUploadResponse()` - 处理文件上传响应
- `handleBatchResponse<T>()` - 处理批量操作响应

## 使用方法

### 1. 创建API类

所有API类都应该继承`BaseAPI`并使用`@Injectable()`注解：

```dart
@Injectable()
class UserAPI extends BaseAPI {
  UserAPI(ApiClient apiClient) : super(apiClient);

  // API方法实现...
}
```

### 2. 实现API方法

#### 获取单个对象

```dart
Future<Either<Failure, User>> getCurrentUser() async {
  return handleApiCall(
    apiClient.get('/user/profile'),
    User.fromJson,
    logTag: 'UserAPI.getCurrentUser',
  );
}
```

#### 获取对象列表

```dart
Future<Either<Failure, List<User>>> getUserList() async {
  return handleApiListCall(
    apiClient.get('/users'),
    User.fromJson,
    logTag: 'UserAPI.getUserList',
  );
}
```

#### 创建/更新对象

```dart
Future<Either<Failure, User>> createUser(CreateUserRequest request) async {
  return handleApiCall(
    apiClient.post('/users', data: request.toJson()),
    User.fromJson,
    logTag: 'UserAPI.createUser',
  );
}
```

#### 删除操作（无返回数据）

```dart
Future<Either<Failure, void>> deleteUser(String id) async {
  return handleApiVoidCall(
    apiClient.delete('/users/$id'),
    logTag: 'UserAPI.deleteUser',
  );
}
```

#### 分页数据

```dart
Future<Either<Failure, PaginatedResponse<User>>> getUsersPaginated({
  int page = 1,
  int pageSize = 10,
}) async {
  return handlePaginatedApiCall(
    apiClient.get('/users/paginated', queryParameters: {
      'page': page,
      'page_size': pageSize,
    }),
    User.fromJson,
    logTag: 'UserAPI.getUsersPaginated',
  );
}
```

### 3. 使用ApiResponseHandler

对于特殊响应格式，可以直接使用`ApiResponseHandler`：

```dart
Future<Either<Failure, bool>> changePassword({
  required String oldPassword,
  required String newPassword,
}) async {
  final response = await apiClient.post<Map<String, dynamic>>(
    '/user/change-password',
    data: {
      'old_password': oldPassword,
      'new_password': newPassword,
    },
  );
  
  return ApiResponseHandler.handleBooleanResponse(response);
}

Future<Either<Failure, String>> getToken() async {
  final response = await apiClient.get<Map<String, dynamic>>('/auth/token');
  return ApiResponseHandler.handleStringResponse(response, dataKey: 'token');
}
```

## 代码对比

### 重构前（旧代码）

```dart
Future<Either<Failure, User>> getCurrentUser() async {
  try {
    final response = await _apiClient.get('/user/profile');

    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json! as Map<String, dynamic>,
    );

    if (apiResponse.isSuccess && apiResponse.hasData) {
      final user = User.fromJson(apiResponse.data!);
      return Right(user);
    } else {
      return Left(ServerFailure(message: apiResponse.message));
    }
  } on AppException catch (e) {
    return Left(mapExceptionToFailure(e));
  } catch (e) {
    return Left(UnknownFailure(message: e.toString()));
  }
}
```

### 重构后（新代码）

```dart
Future<Either<Failure, User>> getCurrentUser() async {
  return handleApiCall(
    apiClient.get('/user/profile'),
    User.fromJson,
    logTag: 'UserAPI.getCurrentUser',
  );
}
```

## 优势

### 1. 代码简化

- 原来30-40行的API方法现在只需要5-8行
- 消除了重复的错误处理和响应解析代码

### 2. 一致性

- 所有API调用使用统一的错误处理机制
- 统一的日志记录格式

### 3. 类型安全

- 利用泛型确保类型安全
- 编译时检查数据转换

### 4. 可维护性

- 错误处理逻辑集中管理
- 易于添加新的响应处理类型

### 5. 可测试性

- 更容易进行单元测试
- Mock更加简单

## 扩展指南

### 添加新的响应处理类型

如果需要处理新的响应格式，可以在`ApiResponseHandler`中添加新方法：

```dart
static Either<Failure, CustomType> handleCustomResponse(
  Response<dynamic> response,
) {
  try {
    // 自定义处理逻辑
    return Right(customData);
  } catch (e) {
    return Left(ServerFailure(message: '自定义响应处理失败: $e'));
  }
}
```

### 添加新的BaseAPI方法

如果有特殊的API调用模式，可以在`BaseAPI`中添加新的处理方法：

```dart
Future<Either<Failure, T>> handleSpecialApiCall<T>(
  Future<Response<dynamic>> apiCall,
  T Function(Map<String, dynamic>) fromJson, {
  String? logTag,
}) async {
  // 特殊处理逻辑
}
```

## 最佳实践

1. **始终使用logTag** - 便于调试和监控
2. **合理选择处理方法** - 根据API返回格式选择合适的处理方法
3. **统一错误处理** - 在Service层统一处理业务逻辑错误
4. **类型安全** - 确保fromJson函数的类型正确性
5. **文档注释** - 为API方法添加清晰的文档注释

## 示例项目

参考`lib/shared/apis/example_api.dart`文件，其中包含了各种API调用场景的完整示例。

## 总结

统一的API响应处理机制显著提升了项目的代码质量和开发效率。通过这套机制，开发者可以专注于业务逻辑，而不需要重复编写样板代码。
