#!/usr/bin/env bash
# 本仓源码网页入口：先等 http://127.0.0.1:端口 就绪，再打开系统默认浏览器。
# 不改官方 pnpm dsh web 的默认「启动同时开浏览器」行为；本脚本显式拆成两步。
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PORT="${DSH_WEB_PORT:-3080}"
HOST="127.0.0.1"
URL="http://${HOST}:${PORT}"

# 默认清掉进程里的 DEEPSEEK_API_KEY，避免模型页锁成「由启动环境提供（只读）」。
# 若就要用环境里的钥匙：DSH_WEB_KEEP_ENV_KEY=1 bash packages/creator/dsh-web.sh
if [ "${DSH_WEB_KEEP_ENV_KEY:-0}" != "1" ]; then
  unset DEEPSEEK_API_KEY || true
fi

cd "$ROOT"

port_ready() {
  if command -v curl >/dev/null 2>&1; then
    if curl -sS -o /dev/null --connect-timeout 1 "$URL"; then
      return 0
    fi
    return 1
  fi
  if (echo >/dev/tcp/"${HOST}"/"${PORT}") >/dev/null 2>&1; then
    return 0
  fi
  return 1
}

# 停掉占用本端口的监听进程（重启意图）。Windows 用 netstat PID；其它用 fuser/lsof。
stop_listener() {
  if command -v netstat >/dev/null 2>&1; then
    local pids
    pids="$(netstat -ano 2>/dev/null | awk -v port=":${PORT}" '$0 ~ port && $0 ~ /LISTENING/ { print $NF }' | sort -u)"
    if [ -n "$pids" ]; then
      echo "dsh-web.sh: 重启，停止占用 ${PORT} 的进程"
      echo "$pids" | while read -r pid; do
        [ -n "$pid" ] || continue
        [ "$pid" = "0" ] && continue
        if command -v taskkill >/dev/null 2>&1; then
          taskkill //PID "$pid" //F >/dev/null 2>&1 || true
        else
          kill "$pid" >/dev/null 2>&1 || true
        fi
      done
      sleep 0.5
    fi
    return
  fi
  if command -v fuser >/dev/null 2>&1; then
    fuser -k "${PORT}/tcp" >/dev/null 2>&1 || true
    return
  fi
}

if [ "${DSH_WEB_RESTART:-0}" = "1" ]; then
  stop_listener
fi

open_browser() {
  # Git Bash 的 powershell.exe / cmd 可能被包装成开出控制台；优先系统 PowerShell
  local win_ps="/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe"
  if [ -x "$win_ps" ]; then
    "$win_ps" -NoProfile -Command "Start-Process '$URL'"
    return
  fi
  if command -v powershell.exe >/dev/null 2>&1; then
    powershell.exe -NoProfile -Command "Start-Process '$URL'"
    return
  fi
  if command -v cmd.exe >/dev/null 2>&1; then
    MSYS_NO_PATHCONV=1 cmd.exe //c start "" "$URL"
    return
  fi
  if command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$URL"
    return
  fi
  if command -v open >/dev/null 2>&1; then
    open "$URL"
    return
  fi
  echo "dsh-web.sh: 服务已在 ${URL}，但找不到可用的打开浏览器命令" >&2
  return 1
}

if port_ready; then
  echo "dsh-web.sh: 已在监听 ${URL}，打开浏览器"
  open_browser
  exit 0
fi

echo "dsh-web.sh: 启动服务（--no-open），就绪后再打开浏览器"
pnpm dsh web --no-open --port "$PORT" &
SERVER_PID=$!

cleanup() {
  if kill -0 "$SERVER_PID" >/dev/null 2>&1; then
    kill "$SERVER_PID" >/dev/null 2>&1 || true
  fi
}
trap cleanup INT TERM

i=0
while [ "$i" -lt 90 ]; do
  if port_ready; then
    echo "dsh-web.sh: 已就绪 ${URL}，打开浏览器"
    open_browser
    wait "$SERVER_PID"
    exit $?
  fi
  if ! kill -0 "$SERVER_PID" >/dev/null 2>&1; then
    echo "dsh-web.sh: 服务进程已退出，未能听到 ${URL}" >&2
    wait "$SERVER_PID" || true
    exit 1
  fi
  i=$((i + 1))
  sleep 0.5
done

echo "dsh-web.sh: 等待 ${URL} 超时" >&2
cleanup
exit 1
