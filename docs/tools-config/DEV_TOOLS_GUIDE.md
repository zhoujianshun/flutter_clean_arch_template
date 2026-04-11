# 🚀 开发工具管理指南

本项目提供了多种启动脚本管理工具，您可以根据喜好和使用场景选择最合适的工具。

## 📋 工具对比表

| 工具 | 难度 | 功能 | 平台支持 | 推荐场景 |
|------|------|------|----------|----------|
| **Just** | ⭐⭐ | ⭐⭐⭐⭐⭐ | 全平台 | 现代化项目，喜欢简洁语法 |
| **Makefile** | ⭐⭐⭐ | ⭐⭐⭐⭐ | 全平台 | 传统项目，团队熟悉Make |
| **VS Code Tasks** | ⭐ | ⭐⭐⭐ | VS Code | IDE集成，图形界面操作 |
| **Task (Go)** | ⭐⭐ | ⭐⭐⭐⭐ | 全平台 | Go生态，YAML配置爱好者 |
| **智能脚本** | ⭐ | ⭐⭐⭐⭐⭐ | Unix/Linux/macOS | 交互式体验，新手友好 |

## 🛠 安装指南

### 1. Just (推荐) ⭐⭐⭐⭐⭐

**安装:**

```bash
# macOS
brew install just

# Ubuntu/Debian
sudo apt install just

# 其他系统
cargo install just
```

**使用:**

```bash
# 查看所有命令
just

# 开发环境启动
just dev

# 构建Release APK
just build-release

# 清理并重置
just reset
```

### 2. Makefile ⭐⭐⭐⭐

**无需安装** (系统自带)

**使用:**

```bash
# 查看帮助
make help

# 开发环境启动
make dev

# 构建Release APK
make build-release

# 完全重置
make reset
```

### 3. VS Code Tasks ⭐⭐⭐⭐

**无需安装** (VS Code内置)

**使用:**

1. 在VS Code中按 `Cmd/Ctrl + Shift + P`
2. 输入 `Tasks: Run Task`
3. 选择想要执行的任务

或使用快捷键：

- `Cmd/Ctrl + Shift + P` → `Tasks: Run Task`

### 4. Task (Go-based) ⭐⭐⭐⭐

**安装:**

```bash
# macOS
brew install go-task/tap/go-task

# 或使用Go安装
go install github.com/go-task/task/v3/cmd/task@latest
```

**使用:**

```bash
# 查看所有任务
task --list-all

# 开发环境启动
task dev

# 构建Release APK
task build:release

# 完全重置
task reset
```

### 5. 智能脚本选择器 (推荐新手) ⭐⭐⭐⭐⭐

**安装依赖:**

```bash
# 安装fzf (可选但推荐)
brew install fzf
```

**使用:**

```bash
# 交互式选择命令
./scripts/dev.sh

# 显示所有命令
./scripts/dev.sh --list

# 显示帮助
./scripts/dev.sh --help
```

## 🎯 使用场景推荐

### 💻 **日常开发** - 推荐智能脚本

```bash
./scripts/dev.sh
# 然后选择: 🔥 开发环境启动
```

### 🔄 **持续集成** - 推荐Makefile

```bash
make clean && make build-release
```

### 🎨 **IDE开发** - 推荐VS Code Tasks

- 按 `Cmd/Ctrl + Shift + P`
- 选择相应任务

### 📦 **复杂构建** - 推荐Just

```bash
just clean
just gen
just build-all
```

### 🔧 **快速原型** - 推荐Task

```bash
task quick  # 清理+生成+启动开发
```

## 📝 常用命令速查

### 基础开发命令

| 操作 | Just | Make | 说明 |
|------|------|------|------|
| 开发启动 | `just dev` | `make dev` | 启动开发环境 |
| 构建Release | `just build-release` | `make build-release` | 构建生产APK |
| 代码生成 | `just gen` | `make gen` | 运行代码生成器 |
| 清理项目 | `just clean` | `make clean` | 清理构建文件 |

### 蒲公英发布命令 ⭐

#### Android 发布

| 操作 | Just | Make | 说明 |
|------|------|------|------|
| 构建+上传APK | `just pgyer-build-upload` | `make pgyer-build-upload` | 一键构建并上传Android到蒲公英 |
| 上传APK | `just pgyer-upload-apk` | `make pgyer-upload-apk` | 上传已构建的APK |
| 快速发布 | `just pgyer-quick` | `make pgyer-quick` | 构建+上传Android(推荐) |
| 完整发布 | `just test-release` | `make test-release` | 清理+代码生成+构建+上传Android |
| 自定义上传 | `just pgyer-upload <file> "<desc>"` | - | 自定义Android文件和描述 |

#### iOS 发布 🍎

