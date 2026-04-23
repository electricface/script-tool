#!/bin/bash

set -e

DEB_URL="https://download.qoder.com/release/latest/qoder_amd64.deb"
DEB_FILE="/tmp/qoder_amd64.deb"
PACKAGE_NAME="qoder"

cleanup() {
    if [[ -f "$DEB_FILE" ]]; then
        rm -f "$DEB_FILE"
        echo "已删除临时文件: $DEB_FILE"
    fi
}

trap cleanup EXIT

echo "正在下载最新版本..."
aria2c -x 16 -s 16 -o "$DEB_FILE" "$DEB_URL" 2>/dev/null

if [[ ! -f "$DEB_FILE" ]]; then
    echo "下载失败"
    exit 1
fi

NEW_VERSION=$(dpkg-deb -I "$DEB_FILE" | grep -i version | head -1 | awk '{print $2}')
if [[ -z "$NEW_VERSION" ]]; then
    echo "无法获取 deb 文件版本"
    exit 1
fi

INSTALLED_VERSION=$(dpkg-query -W -f='${Version}' "$PACKAGE_NAME" 2>/dev/null || echo "")

if [[ -z "$INSTALLED_VERSION" ]]; then
    echo "当前未安装 $PACKAGE_NAME"
    echo "最新版本: $NEW_VERSION"
    read -p "是否安装? [y/N] " choice
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        sudo dpkg -i "$DEB_FILE"
        echo "安装完成"
    else
        echo "已取消安装"
    fi
    exit 0
fi

echo "当前版本: $INSTALLED_VERSION"
echo "最新版本: $NEW_VERSION"

if [[ "$NEW_VERSION" == "$INSTALLED_VERSION" ]]; then
    echo "已是最新版本，无需更新"
    exit 0
fi

if dpkg --compare-versions "$NEW_VERSION" gt "$INSTALLED_VERSION"; then
    echo "发现新版本"
    read -p "是否升级? [y/N] " choice
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        sudo dpkg -i "$DEB_FILE"
        echo "升级完成"
    else
        echo "已取消升级"
    fi
else
    echo "当前版本比下载版本更新，无需操作"
fi
