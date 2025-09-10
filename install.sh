#!/bin/bash

# Cloudflare Auto DDNS - 交互式一键安装脚本
# 支持完全交互式配置，无需手动编辑配置文件

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# 项目信息
PROJECT_NAME="cloudflare-auto-ddns"
SERVICE_NAME="cloudflare-auto-ddns"
INSTALL_DIR="/opt/$PROJECT_NAME"
CONFIG_DIR="/etc/$PROJECT_NAME"

# 配置变量
CF_EMAIL=""
CF_API_TOKEN=""
DAY_START_HOUR=""
DAY_END_HOUR=""
DAY_IP=""
NIGHT_IP=""
DOMAINS_LIST=()
CHECK_INTERVAL=""
TIMEZONE=""

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

log_title() {
    echo -e "${PURPLE}=== $1 ===${NC}"
}

log_input() {
    echo -e "${CYAN}[INPUT]${NC} $1"
}

# 显示欢迎信息
show_welcome() {
    clear
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║          🚀 Cloudflare Auto DDNS 一键安装程序 🚀             ║"
    echo "║                                                              ║"
    echo "║  🎯 智能时间段DNS解析切换工具                                  ║"
    echo "║  🔄 自动发现域名，精确IP替换                                   ║"
    echo "║  🛡️ 保护其他DNS记录，安全可靠                                 ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo -e "${GREEN}欢迎使用 Cloudflare Auto DDNS 交互式安装程序！${NC}"
    echo ""
    echo -e "${YELLOW}📋 本程序将引导您完成以下配置：${NC}"
    echo "  1. Cloudflare 账户信息"
    echo "  2. 时间段和IP设置"
    echo "  3. 域名配置"
    echo "  4. 系统设置"
    echo "  5. 自动安装和启动服务"
    echo ""
    echo -e "${CYAN}💡 提示：程序具有智能发现功能，会自动管理使用目标IP的所有域名！${NC}"
    echo ""
    read -p "按回车键开始配置..." -r
}

# 检查权限
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本必须以root用户运行"
        echo "请使用: sudo $0"
        exit 1
    fi
}

# 检测系统
detect_system() {
    log_step "检测系统环境..."
    
    if [[ -f /etc/debian_version ]]; then
        DISTRO="debian"
        PKG_MANAGER="apt"
        log_info "检测到系统: Debian/Ubuntu"
    elif [[ -f /etc/redhat-release ]]; then
        DISTRO="redhat"
        PKG_MANAGER="yum"
        log_info "检测到系统: CentOS/RHEL"
    else
        log_warn "未知系统，尝试通用安装方式"
        DISTRO="unknown"
    fi
}

# 安装依赖
install_dependencies() {
    log_step "安装系统依赖..."
    
    if [[ $DISTRO == "debian" ]]; then
        apt update >/dev/null 2>&1
        apt install -y python3 python3-pip python3-requests curl >/dev/null 2>&1
    elif [[ $DISTRO == "redhat" ]]; then
        yum install -y python3 python3-pip curl >/dev/null 2>&1
        pip3 install requests >/dev/null 2>&1
    else
        log_warn "请手动安装: python3, python3-pip, python3-requests"
    fi
    
    log_info "系统依赖安装完成"
}

