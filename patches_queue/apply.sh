#!/usr/bin/env bash
#
# apply.sh — VirtualDisplay daemon 补丁队列应用脚本
#
# 目标目录: 默认 ../scrcpy（即 daemon/scrcpy，补丁路径前缀 server/、gradlew 相对该目录）。
# 可用命令:
#   apply.sh list    列出补丁清单（类型 / 目标文件 / 应用顺序）
#   apply.sh check   只读检查每个补丁在目标目录的状态（CLEAN / APPLIED / CONFLICT）
#   apply.sh apply   按序应用补丁（NEW 在前，MODIFY 在后），幂等：已应用的跳过
#   apply.sh reverse 反向撤销已应用的补丁（MODIFY 先，NEW 后）
#
# 选项:
#   -t, --target <dir>  指定目标 git 仓库根目录（默认 ../scrcpy）
#   -h, --help          显示帮助
#
# 说明:
#   - 补丁路径内已含相对前缀（server/...、gradlew），故在目标仓库根执行 git apply。
#   - 新增文件通过补丁首行 "new file mode" 识别；其余为修改。
#   - apply 顺序对 git apply 本身无硬性要求（每个文件只有一个补丁），但为保证
#     编译正确（修改类补丁引用新增类），统一「先 NEW 后 MODIFY」。
#   - 若目标工作区已存在改动（漂移），check 会如实标注 CONFLICT，apply 会跳过并汇总。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_TARGET="$(cd "$SCRIPT_DIR/.." && pwd)/scrcpy"
TARGET="$DEFAULT_TARGET"

usage() {
    sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
    exit 0
}

# --- 收集补丁（NEW 与 MODIFY 分类），按路径排序，保证稳定顺序 ---
PATCH_DIR="$SCRIPT_DIR"
NEW=()
MODIFY=()
while IFS= read -r f; do
    if grep -q 'new file mode' "$f"; then
        NEW+=("$f")
    else
        MODIFY+=("$f")
    fi
done < <(find "$PATCH_DIR" -name '*.patch' | sort)

ALL=("${NEW[@]}" "${MODIFY[@]}")

# --- 工具函数 ---
target_path() { # 从补丁文件路径得到目标相对路径
    local patch="$1"
    local rel="${patch#"$PATCH_DIR"/}"
    echo "${rel%.patch}"
}

# 校验目标是否为可用的 git 仓库（兼容子模块：.git 可能是 gitdir 指针文件）
require_repo() {
    if ! git -C "$TARGET" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "错误: $TARGET 不是 git 仓库" >&2
        exit 1
    fi
}

# 判定单个补丁在目标仓库的状态
# 返回: APPLIED / CLEAN / CONFLICT
patch_state() {
    local patch="$1"
    if git -C "$TARGET" apply --check --reverse "$patch" >/dev/null 2>&1; then
        echo "APPLIED"
    elif git -C "$TARGET" apply --check "$patch" >/dev/null 2>&1; then
        echo "CLEAN"
    else
        echo "CONFLICT"
    fi
}

# --- list ---
cmd_list() {
    echo "补丁队列清单 (共 ${#ALL[@]} 个, 目标: $TARGET)"
    echo "---------------------------------------------------------------"
    echo "[新增文件 - ${#NEW[@]} 个]"
    for f in "${NEW[@]}"; do
        printf "  NEW     %s\n" "$(target_path "$f")"
    done
    echo "[修改上游 - ${#MODIFY[@]} 个]"
    for f in "${MODIFY[@]}"; do
        printf "  MODIFY  %s\n" "$(target_path "$f")"
    done
}

# --- check ---
cmd_check() {
    require_repo
    local n_applied=0 n_clean=0 n_conflict=0
    echo "检查补丁状态 (目标: $TARGET)"
    echo "---------------------------------------------------------------"
    for f in "${ALL[@]}"; do
        local state; state="$(patch_state "$f")"
        printf "  %-8s %s\n" "$state" "$(target_path "$f")"
        case "$state" in
            APPLIED) n_applied=$((n_applied+1)) ;;
            CLEAN) n_clean=$((n_clean+1)) ;;
            CONFLICT) n_conflict=$((n_conflict+1)) ;;
        esac
    done
    echo "---------------------------------------------------------------"
    echo "已应用: $n_applied / 可干净应用: $n_clean / 冲突: $n_conflict / 合计: ${#ALL[@]}"
}

# --- apply ---
cmd_apply() {
    require_repo
    local applied=0 skipped=0 conflict=0
    for f in "${ALL[@]}"; do
        local state; state="$(patch_state "$f")"
        case "$state" in
            APPLIED)
                printf "  [跳过] 已应用  %s\n" "$(target_path "$f")"
                skipped=$((skipped+1))
                ;;
            CLEAN)
                if git -C "$TARGET" apply --check "$f" >/dev/null 2>&1 \
                   && git -C "$TARGET" apply "$f"; then
                    printf "  [应用]          %s\n" "$(target_path "$f")"
                    applied=$((applied+1))
                else
                    printf "  [失败] 应用失败 %s\n" "$(target_path "$f")"
                    conflict=$((conflict+1))
                fi
                ;;
            CONFLICT)
                printf "  [冲突] 需人工   %s\n" "$(target_path "$f")"
                conflict=$((conflict+1))
                ;;
        esac
    done
    echo "---------------------------------------------------------------"
    echo "本次应用: $applied / 已跳过: $skipped / 冲突: $conflict"
    if [ "$conflict" -gt 0 ]; then
        echo "存在冲突补丁，请人工处理或使用 --3way / 手动 git apply。"
    fi
}

# --- reverse ---
cmd_reverse() {
    require_repo
    # 逆向：先撤修改，后撤新增
    local rev=("${MODIFY[@]}" "${NEW[@]}")
    local reversed=0 skipped=0
    for f in "${rev[@]}"; do
        if git -C "$TARGET" apply --check --reverse "$f" >/dev/null 2>&1; then
            if git -C "$TARGET" apply --reverse "$f"; then
                printf "  [撤销]          %s\n" "$(target_path "$f")"
                reversed=$((reversed+1))
            fi
        else
            printf "  [跳过] 未应用   %s\n" "$(target_path "$f")"
            skipped=$((skipped+1))
        fi
    done
    echo "---------------------------------------------------------------"
    echo "撤销: $reversed / 跳过: $skipped"
}

# --- 参数解析 ---
CMD="${1:-help}"
shift || true
while [ "$#" -gt 0 ]; do
    case "$1" in
        -t|--target) TARGET="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) echo "未知选项: $1" >&2; usage ;;
    esac
done

case "$CMD" in
    list) cmd_list ;;
    check) cmd_check ;;
    apply) cmd_apply ;;
    reverse) cmd_reverse ;;
    help) usage ;;
    *) echo "未知命令: $CMD" >&2; usage ;;
esac
