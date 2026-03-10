# OpenClaw 迁移工具

[English](./README.md) | 中文

一个可靠的迁移工具包，帮助您将 OpenClaw 从一台电脑迁移到另一台电脑，同时保留所有配置、凭证和记忆。

## 功能特性

- 📦 **打包** - 从旧电脑导出 OpenClaw 数据
- 🔄 **恢复** - 将数据导入新电脑
- 🔒 **安全** - 正确处理敏感凭证和权限
- 🖥️ **跨平台** - 支持 macOS 和 Linux

## 快速开始

### 第一步：在旧电脑打包

```bash
git clone https://github.com/zrh091110225/openclaw-migration-tool.git
cd openclaw-migration-tool
./pack.sh
```

### 第二步：传输迁移包

将迁移目录复制到新电脑：
- U 盘
- 局域网传输
- AirDrop / 隔空投送

### 第三步：在新电脑恢复

```bash
git clone https://github.com/zrh091110225/openclaw-migration-tool.git
cd openclaw-migration-tool
./restore.sh
```

## 模块说明

| 模块 | 说明 | 默认 | 跨平台 |
|-----|------|:----:|:------:|
| config | openclaw.json - 模型、渠道、认证配置 | ✅ | ✅ |
| credentials | 渠道凭证 - 飞书/Telegram等 token | ✅ | ✅ |
| workspace | 工作区 - AGENTS.md、SOUL.md、记忆等 | ✅ | ✅ |
| memory | 对话历史 | ✅ | ✅ |
| cron | 定时任务 | ❌ | ✅ |
| devices | 设备配对 | ❌ | ⚠️ |
| extensions | 已安装扩展 | ❌ | ❌ |

## 安全警告

迁移包包含敏感数据（API 密钥、OAuth 令牌、渠道凭证）：
- 传输时建议使用加密方式
- 迁移完成后及时删除临时文件
- 如怀疑泄露，请轮换所有 API 密钥

## 详细文档

详细说明请参阅 [迁移指南](./MIGRATION_GUIDE.md)。

## 许可证

MIT License
