#!/bin/bash

# ================= 动态配置区域 =================
# 自动获取当前登录的用户名
CURRENT_USER=$(whoami)
# 设置脚本安装路径
SCRIPT_PATH="/home/${CURRENT_USER}/auto_sync.sh"
# 设置源目录 (当前用户的主目录)
SOURCE_DIR="/home/${CURRENT_USER}/"
# 设置备份目录
BACKUP_BASE="/hub/datasets/${CURRENT_USER}/backup"
# ===============================================

echo ">>> 正在为用户 [${CURRENT_USER}] 部署自动备份系统..."

# 1. 检查并安装 rsync
if ! command -v rsync &> /dev/null; then
    echo "正在安装 rsync..."
    sudo apt-get update && sudo apt-get install -y rsync mailutils
fi

# 2. 创建目录
echo "创建目录结构..."
# 如果源目录不存在（通常不会发生，因为是用户主目录），但为了保险
if [ ! -d "$SOURCE_DIR" ]; then
    echo "警告：源目录 $SOURCE_DIR 不存在！"
fi

if [ ! -d "$BACKUP_BASE" ]; then
    sudo mkdir -p "$BACKUP_BASE"
    # 将备份目录的所有权交给当前用户
    sudo chown -R ${CURRENT_USER}:${CURRENT_USER} "/hub/datasets"
    echo "已创建备份目录: $BACKUP_BASE"
fi

# 3. 生成核心脚本 auto_sync.sh
echo "生成备份脚本: $SCRIPT_PATH"
cat << EOF > "$SCRIPT_PATH"
#!/bin/bash
SOURCE_DIR="/home/${CURRENT_USER}/"
BASE_DEST_DIR="/hub/datasets/${CURRENT_USER}/backup"
# --- 请在部署后修改此邮箱 ---
EMAIL_ADDRESS="your_email@example.com"
LOG_FILE="/tmp/backup_log.txt"
DATE_STR=\$(date "+%Y-%m-%d %H:%M:%S")

BACKUP_TYPE=\$1
[ -z "\$BACKUP_TYPE" ] && BACKUP_TYPE="daily"
TARGET_DIR="\${BASE_DEST_DIR}/\${BACKUP_TYPE}"
[ ! -d "\$TARGET_DIR" ] && mkdir -p "\$TARGET_DIR"

echo "[\$DATE_STR] 开始 \$BACKUP_TYPE 备份..." >> "\$LOG_FILE"

rsync -av --delete "\$SOURCE_DIR" "\$TARGET_DIR" >> "\$LOG_FILE" 2>&1
STATUS=\$?

if [ \$STATUS -eq 0 ]; then
    echo "备份成功 (\$BACKUP_TYPE)"
else
    # 仅在配置了邮件服务时尝试发送
    echo "备份失败 (\$BACKUP_TYPE) 错误码: \$STATUS" | mail -s "备份失败警告" "\$EMAIL_ADDRESS"
fi
EOF

chmod +x "$SCRIPT_PATH"

# 4. 配置 Crontab
echo "配置定时任务..."
CRON_DAILY="5 17 * * * /bin/bash $SCRIPT_PATH daily"
CRON_WEEKLY="10 17 * * 1 /bin/bash $SCRIPT_PATH weekly"

(crontab -l 2>/dev/null) > current_cron

if grep -Fq "$SCRIPT_PATH daily" current_cron; then
    echo "任务已存在，跳过。"
else
    echo "$CRON_DAILY" >> current_cron
    echo "$CRON_WEEKLY" >> current_cron
    crontab current_cron
    echo "定时任务添加成功！"
fi
rm current_cron

echo ">>> 部署完成！"
echo "请记得编辑 $SCRIPT_PATH 修改接收邮件的邮箱地址。"
