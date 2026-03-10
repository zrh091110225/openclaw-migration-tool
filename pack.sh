#!/bin/bash

#==========================================
# OpenClaw 数据迁移 - 打包脚本
# 功能：在旧电脑上打包需要迁移的数据
#==========================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# OpenClaw 数据目录
OPENCLAW_DIR="$HOME/.openclaw"
OUTPUT_DIR="$HOME/openclaw-migration"

# 模块列表（格式：id|描述|默认值）
MODULES=(
    "config|openclaw.json:配置文件 - 模型、渠道、认证配置|1"
    "credentials|credentials/:认证凭证 - 飞书/Telegram等渠道token|1"
    "workspace|workspace/:工作区 - AGENTS.md、SOUL.md、记忆等|1"
    "memory|memory/:对话历史 - main.sqlite 历史会话|1"
    "cron|cron/:定时任务 - jobs.json 定时任务配置|0"
    "devices|devices/:设备配对 - paired.json 配对设备信息|0"
    "extensions|extensions/:已安装扩展 - 飞书插件等(跨平台不兼容)|0"
)

# 选中的模块
SELECTED_MODULES=""

#==========================================
# 辅助函数
#==========================================

print_header() {
    echo -e "${BLUE}=========================================="
    echo -e "  OpenClaw 数据迁移 - 打包脚本"
    echo -e "==========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# 检查OpenClaw是否运行
check_gateway() {
    if netstat -an | grep -q "18789.*LISTEN" 2>/dev/null || ss -tln | grep -q ":18789" 2>/dev/null; then
        print_warning "检测到 OpenClaw gateway 正在运行"
        read -p "打包前需要停止 gateway，是否现在停止? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            openclaw gateway stop
            sleep 2
            print_success "gateway 已停止"
        else
            print_error "请手动停止 gateway 后再运行此脚本"
            exit 1
        fi
    else
        print_info "gateway 未运行"
    fi
}

# 检查数据目录
check_directory() {
    if [ ! -d "$OPENCLAW_DIR" ]; then
        print_error "未找到 OpenClaw 数据目录: $OPENCLAW_DIR"
        exit 1
    fi
    print_success "数据目录: $OPENCLAW_DIR"
}

# 交互式选择模块
select_modules() {
    echo ""
    echo -e "${BLUE}请选择要打包的模块:${NC}"
    echo ""
    
    for module_info in "${MODULES[@]}"; do
        module_id=$(echo "$module_info" | cut -d'|' -f1)
        module_desc=$(echo "$module_info" | cut -d'|' -f2)
        module_default=$(echo "$module_info" | cut -d'|' -f3)
        
        if [ "$module_default" -eq 1 ]; then
            prompt="Y/n"
        else
            prompt="y/N"
        fi
        
        read -p "$module_id: $module_desc [$prompt] " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY && "$module_default" -eq 1 ]]; then
            SELECTED_MODULES="$SELECTED_MODULES $module_id"
            echo -e "   └── ${GREEN}已选择${NC}"
        else
            echo -e "   └── ${YELLOW}已跳过${NC}"
        fi
    done
}

# 检测操作系统
detect_os() {
    OS=$(uname -s)
    case "$OS" in
        Darwin*)     echo "macOS";;
        Linux*)      echo "Linux";;
        CYGWIN*|MINGW*|MSYS*) echo "Windows";;
        *)           echo "Unknown";;
    esac
}

# 获取模块对应的目录
get_module_dir() {
    local module_id="$1"
    case "$module_id" in
        config) echo "openclaw.json";;
        credentials) echo "credentials";;
        workspace) echo "workspace";;
        memory) echo "memory";;
        cron) echo "cron";;
        devices) echo "devices";;
        extensions) echo "extensions";;
    esac
}

# 生成元数据文件
generate_manifest() {
    local notes="$1"
    local openclaw_version=$(openclaw --version 2>/dev/null || echo "unknown")
    local os_name=$(detect_os)
    
    local modules_json="["
    for m in $SELECTED_MODULES; do
        modules_json="$modules_json\"$m\","
    done
    modules_json="${modules_json%,}]"
    
    cat > "$OUTPUT_DIR/migration-manifest.json" << EOF
{
  "manifest_version": "1.0",
  "generated_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "source_machine": {
    "hostname": "$(hostname)",
    "os": "$os_name",
    "os_version": "$(uname -r)",
    "arch": "$(uname -m)",
    "username": "$USER"
  },
  "openclaw_version": "$openclaw_version",
  "selected_modules": $modules_json,
  "migration_type": "backup",
  "notes": "$notes"
}
EOF
}

# 执行打包
create_package() {
    echo ""
    echo -e "${BLUE}开始打包...${NC}"
    
    mkdir -p "$OUTPUT_DIR"
    
    TEMP_DIR=$(mktemp -d)
    trap "rm -rf $TEMP_DIR" EXIT
    
    for module in $SELECTED_MODULES; do
        source_dir=$(get_module_dir "$module")
        if [ -e "$OPENCLAW_DIR/$source_dir" ]; then
            cp -r "$OPENCLAW_DIR/$source_dir" "$TEMP_DIR/"
            print_success "已添加: $module"
        else
            print_warning "跳过: $module (文件不存在)"
        fi
    done
    
    cd "$TEMP_DIR"
    tar -czvf "$OUTPUT_DIR/openclaw-migration.tar.gz" ./*
    
    print_success "迁移包已创建: $OUTPUT_DIR/openclaw-migration.tar.gz"
}

# 显示完成信息
show_summary() {
    echo ""
    echo -e "${GREEN}=========================================="
    echo -e "  打包完成!"
    echo -e "==========================================${NC}"
    echo ""
    echo "生成的文件:"
    echo "  1. openclaw-migration.tar.gz - 迁移数据包"
    echo "  2. migration-manifest.json  - 迁移元数据"
    echo ""
    echo -e "${YELLOW}⚠️  安全警告:${NC}"
    echo "  迁移包包含敏感数据（API密钥、OAuth令牌、渠道凭证）"
    echo "  • 传输时建议使用加密方式"
    echo "  • 避免通过不安全的渠道共享"
    echo "  • 迁移完成后及时删除临时文件"
    echo "  • 如怀疑泄露，请轮换所有API密钥"
    echo ""
    echo "下一步:"
    echo "  1. 将输出目录传输到新电脑: $OUTPUT_DIR"
    echo "  2. 在新电脑上运行恢复脚本"
    echo ""
    
    ls -lh "$OUTPUT_DIR/"
}

#==========================================
# 主流程
#==========================================

main() {
    print_header
    
    check_directory
    check_gateway
    
    echo ""
    read -p "请输入备注信息 (可选，直接回车跳过): " notes
    echo ""
    
    select_modules
    
    if [ -z "$SELECTED_MODULES" ]; then
        print_error "未选择任何模块，退出"
        exit 1
    fi
    
    generate_manifest "$notes"
    print_success "元数据已生成"
    
    create_package
    
    show_summary
}

main "$@"
