#!/bin/bash
# =============================================================================
# OneLive media_kit native libs setup
# 在 flutter clean 之后、flutter build 之前运行此脚本
# 将本地缓存的 MPV/ANGLE 原生库复制到构建目录，绕过 GitHub 下载
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=== OneLive media_kit 原生库设置 ==="

# ---- Windows ----
echo ""
echo "[Windows] 复制 MPV + ANGLE 归档到构建目录..."
WINDOWS_BUILD_DIR="$PROJECT_DIR/build/windows/x64"
if [ ! -d "$WINDOWS_BUILD_DIR" ]; then
  mkdir -p "$WINDOWS_BUILD_DIR"
fi

cp "$SCRIPT_DIR/windows/mpv-dev-x86_64-20230924-git-652a1dd.7z" "$WINDOWS_BUILD_DIR/"
cp "$SCRIPT_DIR/windows/ANGLE.7z" "$WINDOWS_BUILD_DIR/"

echo "  mpv-dev-x86_64-20230924-git-652a1dd.7z → $WINDOWS_BUILD_DIR/"
echo "  ANGLE.7z → $WINDOWS_BUILD_DIR/"

# ---- Android ----
echo ""
echo "[Android] 复制 libmpv JAR 到构建目录..."
ANDROID_BUILD_DIR="$PROJECT_DIR/build/media_kit_libs_android_video/v1.1.7"
if [ ! -d "$ANDROID_BUILD_DIR" ]; then
  mkdir -p "$ANDROID_BUILD_DIR"
fi

cp "$SCRIPT_DIR/android/default-arm64-v8a.jar" "$ANDROID_BUILD_DIR/"

echo "  default-arm64-v8a.jar → $ANDROID_BUILD_DIR/"

echo ""
echo "=== 完成 ==="
echo "现在可以运行: flutter build windows 或 flutter build apk"