| 操作 | Just | Make | 说明 |
|------|------|------|------|
| 构建+上传IPA | `just pgyer-ios-build-upload` | `make pgyer-ios-build-upload` | 一键构建并上传iOS到蒲公英 |
| 上传IPA | `just pgyer-upload-ipa` | `make pgyer-upload-ipa` | 上传已构建的IPA |
| 快速发布 | `just pgyer-ios-quick` | `make pgyer-ios-quick` | 构建+上传iOS(推荐) |
| 完整发布 | `just test-ios-release` | - | 清理+代码生成+构建+上传iOS |
| 自定义上传 | `just pgyer-ios-upload <file> "<desc>"` | - | 自定义iOS文件和描述 |

## 🚀 快速开始

### 第一次使用（推荐流程）

1. **尝试智能脚本**（最友好）:

   ```bash
   ./scripts/dev.sh
   ```

2. **如果喜欢命令行**，安装Just:

   ```bash
   brew install just
   just dev
   ```

3. **如果使用VS Code**，直接使用内置Tasks:
   - `Cmd/Ctrl + Shift + P` → `Tasks: Run Task`

### 团队协作推荐

- **统一使用Makefile**：所有平台兼容
- **或者Just**：现代化且功能强大

## 🚀 蒲公英发布功能

### 快速上手

```bash
# Android: 一键构建并发布测试版本
make pgyer-quick
just pgyer-quick

# iOS: 一键构建并发布测试版本（仅macOS）
make pgyer-ios-quick
just pgyer-ios-quick
```

### 详细功能说明

#### 1. 完整构建上传流程

```bash
make pgyer-build-upload  # 使用项目现有脚本
```

- ✅ 自动清理旧APK
- ✅ 分架构构建APK (减少文件大小)
- ✅ 智能选择最佳APK版本上传
- ✅ 完整的错误处理和日志

#### 2. 上传已构建的APK

```bash
make pgyer-upload-apk    # 上传现有APK
```

- ✅ 自动查找APK文件
- ✅ 优先上传ARM64版本
- ✅ 自动生成时间戳描述

#### 3. 快速发布（推荐）

```bash
make pgyer-quick         # 构建+上传
```

- ✅ 先构建Release APK
- ✅ 再自动上传到蒲公英
- ✅ 适合日常测试发布

#### 4. 完整测试发布

```bash
make test-release        # 完整流程
```

- ✅ 清理项目
- ✅ 重新生成代码
- ✅ 构建Release APK
- ✅ 上传到蒲公英

#### 5. 自定义上传 (Just专用)

```bash
# Android 自定义上传
just pgyer-upload app-release.apk "新版本功能更新"

# iOS 自定义上传 (仅macOS)
just pgyer-ios-upload Runner.ipa "iOS新版本功能更新"
```

### 上传结果

成功上传后，终端会显示：

```
Upload successful! App URL: https://www.pgyer.com/xxxxxx
```

### 配置说明

- **API Key**: 已预设在脚本中
- **自动时间戳**: 支持自动时间戳描述  
- **Android APK选择**: 智能APK版本选择（ARM64 > ARMv7 > x86）
- **iOS IPA支持**: 自动查找并上传IPA文件
- **平台检测**: iOS功能仅在macOS环境可用
- **签名要求**: iOS构建需要正确配置开发者证书和Provisioning Profile

## ⚙️ 自定义配置

### 添加新命令

**Just (justfile):**

```just
# 自定义命令
my-command:
    echo "执行自定义操作"
    flutter run --dart-define=MY_VAR=value
```

**Make (Makefile):**

```makefile
my-command:
 @echo "执行自定义操作"
 flutter run --dart-define=MY_VAR=value
```

**Task (Taskfile.yml):**

```yaml
tasks:
  my-command:
    desc: "自定义命令"
    cmds:
      - echo "执行自定义操作"
      - flutter run --dart-define=MY_VAR=value
```

## 🔧 故障排除

### 常见问题

1. **命令未找到**

   ```bash
   # 检查工具是否安装
   which just  # 或 make/task
   
   # 重新安装
   brew install just
   ```

2. **权限问题**

   ```bash
   # 给脚本添加执行权限
   chmod +x scripts/dev.sh
   ```

3. **Flutter命令失败**

   ```bash
   # 检查Flutter环境
   flutter doctor
   
   # 清理项目
   flutter clean && flutter pub get
   ```

4. **VS Code任务不显示**
   - 确保 `.vscode/tasks.json` 文件存在
   - 重新加载VS Code窗口

## 📊 性能对比

| 工具 | 启动速度 | 内存占用 | 学习成本 |
|------|----------|----------|----------|
| Just | 快 | 低 | 低 |
| Make | 快 | 低 | 中 |
| Task | 中 | 中 | 低 |
| 脚本 | 中 | 中 | 最低 |
| VS Code | 慢 | 高 | 最低 |

## 🎉 总结

- **新手推荐**: 智能脚本选择器 (`./scripts/dev.sh`)
- **日常开发**: Just (`just dev`)  
- **团队协作**: Makefile (`make dev`)
- **IDE用户**: VS Code Tasks
- **Go爱好者**: Task (`task dev`)

选择一个您最舒适的工具，开始高效的Flutter开发之旅！🚀
