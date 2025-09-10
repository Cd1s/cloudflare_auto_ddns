#!/bin/bash

# Cloudflare Auto DDNS - 交互式管理脚本
# 支持添加域名、更换IP、管理自动发现等功能

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# 服务信息
SERVICE_NAME="cloudflare-auto-ddns"
CONFIG_FILE="/etc/cloudflare-auto-ddns/config.json"
LOG_FILE="/var/log/cloudflare-auto-ddns.log"

# 检查是否以root用户运行
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}[ERROR]${NC} 此脚本必须以root用户运行"
        echo "请使用: sudo $0"
        exit 1
    fi
}

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

# 检查配置文件是否存在
check_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_error "配置文件不存在: $CONFIG_FILE"
        echo "请先运行安装脚本: ./install.sh"
        exit 1
    fi
}

# 备份配置文件
backup_config() {
    local backup_file="${CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$CONFIG_FILE" "$backup_file"
    log_info "配置文件已备份: $backup_file"
}

# 重启服务
restart_service() {
    log_step "重启服务以应用新配置..."
    systemctl restart "$SERVICE_NAME"
    sleep 2
    
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        log_info "✅ 服务重启成功"
    else
        log_error "❌ 服务重启失败"
        echo "查看错误日志:"
        journalctl -u "$SERVICE_NAME" -n 10 --no-pager
    fi
}

# 显示主菜单
show_main_menu() {
    clear
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║                                                          ║"
    echo "║       🚀 Cloudflare Auto DDNS 管理工具 🚀                ║"
    echo "║                                                          ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo -e "${YELLOW}请选择操作：${NC}"
    echo ""
    echo "📊 服务管理:"
    echo "  1) 查看服务状态"
    echo "  2) 查看实时日志"
    echo "  3) 重启服务"
    echo "  4) 启动服务"
    echo "  5) 停止服务"
    echo ""
    echo "⚙️ 配置管理:"
    echo "  6) 查看当前配置"
    echo "  7) 更换IP地址"
    echo "  8) 修改时间段"
    echo "  9) 管理域名"
    echo "  10) 自动发现设置"
    echo "  11) 修改检查间隔"
    echo ""
    echo "🔧 高级功能:"
    echo "  12) 手动测试运行"
    echo "  13) 编辑配置文件"
    echo "  14) 查看帮助"
    echo "  0) 退出"
    echo ""
}

# 查看服务状态
show_service_status() {
    log_title "服务状态"
    echo ""
    systemctl status "$SERVICE_NAME" --no-pager
    echo ""
    read -p "按回车键返回主菜单..." -r
}

# 查看实时日志
show_logs() {
    log_title "实时日志"
    echo ""
    echo "按 Ctrl+C 退出日志查看"
    echo ""
    sleep 2
    journalctl -u "$SERVICE_NAME" -f
}

# 查看当前配置
show_config() {
    log_title "当前配置"
    echo ""
    
    if command -v jq >/dev/null 2>&1; then
        cat "$CONFIG_FILE" | jq .
    else
        python3 -c "import json; print(json.dumps(json.load(open('$CONFIG_FILE')), indent=2, ensure_ascii=False))"
    fi
    
    echo ""
    read -p "按回车键返回主菜单..." -r
}

