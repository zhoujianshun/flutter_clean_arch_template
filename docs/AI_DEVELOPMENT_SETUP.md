# AI 辅助开发配置说明

本项目已配置完整的 AI 辅助开发工具链，包含 Cursor Rules、Skills 和 MCP Server，帮助 AI 在编码、调试、审查等环节提供更精准的协助。

---

## 目录结构

```
.cursor/
├── mcp.json                          # MCP Server 配置
├── rules/                            # Cursor Rules（AI 行为规则）
│   ├── project-zh.mdc               # 项目架构规范（中文，始终生效）
│   ├── project.mdc                  # 项目架构规范（英文，手动触发）
│   ├── flutter-official.mdc         # Flutter 官方最佳实践（.dart 文件触发）
│   └── riper-5-cn.mdc              # RIPER-5 开发流程协议（手动触发）
├── skills/                           # Cursor Skills（按需加载的专项能力）
│   ├── riverpod/SKILL.md           # Riverpod 状态管理
│   ├── effective-dart/SKILL.md     # Effective Dart 编码规范
│   ├── architecture-feature-first/SKILL.md  # Feature-First 架构
│   ├── testing/SKILL.md            # 测试最佳实践
│   ├── code-review/SKILL.md        # 代码审查流程
│   ├── dart-3-updates/SKILL.md     # Dart 3 新特性
│   └── accessibility/SKILL.md      # 无障碍设计
.tools/
└── flutter-devtools-mcp/             # Flutter DevTools MCP Server（本地安装）
```

---

## 一、Cursor Rules（规则）

Rules 是始终或按条件注入给 AI 的指令，确保生成的代码符合项目约定。

### 已配置规则

| 规则文件 | 触发方式 | 用途 |
|----------|----------|------|
| `project-zh.mdc` | **始终生效** | 项目架构、技术栈、命名规范、核心模式 |
| `flutter-official.mdc` | 编辑 `.dart` 文件时 | Flutter/Dart 官方最佳实践 |
| `riper-5-cn.mdc` | 手动触发 | RIPER-5 五阶段开发流程控制 |
| `project.mdc` | 手动触发 | 项目规范英文版（备用） |

### 使用方法

- `project-zh.mdc` 无需操作，会自动附加到每次对话中
- `flutter-official.mdc` 在编辑 Dart 文件时自动生效
- `riper-5-cn.mdc` 在对话中输入 `@riper-5-cn` 或要求 AI 进入 RIPER 模式时使用

---

## 二、Cursor Skills（技能）

Skills 是 AI 在判断任务相关时按需加载的专项知识模块，不消耗常规 token 预算。

### 已安装技能

| 技能 | 描述 | 触发场景 |
|------|------|----------|
| **riverpod** | Riverpod 3.0 状态管理全套模式 | 编写 Provider、状态管理、测试 Provider |
| **effective-dart** | Effective Dart 编码规范 | 代码风格审查、命名、文档注释 |
| **architecture-feature-first** | Feature-First 分层架构 | 创建新功能模块、设计目录结构 |
| **testing** | 单元测试 & Widget 测试 | 编写测试、提升覆盖率 |
| **code-review** | 代码审查清单 | 审查 PR、评估代码质量 |
| **dart-3-updates** | Dart 3 新特性 | 使用 sealed class、pattern matching、records |
| **accessibility** | 无障碍设计（WCAG） | UI 可访问性优化 |

### 使用方法

Skills 由 AI 自动判断是否加载，也可通过 `@skills/riverpod` 等方式手动引用。

示例提示：
- "帮我创建一个新的 feature 模块" → 自动加载 `architecture-feature-first`
- "审查一下这个 PR 的代码" → 自动加载 `code-review`
- "写一下这个 Repository 的单元测试" → 自动加载 `testing`

---

## 三、MCP Server（工具服务器）

MCP 让 AI 不仅能读写代码，还能直接操作开发工具。

### 已配置 MCP Server

#### 1. Dart & Flutter MCP Server（官方）

**来源：** Flutter 团队官方  
**启动：** 自动随 Cursor 启动

| 能力 | 说明 |
|------|------|
| 热重载/热重启 | 无需手动操作终端 |
| Widget Inspector | 检查组件树 |
| 运行测试 | 执行 `dart test` |
| 依赖管理 | 分析/添加/移除 pubspec.yaml 依赖 |
| 代码格式化 | `dart format` |
| Flutter Driver | 运行集成测试 |

