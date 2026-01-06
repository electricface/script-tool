#!/bin/bash

# 检查分支是否已合并到指定分支
# 通过比对提交消息来判断
# 用法: check-merged-branches.sh [target_branch]
#   target_branch: 目标分支名称 (默认: master)

# 显示帮助信息
show_help() {
    cat << EOF
用法: $(basename "$0") [目标分支]

检查本地分支是否已合并到目标分支，并可选择删除已合并分支。

参数:
  目标分支        要检查的目标分支名称 (默认: master)

选项:
  -h, --help     显示此帮助信息并退出

示例:
  $(basename "$0")           # 检查是否已合并到 master
  $(basename "$0") main      # 检查是否已合并到 main
  $(basename "$0") develop   # 检查是否已合并到 develop
EOF
    exit 0
}

# 解析参数
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_help
fi

# 设置目标分支
target_branch="${1:-master}"

# 检查目标分支是否存在
if ! git rev-parse --verify "$target_branch" >/dev/null 2>&1; then
    echo "错误: 分支 '$target_branch' 不存在"
    exit 1
fi

# 删除分支的函数
delete_branch() {
    local branch="$1"
    
    read -p "是否删除此分支？[y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if git branch -D "$branch" 2>/dev/null; then
            echo "✓ 已删除本地分支: $branch"
            
            # 检查远程分支是否存在
            if git ls-remote --heads origin "$branch" 2>/dev/null | grep -q "$branch"; then
                read -p "是否同时删除远程分支 origin/$branch？[y/N] " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    if git push origin --delete "$branch" 2>/dev/null; then
                        echo "✓ 已删除远程分支: origin/$branch"
                    else
                        echo "✗ 删除远程分支失败: origin/$branch"
                    fi
                fi
            fi
        else
            echo "✗ 删除失败: $branch"
        fi
    fi
}

echo "检查本地分支合并状态..."
echo "目标分支: $target_branch"
echo "========================================"

# 获取所有分支列表
branches=($(git branch | grep -v "^\*" | grep -v "^  $target_branch$" | sed 's/^  //'))
total_branches=${#branches[@]}
current_index=0

if [ $total_branches -eq 0 ]; then
    echo "没有找到需要检查的分支。"
    exit 0
fi

echo "找到 $total_branches 个分支需要检查"
echo ""

for branch in "${branches[@]}"; do
    ((current_index++))
    echo ""
    echo "[$current_index/$total_branches] 分支: $branch"
    echo "----------------------------------------"
    
    # 获取该分支最新的提交信息
    latest_commit=$(git log "$branch" --format="%H|%s|%an|%ar" -1)
    commit_hash=$(echo "$latest_commit" | cut -d'|' -f1)
    commit_msg=$(echo "$latest_commit" | cut -d'|' -f2)
    commit_author=$(echo "$latest_commit" | cut -d'|' -f3)
    commit_date=$(echo "$latest_commit" | cut -d'|' -f4)
    
    echo "最新提交: $commit_msg"
    echo "作者: $commit_author"
    echo "时间: $commit_date"
    echo "哈希: ${commit_hash:0:8}"
    
    # 检查该提交是否在目标分支中（通过哈希）
    if git branch --contains "$commit_hash" | grep -q "$target_branch"; then
        echo "状态: ✓ 已合并 (提交在 $target_branch 中)"
        echo "建议: 可以安全删除"
        delete_branch "$branch"
    else
        # 通过提交消息搜索（处理 squash merge 情况）
        
        # 1. 先尝试精确匹配提交消息
        exact_match=$(git log "$target_branch" --format="%s" | grep -Fx "$commit_msg")
        
        if [ -n "$exact_match" ]; then
            echo "状态: ✓ 已合并 (在 $target_branch 中找到完全相同的提交消息)"
            echo "匹配提交: $exact_match"
            echo "建议: 可以安全删除"
            delete_branch "$branch"
        else
            # 2. 尝试模糊匹配（去掉前缀和标点）
            search_msg=$(echo "$commit_msg" | sed 's/^.*: //' | sed 's/[[:punct:]]//g' | awk '{print $1" "$2" "$3}')
            
            if [ -n "$search_msg" ]; then
                # 在目标分支中搜索相似的提交消息
                found=$(git log "$target_branch" --format="%s" --grep="$search_msg" -i | head -1)
                
                if [ -n "$found" ]; then
                    echo "状态: ? 可能已合并 (在 $target_branch 中找到相似消息，非精确匹配)"
                    echo "分支提交: $commit_msg"
                    echo "相似提交: $found"
                    echo "建议: 需要人工确认，谨慎删除"
                    delete_branch "$branch"
                else
                    # 显示该分支独有的提交数
                    ahead_count=$(git log "$target_branch".."$branch" --oneline | wc -l)
                    echo "状态: ✗ 未合并"
                    echo "领先 $target_branch: $ahead_count 个提交"
                    echo "建议: 谨慎删除，可能会丢失代码"
                    
                    # 显示该分支的所有提交（最多显示 5 个）
                    echo "分支提交列表:"
                    git log "$target_branch".."$branch" --format="  - %s (%ar) [%h]" --max-count=5
                    
                    delete_branch "$branch"
                fi
            fi
        fi
    fi
    
    echo ""
done

echo "========================================"
echo "检查完成！共检查了 $total_branches 个分支。"
