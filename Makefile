# ============================================================
# Flutter Clean Architecture Template - Makefile
# 用法: make <command>
# ============================================================

# 默认目标：显示所有可用命令
.DEFAULT_GOAL := help

# 声明伪目标（不对应实际文件，避免与同名文件冲突）
.PHONY: help dev staging prod-debug release \
        android-build-debug android-build-release ios-build \
        gen gen-watch \
        clean reset \
        gen-icon gen-splash \
        analyze test \
        deps deps-upgrade \
        devices check

# === 帮助信息 ===

## 显示所有可用命令及说明
help:
	@echo "Flutter Clean Architecture Template - 可用命令:"
	@echo ""
	@echo "  开发运行:"
	@echo "    make dev                 - 开发环境运行"
	@echo "    make staging             - 预发布环境运行"
	@echo "    make prod-debug          - 生产环境 (debug 模式) 运行"
	@echo "    make release             - 生产环境 (release 模式) 运行"
	@echo "    make run ENV=xxx DEV=yyy - 指定环境和设备运行"
	@echo ""
	@echo "  构建打包:"
	@echo "    make android-build-debug   - 构建 Android Debug APK (arm64)"
	@echo "    make android-build-release - 构建 Android Release APK (arm64)"
	@echo "    make ios-build             - 构建 iOS Release"
	@echo ""
	@echo "  代码生成:"
	@echo "    make gen                 - 运行 build_runner 一次性生成"
	@echo "    make gen-watch           - 运行 build_runner 监听模式"
	@echo ""
	@echo "  清理与重置:"
	@echo "    make clean               - 清理项目并重新获取依赖"
	@echo "    make reset               - 清理 + 重新生成代码"
	@echo ""
	@echo "  应用资源:"
	@echo "    make gen-icon            - 生成应用图标"
	@echo "    make gen-splash          - 生成启动页"
	@echo ""
	@echo "  分析与测试:"
	@echo "    make analyze             - 静态代码分析"
	@echo "    make test                - 运行单元测试"
	@echo ""
	@echo "  依赖管理:"
	@echo "    make deps                - 获取依赖 (pub get)"
	@echo "    make deps-upgrade        - 升级依赖 (pub upgrade)"
	@echo ""
	@echo "  其他:"
	@echo "    make devices             - 列出已连接设备"
	@echo "    make check               - 检查环境配置"

# === 开发运行 ===

## 以开发环境启动应用
dev:
	flutter run --dart-define=ENVIRONMENT=development

## 以预发布环境启动应用
staging:
	flutter run --dart-define=ENVIRONMENT=staging

## 以生产环境 (debug 模式) 启动应用
prod-debug:
	flutter run --dart-define=ENVIRONMENT=production

## 以生产环境 (release 模式) 启动应用
release:
	flutter run --release --dart-define=ENVIRONMENT=production

# === 构建打包 ===

## 构建 Android Debug APK（仅 arm64 架构）
android-build-debug:
	flutter build apk --debug --target-platform android-arm64

## 构建 Android Release APK（仅 arm64 架构）
android-build-release:
	flutter build apk --release --target-platform android-arm64

## 构建 iOS Release 版本
ios-build:
	flutter build ios --release

# === 代码生成 ===

## 运行 build_runner 生成代码（一次性，删除冲突输出）
gen:
	dart run build_runner build --delete-conflicting-outputs

## 运行 build_runner 监听模式（文件变动时自动重新生成）
gen-watch:
	dart run build_runner watch --delete-conflicting-outputs

# === 清理与重置 ===

## 清理构建缓存并重新获取依赖
clean:
	flutter clean && flutter pub get

## 完整重置：清理 → 获取依赖 → 重新生成代码
reset: clean gen

# === 应用资源 ===

## 根据配置文件生成应用图标
gen-icon:
	flutter pub run flutter_launcher_icons -f flutter_launcher_icons.yaml

## 根据配置文件生成启动页（闪屏页）
gen-splash:
	flutter pub run flutter_native_splash:create --path=flutter_native_splash.yaml

# === 分析与测试 ===

## 运行 Flutter 静态代码分析（忽略 info 级别警告）
analyze:
	flutter analyze --no-fatal-infos

## 运行所有单元测试
test:
	flutter test

# === 依赖管理 ===

## 获取项目依赖
deps:
	flutter pub get

## 升级项目依赖到最新兼容版本
deps-upgrade:
	flutter pub upgrade

# === 设备管理 ===

## 列出所有已连接的设备
devices:
	flutter devices

# === 多环境运行 ===

## 指定环境和设备运行
## 用法: make run ENV=development DEV=<device-id>
run:
ifndef ENV
	$(error 请指定环境变量 ENV, 例如: make run ENV=development DEV=xxx)
endif
ifndef DEV
	$(error 请指定设备 DEV, 例如: make run ENV=development DEV=xxx)
endif
	flutter run --dart-define=ENVIRONMENT=$(ENV) --device-id=$(DEV)

# === 环境检查 ===

## 检查 Flutter 版本、环境文件和关键依赖
check:
	@echo "Flutter 版本:"
	@flutter --version | head -1
	@echo "环境配置文件:"
	@ls -la assets/env/
	@echo "关键依赖:"
	@flutter pub deps --no-dev | grep -E "(flutter_dotenv|riverpod)"
