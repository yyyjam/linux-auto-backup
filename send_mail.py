# ================= 配置区域 =================
# 发送邮箱
MAIL_USER = 'your_email@qq.com'   
# 授权码
MAIL_PASS = 'YOUR_AUTH_CODE_HERE' 
# 接收邮箱
MAIL_RECEIVER = 'your_email@qq.com'
# ===========================================#!/usr/bin/env python3
import smtplib
import sys
from email.mime.text import MIMEText
from email.header import Header
from email.utils import formataddr  # <--- 新增了这个工具库

# ================= 配置区域 (请再次确认这里) =================
# 发送邮箱
MAIL_USER = 'your_email@qq.com'   
# 授权码
MAIL_PASS = 'YOUR_AUTH_CODE_HERE' 
# 接收邮箱
MAIL_RECEIVER = 'your_email@qq.com'
# ======================================================

def send_email(subject, content):
    smtp_server = 'smtp.qq.com'
    smtp_port = 465

    message = MIMEText(content, 'plain', 'utf-8')
    
    # --- 核心修复 ---
    # QQ邮箱规定：From 必须包含 昵称 和 真实邮箱地址
    # formataddr 会自动把它变成标准格式: "Linux备份助手 <123@qq.com>"
    message['From'] = formataddr(["Linux备份助手", MAIL_USER])
    message['To'] = formataddr(["管理员", MAIL_RECEIVER])
    # ----------------
    
    message['Subject'] = Header(subject, 'utf-8')

    try:
        server = smtplib.SMTP_SSL(smtp_server, smtp_port)
        server.login(MAIL_USER, MAIL_PASS)
        server.sendmail(MAIL_USER, [MAIL_RECEIVER], message.as_string())
        server.quit()
        print("邮件发送成功")
        return True
    except Exception as e:
        print(f"邮件发送失败: {e}")
        return False

if __name__ == '__main__':
    if len(sys.argv) >= 3:
        send_email(sys.argv[1], sys.argv[2])
    else:
        print("Args Error")
