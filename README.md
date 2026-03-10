# OpenClaw Migration Tool

[English](./README.md) | [中文](./README_zh.md)

A reliable migration toolkit for moving OpenClaw from one machine to another while preserving all configurations, credentials, and memories.

## Features

- 📦 **Pack** - Export OpenClaw data from the old machine
- 🔄 **Restore** - Import data to a new machine
- 🔒 **Secure** - Handles sensitive credentials with proper permissions
- 🖥️ **Cross-platform** - Works on macOS and Linux

## Quick Start

### Step 1: Pack on Old Machine

```bash
git clone https://github.com/zrh091110225/openclaw-migration-tool.git
cd openclaw-migration-tool
./pack.sh
```

### Step 2: Transfer

Copy the migration folder to the new machine via:
- USB drive
- LAN transfer
- AirDrop / local network

### Step 3: Restore on New Machine

```bash
git clone https://github.com/zrh091110225/openclaw-migration-tool.git
cd openclaw-migration-tool
./restore.sh
```

## Modules

| Module | Description | Default | Cross-platform |
|--------|-------------|:--------:|:--------------:|
| config | openclaw.json - Model, channel, auth configs | ✅ | ✅ |
| credentials | Channel tokens (Feishu/Telegram/etc) | ✅ | ✅ |
| workspace | AGENTS.md, SOUL.md, memories | ✅ | ✅ |
| memory | Conversation history | ✅ | ✅ |
| cron | Scheduled jobs | ❌ | ✅ |
| devices | Paired devices | ❌ | ⚠️ |
| extensions | Installed extensions | ❌ | ❌ |

## Security Warning

The migration package contains sensitive data (API keys, OAuth tokens, channel credentials):
- Use encrypted transfer when possible
- Delete temporary files after migration
- If you suspect any leak, rotate all API keys

## Documentation

For detailed instructions, see [Migration Guide](./MIGRATION_GUIDE.md).

## License

MIT License
