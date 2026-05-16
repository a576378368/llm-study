#!/bin/bash
# 查看教材任务状态
TEXTBOOK="/home/yang/workspace/大模型教材"
LOG="$TEXTBOOK/.claude-task.log"
PIDFILE="$TEXTBOOK/.claude-task.pid"

echo "=== Claude Code 教材任务状态 ==="
echo ""

if [ -f "$PIDFILE" ]; then
  PID=$(cat "$PIDFILE" | grep -E '^[0-9]+$' | head -1)
  if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
    echo "🟢 运行中 (PID $PID)"
  else
    # PID file 无效，查找正在运行的 claude 任务
    CC_PID=$(ps aux | grep "claude -c.*大模型教材" | grep -v grep | awk '{print $2}' | head -1)
    if [ -n "$CC_PID" ]; then
      echo "🟢 运行中 (PID $CC_PID，检测到活跃进程)"
    else
      echo "⚪ 已结束"
    fi
  fi
else
  CC_PID=$(ps aux | grep "claude -c.*大模型教材" | grep -v grep | awk '{print $2}' | head -1)
  if [ -n "$CC_PID" ]; then
    echo "🟢 运行中 (PID $CC_PID，无 PID 文件但进程活跃)"
  else
    echo "⚪ 未运行"
  fi
fi

echo ""
echo "--- 最近日志 (最后20行) ---"
tail -20 "$LOG" 2>/dev/null || echo "(无日志)"

echo ""
echo "--- 章节完成情况 ---"
total=11
done=$(find "$TEXTBOOK" -name "*.md" -newer "$TEXTBOOK/02模型架构篇/第一章_Transformer架构详解.md" 2>/dev/null | grep -v "^$TEXTBOOK/0" | grep -v "^$TEXTBOOK/README" | wc -l)
# 更准确：检查每个目标文件
completed=0
total=0
for file in \
  "02模型架构篇/第二章_预训练方法.md" \
  "02模型架构篇/第三章_微调技术.md" \
  "02模型架构篇/第四章_高级技术.md" \
  "03应用实践篇/第一章_大模型部署.md" \
  "03应用实践篇/第二章_模型优化.md" \
  "03应用实践篇/第三章_应用开发.md" \
  "03应用实践篇/第四章_案例实战.md" \
  "04前沿进展篇/第一章_多模态大模型.md" \
  "04前沿进展篇/第二章_Agent与工具使用.md" \
  "04前沿进展篇/第三章_最新研究进展.md" \
  "04前沿进展篇/第四章_未来展望.md"; do
  total=$((total+1))
  if [ -s "$TEXTBOOK/$file" ]; then
    lines=$(wc -l < "$TEXTBOOK/$file")
    words=$(wc -w < "$TEXTBOOK/$file")
    echo "✅ $file ($lines 行 / ~${words}字)"
    completed=$((completed+1))
  else
    echo "⬜ $file (未开始)"
  fi
done

echo ""
echo "进度: $completed/$total 章节完成"

echo ""
echo "--- GPU 状态 ---"
nvidia-smi --query-gpu=utilization.gpu,temperature.gpu --format=csv,noheader 2>/dev/null || echo "无法获取"