**使用方法：** 启动 Flutter 应用后，AI 可以直接执行热重载、查看 widget 树等操作。

#### 2. Flutter DevTools MCP Server

**来源：** 社区 (draganbajic/flutter-devtools-mcp)  
**安装位置：** `.tools/flutter-devtools-mcp/`

| 能力 | 说明 |
|------|------|
| 自动发现应用 | 扫描运行中的 Flutter 应用 |
| Widget 重建追踪 | 定位频繁重建的组件 |
| 性能分析 | 帧率分析、卡顿检测、CPU 热点 |
| 内存分析 | 堆快照、泄漏检测、前后对比 |
| 网络抓包 | HTTP 请求/响应捕获 |
| 调试操作 | 截图、debug paint、表达式求值 |

**使用方法：**

1. 以 debug 或 profile 模式运行应用：
   ```bash
   flutter run --profile
   ```

2. 让 AI 连接应用：
   > "找到运行中的 Flutter 应用并连接"

3. 使用调试功能：
   > "追踪 widget 重建，我滚动一下列表"  
   > "拍个内存快照，我修复泄漏后再对比"  
   > "开始性能分析，我操作一下页面"

#### 3. Context7 MCP（已预装）

**用途：** 实时拉取第三方库的最新文档  
**使用场景：** 当你不确定某个包的 API 用法时

示例提示：
> "查一下 Riverpod 3.0 的 @riverpod 注解用法"  
> "AutoRoute 11 的 TypedRoute 怎么配置？"

---

## 四、使用建议

### 日常开发流程

```
1. 编写代码 → AI 自动遵循 project-zh.mdc + flutter-official.mdc
2. 遇到技术问题 → AI 通过 context7 查询最新文档
3. 需要热重载 → AI 通过 Dart MCP 直接操作
4. 性能优化 → AI 通过 flutter-devtools-mcp 分析运行时数据
5. 代码审查 → 触发 code-review skill 进行结构化审查
```

### 复杂任务流程（RIPER-5）

对于复杂功能开发，在对话中引用 `@riper-5-cn` 启用 RIPER-5 协议：

```
RESEARCH → INNOVATE → PLAN → EXECUTE → REVIEW
  研究        创新       规划     执行       审查
```

### 高效提示技巧

| 场景 | 推荐提示 |
|------|----------|
| 新建功能 | "创建 user_profile 功能模块，参考 @architecture-feature-first" |
| 写测试 | "为 AuthRepository 写单元测试，参考 @testing" |
| 代码审查 | "审查当前分支的变更，参考 @code-review" |
| 性能问题 | "连接我的应用，追踪列表页的 widget 重建" |
| API 查询 | "用 context7 查一下 freezed 3.2 的 sealed class 语法" |

---

## 五、维护与更新

### 更新官方规则

```bash
# 重新下载 Flutter 官方最新规则
curl -o .cursor/rules/flutter-official.mdc https://raw.githubusercontent.com/flutter/flutter/refs/heads/main/docs/rules/rules_10k.md
# 注意：需要在文件顶部重新添加 YAML frontmatter
```

### 更新 Skills

```bash
# 从 evanca/flutter-ai-rules 获取最新 skills
git clone --depth 1 https://github.com/evanca/flutter-ai-rules.git /tmp/flutter-ai-rules
cp -r /tmp/flutter-ai-rules/skills/* .cursor/skills/
rm -rf /tmp/flutter-ai-rules
```

### 更新 flutter-devtools-mcp

```bash
cd .tools/flutter-devtools-mcp
git pull
npm install && npm run build
```

---

## 六、参考资源

| 资源 | 链接 |
|------|------|
| Flutter 官方 AI Rules | https://docs.flutter.dev/ai/ai-rules |
| Dart MCP Server | https://github.com/dart-lang/ai/tree/main/pkgs/dart_mcp_server |
| Flutter DevTools MCP | https://github.com/draganbajic/flutter-devtools-mcp |
| evanca/flutter-ai-rules | https://github.com/evanca/flutter-ai-rules |
| Cursor Rules 文档 | https://cursor.com/docs/context/rules |
| awesome-cursorrules | https://github.com/PatrickJS/awesome-cursorrules |
| agent-skills-standard | https://github.com/HoangNguyen0403/agent-skills-standard |
