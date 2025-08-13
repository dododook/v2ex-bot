# V2EX 签到机器人

基于 Telegram 的自动 V2EX 签到工具，支持手动 / 自动签到、Cookie 管理、以及多账户支持。

## 🚀 快速部署（Docker 一键安装）

```bash
bash <(curl -sSL https://raw.githubusercontent.com/dododook/v2ex-bot/refs/heads/main/install.sh)
```

> 该命令将引导你输入 TELEGRAM_BOT_TOKEN 与 ADMIN_IDS，然后自动部署容器。

---

## 📌 Bot 命令说明

| 命令 | 说明 |
|------|------|
| /v2exadd [Cookie] | 添加或更新 V2EX Cookie |
| /v2exlist         | 查看当前是否设置 Cookie |
| /v2excheck        | 手动签到一次 |
| /v2exdel          | 删除当前用户的 Cookie |
| /help             | 查看所有命令菜单 |

---

## 🧱 Docker 镜像

- 镜像名：`yaoguangting/v2ex-bot`
- 默认每日 08:00 自动签到（Asia/Shanghai）

---

## 👤 维护者

- Telegram: [@yaoguangting](https://t.me/yaoguangting)
- GitHub: [yaoguangting/v2ex-bot](https://github.com/yaoguangting/v2ex-bot)
