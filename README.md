# OpenClaw Migration Tool

[English](./README.md) | [中文](./README_zh.md)

A reliable migration toolkit for moving OpenClaw from one machine to another while preserving all configurations, credentials, and memories.

## Features

- 📦 **Pack** - Export OpenClaw data from the old machine (with interactive module selection)
- 🔄 **Restore** - Import data to a new machine (with automatic validation)
- 🔒 **Secure** - Handles sensitive credentials with proper permissions
- 🖥️ **Cross-platform** - Works on macOS and Linux

## Quick Start

### Step 1: Pack on Old Machine

```bash
git clone https://github.com/zrh091110225/openclaw-migration-tool.git
cd openclaw-migration-tool
./pack.sh
```

The pack script will interactively ask you which modules to include:

| Module | Description | Default | Cross-platform |
|--------|-------------|:--------:|:--------------:|
| config | openclaw.json - Model, channel, auth configs | ✅ (Yes) | ✅ |
| credentials | Channel tokens (Feishu/Telegram/WhatsApp/etc) | ✅ (Yes) | ✅ |
| workspace | Workspace files (AGENTS.md, SOUL.md, MEMORY.md, etc) | ✅ (Yes) | ✅ |
| memory | Conversation history (SQLite database) | ✅ (Yes) | ✅ |
| cron | Scheduled tasks configuration | ❌ (No) | ✅ |
| devices | Paired devices information | ❌ (No) | ⚠️ (hardware-bound) |
| extensions | Installed extensions | ❌ (No) | ❌ (incompatible) |

**Default Selection**: If you press Enter without typing, the default option (Y for Yes, N for No) will be applied.

**Recommended for most users**: Select config + credentials + workspace + memory (the defaults)

### Step 2: Transfer

Copy the migration folder to the new machine via:
- USB drive
- LAN transfer (SCP, Rsync)
- AirDrop / local network

The migration package will be created at: `~/openclaw-migration/`

### Step 3: Restore on New Machine

**Prerequisites:**
- OpenClaw must be installed on the new machine
- If not installed, the restore script will prompt you to install it
- Gateway should be stopped (the script will handle this)

```bash
git clone https://github.com/zrh091110225/openclaw-migration-tool.git
cd openclaw-migration-tool
./restore.sh
```

The restore script will:
1. Check if OpenClaw is installed (install if needed)
2. Stop the gateway if running
3. Backup existing data (if any)
4. Restore selected modules
5. Fix file permissions (critical for credentials)
6. Run `openclaw doctor` to fix configuration (recommended)
7. Start the gateway and verify

## Module Details

### ✅ config (openclaw.json)
**What it includes:**
- Model configuration (provider, model name, API keys)
- Channel settings (Feishu, Telegram, Discord, etc.)
- Gateway configuration
- Default behaviors

**When to include:** Always recommended - this is your core configuration

### ✅ credentials
**What it includes:**
- OAuth tokens for connected channels
- API keys stored in keychain
- Channel authentication state

**When to include:** If you want to keep channels connected without re-authentication

### ✅ workspace
**What it includes:**
- AGENTS.md - Agent configuration
- SOUL.md - Agent persona
- MEMORY.md - Long-term memories
- USER.md - User information
- TOOLS.md - Tool configurations
- Custom skills and scripts

**When to include:** Always recommended - this contains your agent's "brain"

### ✅ memory
**What it includes:**
- Conversation history (SQLite database)
- Session logs

**When to include:** If you want to preserve conversation context

### ❌ cron
**What it includes:**
- Scheduled task configurations

**When to include:** Only if you have custom cron jobs set up

### ❌ devices
**What it includes:**
- Paired device information

**When to include:** Not recommended - devices are hardware-bound and need to be re-paired on the new machine

### ❌ extensions
**What it includes:**
- Installed Feishu extensions or plugins

**When to include:** Not recommended - extensions are not cross-platform compatible and should be reinstalled on the new machine

## Security Warning

The migration package contains sensitive data (API keys, OAuth tokens, channel credentials):
- Use encrypted transfer when possible
- Delete temporary files after migration
- If you suspect any leak, rotate all API keys

## Documentation

For detailed instructions, see [Migration Guide](./MIGRATION_GUIDE.md).

## Related

- [OpenClaw Official Docs](https://docs.openclaw.ai)
- [OpenClaw Doctor](https://docs.openclaw.ai/gateway/doctor)

## License

MIT License
