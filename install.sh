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

# === 2. 安装 docker compose plugin ===
if ! docker compose version &>/dev/null; then
  echo ">>> 安装 docker compose plugin..."
  apt-get update -qq
  apt-get install -y docker-compose-plugin
fi

# === 3. 镜像加速配置 ===
DAEMON_FILE="/etc/docker/daemon.json"
if [[ ! -f $DAEMON_FILE ]]; then
  echo ">>> 配置 Docker 镜像加速与日志限制..."
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

# === 4. 创建目录结构 ===
mkdir -p "$PROJECT_DIR"/logs
cd "$PROJECT_DIR"
echo ">>> 当前工作目录：$PROJECT_DIR"

# === 5. 交互输入配置 ===
read -rp "请输入 TELEGRAM_BOT_TOKEN: " TELEGRAM_BOT_TOKEN
if [[ -z "$TELEGRAM_BOT_TOKEN" ]]; then
  echo "❌ Bot Token 不能为空！退出。"
  exit 1
fi

read -rp "请输入 ADMIN_IDS（多个用英文逗号隔开）: " ADMIN_IDS
if [[ -z "$ADMIN_IDS" ]]; then
  echo "❌ 管理员 ID 不能为空！退出。"
  exit 1
fi

# === 6. 写入 .env 文件 ===
cat > .env <<EOF
TELEGRAM_BOT_TOKEN=${TELEGRAM_BOT_TOKEN}
ADMIN_IDS=${ADMIN_IDS}
TZ=Asia/Shanghai
EOF

echo ">>> 写入 .env 成功"

# === 7. 初始化 data.json ===
if [[ ! -f data.json || ! -s data.json ]]; then
  echo '{}' > data.json
  echo ">>> 已初始化 data.json 为空 JSON"
fi

chmod 664 data.json
chown 1000:1000 data.json

# === 8. 拉取镜像 ===
echo "⏬ 正在拉取镜像 $IMAGE..."
if ! docker pull "$IMAGE"; then
  echo "❌ 拉取镜像失败，请先执行 docker login 或更换网络后重试"
  exit 1
fi

# === 9. 启动容器 ===
echo "🚀 启动容器 v2ex-bot 中..."
docker stop v2ex-bot 2>/dev/null || true
docker rm v2ex-bot 2>/dev/null || true

docker run -d \
  --name v2ex-bot \
  --restart unless-stopped \
  --env-file .env \
  -v "$PWD/data.json:/app/data.json" \
  -v "$PWD/logs:/app/logs" \
  "$IMAGE"

sleep 2

if docker ps | grep -q v2ex-bot; then
  echo -e "\n✅ 部署完成！"
  cat <<EOF

📍 使用指南：
- 私聊 bot 输入 /v2exadd [Cookie] 添加账户
- 手动签到命令：/v2ex
- 查看日志：docker logs -f v2ex-bot
- 停止容器：docker stop v2ex-bot

EOF
else
  echo "❌ 容器启动失败，请检查日志："
  docker logs v2ex-bot
fi
