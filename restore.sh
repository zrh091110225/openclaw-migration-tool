#!/bin/bash

#==========================================
# OpenClaw 数据迁移 - 恢复脚本
# 功能：在新电脑上恢复迁移的数据
#==========================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 路径
MIGRATION_DIR="$HOME/openclaw-migration"
OPENCLAW_DIR="$HOME/.openclaw"
MANIFEST_FILE="$MIGRATION_DIR/migration-manifest.json"

#==========================================
# 辅助函数
#==========================================

print_header() {
    echo -e "${BLUE}=========================================="
    echo -e "  OpenClaw 数据迁移 - 恢复脚本"
    echo -e "==========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# 检查迁移包
check_migration_package() {
    if [ ! -d "$MIGRATION_DIR" ]; then
        print_error "未找到迁移目录: $MIGRATION_DIR"
        echo ""
        echo "请先将旧电脑的迁移目录复制到此处"
        exit 1
    fi
    
    if [ ! -f "$MIGRATION_DIR/openclaw-migration.tar.gz" ]; then
        print_error "未找到迁移包文件"
        exit 1
    fi
    
    if [ ! -f "$MANIFEST_FILE" ]; then
        print_warning "未找到元数据文件，将跳过版本检查"
    else
        print_success "找到迁移包"
        cat "$MANIFEST_FILE"
        echo ""
    fi
}

# 检查并处理OpenClaw
check_openclaw() {
    echo ""
    echo -e "${BLUE}检查 OpenClaw 安装状态...${NC}"
    
    if command -v openclaw &> /dev/null; then
        CURRENT_VERSION=$(openclaw --version 2>/dev/null)
        print_success "OpenClaw 已安装: $CURRENT_VERSION"
        
        # 如果有manifest，检查版本
        if [ -f "$MANIFEST_FILE" ]; then
            MANIFEST_VERSION=$(cat "$MANIFEST_FILE" | grep -o '"openclaw_version": "[^"]*"' | head -1 | cut -d'"' -f4)
            
            if [ -n "$MANIFEST_VERSION" ] && [ "$MANIFEST_VERSION" != "unknown" ]; then
                echo ""
                print_info "迁移包版本: $MANIFEST_VERSION"
                print_info "当前版本:   $CURRENT_VERSION"
                
                # 简单版本比较 (主版本号)
                MANIFEST_MAJOR=$(echo "$MANIFEST_VERSION" | cut -d'.' -f1)
                CURRENT_MAJOR=$(echo "$CURRENT_VERSION" | cut -d'.' -f1)
                
                if [ "$MANIFEST_MAJOR" -gt "$CURRENT_MAJOR" ]; then
                    print_warning "迁移包版本较新，建议升级"
                    read -p "是否现在升级 OpenClaw? (y/n): " -n 1 -r
                    echo
                    if [[ $REPLY =~ ^[Yy]$ ]]; then
                        npm install -g openclaw
                        print_success "OpenClaw 已升级"
                    fi
                fi
            fi
        fi
    else
        print_warning "OpenClaw 未安装"
        read -p "是否现在安装 OpenClaw? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            npm install -g openclaw
            print_success "OpenClaw 安装完成"
        else
            print_error "无法继续，请先安装 OpenClaw"
            exit 1
        fi
    fi
}

# 停止gateway
stop_gateway() {
    echo ""
    echo -e "${BLUE}停止 OpenClaw gateway...${NC}"
    
    if openclaw gateway status &> /dev/null; then
        openclaw gateway stop
        print_success "gateway 已停止"
    else
        print_info "gateway 未运行"
    fi
}

# 备份现有数据
backup_existing_data() {
    if [ -d "$OPENCLAW_DIR" ] && [ "$(ls -A $OPENCLAW_DIR 2>/dev/null)" ]; then
        print_warning "检测到现有 OpenClaw 数据"
        read -p "是否备份现有数据? (y/n): " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            BACKUP_DIR="$HOME/openclaw-backup-$(date +%Y%m%d-%H%M%S)"
            cp -r "$OPENCLAW_DIR" "$BACKUP_DIR"
            print_success "现有数据已备份到: $BACKUP_DIR"
        fi
    fi
}

# 恢复数据
restore_data() {
    echo ""
    echo -e "${BLUE}开始恢复数据...${NC}"
    
    # 确保目录存在
    mkdir -p "$OPENCLAW_DIR"
    
    # 解压
    tar -xzvf "$MIGRATION_DIR/openclaw-migration.tar.gz" -C "$OPENCLAW_DIR"
    
    print_success "数据已恢复到: $OPENCLAW_DIR"
}

# 修复权限
fix_permissions() {
    echo ""
    echo -e "${BLUE}修复文件权限...${NC}"
    
    # credentials 目录必须为 700
    if [ -d "$OPENCLAW_DIR/credentials" ]; then
        chmod 700 "$OPENCLAW_DIR/credentials"
        print_success "credentials 权限已修复"
    fi
    
    # 检查 key 文件
    find "$OPENCLAW_DIR" -name "*.json" -exec chmod 600 {} \; 2>/dev/null
    print_success "文件权限已修复"
}

# 显示迁移信息
show_migration_info() {
    if [ -f "$MANIFEST_FILE" ]; then
        echo ""
        echo -e "${GREEN}=========================================="
        echo -e "  迁移信息"
        echo -e "==========================================${NC}"
        echo ""
        
        # 解析并显示关键信息
        echo "📦 迁移模块:"
        cat "$MANIFEST_FILE" | grep -A 20 '"selected_modules"' | head -15
        
        echo ""
        echo "🖥️  源机器:"
        cat "$MANIFEST_FILE" | grep -A 5 '"source_machine"' | grep -v "^{" | grep -v "^  }"
        
        if [ -n "$(cat "$MANIFEST_FILE" | grep '"notes"')" ]; then
            echo ""
            echo "📝 备注:"
            cat "$MANIFEST_FILE" | grep '"notes"' | cut -d'"' -f4
        fi
    fi
}

# 验证恢复
verify_restore() {
    echo ""
    echo -e "${BLUE}验证恢复结果...${NC}"
    
    local verified=0
    
    # 检查关键文件
    if [ -f "$OPENCLAW_DIR/openclaw.json" ]; then
        print_success "配置文件已恢复"
        verified=$((verified + 1))
    fi
    
    if [ -d "$OPENCLAW_DIR/credentials" ]; then
        print_success "凭证目录已恢复"
        verified=$((verified + 1))
    fi
    
    if [ -d "$OPENCLAW_DIR/workspace" ]; then
        print_success "工作区已恢复"
        verified=$((verified + 1))
    fi
    
    if [ -d "$OPENCLAW_DIR/memory" ]; then
        print_success "对话历史已恢复"
        verified=$((verified + 1))
    fi
    
    echo ""
    if [ $verified -ge 3 ]; then
        print_success "核心数据恢复成功"
    else
        print_warning "部分数据可能未正确恢复，请检查"
    fi
}

# 运行 openclaw doctor（官方推荐的关键步骤）
run_doctor() {
    echo ""
    echo -e "${BLUE}运行 openclaw doctor 修复配置...${NC}"
    echo ""
    echo "此命令会:"
    echo "  • 检查并修复配置文件"
    echo "  • 应用配置迁移"
    echo "  • 警告版本不匹配问题"
    echo ""
    
    read -p "是否运行 doctor? (y/n): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        openclaw doctor
        print_success "doctor 执行完成"
    else
        print_warning "跳过 doctor，建议手动运行以确保配置正确"
    fi
}

# 启动并验证
start_and_verify() {
    echo ""
    echo -e "${BLUE}启动 OpenClaw gateway...${NC}"
    
    openclaw gateway start
    
    sleep 2
    
    if openclaw gateway status &> /dev/null; then
        print_success "gateway 已启动"
    else
        print_error "gateway 启动失败，请检查配置"
    fi
}

# 验证迁移结果
final_verification() {
    echo ""
    echo -e "${BLUE}=========================================="
    echo -e "  验证检查清单"
    echo -e "==========================================${NC}"
    echo ""
    
    # 检查 gateway 状态
    if openclaw status &> /dev/null; then
        print_success "✅ Gateway 正在运行"
    else
        print_error "❌ Gateway 未运行"
    fi
    
    # 检查工作区文件
    if [ -f "$OPENCLAW_DIR/workspace/MEMORY.md" ] || [ -f "$OPENCLAW_DIR/workspace/AGENTS.md" ]; then
        print_success "✅ 工作区文件存在"
    else
        print_warning "⚠️ 工作区文件可能不存在"
    fi
    
    # 检查凭证
    if [ -d "$OPENCLAW_DIR/credentials" ]; then
        print_success "✅ 凭证目录存在"
    fi
    
    echo ""
    echo "请手动确认:"
    echo "  • 各渠道是否仍连接（如 WhatsApp 无需重新配对）"
    echo "  • 仪表板是否显示现有会话"
    echo "  • 工作区文件（记忆、配置）是否完整"
}

# 显示后续步骤
show_next_steps() {
    echo ""
    echo -e "${GREEN}=========================================="
    echo -e "  恢复完成!"
    echo -e "==========================================${NC}"
    echo ""
    echo "📋 后续步骤:"
    echo "  1. 检查各渠道是否正常工作 (飞书/Telegram等)"
    echo "  2. 如有设备需要配对，使用 'openclaw nodes pair' 重新配对"
    echo "  3. 如使用扩展，可能需要在新电脑重新安装"
    echo ""
    echo "🗑️  清理建议:"
    echo "  - 确认迁移成功后，可删除旧电脑数据"
    echo "  - 如有备份，可保留1-2周后再删除"
    echo ""
}

#==========================================
# 主流程
#==========================================

main() {
    print_header
    
    # 检查迁移包
    check_migration_package
    
    # 检查OpenClaw
    check_openclaw
    
    # 停止gateway
    stop_gateway
    
    # 备份现有数据
    backup_existing_data
    
    # 恢复数据
    restore_data
    
    # 修复权限
    fix_permissions
    
    # 显示迁移信息
    show_migration_info
    
    # 验证
    verify_restore
    
    # 运行 doctor（关键步骤）
    run_doctor
    
    # 启动
    start_and_verify
    
    # 最终验证
    final_verification
    
    # 后续步骤
    show_next_steps
}

# 运行
main "$@"
