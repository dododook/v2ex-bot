#!/bin/bash

set -e

echo "📦 V2EX 签到机器人部署开始..."

# 1. 输入配置
read -p "请输入 TELEGRAM_BOT_TOKEN: " TELEGRAM_BOT_TOKEN
read -p "请输入 ADMIN_IDS（支持多个用英文逗号隔开）: " ADMIN_IDS

# 2. 创建目录
WORKDIR="/opt/v2ex-bot"
mkdir -p "$WORKDIR"/logs
cd "$WORKDIR"

# 3. 创建 .env 文件
cat > .env <<EOF
TELEGRAM_BOT_TOKEN=${TELEGRAM_BOT_TOKEN}
ADMIN_IDS=${ADMIN_IDS}
TZ=Asia/Shanghai
EOF

# 4. 创建 data.json 并赋权限
touch data.json
chmod 664 data.json
chown 1000:1000 data.json

# 5. 拉取镜像
echo "⏬ 正在拉取镜像 yaoguangting/v2ex-bot:latest..."
docker pull yaoguangting/v2ex-bot:latest

# 6. 运行容器
echo "🚀 正在启动容器..."
docker stop v2ex-bot 2>/dev/null || true
docker rm v2ex-bot 2>/dev/null || true

docker run -d \
  --name v2ex-bot \
  --restart unless-stopped \
  --env-file .env \
  -v $PWD/data.json:/app/data.json \
  -v $PWD/logs:/app/logs \
  yaoguangting/v2ex-bot:latest

echo "✅ 部署完成！"
echo "📍 请在 Telegram 中给你的机器人发送命令 /v2exadd [Cookie] 来添加账户"