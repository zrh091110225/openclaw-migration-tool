# OpenClaw 迁移工具

[English](./README.md) | 中文

一个可靠的迁移工具包，帮助您将 OpenClaw 从一台电脑迁移到另一台电脑，同时保留所有配置、凭证和记忆。

## 功能特性

- 📦 **打包** - 从旧电脑导出 OpenClaw 数据（支持交互式模块选择）
- 🔄 **恢复** - 将数据导入新电脑（自动验证）
- 🔒 **安全** - 正确处理敏感凭证和权限
- 🖥️ **跨平台** - 支持 macOS 和 Linux

## 快速开始

### 第一步：在旧电脑打包

```bash
git clone https://github.com/zrh091110225/openclaw-migration-tool.git
cd openclaw-migration-tool
./pack.sh
```

打包脚本会交互式询问您要包含哪些模块：

| 模块 | 说明 | 默认 | 跨平台 |
|-----|------|:----:|:------:|
| config | openclaw.json - 模型、渠道、认证配置 | ✅ (是) | ✅ |
| credentials | 渠道凭证 (飞书/Telegram/WhatsApp等 token) | ✅ (是) | ✅ |
| workspace | 工作区文件 (AGENTS.md, SOUL.md, MEMORY.md 等) | ✅ (是) | ✅ |
| memory | 对话历史 (SQLite 数据库) | ✅ (是) | ✅ |
| cron | 定时任务配置 | ❌ (否) | ✅ |
| devices | 配对设备信息 | ❌ (否) | ⚠️ (硬件绑定) |
| extensions | 已安装扩展 | ❌ (否) | ❌ (不兼容) |

**默认选择**：如果直接按回车不输入，将应用默认选项（Y 为是，N 为否）

**推荐大多数用户选择**：config + credentials + workspace + memory（默认选项）

### 第二步：传输迁移包

将迁移目录复制到新电脑：
- U 盘
- 局域网传输 (SCP, Rsync)
- AirDrop / 隔空投送

迁移包生成位置：`~/openclaw-migration/`

### 第三步：在新电脑恢复

**前置依赖：**
- 新电脑必须已安装 OpenClaw
- 如果未安装，恢复脚本会提示您安装
- Gateway 应处于停止状态（脚本会自动处理）

```bash
git clone https://github.com/zrh091110225/openclaw-migration-tool.git
cd openclaw-migration-tool
./restore.sh
```

恢复脚本会：
1. 检查 OpenClaw 是否已安装（如未安装则安装）
2. 停止 Gateway（如果正在运行）
3. 备份现有数据（如果有）
4. 恢复选中的模块
5. 修复文件权限（对凭证目录至关重要）
6. 运行 `openclaw doctor` 修复配置（推荐）
7. 启动 Gateway 并验证

## 模块详解

### ✅ config (openclaw.json)
**包含内容：**
- 模型配置（提供商、模型名称、API Key）
- 渠道设置（飞书、Telegram、Discord 等）
- Gateway 配置
- 默认行为设置

**建议选择：** 始终推荐 - 这是您的核心配置

### ✅ credentials
**包含内容：**
- 已连接渠道的 OAuth token
- 存储在 keychain 中的 API Key
- 渠道认证状态

**建议选择：** 如果希望保持渠道连接状态而无需重新认证

### ✅ workspace
**包含内容：**
- AGENTS.md - Agent 配置
- SOUL.md - Agent 人设
- MEMORY.md - 长期记忆
- USER.md - 用户信息
- TOOLS.md - 工具配置
- 自定义技能和脚本

**建议选择：** 始终推荐 - 这是您 Agent 的"大脑"

### ✅ memory
**包含内容：**
- 对话历史（SQLite 数据库）
- 会话日志

**建议选择：** 如果希望保留对话上下文

### ❌ cron
**包含内容：**
- 定时任务配置

**建议选择：** 仅当您有自定义定时任务时

### ❌ devices
**包含内容：**
- 配对设备信息

**建议选择：** 不推荐 - 设备与硬件绑定，需要在新电脑上重新配对

### ❌ extensions
**包含内容：**
- 已安装的飞书扩展或插件

**建议选择：** 不推荐 - 扩展不支持跨平台，应在新电脑上重新安装

## 安全警告

迁移包包含敏感数据（API 密钥、OAuth 令牌、渠道凭证）：
- 传输时建议使用加密方式
- 迁移完成后及时删除临时文件
- 如怀疑泄露，请轮换所有 API 密钥

## 详细文档

详细说明请参阅 [迁移指南](./MIGRATION_GUIDE.md)。

## 相关链接

- [OpenClaw 官方文档](https://docs.openclaw.ai)
- [OpenClaw Doctor](https://docs.openclaw.ai/gateway/doctor)

## 许可证

MIT License
