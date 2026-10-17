#!/usr/bin/env bash
# D4KeyHelp 测试入口：把「加载期校验 → 冒烟测试 → 血球回归」串成一条命令。
#
#   bash tests/run.sh                  # 依次跑全部
#   bash tests/run.sh validate         # 只跑加载期校验（最快，改完立刻自检用）
#   bash tests/run.sh smoke            # 只跑冒烟测试
#   bash tests/run.sh globe            # 只跑血球回归
#   bash tests/run.sh globe --export   # 血球回归前先重新生成 tests/data/*.bin
#
# 退出码：0 = 全部通过，1 = 有失败项，2 = 环境不满足（找不到解释器等）。
#
# 为什么这里不写裸的 `AutoHotkey64.exe tests/SmokeTest.ahk`：
#   1) 解释器不在 PATH 上，必须用绝对路径（本脚本会自动探测）；
#   2) MSYS/Git-Bash 会把 /validate 改写成 Windows 路径（变成 C:/Program Files/Git/validate），
#      AHK 收到的是一个不存在的脚本名而不是开关，于是脚本被真正执行、进程挂住不退出。
#      所以开关必须写成 //validate（双斜杠）。MSYS_NO_PATHCONV=1 也能挡住改写，但它同时会
#      把 /c/... 形式的脚本路径也一并破坏，所以本脚本统一用双斜杠写法。
#   3) 加载期报错时 AHK 默认弹对话框等用户点确定，非交互环境下会永久挂住；
#      对「语法错误」加 //ErrorStdOut 能把消息改发到 stderr，但对「调用不存在的函数」
#      这类加载期错误它仍会弹窗，所以本脚本再叠一层 timeout 兜底（见 AHK_TIMEOUT_SECS）。

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT" || exit 2

STEP="${1:-all}"
shift || true
FORCE_EXPORT=0
for arg in "$@"; do
    [ "$arg" = "--export" ] && FORCE_EXPORT=1
done

# ---------- 环境探测 ----------

find_ahk() {
    # 显式指定了 AHK 就只认它：写错了应当报错，而不是悄悄换一个解释器去跑
    if [ -n "${AHK:-}" ]; then
        if [ -f "${AHK}" ]; then printf '%s\n' "$AHK"; return 0; fi
        return 1
    fi
    local cand
    for cand in \
        "/c/Program Files/AutoHotkey/v2/AutoHotkey64.exe" \
        "/c/Program Files/AutoHotkey/v2/AutoHotkey.exe" \
        "/c/Program Files/AutoHotkey/AutoHotkey64.exe" \
        "$(command -v AutoHotkey64.exe 2>/dev/null || true)" \
        "$(command -v AutoHotkey.exe 2>/dev/null || true)"
    do
        if [ -n "$cand" ] && [ -f "$cand" ]; then printf '%s\n' "$cand"; return 0; fi
    done
    return 1
}

# 生成 tests/data/*.bin 需要 Pillow。注意本机 `python`(3.14) 有 Pillow，而
# `python3` 是 WindowsApps 里的 3.13、没有 Pillow，所以按可用性挑而不是写死。
find_python_with_pillow() {
    local cand
    for cand in python python3 py; do
        if command -v "$cand" >/dev/null 2>&1 && "$cand" -c "import PIL" >/dev/null 2>&1; then
            printf '%s\n' "$cand"; return 0
        fi
    done
    return 1
}

AHK="$(find_ahk || true)"
if [ -z "$AHK" ]; then
    echo "找不到 AutoHotkey v2 解释器。请安装，或用 AHK=/path/to/AutoHotkey64.exe 指定。" >&2
    exit 2
fi
PY="$(find_python_with_pillow || true)"

# 给 AHK 调用加个超时兜底。正常情况下不该触发；触发说明脚本卡住了
# （最常见的原因就是弹了模态错误对话框在等用户点确定）。
# validate 正常只要约 0.1 秒，冒烟/血球测试正常 2-3 秒；这里取 30 秒很宽松。
# 注意：不同步骤的期望耗时差很多，所以允许用 RUN_TIMEOUT 单独收紧（见 step_validate）。
AHK_TIMEOUT_SECS=30
AHK_TIMEOUT=""
if command -v timeout >/dev/null 2>&1; then
    AHK_TIMEOUT="timeout $AHK_TIMEOUT_SECS"
fi