# 配置Cloudflare信息
config_cloudflare() {
    log_title "Cloudflare 账户配置"
    echo ""
    echo -e "${YELLOW}📝 请输入您的 Cloudflare 账户信息：${NC}"
    echo ""
    
    # Cloudflare邮箱
    while [[ -z "$CF_EMAIL" ]]; do
        log_input "请输入 Cloudflare 账户邮箱："
        read -r CF_EMAIL
        if [[ ! "$CF_EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            log_error "邮箱格式不正确，请重新输入"
            CF_EMAIL=""
        fi
    done
    
    echo ""
    echo -e "${CYAN}🔑 如何获取 Cloudflare API Token:${NC}"
    echo "  1. 访问: https://dash.cloudflare.com/profile/api-tokens"
    echo "  2. 点击 'Create Token'"
    echo "  3. 选择 'Custom token'"
    echo "  4. 设置权限: Zone:Zone:Read, Zone:DNS:Edit"
    echo "  5. 选择要管理的域名"
    echo "  6. 复制生成的 Token"
    echo ""
    
    # API Token
    while [[ -z "$CF_API_TOKEN" ]]; do
        log_input "请输入 Cloudflare API Token："
        read -r CF_API_TOKEN
        if [[ ${#CF_API_TOKEN} -lt 20 ]]; then
            log_error "API Token 格式不正确，请重新输入"
            CF_API_TOKEN=""
        fi
    done
    
    # 验证API Token
    log_step "验证 API Token..."
    if curl -s -H "Authorization: Bearer $CF_API_TOKEN" \
        "https://api.cloudflare.com/client/v4/user/tokens/verify" | \
        grep -q '"success":true'; then
        log_info "✅ API Token 验证成功"
    else
        log_error "❌ API Token 验证失败，请检查Token是否正确"
        exit 1
    fi
    
    echo ""
}

# 配置时区
config_timezone() {
    log_title "时区配置"
    echo ""
    echo -e "${YELLOW}🌍 请选择您的时区：${NC}"
    echo ""
    echo "1) Asia/Shanghai (北京时间/中国标准时间) [推荐]"
    echo "2) Asia/Hong_Kong (香港时间)"
    echo "3) Asia/Taipei (台北时间)"
    echo "4) Asia/Tokyo (东京时间)"
    echo "5) Europe/London (伦敦时间)"
    echo "6) America/New_York (纽约时间)"
    echo "7) America/Los_Angeles (洛杉矶时间)"
    echo "8) UTC (协调世界时)"
    echo "9) 使用系统当前时区"
    echo "10) 手动输入时区"
    echo ""
    
    while true; do
        log_input "请选择时区 (1-10)："
        read -r tz_choice
        
        case $tz_choice in
            1) TIMEZONE="Asia/Shanghai"; break ;;
            2) TIMEZONE="Asia/Hong_Kong"; break ;;
            3) TIMEZONE="Asia/Taipei"; break ;;
            4) TIMEZONE="Asia/Tokyo"; break ;;
            5) TIMEZONE="Europe/London"; break ;;
            6) TIMEZONE="America/New_York"; break ;;
            7) TIMEZONE="America/Los_Angeles"; break ;;
            8) TIMEZONE="UTC"; break ;;
            9) TIMEZONE="$(timedatectl show --property=Timezone --value 2>/dev/null || echo 'UTC')"; break ;;
            10) 
                log_input "请输入时区 (如: Asia/Shanghai)："
                read -r TIMEZONE
                if [[ -n "$TIMEZONE" ]]; then
                    break
                fi
                ;;
            *) log_error "无效选择，请输入 1-10" ;;
        esac
    done
    
    log_info "已选择时区: $TIMEZONE"
    
    # 显示当前时间
    if command -v timedatectl >/dev/null 2>&1; then
        current_time=$(TZ="$TIMEZONE" date '+%Y-%m-%d %H:%M:%S %Z')
        log_info "当前时间: $current_time"
    fi
    
    echo ""
}

