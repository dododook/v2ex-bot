#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="/opt/v2ex-bot"
IMAGE="yaoguangting/v2ex-bot:latest"

echo "📦 V2EX 签到机器人部署开始..."

# === 1. 检查并安装 Docker ===
if ! command -v docker &>/dev/null; then
  echo ">>> Docker 未安装，正在自动安装..."
  curl -fsSL https://get.docker.com | bash
fi

# === 2. 检查 docker compose plugin（可选）===
if ! docker compose version &>/dev/null; then
  echo ">>> 安装 docker compose plugin..."
  apt-get update -qq
  apt-get install -y docker-compose-plugin
fi

# === 3. 配置镜像加速器 + 日志限制 ===
DAEMON_FILE="/etc/docker/daemon.json"
if [[ ! -f $DAEMON_FILE ]]; then
  echo '>>> 配置 Docker 镜像加速与日志限制...'
  cat > "$DAEMON_FILE" <<EOF
{
  "registry-mirrors": ["https://hub-mirror.c.163.com"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF
  systemctl restart docker
else
  echo ">>> /etc/docker/daemon.json 已存在，重启 Docker..."
  systemctl restart docker
fi

# === 4. 创建目录并进入 ===
mkdir -p "$PROJECT_DIR"/logs
cd "$PROJECT_DIR"
echo ">>> 当前工作目录：$PROJECT_DIR"

# === 5. 用户输入配置 ===
read -rp "请输入 TELEGRAM_BOT_TOKEN: " TELEGRAM_BOT_TOKEN
read -rp "请输入 ADMIN_IDS（支持多个用英文逗号隔开）: " ADMIN_IDS

# === 6. 写入 .env 文件 ===
cat > .env <<EOF
TELEGRAM_BOT_TOKEN=${TELEGRAM_BOT_TOKEN}
ADMIN_IDS=${ADMIN_IDS}
TZ=Asia/Shanghai
EOF

# === 7. 创建数据文件和权限 ===
touch data.json
chmod 664 data.json
chown 1000:1000 data.json

# === 8. 拉取镜像 ===
echo "⏬ 正在拉取镜像 $IMAGE..."
docker pull "$IMAGE"

# === 9. 启动容器 ===
echo "🚀 正在启动容器..."
docker stop v2ex-bot 2>/dev/null || true
docker rm v2ex-bot 2>/dev/null || true

docker run -d \
  --name v2ex-bot \
  --restart unless-stopped \
  --env-file .env \
  -v "$PWD/data.json:/app/data.json" \
  -v "$PWD/logs:/app/logs" \
  "$IMAGE"

# === 10. 成功提示 ===
cat <<EOF

✅ 部署完成！

📍 请在 Telegram 中给你的机器人发送命令：
    /v2exadd [你的 Cookie]

📎 查看日志：
    docker logs -f v2ex-bot

🕗 如需每日自动签到，可手动添加 crontab：
    0 8 * * * docker exec -t v2ex-bot node /app/scripts/checkin.js

EOF