# 跑一次 AHK 并把输出/退出码放到全局，供各步骤使用。
# 超时被杀时退出码是 124，会被上层当作失败，而不是把整个 runner 拖住。
#
# 参数顺序很重要：AHK 的用法是 `AutoHotkey.exe [开关...] [脚本] [脚本参数...]`，
# 开关必须放在脚本**前面**。写在脚本后面会被当成「传给脚本的参数」而不是开关，
# 于是 //validate 静默失效、脚本被真的执行（D4keyHelp.ahk 是主程序，会一直挂着）。
run_ahk() {  # run_ahk [开关...] <脚本>
    local to="${RUN_TIMEOUT:-$AHK_TIMEOUT}"
    AHK_OUT="$($to "$AHK" "$@" 2>&1)"
    AHK_RC=$?
    return 0
}

# ---------- 结果汇总 ----------

PASS=0
FAIL=0
FAILED_STEPS=()

report() {  # report <名称> <0=通过 1=失败> [详情]
    local name="$1" ok="$2" detail="${3:-}"
    if [ "$ok" -eq 0 ]; then
        printf '  [通过] %s%s\n' "$name" "${detail:+  ($detail)}"
        PASS=$((PASS + 1))
    else
        printf '  [失败] %s%s\n' "$name" "${detail:+  ($detail)}"
        FAIL=$((FAIL + 1))
        FAILED_STEPS+=("$name")
    fi
}

indent() { sed 's/^/        /'; }

# 从 tests/result.txt 的一行里取字段，例如 field <文件> screenShot state -> ok
# 注意：结果文件由 AHK 以 UTF-8 写出并带 BOM，首行前面会多出 EF BB BF 三个字节，
# 不剥掉的话 `^screenShot:` 匹配不到第一行，会把通过项误判成失败。
field() {
    sed -e '1s/^\xEF\xBB\xBF//' "$1" \
        | grep "^$2:" | head -1 \
        | sed -n "s/.*[ =]$3=\([^ ]*\).*/\1/p"
}

# ---------- 1. 加载期校验 ----------

step_validate() {
    echo "== 1/3 加载期校验（语法 + #Include + 函数名是否定义）=="
    local f rc
    # validate 正常约 0.1 秒，收紧到 10 秒，出错时不必白等 30 秒
    local RUN_TIMEOUT
    if command -v timeout >/dev/null 2>&1; then RUN_TIMEOUT="timeout 10"; fi
    for f in D4keyHelp.ahk tests/SmokeTest.ahk tests/HealthGlobeTest.ahk; do
        run_ahk //validate //ErrorStdOut "$f"
        rc=$AHK_RC
        if [ "$rc" -eq 0 ]; then
            report "$f" 0
        elif [ "$rc" -eq 124 ]; then
            # /validate 对「语法错误」和「#Include 找不到目标」会把消息发到 stderr 并正常退出，
            # 但对「调用不存在的函数」这类加载期错误会弹模态对话框，//ErrorStdOut 拦不住，
            # 进程就一直等用户点确定。这里靠上面的 timeout 兜底，并提示可能是这类弹窗。
            report "$f" 1 "超时 10s 未返回（很可能弹了错误对话框在等确认）"
            printf '%s\n' "$AHK_OUT" | grep -v '^$' | indent
        else
            report "$f" 1 "退出码 $rc"
            printf '%s\n' "$AHK_OUT" | grep -v '^$' | indent
        fi
    done
}

# ---------- 2. 冒烟测试 ----------

step_smoke() {
    echo "== 2/3 冒烟测试（加载全部模块 + 创建界面）=="
    local report_file="tests/smoke_result.txt"
    rm -f "$report_file"
    run_ahk tests/SmokeTest.ahk

    if [ ! -f "$report_file" ]; then
        if [ "$AHK_RC" -eq 124 ]; then
            report "冒烟测试" 1 "超时 ${AHK_TIMEOUT_SECS}s 未返回（很可能弹了错误对话框在等确认）"
        else
            report "冒烟测试" 1 "没有生成 $report_file（退出码 $AHK_RC）"
        fi
        return 1
    fi
    # SmokeTest 内部用 try/catch 兜住异常，所以进程退出码恒为 0，
    # 只能看结果文件里有没有「失败」「异常」字样。
    if grep -qE '失败|异常' "$report_file"; then
        report "冒烟测试" 1 "结果文件里有失败项"
        indent < "$report_file"
        return 1
    fi
    report "冒烟测试" 0
    indent < "$report_file"
    return 0
}

