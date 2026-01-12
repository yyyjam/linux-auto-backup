#!/bin/bash

# ================= 配置区域 =================
# 源目录
SOURCE_DIR="/home/xinzhe/"

# 目标基础目录
BASE_DEST_DIR="/hub/datasets/xinzhe/backup"

# 日志文件路径
LOG_FILE="/tmp/backup_log.txt"

# Python 发信脚本路径 (必须确认这个文件存在且配置正确)
MAIL_SCRIPT="/home/xinzhe/send_mail.py"

# 获取当前时间
DATE_STR=$(date "+%Y-%m-%d %H:%M:%S")
# ===========================================

# 1. 获取参数 (daily 或 weekly)，默认为 daily
BACKUP_TYPE=$1
if [ -z "$BACKUP_TYPE" ]; then
    BACKUP_TYPE="daily"
fi

# 2. 确定具体备份目录
TARGET_DIR="${BASE_DEST_DIR}/${BACKUP_TYPE}"

# 3. 确保目录存在
if [ ! -d "$TARGET_DIR" ]; then
    mkdir -p "$TARGET_DIR"
fi

# 4. 记录开始时间到日志
echo "------------------------------------------------" >> "$LOG_FILE"
echo "[$DATE_STR] 开始执行 $BACKUP_TYPE 备份..." >> "$LOG_FILE"

# 5. === 执行 RSYNC 同步 ===
# -a: 归档模式
# -v: 详细输出
# --delete: 镜像同步 (源目录删除的文件，备份目录也会删除)
rsync -av --delete "$SOURCE_DIR" "$TARGET_DIR" >> "$LOG_FILE" 2>&1

# 获取 rsync 退出状态码 (0 表示成功)
RSYNC_STATUS=$?

# 6. === 准备邮件内容 ===
# 获取日志文件的最后 10 行，作为邮件正文的一部分
LOG_TAIL=$(tail -n 10 "$LOG_FILE")

if [ $RSYNC_STATUS -eq 0 ]; then
    # --- 成功情况 ---
    SUBJECT="[成功] 数据备份通知 - $BACKUP_TYPE"
    BODY="备份成功完成。\n\n执行时间: $DATE_STR\n备份类型: $BACKUP_TYPE\n源目录: $SOURCE_DIR\n目标目录: $TARGET_DIR\n\n--- 日志摘要 ---\n$LOG_TAIL"
else
    # --- 失败情况 ---
    SUBJECT="[失败] 严重警告：数据备份异常 - $BACKUP_TYPE"
    BODY="备份过程中发生错误，请立即检查服务器！\n\n执行时间: $DATE_STR\n错误代码: $RSYNC_STATUS\n\n--- 日志摘要 ---\n$LOG_TAIL"
fi

# 7. === 调用 Python 脚本发送邮件 ===
# 这里不再使用 Linux 自带的 mail，而是调用我们写好的 Python 脚本
echo "正在发送邮件通知..."
python3 "$MAIL_SCRIPT" "$SUBJECT" "$BODY"

# 8. 终端输出结果 (方便手动调试)
echo "备份任务结束。状态码: $RSYNC_STATUS"
