#!/bin/bash

set -e

echo "📦 正在初始化 V2EX 签到机器人环境..."

# 设置变量
DIR="/opt/v2ex-bot"
REPO="yaoguangting/v2ex-bot"
IMAGE_TAG="latest"

# 创建目录
mkdir -p "$DIR/logs"
cd "$DIR"

# 交互获取用户输入
read -p "请输入你的 Telegram Bot Token: " TELEGRAM_BOT_TOKEN
read -p "请输入你的 Telegram 用户 ID（多个用英文逗号隔开）: " ADMIN_IDS

# 写入 .env 文件
cat <<EOF > "$DIR/.env"
TELEGRAM_BOT_TOKEN=${TELEGRAM_BOT_TOKEN}
ADMIN_IDS=${ADMIN_IDS}
TZ=Asia/Shanghai
EOF

# 如果不存在 data.json 就创建
if [ ! -f "$DIR/data.json" ]; then
  touch "$DIR/data.json"
  chown 1000:1000 "$DIR/data.json"
fi

# 拉取镜像（如使用远程仓库）
echo "📥 拉取 Docker 镜像..."
docker pull ${REPO}:${IMAGE_TAG}

# 停止并删除旧容器
echo "🧹 清理旧容器（如有）..."
docker stop v2ex-bot 2>/dev/null || true
docker rm v2ex-bot 2>/dev/null || true

# 启动容器
echo "🚀 启动 V2EX 签到机器人..."
docker run -d \
  --name v2ex-bot \
  --restart unless-stopped \
  --env-file "$DIR/.env" \
  -v "$DIR/data.json:/app/data.json" \
  -v "$DIR/logs:/app/logs" \
  ${REPO}:${IMAGE_TAG}

echo "✅ 安装完成！你现在可以在 Telegram 中使用你的 bot 了。"
