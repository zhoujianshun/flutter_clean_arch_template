# Clean Architecture 两种模式：标准型 vs 务实型

本模板内置两个示例功能模块，分别演示不同规模项目适用的架构模式。

## 速查对比

| 维度 | 标准型 `_example` | 务实型 `_example_simple` |
|------|-------------------|-------------------------|
| **适用场景** | 大型项目 / 多人协作 / 长期维护 | 小型项目 / 快速迭代 / MVP |
| **DTO ↔ Entity** | 分离（`ExampleItemDto` + `ExampleItem`） | 合一（`TodoModel` 直接共用） |
| **Mapper** | 有（`example_mapper.dart`） | 无 |
| **DataSource** | 继承 `BaseAPI`，调用真实 API | 继承 `BaseAPI`，调用真实 API |
| **Repository 职责** | 调用 DataSource + DTO→Entity 转换 + 日志 | 透传 DataSource 返回值 |
| **Domain 层依赖** | 仅依赖自己的 Entity + 共享类型 | 可引用 Data 层 Model（务实做法） |
| **文件数量** | 多（≈10 个源文件） | 少（≈7 个源文件） |
| **样板代码** | 较多 | 较少 |
| **可测试性** | 高（每层独立 mock） | 中（Repository 较薄，测试集中在 DataSource） |
| **扩展性** | 高（可独立演进 API 与业务模型） | 中（API 变化直接影响 UI） |

## 标准型：`_example`（推荐用于大型项目）

### 目录结构

```text
features/_example/
├── data/
│   ├── datasources/
│   │   └── example_remote_datasource.dart   ← 继承 BaseAPI，发起 HTTP 请求
│   ├── models/
│   │   ├── example_item_dto.dart            ← API 响应 DTO（字段对齐 JSON）
│   │   ├── example_mapper.dart              ← DTO → Entity 映射扩展
│   │   └── get_example_list_request.dart    ← 请求参数模型
│   └── repositories/
│       └── example_repository_impl.dart     ← Repository 实现（转换 + 编排）
├── domain/
│   ├── entities/
│   │   └── example_item.dart                ← 纯领域实体（业务友好类型）
│   └── repositories/
│       └── example_repository.dart          ← Repository 接口
└── presentation/
    ├── pages/
    │   ├── example_list_page.dart
    │   └── example_detail_page.dart
    └── providers/
        ├── example_list_provider.dart
        └── example_detail_provider.dart
```

### 数据流

```text
API JSON
  │
  ▼
ExampleRemoteDataSource (BaseAPI)
  │  返回 Either<Failure, PaginatedData<ExampleItemDto>>
  ▼
ExampleRepositoryImpl
  │  DTO → Entity 转换（ExampleItemDtoMapper）
  │  返回 Either<Failure, PaginatedData<ExampleItem>>
  ▼
Provider (@riverpod)
  │  fold: Left → throw Failure, Right → state = data
  ▼
Widget (ConsumerWidget)
  │  asyncValue.when(data/loading/error)
  ▼
UI
```

### 核心特点

1. **DTO / Entity 分离**：`ExampleItemDto` 的 `createdAt` 是 `String`（对齐 API），`ExampleItem` 的 `createdAt` 是 `DateTime`（业务友好）
2. **Mapper 层**：`example_mapper.dart` 中的扩展方法完成类型转换
3. **DataSource 继承 BaseAPI**：获得统一的错误处理、日志、CancelToken 能力
4. **Request 模型**：`GetExampleListRequest` 封装请求参数，DataSource 调用 `request.toJson()`
5. **Repository 有真实逻辑**：转换、日志、可能的缓存策略
6. **详情页使用独立 Provider**：`exampleDetailProvider(id)` 带参数，支持缓存与失效

### 何时选择标准型

- API 响应字段名与业务语义不一致（snake_case vs camelCase、String 时间 vs DateTime）
- 需要聚合多个 API 响应为一个业务对象
- 团队多人协作，需要清晰的层级边界
- 项目预计长期维护，API 可能频繁变化

---

## 务实型：`_example_simple`（推荐用于小型项目）

### 目录结构

```text
features/_example_simple/
├── data/
│   ├── datasources/
│   │   └── todo_remote_datasource.dart      ← 继承 BaseAPI
│   ├── models/
│   │   └── todo_model.dart                  ← Model 直接共用（API + 业务）
│   └── repositories/
│       └── todo_repository_impl.dart        ← 薄 Repository（直接透传）
├── domain/
│   └── repositories/
│       └── todo_repository.dart             ← 接口（引用 Data 层 Model）
└── presentation/
    ├── pages/
    │   └── todo_list_page.dart
    └── providers/
        └── todo_list_provider.dart
```

### 数据流

```text
API JSON
  │
  ▼
TodoRemoteDataSource (BaseAPI)
  │  返回 Either<Failure, List<TodoModel>>
  ▼
TodoRepositoryImpl
  │  直接透传（无转换）
  │  返回 Either<Failure, List<TodoModel>>
  ▼
Provider (@riverpod)
  │  fold: Left → throw, Right → state = data
  ▼
Widget → UI
```

### 核心特点

1. **Model 共用**：`TodoModel` 同时是 API DTO 和业务模型，`@JsonKey` 处理字段映射
2. **无 Mapper**：省去转换步骤，减少样板代码
3. **Domain 引用 Data Model**：Repository 接口直接使用 `TodoModel`（务实做法）
4. **薄 Repository**：直接委托给 DataSource，无额外逻辑
5. **无独立 Entity 目录**：`domain/` 下只有 `repositories/`
6. **CRUD 完整**：包含 create/delete 操作示例

### 何时选择务实型

- API 字段与业务模型高度一致，无需转换
- 小团队或个人项目，追求开发速度
- MVP / 原型阶段，架构可后续演进
- 功能简单，无复杂聚合需求

---

## 从务实型升级到标准型

当项目规模增长，可按以下步骤渐进升级：

1. **引入 Entity**：在 `domain/entities/` 创建纯领域模型
2. **重命名 Model → DTO**：将 `todo_model.dart` 改为 `todo_dto.dart`
3. **创建 Mapper**：添加 DTO → Entity 的扩展方法
4. **更新 Repository**：在实现中调用 Mapper 转换
5. **更新 Provider/Widget**：引用 Entity 而非 Model

这种渐进式升级不影响已有功能，每一步都可独立提交和测试。

---

## 选择决策树

```text
新功能模块
  │
  ├─ API 响应与 UI 需求一致？
  │   ├─ 是 → 务实型（_example_simple）
  │   └─ 否 → 需要转换
  │         │
  │         ├─ 多个 API 需聚合？
  │         │   └─ 是 → 标准型 + 独立 Entity
  │         │
  │         └─ 仅字段名/类型不同？
  │             └─ 标准型 + Mapper
  │
  └─ 项目规模？
      ├─ 大型 / 多人 / 长期 → 标准型
      └─ 小型 / 个人 / MVP → 务实型
```

> **建议**：同一项目中可混用两种模式。核心功能用标准型，辅助功能用务实型。