# 更换IP地址
change_ip() {
    log_title "更换IP地址"
    echo ""
    
    # 读取当前IP配置
    current_day_ip=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE'))['schedule']['day_ip'])")
    current_night_ip=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE'))['schedule']['night_ip'])")
    
    echo -e "${YELLOW}当前IP配置：${NC}"
    echo "  白天IP: $current_day_ip"
    echo "  夜间IP: $current_night_ip"
    echo ""
    
    echo -e "${CYAN}请输入新的IP地址 (留空保持不变)：${NC}"
    
    # 输入新的白天IP
    while true; do
        echo -n "新的白天IP: "
        read -r new_day_ip
        
        if [[ -z "$new_day_ip" ]]; then
            new_day_ip="$current_day_ip"
            break
        elif [[ "$new_day_ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
            break
        else
            log_error "IP地址格式不正确，请重新输入"
        fi
    done
    
    # 输入新的夜间IP
    while true; do
        echo -n "新的夜间IP: "
        read -r new_night_ip
        
        if [[ -z "$new_night_ip" ]]; then
            new_night_ip="$current_night_ip"
            break
        elif [[ "$new_night_ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
            if [[ "$new_night_ip" == "$new_day_ip" ]]; then
                log_error "夜间IP不能与白天IP相同"
            else
                break
            fi
        else
            log_error "IP地址格式不正确，请重新输入"
        fi
    done
    
    # 确认更改
    echo ""
    echo -e "${YELLOW}确认更改：${NC}"
    echo "  白天IP: $current_day_ip → $new_day_ip"
    echo "  夜间IP: $current_night_ip → $new_night_ip"
    echo ""
    
    read -p "确认更改？(y/N): " -r confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        log_info "已取消更改"
        return
    fi
    
    # 备份并更新配置
    backup_config
    
    python3 << EOF
import json

with open('$CONFIG_FILE', 'r') as f:
    config = json.load(f)

config['schedule']['day_ip'] = '$new_day_ip'
config['schedule']['night_ip'] = '$new_night_ip'

with open('$CONFIG_FILE', 'w') as f:
    json.dump(config, f, indent=2, ensure_ascii=False)
EOF

    log_info "✅ IP地址更新完成"
    restart_service
    
    echo ""
    read -p "按回车键返回主菜单..." -r
}

# 修改时间段
change_schedule() {
    log_title "修改时间段"
    echo ""
    
    # 读取当前时间配置
    current_start=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE'))['schedule']['day_start_hour'])")
    current_end=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE'))['schedule']['day_end_hour'])")
    
    echo -e "${YELLOW}当前时间段配置：${NC}"
    echo "  白天时段: ${current_start}:00 - ${current_end}:00"
    echo "  夜间时段: ${current_end}:00 - ${current_start}:00"
    echo ""
    
    # 输入新的时间段
    while true; do
        echo -n "白天开始时间 (0-23小时): "
        read -r new_start
        
        if [[ "$new_start" =~ ^[0-9]+$ ]] && [[ $new_start -ge 0 && $new_start -le 23 ]]; then
            break
        else
            log_error "请输入有效的小时数 (0-23)"
        fi
    done
    
    while true; do
        echo -n "白天结束时间 (0-23小时): "
        read -r new_end
        
        if [[ "$new_end" =~ ^[0-9]+$ ]] && [[ $new_end -ge 0 && $new_end -le 23 ]]; then
            if [[ $new_end -eq $new_start ]]; then
                log_error "结束时间不能与开始时间相同"
            else
                break
            fi
        else
            log_error "请输入有效的小时数 (0-23)"
        fi
    done
    
    # 确认更改
    echo ""
    echo -e "${YELLOW}确认更改：${NC}"
    echo "  白天时段: ${current_start}:00-${current_end}:00 → ${new_start}:00-${new_end}:00"
    echo "  夜间时段: ${current_end}:00-${current_start}:00 → ${new_end}:00-${new_start}:00"
    echo ""
    
    read -p "确认更改？(y/N): " -r confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        log_info "已取消更改"
        return
    fi
    
    # 备份并更新配置
    backup_config
    
    python3 << EOF
import json

with open('$CONFIG_FILE', 'r') as f:
    config = json.load(f)

config['schedule']['day_start_hour'] = $new_start
config['schedule']['day_end_hour'] = $new_end

with open('$CONFIG_FILE', 'w') as f:
    json.dump(config, f, indent=2, ensure_ascii=False)
EOF

    log_info "✅ 时间段更新完成"
    restart_service
    
    echo ""
    read -p "按回车键返回主菜单..." -r
}

# 管理域名
manage_domains() {
    while true; do
        log_title "域名管理"
        echo ""
        
        # 显示当前域名
        echo -e "${YELLOW}当前配置的域名：${NC}"
        python3 << 'EOF'
import json

with open('/etc/cloudflare-auto-ddns/config.json', 'r') as f:
    config = json.load(f)

domains = config.get('domains', [])
if not domains:
    print("  (无)")
else:
    for i, domain in enumerate(domains, 1):
        print(f"  {i}. {domain['name']} (Zone: {domain['zone']})")
EOF
        
        echo ""
        echo -e "${CYAN}域名管理操作：${NC}"
        echo "  1) 添加域名"
        echo "  2) 删除域名"
        echo "  3) 列出所有域名"
        echo "  0) 返回主菜单"
        echo ""
        
        read -p "请选择操作 (0-3): " -r domain_action
        
        case $domain_action in
            1) add_domain ;;
            2) remove_domain ;;
            3) list_all_domains ;;
            0) break ;;
            *) log_error "无效选择" ;;
        esac
    done
}

