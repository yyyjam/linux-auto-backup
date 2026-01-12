#!/bin/bash
# ================= 配置区域 =================
CURRENT_USER=$(whoami)
# 安装目标路径
INSTALL_DIR="/home/${CURRENT_USER}"
SCRIPT_SYNC="${INSTALL_DIR}/auto_sync.sh"
SCRIPT_MAIL="${INSTALL_DIR}/send_mail.py"
# ===========================================

echo ">>> 开始安装备份系统..."

# 1. 检查必要软件
if ! command -v rsync &> /dev/null; then
    echo "安装依赖: rsync..."
    sudo apt-get update && sudo apt-get install -y rsync
fi

# 2. 复制脚本文件
echo "正在部署脚本到 ${INSTALL_DIR} ..."
cp auto_sync.sh "$SCRIPT_SYNC"
cp send_mail.py "$SCRIPT_MAIL"

# 3. 赋予权限
chmod +x "$SCRIPT_SYNC"
# python脚本不需要执行权限，但给上也无妨
chmod +x "$SCRIPT_MAIL"

echo "✅ 脚本部署完成。"
echo "⚠️  重要提示：请务必编辑 ${SCRIPT_MAIL} 填入你的真实邮箱和授权码！"

# 4. 配置定时任务
echo "配置定时任务..."
CRON_DAILY="5 17 * * * /bin/bash $SCRIPT_SYNC daily"
CRON_WEEKLY="10 17 * * 1 /bin/bash $SCRIPT_SYNC weekly"

(crontab -l 2>/dev/null) > current_cron

if grep -Fq "$SCRIPT_SYNC daily" current_cron; then
    echo "任务已存在，跳过。"
else
    echo "$CRON_DAILY" >> current_cron
    echo "$CRON_WEEKLY" >> current_cron
    crontab current_cron
    echo "✅ 定时任务添加成功！"
fi
rm current_cron

echo ">>> 安装全部完成！"
