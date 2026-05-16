#!/bin/bash
# 大模型教材编写任务 - Claude Code 驱动脚本
# 用法: ./run-textbook.sh [章节号]
# 不带参数则从上次停止的地方继续

WORKSPACE="/home/yang/workspace"
TEXTBOOK="$WORKSPACE/大模型教材"
OUTLINE="$WORKSPACE/大模型教材大纲.md"
LOG="$TEXTBOOK/.claude-task.log"
PIDFILE="$TEXTBOOK/.claude-task.pid"

# 章节映射
CHAPTERS=(
  "02模型架构篇/第二章_预训练方法.md:第二章:预训练方法"
  "02模型架构篇/第三章_微调技术.md:第三章:微调技术"
  "02模型架构篇/第四章_高级技术.md:第四章:高级技术"
  "03应用实践篇/第一章_大模型部署.md:第一章:大模型部署"
  "03应用实践篇/第二章_模型优化.md:第二章:模型优化"
  "03应用实践篇/第三章_应用开发.md:第三章:应用开发"
  "03应用实践篇/第四章_案例实战.md:第四章:案例实战"
  "04前沿进展篇/第一章_多模态大模型.md:第一章:多模态大模型"
  "04前沿进展篇/第二章_Agent与工具使用.md:第二章:Agent与工具使用"
  "04前沿进展篇/第三章_最新研究进展.md:第三章:最新研究进展"
  "04前沿进展篇/第四章_未来展望.md:第四章:未来展望"
)

# 找下一个待写章节
find_next_chapter() {
  for entry in "${CHAPTERS[@]}"; do
    file="${entry%%:*}"
    chapter="${entry##*:}"
    if [ ! -f "$TEXTBOOK/$file" ] || [ ! -s "$TEXTBOOK/$file" ]; then
      echo "$file|$chapter"
      return
    fi
  done
  echo "ALL_DONE"
}

# 主流程
cd "$WORKSPACE"

if [ -f "$PIDFILE" ]; then
  OLD_PID=$(cat "$PIDFILE")
  if kill -0 "$OLD_PID" 2>/dev/null; then
    echo "❌ Claude Code 已在运行 (PID $OLD_PID)，先运行 stop 停止它"
    exit 1
  fi
fi

NEXT=$(find_next_chapter)
if [ "$NEXT" = "ALL_DONE" ]; then
  echo "✅ 所有章节已完成，无需继续"
  exit 0
fi

TARGET_FILE="${NEXT%%|*}"
TARGET_CHAPTER="${NEXT##|*}"

echo "📝 目标: 编写 $TARGET_CHAPTER -> $TARGET_FILE"

# 构建 Claude Code 指令
CLAUDE_CMD="阅读 $OUTLINE，然后编写大模型教材的 $TARGET_CHAPTER 内容，
输出到 $TEXTBOOK/$TARGET_FILE。

要求：
- 目标字数：5000-8000字
- 语言：中文
- 技术教材风格，面向有机器学习基础的学习者
- 公式用 LaTeX 格式（\$...\$）
- 代码块标注语言
- 重要概念加粗

写完后报告：已完成 [章节名]，共 [字数] 字"

echo "[$(date)] 开始任务: $TARGET_CHAPTER" >> "$LOG"
echo "Claude Code PID: $$" > "$PIDFILE"

nohup claude -c "$CLAUDE_CMD" >> "$LOG" 2>&1 &
CC_PID=$!
echo "$CC_PID" > "$PIDFILE"
echo "[$(date)] Claude Code PID: $CC_PID" >> "$LOG"

# 等待完成，最多等2小时
wait $CC_PID
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
  echo "[$(date)] 完成: $TARGET_CHAPTER" >> "$LOG"
  if [ -f "$TEXTBOOK/$TARGET_FILE" ]; then
    words=$(wc -w < "$TEXTBOOK/$TARGET_FILE" 2>/dev/null || echo '未知')
    echo "[$(date)] 输出: $TARGET_FILE (~${words}字)" >> "$LOG"
  fi
else
  echo "[$(date)] 失败，退出码: $EXIT_CODE" >> "$LOG"
fi

rm -f "$PIDFILE"
exit $EXIT_CODE
