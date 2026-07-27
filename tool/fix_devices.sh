#!/usr/bin/env bash

# macOS Flutter 真机设备一键修复脚本
# 适用于：Android adb 不识别、iOS 设备 unavailable、Flutter devices 识别异常

set -u

SCRIPT_NAME="$(basename "$0")"
FORCE_DEEP_FIX=0
SKIP_DEEP_FIX=0

usage() {
  cat <<'EOF'
用法:
  ./tool/fix_devices.sh [选项]

选项:
  --deep        自动执行深度修复（需要 sudo）
  --no-sudo     跳过深度修复，仅执行无需 sudo 的步骤
  -h, --help    查看帮助

说明:
  1) 脚本会先展示当前设备状态
  2) 执行快速修复（adb + CoreDeviceService）
  3) 可选执行深度修复（重启 usbmuxd/remoted）
  4) 最后再次检测设备
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --deep)
      FORCE_DEEP_FIX=1
      ;;
    --no-sudo)
      SKIP_DEEP_FIX=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "[ERROR] 未知参数: $1"
      usage
      exit 1
      ;;
  esac
  shift
done

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "[ERROR] 该脚本仅支持 macOS。"
  exit 1
fi

section() {
  echo
  echo "============================================================"
  echo "$1"
  echo "============================================================"
}

info() {
  echo "[INFO] $1"
}

warn() {
  echo "[WARN] $1"
}

ok() {
  echo "[OK] $1"
}

run_soft() {
  echo "+ $*"
  "$@" || warn "命令执行失败（已跳过继续）: $*"
}

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

show_status() {
  section "当前设备状态"

  if has_cmd flutter; then
    run_soft flutter devices --device-timeout 10
  else
    warn "未找到 flutter 命令，跳过 Flutter 设备检测。"
  fi

  if has_cmd adb; then
    run_soft adb devices -l
  else
    warn "未找到 adb 命令，跳过 Android 设备检测。"
  fi

  if has_cmd xcrun; then
    if xcrun -f devicectl >/dev/null 2>&1; then
      run_soft xcrun devicectl list devices
    else
      run_soft xcrun xctrace list devices
    fi
  else
    warn "未找到 xcrun 命令，跳过 iOS 设备检测。"
  fi
}

quick_fix() {
  section "执行快速修复（无需 sudo）"

  if has_cmd adb; then
    run_soft adb kill-server
    run_soft adb start-server
  fi

  # CoreDeviceService 是用户进程，可直接重启
  run_soft killall CoreDeviceService
}

deep_fix() {
  section "执行深度修复（需要 sudo）"

  info "将重启 usbmuxd/remoted/RemotePairingDataVaultHelper。"
  if ! sudo -v; then
    warn "sudo 验证失败，无法执行深度修复。"
    return 1
  fi

  run_soft sudo killall -9 usbmuxd remoted
  run_soft sudo pkill -9 -f RemotePairingDataVaultHelper

  if has_cmd adb; then
    run_soft adb kill-server
    run_soft adb start-server
  fi

  return 0
}

count_android_devices() {
  if ! has_cmd adb; then
    echo 0
    return
  fi

  adb devices | awk 'NR>1 && $2=="device" {c++} END {print c+0}'
}

count_ios_available_devices() {
  if ! has_cmd xcrun || ! xcrun -f devicectl >/dev/null 2>&1; then
    echo 0
    return
  fi

  xcrun devicectl list devices 2>/dev/null | awk '/available \(paired\)/ {c++} END {print c+0}'
}

maybe_run_deep_fix() {
  local do_deep_fix=0

  if [[ "$SKIP_DEEP_FIX" -eq 1 ]]; then
    info "已指定 --no-sudo，跳过深度修复。"
    return 0
  fi

  if [[ "$FORCE_DEEP_FIX" -eq 1 ]]; then
    do_deep_fix=1
  else
    read -r -p "是否执行深度修复（需要 sudo）? [y/N] " answer
    case "$answer" in
      y|Y|yes|YES)
        do_deep_fix=1
        ;;
      *)
        do_deep_fix=0
        ;;
    esac
  fi

  if [[ "$do_deep_fix" -eq 1 ]]; then
    deep_fix
  else
    info "已跳过深度修复。"
  fi
}

section "Flutter 真机设备修复工具"
info "脚本: $SCRIPT_NAME"
info "提示: 执行过程中请保持手机解锁，并确认信任弹窗。"

show_status
quick_fix
maybe_run_deep_fix

section "请执行一次手动动作"
echo "1) 重新插拔数据线（请用可传数据的线）"
echo "2) Android 选择 USB 文件传输，并确认 USB 调试授权"
echo "3) iOS 确认“信任此电脑”，且开启开发者模式"
echo
read -r -p "完成以上动作后按回车继续..."

show_status

android_count="$(count_android_devices)"
ios_count="$(count_ios_available_devices)"

section "结果汇总"
echo "Android 可用设备数: $android_count"
echo "iOS 可用(available paired)设备数: $ios_count"

if [[ "$android_count" -gt 0 || "$ios_count" -gt 0 ]]; then
  ok "至少检测到一种可用真机设备，修复基本成功。"
  exit 0
fi

warn "仍未检测到可用真机设备。"
echo "建议下一步："
echo "- 继续更换数据线/接口（优先直连 Mac）"
echo "- Android 执行：开发者选项 -> 撤销 USB 调试授权，再重连"
echo "- iOS 在 Xcode Devices 中先 Unpair 再 Pair"
echo "- 最后手段：重启电脑"

exit 2