# 添加域名
add_domain() {
    echo ""
    log_step "添加新域名"
    echo ""
    
    echo -n "域名 (如: www.example.com): "
    read -r domain_name
    echo -n "根域名/Zone (如: example.com): "
    read -r zone_name
    
    if [[ -z "$domain_name" || -z "$zone_name" ]]; then
        log_error "域名和Zone不能为空"
        return
    fi
    
    # 确认添加
    echo ""
    echo -e "${YELLOW}确认添加域名：${NC}"
    echo "  域名: $domain_name"
    echo "  Zone: $zone_name"
    echo ""
    
    read -p "确认添加？(y/N): " -r confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        log_info "已取消添加"
        return
    fi
    
    # 备份并更新配置
    backup_config
    
    python3 << EOF
import json

with open('$CONFIG_FILE', 'r') as f:
    config = json.load(f)

new_domain = {
    "name": "$domain_name",
    "zone": "$zone_name",
    "type": "A"
}

config['domains'].append(new_domain)

with open('$CONFIG_FILE', 'w') as f:
    json.dump(config, f, indent=2, ensure_ascii=False)
EOF

    log_info "✅ 域名添加完成"
    restart_service
    
    echo ""
    read -p "按回车键继续..." -r
}

# 删除域名
remove_domain() {
    echo ""
    log_step "删除域名"
    echo ""
    
    # 显示当前域名列表
    domain_count=$(python3 -c "import json; print(len(json.load(open('$CONFIG_FILE'))['domains']))")
    
    if [[ $domain_count -eq 0 ]]; then
        log_error "没有配置的域名可删除"
        read -p "按回车键继续..." -r
        return
    fi
    
    echo -e "${YELLOW}当前域名列表：${NC}"
    python3 << 'EOF'
import json

with open('/etc/cloudflare-auto-ddns/config.json', 'r') as f:
    config = json.load(f)

for i, domain in enumerate(config['domains'], 1):
    print(f"  {i}. {domain['name']} (Zone: {domain['zone']})")
EOF
    
    echo ""
    echo -n "请输入要删除的域名编号: "
    read -r domain_index
    
    if [[ ! "$domain_index" =~ ^[0-9]+$ ]] || [[ $domain_index -lt 1 || $domain_index -gt $domain_count ]]; then
        log_error "无效的编号"
        read -p "按回车键继续..." -r
        return
    fi
    
    # 获取要删除的域名信息
    domain_info=$(python3 -c "import json; config = json.load(open('$CONFIG_FILE')); domain = config['domains'][$domain_index-1]; print(f\"{domain['name']} (Zone: {domain['zone']})\")")
    
    # 确认删除
    echo ""
    echo -e "${YELLOW}确认删除域名：${NC}"
    echo "  $domain_info"
    echo ""
    
    read -p "确认删除？(y/N): " -r confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        log_info "已取消删除"
        return
    fi
    
    # 备份并更新配置
    backup_config
    
    python3 << EOF
import json

with open('$CONFIG_FILE', 'r') as f:
    config = json.load(f)

del config['domains'][$domain_index-1]

with open('$CONFIG_FILE', 'w') as f:
    json.dump(config, f, indent=2, ensure_ascii=False)
EOF

    log_info "✅ 域名删除完成"
    restart_service
    
    echo ""
    read -p "按回车键继续..." -r
}