# 配置时间段和IP
config_schedule() {
    log_title "时间段和IP配置"
    echo ""
    echo -e "${YELLOW}⏰ 请配置时间段切换规则：${NC}"
    echo ""
    echo -e "${CYAN}说明：程序会根据时间段自动切换不同的IP地址${NC}"
    echo "例如：白天使用高速线路IP，夜间使用经济线路IP"
    echo ""
    
    # 白天开始时间
    while [[ -z "$DAY_START_HOUR" || $DAY_START_HOUR -lt 0 || $DAY_START_HOUR -gt 23 ]]; do
        log_input "白天开始时间 (0-23小时，如：6表示早上6点)："
        read -r DAY_START_HOUR
        if [[ ! "$DAY_START_HOUR" =~ ^[0-9]+$ ]] || [[ $DAY_START_HOUR -lt 0 || $DAY_START_HOUR -gt 23 ]]; then
            log_error "请输入有效的小时数 (0-23)"
            DAY_START_HOUR=""
        fi
    done
    
    # 白天结束时间
    while [[ -z "$DAY_END_HOUR" || $DAY_END_HOUR -lt 0 || $DAY_END_HOUR -gt 23 || $DAY_END_HOUR -eq $DAY_START_HOUR ]]; do
        log_input "白天结束时间 (0-23小时，如：22表示晚上10点)："
        read -r DAY_END_HOUR
        if [[ ! "$DAY_END_HOUR" =~ ^[0-9]+$ ]] || [[ $DAY_END_HOUR -lt 0 || $DAY_END_HOUR -gt 23 ]]; then
            log_error "请输入有效的小时数 (0-23)"
            DAY_END_HOUR=""
        elif [[ $DAY_END_HOUR -eq $DAY_START_HOUR ]]; then
            log_error "结束时间不能与开始时间相同"
            DAY_END_HOUR=""
        fi
    done
    
    echo ""
    log_info "白天时段: ${DAY_START_HOUR}:00 - ${DAY_END_HOUR}:00"
    log_info "夜间时段: ${DAY_END_HOUR}:00 - ${DAY_START_HOUR}:00"
    echo ""
    
    # 白天IP
    while [[ -z "$DAY_IP" ]]; do
        log_input "白天使用的IP地址："
        read -r DAY_IP
        if [[ ! "$DAY_IP" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
            log_error "IP地址格式不正确，请重新输入"
            DAY_IP=""
        fi
    done
    
    # 夜间IP
    while [[ -z "$NIGHT_IP" ]]; do
        log_input "夜间使用的IP地址："
        read -r NIGHT_IP
        if [[ ! "$NIGHT_IP" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
            log_error "IP地址格式不正确，请重新输入"
            NIGHT_IP=""
        elif [[ "$NIGHT_IP" == "$DAY_IP" ]]; then
            log_error "夜间IP不能与白天IP相同"
            NIGHT_IP=""
        fi
    done
    
    echo ""
    log_info "配置完成："
    log_info "  白天 (${DAY_START_HOUR}:00-${DAY_END_HOUR}:00): $DAY_IP"
    log_info "  夜间 (${DAY_END_HOUR}:00-${DAY_START_HOUR}:00): $NIGHT_IP"
    echo ""
}

# 配置自动发现功能
config_auto_discovery() {
    log_title "自动发现功能配置"
    echo ""
    echo -e "${YELLOW}🔍 智能发现功能说明：${NC}"
    echo ""
    echo -e "${GREEN}开启智能发现 (推荐)：${NC}"
    echo "  ✅ 自动扫描您Cloudflare账户中的所有Zone"
    echo "  ✅ 发现所有使用 $DAY_IP 或 $NIGHT_IP 的域名"
    echo "  ✅ 自动管理这些域名，无需手动配置"
    echo "  ✅ 新域名会自动加入管理"
    echo ""
    echo -e "${CYAN}关闭智能发现：${NC}"
    echo "  🔒 只管理您手动配置的域名"
    echo "  🔒 更加精确控制，避免意外修改"
    echo "  🔒 适合复杂DNS配置环境"
    echo ""
    echo -e "${RED}⚠️  示例场景：${NC}"
    echo "  假设您有 1.example.com 解析到 $DAY_IP"
    echo "  同时 2.example.com 也恰好解析到 $DAY_IP"
    echo "  如果开启自动发现，两个域名都会被管理"
    echo "  如果关闭自动发现，只有手动配置的域名会被管理"
    echo ""
    
    while true; do
        log_input "是否开启智能发现功能？(Y/n):"
        read -r auto_discovery_choice
        
        case $auto_discovery_choice in
            [Yy]|"") 
                AUTO_DISCOVERY=true
                log_info "✅ 已开启智能发现功能"
                break
                ;;
            [Nn])
                AUTO_DISCOVERY=false
                log_warn "🔒 已关闭智能发现功能，仅管理手动配置的域名"
                break
                ;;
            *)
                log_error "请输入 Y 或 N"
                ;;
        esac
    done
    echo ""
}

# 配置域名
config_domains() {
    log_title "域名配置"
    echo ""
    
    if [[ "$AUTO_DISCOVERY" == "true" ]]; then
        echo -e "${YELLOW}🌐 域名配置 (可选)：${NC}"
        echo ""
        echo -e "${CYAN}💡 智能发现已开启：${NC}"
        echo "  ✅ 系统会自动发现所有使用目标IP的域名"
        echo "  ✅ 这里配置的域名会优先处理"
        echo "  ✅ 可以不配置任何域名，完全依赖智能发现"
        echo ""
        read -p "是否要手动添加优先处理的域名？(y/N): " -r add_domains
    else
        echo -e "${YELLOW}🌐 域名配置 (必需)：${NC}"
        echo ""
        echo -e "${RED}⚠️  智能发现已关闭：${NC}"
        echo "  🔒 系统只会管理您手动配置的域名"
        echo "  🔒 请至少添加一个域名"
        echo ""
        add_domains="y"
    fi
    
    if [[ $add_domains =~ ^[Yy]$ ]]; then
        echo ""
        echo -e "${YELLOW}请添加域名 (格式：域名,根域名)：${NC}"
        echo "例如："
        echo "  www.example.com,example.com"
        echo "  api.example.com,example.com"
        echo "  blog.mysite.org,mysite.org"
        echo ""
        echo "输入空行结束添加"
        echo ""
        
        while true; do
            log_input "域名,根域名 (或直接回车结束)："
            read -r domain_input
            
            if [[ -z "$domain_input" ]]; then
                break
            fi
            
            if [[ "$domain_input" =~ ^([a-zA-Z0-9.-]+),([a-zA-Z0-9.-]+)$ ]]; then
                domain_name="${BASH_REMATCH[1]}"
                zone_name="${BASH_REMATCH[2]}"
                DOMAINS_LIST+=("$domain_name,$zone_name")
                log_info "已添加: $domain_name (Zone: $zone_name)"
            else
                log_error "格式不正确，请使用：域名,根域名"
            fi
        done
    fi
    
    if [[ ${#DOMAINS_LIST[@]} -eq 0 ]]; then
        if [[ "$AUTO_DISCOVERY" == "true" ]]; then
            log_info "未手动配置域名，将完全依赖智能发现功能"
        else
            log_error "智能发现已关闭，但未配置任何域名，请至少添加一个域名"
            config_domains  # 重新调用域名配置
            return
        fi
    else
        log_info "手动配置了 ${#DOMAINS_LIST[@]} 个域名"
    fi
    
    echo ""
}

# 配置其他选项
config_advanced() {
    log_title "高级配置"
    echo ""
    
    # 检查间隔
    echo -e "${YELLOW}⏱️ 检查间隔配置：${NC}"
    echo "1) 1分钟 (快速响应，适合测试)"
    echo "2) 5分钟 (推荐，平衡性能和及时性)"
    echo "3) 10分钟 (节省资源)"
    echo "4) 自定义"
    echo ""
    
    while true; do
        log_input "请选择检查间隔 (1-4)："
        read -r interval_choice
        
        case $interval_choice in
            1) CHECK_INTERVAL=60; break ;;
            2) CHECK_INTERVAL=300; break ;;
            3) CHECK_INTERVAL=600; break ;;
            4)
                while [[ -z "$CHECK_INTERVAL" || $CHECK_INTERVAL -lt 30 ]]; do
                    log_input "请输入检查间隔 (秒，最小30秒)："
                    read -r CHECK_INTERVAL
                    if [[ ! "$CHECK_INTERVAL" =~ ^[0-9]+$ ]] || [[ $CHECK_INTERVAL -lt 30 ]]; then
                        log_error "请输入有效的秒数 (≥30)"
                        CHECK_INTERVAL=""
                    fi
                done
                break
                ;;
            *) log_error "无效选择，请输入 1-4" ;;
        esac
    done
    
    log_info "检查间隔: ${CHECK_INTERVAL}秒"
    echo ""
}

