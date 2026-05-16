#!/bin/bash
# 停止 Claude Code 教材任务
PIDFILE="/home/yang/workspace/大模型教材/.claude-task.pid"
LOG="/home/yang/workspace/大模型教材/.claude-task.log"

if [ -f "$PIDFILE" ]; then
  PID=$(cat "$PIDFILE")
  if kill -0 "$PID" 2>/dev/null; then
    echo "停止 PID $PID ..."
    kill "$PID"
    sleep 1
    kill -9 "$PID" 2>/dev/null
    echo "已停止"
  else
    echo "进程不存在"
  fi
  rm -f "$PIDFILE"
else
  # fallback: 杀所有 claude 进程
  pkill -f "claude -c.*大模型教材"
  echo "已发送 kill 信号"
fi

echo "--- 最近日志 ---"
tail -20 "$LOG" 2>/dev/null
