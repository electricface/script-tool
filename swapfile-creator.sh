#!/bin/bash
# swapfile-creator.sh - 创建两个 swapfile 并启用，支持容错和自动恢复

# 默认值
BLOCK_SIZE="1M"

echo "请输入要创建的 swapfile 数量"
read -p "Swapfile 数量: " SWAPFILE_COUNT

# 验证数量是否为正整数
if ! [[ "$SWAPFILE_COUNT" =~ ^[1-9][0-9]*$ ]]; then
    echo "❌ 请输入有效的正整数"
    exit 1
fi

# 初始化数组
declare -a SWAPFILES
declare -a SIZES

# 循环获取每个 swapfile 的信息
for ((i=1; i<=SWAPFILE_COUNT; i++)); do
    echo ""
    echo "=== 配置第 $i 个 swapfile ==="
    
    # 获取并验证 swapfile 路径
    while true; do
        read -p "Swapfile 路径 (例如: /swapfile$i): " SWAPFILE_PATH
        
        # 检查路径是否为空
        if [[ -z "$SWAPFILE_PATH" ]]; then
            echo "❌ 路径不能为空，请重新输入"
            continue
        fi
        
        # 获取父目录
        PARENT_DIR=$(dirname "$SWAPFILE_PATH")
        
        # 检查父目录是否存在
        if [[ ! -d "$PARENT_DIR" ]]; then
            echo "❌ 父目录不存在: $PARENT_DIR"
            echo "   请确保父目录存在或使用其他路径"
            continue
        fi
        
        # 验证通过，跳出循环
        break
    done
    
    read -p "Swapfile 大小 (例如: 2G 或 2048M): " SIZE
    
    # 验证大小格式
    if ! [[ "$SIZE" =~ ^([0-9]+)[GM]$ ]]; then
        echo "❌ 仅支持 '数字G' 或 '数字M' 格式（如 10G, 2048M）"
        exit 1
    fi
    
    SWAPFILES+=($SWAPFILE_PATH)
    SIZES+=($SIZE)
done

echo ""
echo "📋 已配置 ${#SWAPFILES[@]} 个 swapfile:"
for ((i=0; i<${#SWAPFILES[@]}; i++)); do
    echo "  $((i+1)). ${SWAPFILES[$i]} - ${SIZES[$i]}"
done
echo ""
echo "📝 如需开机自动挂载，请在 /etc/fstab 中添加以下内容:"
echo "---"
for ((i=0; i<${#SWAPFILES[@]}; i++)); do
    # 计算优先级，从 -2 开始递减
    PRIORITY=$((-(i+2)))
    echo "${SWAPFILES[$i]} none swap sw,pri=$PRIORITY 0 0"
done
echo "---"
echo ""

# 处理每个 swapfile
for ((idx=0; idx<${#SWAPFILES[@]}; idx++)); do
    swapfile="${SWAPFILES[$idx]}"
    SIZE="${SIZES[$idx]}"
    
    echo "=== 处理 $((idx+1))/${#SWAPFILES[@]}: $swapfile ($SIZE) ==="
    
    # 自动计算 count（假设 bs=1M）
    if [[ "$SIZE" =~ ^([0-9]+)G$ ]]; then
        COUNT=$(( ${BASH_REMATCH[1]} * 1024 ))
    elif [[ "$SIZE" =~ ^([0-9]+)M$ ]]; then
        COUNT=$(( ${BASH_REMATCH[1]} ))
    else
        echo "❌ 仅支持 '数字G' 或 '数字M' 格式（如 10G, 2048M）"
        exit 1
    fi

    # 检查文件是否存在，若存在则先卸载后删除（容错）
    if [[ -f "$swapfile" ]]; then
        echo "⚠️ 旧文件 $swapfile 存在"
        # 检查是否已挂载为 swap，如果是则先卸载
        if swapon --show | grep -q "$swapfile"; then
            echo "📤 正在卸载已挂载的 swap: $swapfile"
            if ! sudo swapoff "$swapfile"; then
                echo "❌ 卸载失败: $swapfile"
                exit 1
            fi
        fi
        echo "🗑️ 正在删除旧文件: $swapfile"
        sudo rm -f "$swapfile"
    fi

    # 创建文件（使用 dd，支持断点续传重试）
    echo "⏳ 正在创建 $swapfile ($SIZE)..."
    if ! sudo dd if=/dev/zero of="$swapfile" bs="$BLOCK_SIZE" count="$COUNT" status=none 2>/dev/null; then
        echo "❌ 创建失败: $swapfile"
        exit 1
    fi

    # 设置权限（仅 root 可读写）
    sudo chmod 600 "$swapfile"

    # 格式化为 swap
    echo "🔧 正在格式化为 swap..."
    if ! sudo mkswap "$swapfile" >/dev/null; then
        echo "❌ 格式化失败: $swapfile"
        exit 1
    fi

    # 启用 swap
    echo "⚡ 正在启用 swap..."
    if ! sudo swapon "$swapfile"; then
        echo "❌ 启用失败: $swapfile"
        exit 1
    fi

    echo "✅ 成功创建并启用: $swapfile"
done

echo
echo "🎉 所有 swapfile 创建并启用完成！"
swapon --show
free -h