# 列出所有相关域名
list_all_domains() {
    echo ""
    log_step "扫描所有相关域名"
    echo ""
    
    log_info "正在扫描Cloudflare账户中的域名..."
    
    # 使用Python脚本扫描
    timeout 30 python3 << 'EOF'
import json
import sys
import os

# 添加脚本路径
sys.path.insert(0, '/opt/cloudflare-auto-ddns')

try:
    from auto_ddns import CloudflareAPI
    
    # 读取配置
    with open('/etc/cloudflare-auto-ddns/config.json', 'r') as f:
        config = json.load(f)
    
    # 初始化API
    cf_api = CloudflareAPI(
        config['cloudflare']['email'],
        config['cloudflare']['api_token']
    )
    
    managed_ips = [config['schedule']['day_ip'], config['schedule']['night_ip']]
    print(f"管理的IP地址: {', '.join(managed_ips)}")
    print()
    
    # 获取所有Zone
    zones_scanned = set()
    for domain_config in config['domains']:
        zone_name = domain_config['zone']
        if zone_name in zones_scanned:
            continue
        zones_scanned.add(zone_name)
        
        try:
            zone_id = cf_api.get_zone_id(zone_name)
            records = cf_api.get_dns_records(zone_id)
            
            print(f"Zone: {zone_name}")
            found_domains = []
            
            for record in records:
                if record['content'] in managed_ips:
                    found_domains.append(f"  ✓ {record['name']} → {record['content']}")
            
            if found_domains:
                for domain in found_domains:
                    print(domain)
            else:
                print("  (未找到使用管理IP的域名)")
            print()
            
        except Exception as e:
            print(f"Zone {zone_name}: 扫描失败 - {str(e)}")
            print()

except Exception as e:
    print(f"扫描失败: {str(e)}")
EOF

    echo ""
    read -p "按回车键继续..." -r
}

# 自动发现设置
auto_discovery_settings() {
    log_title "自动发现功能设置"
    echo ""
    
    # 读取当前设置
    current_setting=$(python3 -c "import json; print('开启' if json.load(open('$CONFIG_FILE')).get('auto_discovery', True) else '关闭')")
    
    echo -e "${YELLOW}当前自动发现功能：${NC} $current_setting"
    echo ""
    echo -e "${CYAN}自动发现功能说明：${NC}"
    echo "  开启：自动扫描并管理所有使用目标IP的域名"
    echo "  关闭：仅管理手动配置的域名列表"
    echo ""
    
    echo "1) 开启自动发现"
    echo "2) 关闭自动发现"
    echo "0) 返回主菜单"
    echo ""
    
    read -p "请选择 (0-2): " -r discovery_choice
    
    case $discovery_choice in
        1)
            new_setting="true"
            setting_text="开启"
            ;;
        2)
            new_setting="false"
            setting_text="关闭"
            ;;
        0)
            return
            ;;
        *)
            log_error "无效选择"
            read -p "按回车键继续..." -r
            return
            ;;
    esac
    
    # 确认更改
    echo ""
    echo -e "${YELLOW}确认更改自动发现功能：${NC}"
    echo "  当前: $current_setting"
    echo "  新设置: $setting_text"
    echo ""
    
    read -p "确认更改？(y/N): " -r confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        log_info "已取消更改"
        return
    fi
    
    # 备份并更新配置
    backup_config
    
    python3 << EOF
import json

with open('$CONFIG_FILE', 'r') as f:
    config = json.load(f)

config['auto_discovery'] = $new_setting

with open('$CONFIG_FILE', 'w') as f:
    json.dump(config, f, indent=2, ensure_ascii=False)
EOF

    log_info "✅ 自动发现功能设置更新完成"
    restart_service
    
    echo ""
    read -p "按回车键返回主菜单..." -r
}

# 修改检查间隔
change_interval() {
    log_title "修改检查间隔"
    echo ""
    
    # 读取当前间隔
    current_interval=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE'))['check_interval'])")
    
    echo -e "${YELLOW}当前检查间隔：${NC} ${current_interval}秒"
    echo ""
    echo "推荐间隔："
    echo "  60秒  - 快速响应 (适合测试)"
    echo "  300秒 - 推荐设置 (平衡性能和及时性)"
    echo "  600秒 - 节省资源"
    echo ""
    
    while true; do
        echo -n "新的检查间隔 (秒，最小30): "
        read -r new_interval
        
        if [[ "$new_interval" =~ ^[0-9]+$ ]] && [[ $new_interval -ge 30 ]]; then
            break
        else
            log_error "请输入有效的秒数 (≥30)"
        fi
    done
    
    # 确认更改
    echo ""
    echo -e "${YELLOW}确认更改：${NC}"
    echo "  检查间隔: ${current_interval}秒 → ${new_interval}秒"
    echo ""
    
    read -p "确认更改？(y/N): " -r confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        log_info "已取消更改"
        return
    fi
    
    # 备份并更新配置
    backup_config
    
    python3 << EOF
import json

with open('$CONFIG_FILE', 'r') as f:
    config = json.load(f)

config['check_interval'] = $new_interval

with open('$CONFIG_FILE', 'w') as f:
    json.dump(config, f, indent=2, ensure_ascii=False)
EOF

    log_info "✅ 检查间隔更新完成"
    restart_service
    
    echo ""
    read -p "按回车键返回主菜单..." -r
}

