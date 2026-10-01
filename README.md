# 每日签到汇总系统

一个基于青龙面板的每日签到汇总脚本，支持多平台签到并发送飞书通知。

## 功能特点

- 📋 支持 7+ 平台签到（百度网盘、Bilibili、微软积分等）
- 🔔 飞书机器人通知（单条汇总消息）
- ⏰ 定时任务支持（cron）
- 🎲 随机延迟防风控
- 🐳 Docker 容器集成

## 支持的平台

| 平台 | 状态 |
|------|------|
| 百度网盘 | ✅ |
| Bilibili | ✅ |
| 微软积分 | ✅ |
| 恩山论坛 | ✅ |
| 全民K歌 | ✅ |
| 百度贴吧 | ✅ |
| WPS签到 | ✅ |
| 阿里云盘 | ✅ |

## 环境要求

- Docker（运行青龙面板）
- Node.js 16+（可选）
- Python 3.8+（可选）

## 快速开始

### 1. 克隆仓库

```bash
git clone https://github.com/kunhuaa/daily-checkin.git
cd daily-checkin
```

### 2. 配置环境变量

复制 `.env.example` 并修改：

```bash
cp .env.example .env
```

需要配置：
- `FEISHU_WEBHOOK` - 飞书机器人 Webhook 地址
- `QL_COOKIE` - 青龙面板 Cookie

### 3. 运行签到

```bash
# 手动执行
bash daily_checkin.sh

# 或添加到 crontab（每天 7:00 执行）
0 7 * * * /path/to/daily_checkin.sh
```

## 文件说明

```
├── daily_checkin.sh      # 主签到脚本
├── .env.example          # 环境变量模板
├── README.md             # 说明文档
└── config.json           # 平台配置（需自行填写）
```

## 注意事项

1. 各平台的 Cookie/Token 需要自行从浏览器获取
2. 飞书 Webhook 需要在群里添加自定义机器人获取
3. 建议在青龙面板中配置环境变量，而非直接修改脚本

## 许可证

MIT License
