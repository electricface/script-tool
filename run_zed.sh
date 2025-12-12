#!/bin/sh
# 使用 intel 显卡
export ZED_DEVICE_ID=0x9bc5
exec $HOME/.local/zed.app/bin/zed "$@"

