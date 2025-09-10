#!/bin/bash

# Cloudflare Auto DDNS 安装和配置脚本
# GitHub: https://github.com/your-username/cloudflare-auto-ddns

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 项目信息
PROJECT_NAME="cloudflare-auto-ddns"
SERVICE_NAME="cloudflare-auto-ddns"
INSTALL_DIR="/opt/$PROJECT_NAME"
CONFIG_DIR="/etc/$PROJECT_NAME"

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# 检查是否以root用户运行
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本必须以root用户运行"
        echo "请使用: sudo ./setup.sh"
        exit 1
    fi
}

# 检测系统
detect_system() {
    if [[ -f /etc/debian_version ]]; then
        DISTRO="debian"
        PKG_MANAGER="apt"
    elif [[ -f /etc/redhat-release ]]; then
        DISTRO="redhat"
        PKG_MANAGER="yum"
    else
        log_error "不支持的系统，请手动安装"
        exit 1
    fi
    
    log_info "检测到系统: $DISTRO"
}

# 安装依赖
install_dependencies() {
    log_step "安装系统依赖..."
    
    if [[ $DISTRO == "debian" ]]; then
        apt update
        apt install -y python3 python3-pip python3-requests
    elif [[ $DISTRO == "redhat" ]]; then
        yum install -y python3 python3-pip
        pip3 install requests
    fi
    
    log_info "依赖安装完成"
}

# 创建安装目录
create_directories() {
    log_step "创建安装目录..."
    
    mkdir -p $INSTALL_DIR
    mkdir -p $CONFIG_DIR
    mkdir -p /var/log
    
    log_info "目录创建完成"
}

# 复制文件
copy_files() {
    log_step "复制程序文件..."
    
    # 复制主程序
    cp auto_ddns.py $INSTALL_DIR/
    chmod +x $INSTALL_DIR/auto_ddns.py
    
    # 复制配置模板
    if [[ ! -f $CONFIG_DIR/config.json ]]; then
        cp config.example.json $CONFIG_DIR/config.json
        log_warn "已创建配置文件模板: $CONFIG_DIR/config.json"
        log_warn "请编辑此文件并填入您的Cloudflare信息"
    fi
    
    log_info "文件复制完成"
}

# 创建systemd服务
create_service() {
    log_step "创建systemd服务..."
    
    cat > /etc/systemd/system/$SERVICE_NAME.service << EOF
[Unit]
Description=Cloudflare Auto DDNS - 智能时间段DNS解析切换服务
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=$INSTALL_DIR
ExecStart=/usr/bin/python3 $INSTALL_DIR/auto_ddns.py $CONFIG_DIR/config.json
Restart=always
RestartSec=30
StandardOutput=journal
StandardError=journal
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOF

    # 重新加载systemd配置
    systemctl daemon-reload
    
    # 启用服务
    systemctl enable $SERVICE_NAME
    
    log_info "systemd服务创建完成"
}

# 设置权限
set_permissions() {
    log_step "设置文件权限..."
    
    # 设置配置文件权限（仅root可读写）
    chmod 600 $CONFIG_DIR/config.json
    
    # 设置程序文件权限
    chmod 755 $INSTALL_DIR/auto_ddns.py
    
    log_info "权限设置完成"
}

# 创建管理脚本
create_management_script() {
    log_step "创建管理脚本..."
    
    cat > /usr/local/bin/$PROJECT_NAME << 'EOF'
#!/bin/bash

# Cloudflare Auto DDNS 管理脚本

SERVICE_NAME="cloudflare-auto-ddns"
CONFIG_FILE="/etc/cloudflare-auto-ddns/config.json"

case "$1" in
    start)
        echo "启动服务..."
        systemctl start $SERVICE_NAME
        ;;
    stop)
        echo "停止服务..."
        systemctl stop $SERVICE_NAME
        ;;
    restart)
        echo "重启服务..."
        systemctl restart $SERVICE_NAME
        ;;
    status)
        systemctl status $SERVICE_NAME
        ;;
    logs)
        echo "查看实时日志 (按Ctrl+C退出):"
        journalctl -u $SERVICE_NAME -f
        ;;
    config)
        echo "编辑配置文件: $CONFIG_FILE"
        ${EDITOR:-nano} $CONFIG_FILE
        echo "配置已修改，是否重启服务? (y/N)"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            systemctl restart $SERVICE_NAME
        fi
        ;;
    test)
        echo "测试运行..."
        /usr/bin/python3 /opt/cloudflare-auto-ddns/auto_ddns.py $CONFIG_FILE
        ;;
    *)
        echo "Cloudflare Auto DDNS 管理工具"
        echo ""
        echo "用法: $0 {start|stop|restart|status|logs|config|test}"
        echo ""
        echo "命令说明:"
        echo "  start   - 启动服务"
        echo "  stop    - 停止服务"
        echo "  restart - 重启服务"
        echo "  status  - 查看服务状态"
        echo "  logs    - 查看实时日志"
        echo "  config  - 编辑配置文件"
        echo "  test    - 测试运行"
        exit 1
        ;;
esac
EOF

    chmod +x /usr/local/bin/$PROJECT_NAME
    
    log_info "管理脚本创建完成: $PROJECT_NAME"
}

# 显示安装结果
show_result() {
    echo ""
    log_info "🎉 Cloudflare Auto DDNS 安装完成！"
    echo ""
    echo -e "${YELLOW}📁 安装位置:${NC}"
    echo "  程序目录: $INSTALL_DIR"
    echo "  配置文件: $CONFIG_DIR/config.json"
    echo "  日志文件: /var/log/cloudflare-auto-ddns.log"
    echo ""
    echo -e "${YELLOW}⚙️ 下一步操作:${NC}"
    echo "  1. 编辑配置文件: $PROJECT_NAME config"
    echo "  2. 启动服务: $PROJECT_NAME start"
    echo "  3. 查看状态: $PROJECT_NAME status"
    echo "  4. 查看日志: $PROJECT_NAME logs"
    echo ""
    echo -e "${YELLOW}🔧 管理命令:${NC}"
    echo "  $PROJECT_NAME start    # 启动服务"
    echo "  $PROJECT_NAME stop     # 停止服务"
    echo "  $PROJECT_NAME restart  # 重启服务"
    echo "  $PROJECT_NAME status   # 查看状态"
    echo "  $PROJECT_NAME logs     # 查看日志"
    echo "  $PROJECT_NAME config   # 编辑配置"
    echo "  $PROJECT_NAME test     # 测试运行"
    echo ""
    
    if [[ ! -s $CONFIG_DIR/config.json || $(grep -c "your-email@example.com" $CONFIG_DIR/config.json) -gt 0 ]]; then
        echo -e "${RED}⚠️  重要提醒:${NC}"
        echo "  请先编辑配置文件并填入您的Cloudflare信息！"
        echo "  配置文件位置: $CONFIG_DIR/config.json"
        echo ""
    fi
}

# 主安装流程
main() {
    echo "================================================"
    echo "    Cloudflare Auto DDNS 安装程序"
    echo "================================================"
    echo ""
    
    check_root
    detect_system
    install_dependencies
    create_directories
    copy_files
    create_service
    set_permissions
    create_management_script
    show_result
}

# 如果直接运行此脚本
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