# 手动测试运行
test_run() {
    log_title "手动测试运行"
    echo ""
    
    log_warn "将停止服务并手动运行程序进行测试"
    echo "测试完成后需要手动重启服务"
    echo ""
    
    read -p "继续测试？(y/N): " -r confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        return
    fi
    
    # 停止服务
    systemctl stop "$SERVICE_NAME"
    
    echo ""
    log_info "开始测试运行 (按Ctrl+C退出)..."
    echo ""
    
    # 手动运行程序
    /usr/bin/python3 /opt/cloudflare-auto-ddns/auto_ddns.py "$CONFIG_FILE"
    
    echo ""
    read -p "按回车键重启服务..." -r
    systemctl start "$SERVICE_NAME"
    log_info "服务已重启"
}

# 编辑配置文件
edit_config() {
    log_title "编辑配置文件"
    echo ""
    
    log_warn "直接编辑配置文件可能导致格式错误"
    echo "建议使用其他菜单选项进行配置修改"
    echo ""
    
    read -p "继续编辑？(y/N): " -r confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        return
    fi
    
    # 备份配置文件
    backup_config
    
    # 使用编辑器
    if command -v nano >/dev/null 2>&1; then
        nano "$CONFIG_FILE"
    elif command -v vim >/dev/null 2>&1; then
        vim "$CONFIG_FILE"
    else
        log_error "未找到文本编辑器"
        return
    fi
    
    # 验证配置文件
    if python3 -c "import json; json.load(open('$CONFIG_FILE'))" 2>/dev/null; then
        log_info "✅ 配置文件格式正确"
        restart_service
    else
        log_error "❌ 配置文件格式错误，已恢复备份"
        cp "${CONFIG_FILE}.backup."* "$CONFIG_FILE" 2>/dev/null || true
    fi
    
    echo ""
    read -p "按回车键返回主菜单..." -r
}

# 显示帮助
show_help() {
    log_title "帮助信息"
    echo ""
    echo -e "${YELLOW}Cloudflare Auto DDNS 管理工具${NC}"
    echo ""
    echo -e "${CYAN}功能说明：${NC}"
    echo "  - 根据时间段自动切换DNS解析IP"
    echo "  - 支持智能发现功能，自动管理相关域名"
    echo "  - 精确IP替换，保护其他DNS记录"
    echo ""
    echo -e "${CYAN}配置文件：${NC} $CONFIG_FILE"
    echo -e "${CYAN}日志文件：${NC} $LOG_FILE"
    echo -e "${CYAN}服务名称：${NC} $SERVICE_NAME"
    echo ""
    echo -e "${CYAN}常用命令：${NC}"
    echo "  systemctl status $SERVICE_NAME"
    echo "  journalctl -u $SERVICE_NAME -f"
    echo "  cloudflare-auto-ddns [status|logs|restart]"
    echo ""
    echo -e "${CYAN}项目地址：${NC}"
    echo "  https://github.com/Cd1s/cloudflare_auto_ddns"
    echo ""
    read -p "按回车键返回主菜单..." -r
}

# 主循环
main() {
    check_root
    check_config
    
    while true; do
        show_main_menu
        read -p "请选择操作 (0-14): " -r choice
        
        case $choice in
            1) show_service_status ;;
            2) show_logs ;;
            3) restart_service; read -p "按回车键继续..." -r ;;
            4) systemctl start "$SERVICE_NAME"; log_info "服务已启动"; read -p "按回车键继续..." -r ;;
            5) systemctl stop "$SERVICE_NAME"; log_info "服务已停止"; read -p "按回车键继续..." -r ;;
            6) show_config ;;
            7) change_ip ;;
            8) change_schedule ;;
            9) manage_domains ;;
            10) auto_discovery_settings ;;
            11) change_interval ;;
            12) test_run ;;
            13) edit_config ;;
            14) show_help ;;
            0) 
                log_info "感谢使用 Cloudflare Auto DDNS 管理工具！"
                exit 0
                ;;
            *) 
                log_error "无效选择，请输入 0-14"
                sleep 1
                ;;
        esac
    done
}

# 运行主程序
main "$@"