# 显示配置摘要
show_summary() {
    log_title "配置摘要"
    echo ""
    echo -e "${GREEN}📋 您的配置信息：${NC}"
    echo ""
    echo -e "${CYAN}Cloudflare 账户:${NC}"
    echo "  邮箱: $CF_EMAIL"
    echo "  API Token: ${CF_API_TOKEN:0:10}...${CF_API_TOKEN: -4}"
    echo ""
    echo -e "${CYAN}时区设置:${NC}"
    echo "  时区: $TIMEZONE"
    if command -v timedatectl >/dev/null 2>&1; then
        current_time=$(TZ="$TIMEZONE" date '+%Y-%m-%d %H:%M:%S %Z')
        echo "  当前时间: $current_time"
    fi
    echo ""
    echo -e "${CYAN}时间段配置:${NC}"
    echo "  白天时段: ${DAY_START_HOUR}:00 - ${DAY_END_HOUR}:00 → $DAY_IP"
    echo "  夜间时段: ${DAY_END_HOUR}:00 - ${DAY_START_HOUR}:00 → $NIGHT_IP"
    echo ""
    echo -e "${CYAN}域名配置:${NC}"
    echo "  🔍 智能发现功能: $(if [[ "$AUTO_DISCOVERY" == "true" ]]; then echo "开启"; else echo "关闭"; fi)"
    if [[ ${#DOMAINS_LIST[@]} -eq 0 ]]; then
        if [[ "$AUTO_DISCOVERY" == "true" ]]; then
            echo "  🔍 智能发现模式 (自动管理所有相关域名)"
        else
            echo "  🔒 仅手动模式 (未配置域名)"
        fi
    else
        echo "  📝 手动配置域名:"
        for domain in "${DOMAINS_LIST[@]}"; do
            IFS=',' read -r domain_name zone_name <<< "$domain"
            echo "    - $domain_name (Zone: $zone_name)"
        done
        if [[ "$AUTO_DISCOVERY" == "true" ]]; then
            echo "  🔍 + 智能发现其他域名"
        fi
    fi
    echo ""
    echo -e "${CYAN}系统配置:${NC}"
    echo "  检查间隔: ${CHECK_INTERVAL}秒"
    echo "  日志文件: /var/log/$SERVICE_NAME.log"
    echo "  配置文件: $CONFIG_DIR/config.json"
    echo ""
    
    read -p "确认配置并开始安装？(Y/n): " -r confirm
    if [[ $confirm =~ ^[Nn]$ ]]; then
        log_error "安装已取消"
        exit 1
    fi
}

# 生成配置文件
generate_config() {
    log_step "生成配置文件..."
    
    mkdir -p "$CONFIG_DIR"
    
    cat > "$CONFIG_DIR/config.json" << EOF
{
  "cloudflare": {
    "email": "$CF_EMAIL",
    "api_token": "$CF_API_TOKEN"
  },
  "schedule": {
    "day_start_hour": $DAY_START_HOUR,
    "day_end_hour": $DAY_END_HOUR,
    "day_ip": "$DAY_IP",
    "night_ip": "$NIGHT_IP",
    "_comment": "时间使用时区: $TIMEZONE"
  },
  "domains": [
EOF

    # 添加手动配置的域名
    if [[ ${#DOMAINS_LIST[@]} -gt 0 ]]; then
        for i in "${!DOMAINS_LIST[@]}"; do
            IFS=',' read -r domain_name zone_name <<< "${DOMAINS_LIST[$i]}"
            echo "    {" >> "$CONFIG_DIR/config.json"
            echo "      \"name\": \"$domain_name\"," >> "$CONFIG_DIR/config.json"
            echo "      \"zone\": \"$zone_name\"," >> "$CONFIG_DIR/config.json"
            echo "      \"type\": \"A\"" >> "$CONFIG_DIR/config.json"
            if [[ $i -eq $((${#DOMAINS_LIST[@]} - 1)) ]]; then
                echo "    }" >> "$CONFIG_DIR/config.json"
            else
                echo "    }," >> "$CONFIG_DIR/config.json"
            fi
        done
    fi

    cat >> "$CONFIG_DIR/config.json" << EOF
  ],
  "auto_discovery": $AUTO_DISCOVERY,
  "log": {
    "level": "INFO",
    "file": "/var/log/$SERVICE_NAME.log"
  },
  "check_interval": $CHECK_INTERVAL
}
EOF

    chmod 600 "$CONFIG_DIR/config.json"
    log_info "配置文件已生成: $CONFIG_DIR/config.json"
}

# 安装程序文件
install_files() {
    log_step "安装程序文件..."
    
    mkdir -p "$INSTALL_DIR"
    
    # 复制主程序
    cp auto_ddns.py "$INSTALL_DIR/"
    chmod +x "$INSTALL_DIR/auto_ddns.py"
    
    log_info "程序文件安装完成"
}

# 创建systemd服务
create_service() {
    log_step "创建系统服务..."
    
    cat > "/etc/systemd/system/$SERVICE_NAME.service" << EOF
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
Environment=TZ=$TIMEZONE

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable "$SERVICE_NAME"
    
    log_info "系统服务创建完成"
}

# 创建管理命令
create_management_command() {
    log_step "创建管理命令..."
    
    cat > "/usr/local/bin/$PROJECT_NAME" << 'EOF'
#!/bin/bash

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
        echo "配置文件位置: $CONFIG_FILE"
        echo "当前配置:"
        cat $CONFIG_FILE | python3 -m json.tool
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
        echo "  config  - 查看配置信息"
        echo "  test    - 测试运行"
        exit 1
        ;;
esac
EOF

    chmod +x "/usr/local/bin/$PROJECT_NAME"
    log_info "管理命令创建完成: $PROJECT_NAME"
}

# 启动服务
start_service() {
    log_step "启动服务..."
    
    systemctl start "$SERVICE_NAME"
    sleep 3
    
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        log_info "✅ 服务启动成功！"
    else
        log_error "❌ 服务启动失败"
        echo "查看错误日志:"
        journalctl -u "$SERVICE_NAME" -n 10 --no-pager
        exit 1
    fi
}

# 显示安装结果
show_result() {
    clear
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║               🎉 安装完成！服务正在运行中 🎉                   ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    
    log_info "🚀 Cloudflare Auto DDNS 安装完成！"
    echo ""
    
    echo -e "${YELLOW}📂 文件位置：${NC}"
    echo "  程序目录: $INSTALL_DIR"
    echo "  配置文件: $CONFIG_DIR/config.json"
    echo "  日志文件: /var/log/$SERVICE_NAME.log"
    echo ""
    
    echo -e "${YELLOW}🎯 当前配置：${NC}"
    current_time=$(TZ="$TIMEZONE" date '+%Y-%m-%d %H:%M:%S %Z')
    current_hour=$(TZ="$TIMEZONE" date '+%H')
    
    echo "  时区: $TIMEZONE"
    echo "  当前时间: $current_time"
    
    if [[ $current_hour -ge $DAY_START_HOUR && $current_hour -lt $DAY_END_HOUR ]]; then
        echo "  当前时段: 🌅 白天 ($DAY_START_HOUR:00-$DAY_END_HOUR:00)"
        echo "  当前IP: $DAY_IP"
    else
        echo "  当前时段: 🌙 夜间 ($DAY_END_HOUR:00-$DAY_START_HOUR:00)"
        echo "  当前IP: $NIGHT_IP"
    fi
    
    echo "  检查间隔: ${CHECK_INTERVAL}秒"
    echo ""
    
    echo -e "${YELLOW}🔧 管理命令：${NC}"
    echo "  $PROJECT_NAME status   # 查看服务状态"
    echo "  $PROJECT_NAME logs     # 查看实时日志"
    echo "  $PROJECT_NAME restart  # 重启服务"
    echo "  $PROJECT_NAME config   # 查看配置"
    echo "  $PROJECT_NAME test     # 测试运行"
    echo ""
    
    echo -e "${YELLOW}🔍 智能发现功能：${NC}"
    echo "  ✅ 系统会自动扫描您的Cloudflare账户"
    echo "  ✅ 发现所有使用 $DAY_IP 或 $NIGHT_IP 的域名"
    echo "  ✅ 自动添加到管理列表进行时间段切换"
    echo "  ✅ 无需手动配置，添加新域名后自动生效"
    echo ""
    
    echo -e "${GREEN}🎊 安装成功！服务已启动并将在后台自动运行！${NC}"
    echo ""
    
    read -p "按回车键查看实时日志 (Ctrl+C 退出日志查看): " -r
    journalctl -u "$SERVICE_NAME" -f
}

# 主安装流程
main() {
    show_welcome
    check_root
    detect_system
    install_dependencies
    config_cloudflare
    config_timezone
    config_schedule
    config_auto_discovery
    config_domains
    config_advanced
    show_summary
    generate_config
    install_files
    create_service
    create_management_command
    start_service
    show_result
}

# 运行主程序
main "$@"
