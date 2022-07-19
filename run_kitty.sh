#!/bin/sh
export GLFW_IM_MODULE=ibus 
exec /home/del0/applications/kitty-*/bin/kitty --title 'Kitty Terminal'

# 用途：
# 请把这个脚本设置为 kitty 命令
# sudo ln -sfv $PROJ_SCRIPT_TOOL/run_kitty.sh /usr/local/bin/kitty
