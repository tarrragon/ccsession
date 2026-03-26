#!/usr/bin/env bash
set -uo pipefail

# Smoke Test - 版本發布前快速驗證腳本
# 用法: ./scripts/smoke-test.sh [--skip-tests] [--quick]

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SERVER_DIR="${PROJECT_ROOT}/server"
UI_DIR="${PROJECT_ROOT}/ui"

HEALTH_URL="http://localhost:8765/health"
WS_URL="http://localhost:8765/ws"
MAX_WAIT_SECS=10

# 顏色
GREEN='\033[32m'
RED='\033[31m'
YELLOW='\033[33m'
RESET='\033[0m'

# 計數器
pass_count=0
fail_count=0
skip_count=0

# 參數解析
skip_tests=false
quick_mode=false
for arg in "$@"; do
    case "$arg" in
        --skip-tests) skip_tests=true ;;
        --quick) quick_mode=true ;;
        *) echo "Unknown argument: $arg"; exit 1 ;;
    esac
done

# 背景程序 PID（用於 trap 清理）
server_pid=""

cleanup() {
    if [[ -n "$server_pid" ]]; then
        kill "$server_pid" 2>/dev/null
        wait "$server_pid" 2>/dev/null
    fi
}
trap cleanup EXIT

record_result() {
    local name="$1"
    local exit_code="$2"
    if [[ "$exit_code" -eq 0 ]]; then
        echo -e "  ${GREEN}PASS${RESET}  ${name}"
        ((pass_count++))
    else
        echo -e "  ${RED}FAIL${RESET}  ${name}"
        ((fail_count++))
    fi
}

record_skip() {
    local name="$1"
    echo -e "  ${YELLOW}SKIP${RESET}  ${name}"
    ((skip_count++))
}

echo "=== Smoke Test ==="
echo ""

# 1. Go Backend 編譯
(cd "$SERVER_DIR" && go build -o /dev/null .) 2>&1
record_result "Go build" $?

# 2. Go Backend 測試
if [[ "$skip_tests" == true || "$quick_mode" == true ]]; then
    record_skip "Go test"
else
    (cd "$SERVER_DIR" && go test ./... -count=1 -timeout 60s) 2>&1
    record_result "Go test" $?
fi

# 3. Flutter 分析
if [[ "$quick_mode" == true ]]; then
    record_skip "Dart analyze"
else
    (cd "$UI_DIR" && dart analyze) 2>&1
    record_result "Dart analyze" $?
fi

# 4. Flutter 測試
if [[ "$skip_tests" == true || "$quick_mode" == true ]]; then
    record_skip "Flutter test"
else
    (cd "$UI_DIR" && flutter test) 2>&1
    record_result "Flutter test" $?
fi

# 5. Go Backend 啟動 + 健康檢查
(cd "$SERVER_DIR" && go run . 2>/dev/null) &
server_pid=$!

health_ok=false
for i in $(seq 1 "$MAX_WAIT_SECS"); do
    if curl -sf "$HEALTH_URL" >/dev/null 2>&1; then
        health_ok=true
        break
    fi
    sleep 1
done

if [[ "$health_ok" == true ]]; then
    record_result "Health check" 0
else
    record_result "Health check" 1
fi

# 6. WebSocket 連通檢查
if [[ "$health_ok" == true ]]; then
    ws_response=$(curl -sf -o /dev/null -w "%{http_code}" \
        -H "Connection: Upgrade" \
        -H "Upgrade: websocket" \
        -H "Sec-WebSocket-Version: 13" \
        -H "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==" \
        "$WS_URL" 2>&1)
    if [[ "$ws_response" == "101" ]]; then
        record_result "WebSocket upgrade" 0
    else
        record_result "WebSocket upgrade" 1
    fi
else
    record_result "WebSocket upgrade" 1
fi

# 清理 server
kill "$server_pid" 2>/dev/null
wait "$server_pid" 2>/dev/null
server_pid=""

# 統計
echo ""
echo "=== Results ==="
total=$((pass_count + fail_count + skip_count))
echo "  Total: ${total}  Pass: ${pass_count}  Fail: ${fail_count}  Skip: ${skip_count}"

if [[ "$fail_count" -gt 0 ]]; then
    echo -e "  ${RED}FAILED${RESET}"
    exit 1
else
    echo -e "  ${GREEN}ALL PASSED${RESET}"
    exit 0
fi