# ---------- 3. 血球识别回归 ----------

step_globe() {
    echo "== 3/3 血球识别回归（2K 参考截图的真实像素）=="
    local data_dir="tests/data" name missing=""

    # *.bin 由 ExportGlobeWindows.py 从仓库根目录的 2K 截图生成，体积大且不入库
    if [ "$FORCE_EXPORT" -eq 1 ] || [ ! -f "$data_dir/screenShot.bin" ]; then
        if [ -z "$PY" ]; then
            report "生成 $data_dir/*.bin" 1 "找不到带 Pillow 的 Python（试过 python/python3/py）"
            return 1
        fi
        if "$PY" tests/ExportGlobeWindows.py >/dev/null 2>&1; then
            report "生成 $data_dir/*.bin" 0 "用 $PY"
        else
            report "生成 $data_dir/*.bin" 1 "$PY tests/ExportGlobeWindows.py 失败"
            return 1
        fi
    fi

    for name in screenShot screenShot2 lowblood sample2 live; do
        [ -f "$data_dir/$name.bin" ] || missing="$missing $name"
    done
    if [ -n "$missing" ]; then
        report "血球回归数据" 1 "缺少$missing 的 .bin（仓库根目录的参考截图不全？）"
        return 1
    fi

    local report_file="tests/result.txt"
    rm -f "$report_file"
    run_ahk tests/HealthGlobeTest.ahk

    if [ ! -f "$report_file" ]; then
        if [ "$AHK_RC" -eq 124 ]; then
            report "血球回归" 1 "超时 ${AHK_TIMEOUT_SECS}s 未返回（很可能弹了错误对话框在等确认）"
        else
            report "血球回归" 1 "没有生成 $report_file（退出码 $AHK_RC）"
        fi
        return 1
    fi
    if ! grep -q '^done$' "$report_file"; then
        report "血球回归" 1 "结果文件没有正常收尾（缺 done 行）"
        indent < "$report_file"
        return 1
    fi

    # 期望值对应 tests/HealthGlobeTest.ahk 顶部注释与 functions/HealthGlobe.ahk 的标定值。
    # 若重新标定了血球算法，改这里的期望即可。
    local case_name st pc lo hi expect_state bad=0
    for case_name in screenShot screenShot2 lowblood sample2 live; do
        st="$(field "$report_file" "$case_name" state)"
        pc="$(field "$report_file" "$case_name" pct)"
        lo=""; hi=""; expect_state=""
        case "$case_name" in
            screenShot)  expect_state=ok;     lo=100; hi=100 ;;   # 满血
            screenShot2) expect_state=shield                ;;   # 护盾遮挡血球
            lowblood)    expect_state=ok;     lo=21;  hi=31  ;;   # 约 26%，给 ±5 余量
            sample2)     expect_state=ok;     lo=100; hi=100 ;;   # 满血
            live)        expect_state=ok;     lo=100; hi=100 ;;   # 满血
        esac

        if [ "$st" != "$expect_state" ]; then
            report "$case_name" 1 "state=$st，期望 $expect_state"
            bad=1
            continue
        fi
        if [ -n "$lo" ]; then
            if [ -z "$pc" ] || [ "$pc" -lt "$lo" ] || [ "$pc" -gt "$hi" ]; then
                report "$case_name" 1 "pct=$pc，期望 $lo-$hi"
                bad=1
                continue
            fi
        fi
        report "$case_name" 0 "state=$st pct=$pc"
    done

    echo "  ---- tests/result.txt ----"
    indent < "$report_file"
    return $bad
}

# ---------- 调度 ----------

echo "解释器: $AHK"
[ -n "$PY" ] && echo "Python : $PY（含 Pillow）"
echo

case "$STEP" in
    validate) step_validate ;;
    smoke)    step_smoke ;;
    globe)    step_globe ;;
    all)      step_validate; step_smoke; step_globe ;;
    *)
        echo "用法: bash tests/run.sh [validate|smoke|globe|all] [--export]" >&2
        exit 2
        ;;
esac

echo
echo "== 汇总: 通过 $PASS 项，失败 $FAIL 项 =="
if [ "$FAIL" -gt 0 ]; then
    echo "失败项: ${FAILED_STEPS[*]:-}"
    exit 1
fi
exit 0
