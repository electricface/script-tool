#!/bin/bash

# 设置 uTools 的路径和用户 UID
UTOOLS_PATH="/opt/uTools/utools"
#UID=$(id -u)  # 获取当前用户的 UID，也可以手动指定如 UID=1000

# 检查 uTools 是否已经运行
if pgrep -U "$UID" -f "$UTOOLS_PATH" > /dev/null; then
    # 如果已运行，使用 xdotool 发送 Alt+Space
    echo "uTools is already running. Triggering Alt+Space..."
    xdotool key alt+space
else
    # 如果未运行，启动 uTools
    echo "uTools is not running. Starting it..."
    dde-am --by-user utools
fi
