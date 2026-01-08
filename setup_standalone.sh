#!/bin/bash

# Cloudflare Auto DDNS - 独立安装脚本
# 无需git，一键安装到系统
# 作者: https://github.com/Cd1s/cloudflare_auto_ddns

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
SERVICE_NAME="cloudflare-auto-ddns"
INSTALL_DIR="/etc/cloudflare_auto_ddns"
BIN_DIR="/usr/local/bin"
LOG_FILE="/var/log/cloudflare-auto-ddns.log"

# 配置变量
CF_EMAIL=""
CF_API_TOKEN=""
DAY_START_HOUR=""
DAY_END_HOUR=""
DAY_IP=""
NIGHT_IP=""
TARGET_ZONES=()
TARGET_DOMAINS=()
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
    echo "║  项目地址: https://github.com/Cd1s/cloudflare_auto_ddns      ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo -e "${GREEN}欢迎使用 Cloudflare Auto DDNS 一键安装程序！${NC}"
    echo ""
    echo -e "${YELLOW}📋 本程序将引导您完成以下配置：${NC}"
    echo "  1. Cloudflare 账户信息"
    echo "  2. 时间段和IP设置"
    echo "  3. 域名扫描模式配置"
    echo "  4. 系统设置"
    echo "  5. 自动安装和启动服务"
    echo ""
    echo -e "${CYAN}💡 安装完成后，使用 'cfddns' 命令即可进入管理界面！${NC}"
    echo ""
    
    # 检测是否通过管道运行，如果是则自动继续
    if [[ -t 0 ]]; then
        read -p "按回车键开始配置..." -r
    else
        echo "检测到非交互模式，自动开始配置..."
        sleep 2
    fi
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
        apt install -y python3 python3-requests curl >/dev/null 2>&1
    elif [[ $DISTRO == "redhat" ]]; then
        yum install -y python3 curl >/dev/null 2>&1
        # 使用系统包管理器安装requests
        if command -v dnf >/dev/null 2>&1; then
            dnf install -y python3-requests >/dev/null 2>&1
        else
            yum install -y python3-requests >/dev/null 2>&1 || {
                # 如果包管理器中没有，则使用pip
                command -v pip3 >/dev/null 2>&1 || yum install -y python3-pip >/dev/null 2>&1
                pip3 install requests >/dev/null 2>&1
            }
        fi
    else
        log_warn "请手动安装: python3, python3-requests"
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

# 配置域名
config_domains() {
    log_title "域名配置"
    echo ""
    
    echo -e "${YELLOW}🌐 域名扫描模式选择：${NC}"
    echo ""
    echo "1) 扫描所有Zone (推荐) - 自动扫描所有zone下使用目标IP的域名并更换"
    echo "2) 指定Zone扫描 - 只扫描指定的zone(如 example.com)，更换其下的所有使用目标IP的域名"
    echo "3) 指定具体域名 - 只更换指定的具体域名(如 www.example.com, api.example.com)"
    echo ""
    
    while true; do
        log_input "请选择模式 (1-3)："
        read -r mode_choice
        
        case $mode_choice in
            1)
                log_info "已选择：扫描所有Zone模式"
                echo -e "${CYAN}💡 系统将自动扫描您账户下所有zone，并更换使用目标IP的域名${NC}"
                break
                ;;
            2)
                echo ""
                echo -e "${YELLOW}请输入要扫描的Zone (根域名)：${NC}"
                echo "例如："
                echo "  example.com"
                echo "  mysite.org"
                echo ""
                echo "输入空行结束添加"
                echo ""
                
                while true; do
                    log_input "Zone名称 (或直接回车结束)："
                    read -r zone_input
                    
                    if [[ -z "$zone_input" ]]; then
                        break
                    fi
                    
                    if [[ "$zone_input" =~ ^[a-zA-Z0-9.-]+$ ]]; then
                        TARGET_ZONES+=("$zone_input")
                        log_info "已添加Zone: $zone_input"
                    else
                        log_error "Zone格式不正确，请输入有效的域名"
                    fi
                done
                
                if [[ ${#TARGET_ZONES[@]} -eq 0 ]]; then
                    log_error "未添加任何Zone，请至少添加一个"
                    continue
                else
                    log_info "已配置 ${#TARGET_ZONES[@]} 个Zone"
                    break
                fi
                ;;
            3)
                echo ""
                echo -e "${YELLOW}请输入要更换的具体域名：${NC}"
                echo "格式: 域名,所属Zone"
                echo "例如："
                echo "  www.example.com,example.com"
                echo "  api.example.com,example.com"
                echo "  blog.mysite.org,mysite.org"
                echo ""
                echo "输入空行结束添加"
                echo ""
                
                while true; do
                    log_input "域名,Zone (或直接回车结束)："
                    read -r domain_input
                    
                    if [[ -z "$domain_input" ]]; then
                        break
                    fi
                    
                    if [[ "$domain_input" =~ ^([a-zA-Z0-9.-]+),([a-zA-Z0-9.-]+)$ ]]; then
                        domain_name="${BASH_REMATCH[1]}"
                        zone_name="${BASH_REMATCH[2]}"
                        TARGET_DOMAINS+=("$domain_name,$zone_name")
                        log_info "已添加: $domain_name (Zone: $zone_name)"
                    else
                        log_error "格式不正确，请使用：域名,Zone"
                    fi
                done
                
                if [[ ${#TARGET_DOMAINS[@]} -eq 0 ]]; then
                    log_error "未添加任何域名，请至少添加一个"
                    continue
                else
                    log_info "已配置 ${#TARGET_DOMAINS[@]} 个域名"
                    break
                fi
                ;;
            *)
                log_error "无效选择，请输入 1-3"
                ;;
        esac
    done
    
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
    if [[ ${#TARGET_ZONES[@]} -gt 0 ]]; then
        echo "  📂 指定Zone扫描模式"
        echo "  扫描以下Zone下使用目标IP的域名:"
        for zone in "${TARGET_ZONES[@]}"; do
            echo "    - $zone"
        done
    elif [[ ${#TARGET_DOMAINS[@]} -gt 0 ]]; then
        echo "  📝 指定域名模式"
        echo "  只更换以下具体域名:"
        for domain in "${TARGET_DOMAINS[@]}"; do
            IFS=',' read -r domain_name zone_name <<< "$domain"
            echo "    - $domain_name (Zone: $zone_name)"
        done
    else
        echo "  🔍 全局扫描模式"
        echo "  扫描所有Zone下使用目标IP的域名"
    fi
    echo ""
    echo -e "${CYAN}系统配置:${NC}"
    echo "  安装目录: $INSTALL_DIR"
    echo "  检查间隔: ${CHECK_INTERVAL}秒"
    echo "  日志文件: $LOG_FILE"
    echo "  管理命令: cfddns"
    echo ""
    
    read -p "确认配置并开始安装？(Y/n): " -r confirm
    if [[ $confirm =~ ^[Nn]$ ]]; then
        log_error "安装已取消"
        exit 1
    fi
}

# 创建主程序文件
create_main_program() {
    log_step "创建主程序文件..."
    
    cat > "$INSTALL_DIR/auto_ddns.py" << 'MAIN_PROGRAM_EOF'
#!/usr/bin/env python3
"""
Cloudflare Auto DDNS - 智能时间段DNS解析切换工具
根据时间段自动切换Cloudflare DNS记录的IP地址
专注于只替换指定的IP记录，完全保留其他解析记录

GitHub: https://github.com/Cd1s/cloudflare_auto_ddns
License: MIT
"""

import json
import time
import logging
import requests
import sys
import os
import signal
from datetime import datetime
from typing import Dict, List


class CloudflareAPI:
    """Cloudflare API 交互类"""
    
    def __init__(self, email: str, api_token: str):
        self.email = email
        self.api_token = api_token
        self.base_url = "https://api.cloudflare.com/client/v4"
        self.headers = {
            "Authorization": f"Bearer {api_token}",
            "Content-Type": "application/json"
        }
    
    def _make_request(self, method: str, endpoint: str, data: Dict = None) -> Dict:
        """发送API请求"""
        url = f"{self.base_url}/{endpoint}"
        
        try:
            response = getattr(requests, method.lower())(
                url, headers=self.headers, json=data, timeout=30
            )
            response.raise_for_status()
            result = response.json()
            
            if not result.get("success", False):
                errors = result.get("errors", [])
                error_msg = "; ".join([err.get("message", "未知错误") for err in errors])
                raise Exception(f"Cloudflare API错误: {error_msg}")
            
            return result
            
        except Exception as e:
            raise Exception(f"请求失败: {str(e)}")
    
    def get_zone_id(self, domain: str) -> str:
        """获取域名的Zone ID"""
        result = self._make_request("GET", f"zones?name={domain}")
        zones = result.get("result", [])
        if not zones:
            raise Exception(f"未找到域名 {domain}")
        return zones[0]["id"]
    
    def get_dns_records(self, zone_id: str, name: str = None) -> List[Dict]:
        """获取DNS记录"""
        endpoint = f"zones/{zone_id}/dns_records?type=A"
        if name:
            endpoint += f"&name={name}"
        result = self._make_request("GET", endpoint)
        return result.get("result", [])
    
    def update_dns_record(self, zone_id: str, record_id: str, name: str, content: str) -> Dict:
        """更新DNS记录"""
        data = {
            "type": "A",
            "name": name,
            "content": content,
            "ttl": 300
        }
        return self._make_request("PUT", f"zones/{zone_id}/dns_records/{record_id}", data)


class AutoDDNS:
    """自动DDNS主类"""
    
    def __init__(self, config_path: str):
        self.config = self._load_config(config_path)
        self.cf_api = CloudflareAPI(
            self.config["cloudflare"]["email"],
            self.config["cloudflare"]["api_token"]
        )
        self.logger = self._setup_logging()
        self.running = True
        self.zone_cache = {}
        
        # 信号处理
        signal.signal(signal.SIGTERM, self._signal_handler)
        signal.signal(signal.SIGINT, self._signal_handler)
    
    def _signal_handler(self, signum, frame):
        self.logger.info(f"收到信号 {signum}，正在退出...")
        self.running = False
    
    def _load_config(self, config_path: str) -> Dict:
        """加载配置文件"""
        try:
            with open(config_path, 'r', encoding='utf-8') as f:
                config = json.load(f)
            
            # 验证必要的配置项
            required_fields = [
                "cloudflare.email", "cloudflare.api_token",
                "schedule.day_start_hour", "schedule.day_end_hour",
                "schedule.day_ip", "schedule.night_ip", "domains"
            ]
            
            for field in required_fields:
                keys = field.split('.')
                value = config
                try:
                    for key in keys:
                        value = value[key]
                except KeyError:
                    raise Exception(f"配置文件缺少必要字段: {field}")
            
            return config
            
        except FileNotFoundError:
            raise Exception(f"配置文件未找到: {config_path}")
        except json.JSONDecodeError as e:
            raise Exception(f"配置文件JSON格式错误: {str(e)}")
    
    def _setup_logging(self) -> logging.Logger:
        """设置日志"""
        log_config = self.config.get("log", {})
        log_level = getattr(logging, log_config.get("level", "INFO").upper())
        log_file = log_config.get("file", "/var/log/cloudflare-auto-ddns.log")
        
        # 创建日志目录
        log_dir = os.path.dirname(log_file)
        try:
            os.makedirs(log_dir, exist_ok=True)
        except PermissionError:
            log_file = "cloudflare-auto-ddns.log"  # 降级到当前目录
        
        # 配置日志格式
        formatter = logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
        
        # 文件处理器
        try:
            file_handler = logging.FileHandler(log_file, encoding='utf-8')
            file_handler.setFormatter(formatter)
        except PermissionError:
            file_handler = None
        
        # 控制台处理器
        console_handler = logging.StreamHandler()
        console_handler.setFormatter(formatter)
        
        # 设置logger
        logger = logging.getLogger("CloudflareAutoDDNS")
        logger.setLevel(log_level)
        
        if file_handler:
            logger.addHandler(file_handler)
        logger.addHandler(console_handler)
        
        return logger
    
    def get_current_target_ip(self) -> str:
        """根据当前时间获取目标IP"""
        now = datetime.now()
        current_hour = now.hour
        
        schedule = self.config["schedule"]
        day_start = schedule["day_start_hour"]
        day_end = schedule["day_end_hour"]
        
        self.logger.debug(f"当前时间: {now.strftime('%H:%M:%S')} (小时: {current_hour})")
        
        # 白天时间段
        if day_start <= current_hour < day_end:
            return schedule["day_ip"]
        else:
            return schedule["night_ip"]
    
    def get_zone_id(self, zone_name: str) -> str:
        """获取Zone ID（带缓存）"""
        if zone_name not in self.zone_cache:
            self.zone_cache[zone_name] = self.cf_api.get_zone_id(zone_name)
        return self.zone_cache[zone_name]
    
    def update_domain_records(self) -> int:
        """更新域名记录，只替换指定的IP"""
        target_ip = self.get_current_target_ip()
        managed_ips = [self.config["schedule"]["day_ip"], self.config["schedule"]["night_ip"]]
        auto_discovery = self.config.get("auto_discovery", True)
        
        self.logger.info(f"目标IP: {target_ip}, 管理的IP: {managed_ips}")
        self.logger.info(f"自动发现功能: {'开启' if auto_discovery else '关闭'}")
        
        updated_count = 0
        
        # 处理配置中的域名
        for domain_config in self.config["domains"]:
            domain_name = domain_config["name"]
            zone_name = domain_config["zone"]
            
            try:
                zone_id = self.get_zone_id(zone_name)
                records = self.cf_api.get_dns_records(zone_id, domain_name)
                
                for record in records:
                    record_ip = record["content"]
                    
                    # 只更新我们管理的IP
                    if record_ip in managed_ips and record_ip != target_ip:
                        self.logger.info(f"更新配置域名 {domain_name}: {record_ip} -> {target_ip}")
                        
                        self.cf_api.update_dns_record(
                            zone_id, record["id"], domain_name, target_ip
                        )
                        updated_count += 1
                        self.logger.info(f"✅ 成功更新配置域名 {domain_name}")
                        
            except Exception as e:
                self.logger.error(f"❌ 处理域名 {domain_name} 失败: {str(e)}")
        
        # 智能发现功能（可选）
        if auto_discovery:
            self.logger.info("🔍 开始智能发现扫描...")
            zones_scanned = set()
            for domain_config in self.config["domains"]:
                zone_name = domain_config["zone"]
                if zone_name in zones_scanned:
                    continue
                zones_scanned.add(zone_name)
                
                try:
                    zone_id = self.get_zone_id(zone_name)
                    all_records = self.cf_api.get_dns_records(zone_id)
                    
                    configured_domains = [d["name"] for d in self.config["domains"]]
                    
                    for record in all_records:
                        record_name = record["name"]
                        record_ip = record["content"]
                        
                        # 跳过已配置的域名，只处理未配置但使用我们管理IP的域名
                        if (record_name not in configured_domains and 
                            record_ip in managed_ips and 
                            record_ip != target_ip):
                            
                            self.logger.info(f"🔍 智能发现域名 {record_name}: {record_ip} -> {target_ip}")
                            
                            self.cf_api.update_dns_record(
                                zone_id, record["id"], record_name, target_ip
                            )
                            updated_count += 1
                            self.logger.info(f"✅ 成功更新发现域名 {record_name}")
                            
                except Exception as e:
                    self.logger.error(f"❌ 扫描Zone {zone_name} 失败: {str(e)}")
        else:
            self.logger.info("🔒 智能发现功能已关闭，仅处理配置中的域名")
        
        return updated_count
    
    def run(self) -> None:
        """主运行循环"""
        self.logger.info("🚀 Cloudflare Auto DDNS 启动")
        
        # 显示配置信息
        schedule = self.config["schedule"]
        self.logger.info(f"配置: 白天({schedule['day_start_hour']}-{schedule['day_end_hour']}) = {schedule['day_ip']}")
        self.logger.info(f"配置: 夜间({schedule['day_end_hour']}-{schedule['day_start_hour']}) = {schedule['night_ip']}")
        
        # 立即执行一次
        try:
            count = self.update_domain_records()
            if count > 0:
                self.logger.info(f"✅ 启动时更新了 {count} 个DNS记录")
            else:
                self.logger.info("✅ 启动时检查完成，无需更新")
        except Exception as e:
            self.logger.error(f"❌ 启动时更新失败: {str(e)}")
        
        # 主循环
        check_interval = self.config.get("check_interval", 300)
        self.logger.info(f"⏰ 每 {check_interval} 秒检查一次")
        
        while self.running:
            try:
                time.sleep(check_interval)
                if not self.running:
                    break
                
                count = self.update_domain_records()
                if count > 0:
                    self.logger.info(f"✅ 本轮更新了 {count} 个DNS记录")
                    
            except KeyboardInterrupt:
                break
            except Exception as e:
                self.logger.error(f"❌ 运行错误: {str(e)}")
                time.sleep(60)  # 错误后等待1分钟
        
        self.logger.info("🛑 Cloudflare Auto DDNS 已停止")


def main():
    """主函数"""
    if len(sys.argv) != 2:
        print("用法: python3 auto_ddns.py <配置文件路径>")
        print("示例: python3 auto_ddns.py /etc/cloudflare_auto_ddns/config.json")
        sys.exit(1)
    
    config_path = sys.argv[1]
    
    if not os.path.exists(config_path):
        print(f"❌ 配置文件不存在: {config_path}")
        sys.exit(1)
    
    try:
        ddns = AutoDDNS(config_path)
        ddns.run()
    except Exception as e:
        print(f"❌ 启动失败: {str(e)}")
        sys.exit(1)


if __name__ == "__main__":
    main()
MAIN_PROGRAM_EOF

    chmod +x "$INSTALL_DIR/auto_ddns.py"
    log_info "主程序文件创建完成"
}

# 生成配置文件
generate_config() {
    log_step "生成配置文件..."
    
    cat > "$INSTALL_DIR/config.json" << EOF
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
  "target_zones": [
EOF

    # 添加目标zones
    if [[ ${#TARGET_ZONES[@]} -gt 0 ]]; then
        for i in "${!TARGET_ZONES[@]}"; do
            if [[ $i -eq $((${#TARGET_ZONES[@]} - 1)) ]]; then
                echo "    \"${TARGET_ZONES[$i]}\"" >> "$INSTALL_DIR/config.json"
            else
                echo "    \"${TARGET_ZONES[$i]}\"," >> "$INSTALL_DIR/config.json"
            fi
        done
    fi

    cat >> "$INSTALL_DIR/config.json" << EOF
  ],
  "target_domains": [
EOF

    # 添加目标域名
    if [[ ${#TARGET_DOMAINS[@]} -gt 0 ]]; then
        for i in "${!TARGET_DOMAINS[@]}"; do
            IFS=',' read -r domain_name zone_name <<< "${TARGET_DOMAINS[$i]}"
            echo "    {" >> "$INSTALL_DIR/config.json"
            echo "      \"name\": \"$domain_name\"," >> "$INSTALL_DIR/config.json"
            echo "      \"zone\": \"$zone_name\"" >> "$INSTALL_DIR/config.json"
            if [[ $i -eq $((${#TARGET_DOMAINS[@]} - 1)) ]]; then
                echo "    }" >> "$INSTALL_DIR/config.json"
            else
                echo "    }," >> "$INSTALL_DIR/config.json"
            fi
        done
    fi

    cat >> "$INSTALL_DIR/config.json" << EOF
  ],
  "_domain_config_comment": "配置说明：1) target_zones不为空: 只扫描这些zone下使用目标IP的域名; 2) target_domains不为空: 只更新这些具体域名; 3) 都为空: 扫描所有zones下使用目标IP的域名",
  "log": {
    "level": "INFO",
    "file": "$LOG_FILE"
  },
  "check_interval": $CHECK_INTERVAL
}
EOF

    chmod 600 "$INSTALL_DIR/config.json"
    log_info "配置文件已生成: $INSTALL_DIR/config.json"
}

# 创建管理脚本
create_management_script() {
    log_step "创建管理脚本..."
    
    cat > "$INSTALL_DIR/manage.py" << 'MANAGE_SCRIPT_EOF'
#!/usr/bin/env python3
"""
Cloudflare Auto DDNS 管理工具
提供交互式管理界面
"""

import json
import os
import sys
import subprocess
import time
from datetime import datetime


class DDNSManager:
    def __init__(self):
        self.config_file = "/etc/cloudflare_auto_ddns/config.json"
        self.service_name = "cloudflare-auto-ddns"
        self.log_file = "/var/log/cloudflare-auto-ddns.log"
    
    def load_config(self):
        """加载配置文件"""
        try:
            with open(self.config_file, 'r', encoding='utf-8') as f:
                return json.load(f)
        except Exception as e:
            print(f"❌ 加载配置文件失败: {e}")
            return None
    
    def save_config(self, config):
        """保存配置文件"""
        try:
            # 备份原配置
            backup_file = f"{self.config_file}.backup.{int(time.time())}"
            subprocess.run(['cp', self.config_file, backup_file], check=True)
            
            with open(self.config_file, 'w', encoding='utf-8') as f:
                json.dump(config, f, indent=2, ensure_ascii=False)
            print("✅ 配置保存成功")
            return True
        except Exception as e:
            print(f"❌ 保存配置失败: {e}")
            return False
    
    def run_command(self, cmd):
        """执行系统命令"""
        try:
            result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
            return result.returncode == 0, result.stdout, result.stderr
        except Exception as e:
            return False, "", str(e)
    
    def restart_service(self):
        """重启服务"""
        print("🔄 重启服务...")
        success, stdout, stderr = self.run_command(f"systemctl restart {self.service_name}")
        if success:
            print("✅ 服务重启成功")
        else:
            print(f"❌ 服务重启失败: {stderr}")
        return success
    
    def show_main_menu(self):
        """显示主菜单"""
        print("\n" + "="*60)
        print("🚀 Cloudflare Auto DDNS 管理工具")
        print("="*60)
        print()
        print("📊 服务管理:")
        print("  1) 查看服务状态")
        print("  2) 查看实时日志")
        print("  3) 重启服务")
        print("  4) 启动服务")
        print("  5) 停止服务")
        print()
        print("⚙️ 配置管理:")
        print("  6) 查看当前配置")
        print("  7) 更换IP地址")
        print("  8) 修改时间段")
        print("  9) 管理域名")
        print("  10) 自动发现设置")
        print("  11) 修改检查间隔")
        print()
        print("🔧 高级功能:")
        print("  12) 手动测试运行")
        print("  0) 退出")
        print()
    
    def show_service_status(self):
        """显示服务状态"""
        print("\n📊 服务状态:")
        success, stdout, stderr = self.run_command(f"systemctl status {self.service_name} --no-pager")
        if success:
            print(stdout)
        else:
            print(f"❌ 获取状态失败: {stderr}")
        input("\n按回车键继续...")
    
    def show_logs(self):
        """显示实时日志"""
        print("\n📝 实时日志 (按 Ctrl+C 退出):")
        try:
            subprocess.run(f"journalctl -u {self.service_name} -f", shell=True)
        except KeyboardInterrupt:
            print("\n日志查看已退出")
    
    def show_config(self):
        """显示当前配置"""
        print("\n⚙️ 当前配置:")
        config = self.load_config()
        if config:
            print(json.dumps(config, indent=2, ensure_ascii=False))
        input("\n按回车键继续...")
    
    def change_ip(self):
        """更换IP地址"""
        print("\n🔄 更换IP地址")
        config = self.load_config()
        if not config:
            return
        
        current_day_ip = config['schedule']['day_ip']
        current_night_ip = config['schedule']['night_ip']
        
        print(f"\n当前配置:")
        print(f"  白天IP: {current_day_ip}")
        print(f"  夜间IP: {current_night_ip}")
        
        new_day_ip = input(f"\n新的白天IP (留空保持 {current_day_ip}): ").strip()
        if not new_day_ip:
            new_day_ip = current_day_ip
        
        new_night_ip = input(f"新的夜间IP (留空保持 {current_night_ip}): ").strip()
        if not new_night_ip:
            new_night_ip = current_night_ip
        
        if new_day_ip == new_night_ip:
            print("❌ 白天IP和夜间IP不能相同")
            return
        
        confirm = input(f"\n确认更改？ {current_day_ip}->{new_day_ip}, {current_night_ip}->{new_night_ip} (y/N): ")
        if confirm.lower() == 'y':
            config['schedule']['day_ip'] = new_day_ip
            config['schedule']['night_ip'] = new_night_ip
            if self.save_config(config):
                self.restart_service()
    
    def change_schedule(self):
        """修改时间段"""
        print("\n⏰ 修改时间段")
        config = self.load_config()
        if not config:
            return
        
        current_start = config['schedule']['day_start_hour']
        current_end = config['schedule']['day_end_hour']
        
        print(f"\n当前时间段:")
        print(f"  白天: {current_start}:00 - {current_end}:00")
        print(f"  夜间: {current_end}:00 - {current_start}:00")
        
        try:
            new_start = int(input(f"\n白天开始时间 (0-23): "))
            new_end = int(input(f"白天结束时间 (0-23): "))
            
            if not (0 <= new_start <= 23 and 0 <= new_end <= 23):
                print("❌ 时间必须在0-23之间")
                return
            
            if new_start == new_end:
                print("❌ 开始时间和结束时间不能相同")
                return
            
            confirm = input(f"\n确认更改？ {current_start}-{current_end} -> {new_start}-{new_end} (y/N): ")
            if confirm.lower() == 'y':
                config['schedule']['day_start_hour'] = new_start
                config['schedule']['day_end_hour'] = new_end
                if self.save_config(config):
                    self.restart_service()
                    
        except ValueError:
            print("❌ 请输入有效的数字")
    
    def manage_domains(self):
        """管理域名"""
        while True:
            print("\n🌐 域名管理")
            config = self.load_config()
            if not config:
                return
            
            domains = config.get('domains', [])
            print(f"\n当前域名 ({len(domains)}个):")
            for i, domain in enumerate(domains, 1):
                print(f"  {i}. {domain['name']} (Zone: {domain['zone']})")
            
            print("\n操作:")
            print("  1) 添加域名")
            print("  2) 删除域名")
            print("  0) 返回主菜单")
            
            choice = input("\n请选择 (0-2): ").strip()
            
            if choice == '1':
                domain_name = input("\n域名 (如: www.example.com): ").strip()
                zone_name = input("根域名 (如: example.com): ").strip()
                
                if domain_name and zone_name:
                    new_domain = {
                        "name": domain_name,
                        "zone": zone_name,
                        "type": "A"
                    }
                    config['domains'].append(new_domain)
                    if self.save_config(config):
                        self.restart_service()
                        print(f"✅ 已添加域名: {domain_name}")
            
            elif choice == '2':
                if not domains:
                    print("❌ 没有域名可删除")
                    continue
                
                try:
                    index = int(input(f"\n要删除的域名编号 (1-{len(domains)}): ")) - 1
                    if 0 <= index < len(domains):
                        domain_name = domains[index]['name']
                        confirm = input(f"确认删除 {domain_name}？ (y/N): ")
                        if confirm.lower() == 'y':
                            del config['domains'][index]
                            if self.save_config(config):
                                self.restart_service()
                                print(f"✅ 已删除域名: {domain_name}")
                    else:
                        print("❌ 无效的编号")
                except ValueError:
                    print("❌ 请输入有效的数字")
            
            elif choice == '0':
                break
    
    def toggle_auto_discovery(self):
        """切换自动发现功能"""
        print("\n🔍 自动发现功能设置")
        config = self.load_config()
        if not config:
            return
        
        current = config.get('auto_discovery', True)
        print(f"\n当前状态: {'开启' if current else '关闭'}")
        
        print("\n1) 开启自动发现")
        print("2) 关闭自动发现")
        print("0) 返回")
        
        choice = input("\n请选择 (0-2): ").strip()
        
        if choice == '1':
            new_setting = True
        elif choice == '2':
            new_setting = False
        else:
            return
        
        if new_setting != current:
            config['auto_discovery'] = new_setting
            if self.save_config(config):
                self.restart_service()
                print(f"✅ 自动发现功能已{'开启' if new_setting else '关闭'}")
    
    def change_interval(self):
        """修改检查间隔"""
        print("\n⏱️ 修改检查间隔")
        config = self.load_config()
        if not config:
            return
        
        current = config.get('check_interval', 300)
        print(f"\n当前间隔: {current}秒")
        
        try:
            new_interval = int(input("\n新的检查间隔 (秒，最小30): "))
            if new_interval < 30:
                print("❌ 间隔不能小于30秒")
                return
            
            confirm = input(f"\n确认更改？ {current} -> {new_interval} (y/N): ")
            if confirm.lower() == 'y':
                config['check_interval'] = new_interval
                if self.save_config(config):
                    self.restart_service()
                    
        except ValueError:
            print("❌ 请输入有效的数字")
    
    def test_run(self):
        """测试运行"""
        print("\n🧪 手动测试运行")
        print("⚠️  将停止服务并手动运行程序")
        
        confirm = input("\n继续？ (y/N): ")
        if confirm.lower() != 'y':
            return
        
        print("\n停止服务...")
        self.run_command(f"systemctl stop {self.service_name}")
        
        print("开始测试运行 (按 Ctrl+C 退出):")
        try:
            subprocess.run([
                "python3", 
                "/etc/cloudflare_auto_ddns/auto_ddns.py", 
                "/etc/cloudflare_auto_ddns/config.json"
            ])
        except KeyboardInterrupt:
            print("\n测试运行已退出")
        
        print("\n重启服务...")
        self.run_command(f"systemctl start {self.service_name}")
    
    def run(self):
        """运行管理工具"""
        if os.geteuid() != 0:
            print("❌ 此工具需要root权限运行")
            print("请使用: sudo cfddns")
            sys.exit(1)
        
        if not os.path.exists(self.config_file):
            print(f"❌ 配置文件不存在: {self.config_file}")
            print("请先运行安装脚本")
            sys.exit(1)
        
        while True:
            self.show_main_menu()
            choice = input("请选择操作 (0-12): ").strip()
            
            if choice == '1':
                self.show_service_status()
            elif choice == '2':
                self.show_logs()
            elif choice == '3':
                self.restart_service()
                input("按回车键继续...")
            elif choice == '4':
                self.run_command(f"systemctl start {self.service_name}")
                print("✅ 服务启动命令已执行")
                input("按回车键继续...")
            elif choice == '5':
                self.run_command(f"systemctl stop {self.service_name}")
                print("✅ 服务停止命令已执行")
                input("按回车键继续...")
            elif choice == '6':
                self.show_config()
            elif choice == '7':
                self.change_ip()
            elif choice == '8':
                self.change_schedule()
            elif choice == '9':
                self.manage_domains()
            elif choice == '10':
                self.toggle_auto_discovery()
            elif choice == '11':
                self.change_interval()
            elif choice == '12':
                self.test_run()
            elif choice == '0':
                print("\n👋 感谢使用 Cloudflare Auto DDNS 管理工具！")
                break
            else:
                print("❌ 无效选择")
                time.sleep(1)


if __name__ == "__main__":
    manager = DDNSManager()
    manager.run()
MANAGE_SCRIPT_EOF

    chmod +x "$INSTALL_DIR/manage.py"
    log_info "管理脚本创建完成"
}

# 创建系统服务
create_systemd_service() {
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
ExecStart=/usr/bin/python3 $INSTALL_DIR/auto_ddns.py $INSTALL_DIR/config.json
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

# 创建cfddns命令
create_cfddns_command() {
    log_step "创建 cfddns 命令..."
    
    cat > "$BIN_DIR/cfddns" << EOF
#!/bin/bash
# Cloudflare Auto DDNS 管理命令
exec python3 $INSTALL_DIR/manage.py "\$@"
EOF

    chmod +x "$BIN_DIR/cfddns"
    log_info "cfddns 命令创建完成"
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
    
    echo -e "${YELLOW}📂 安装信息：${NC}"
    echo "  安装目录: $INSTALL_DIR"
    echo "  配置文件: $INSTALL_DIR/config.json"
    echo "  日志文件: $LOG_FILE"
    echo "  服务名称: $SERVICE_NAME"
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
    echo "  自动发现: $(if [[ "$AUTO_DISCOVERY" == "true" ]]; then echo "开启"; else echo "关闭"; fi)"
    echo ""
    
    echo -e "${YELLOW}🔧 管理命令：${NC}"
    echo -e "${GREEN}  cfddns${NC}                    # 进入管理界面"
    echo "  systemctl status $SERVICE_NAME"
    echo "  journalctl -u $SERVICE_NAME -f"
    echo ""
    
    echo -e "${YELLOW}🔍 智能发现功能：${NC}"
    if [[ "$AUTO_DISCOVERY" == "true" ]]; then
        echo "  ✅ 系统会自动扫描您的Cloudflare账户"
        echo "  ✅ 发现所有使用 $DAY_IP 或 $NIGHT_IP 的域名"
        echo "  ✅ 自动添加到管理列表进行时间段切换"
        echo "  ✅ 无需手动配置，添加新域名后自动生效"
    else
        echo "  🔒 智能发现已关闭，仅管理手动配置的域名"
        echo "  🔒 如需添加新域名，请使用 cfddns 命令"
    fi
    echo ""
    
    echo -e "${GREEN}🎊 安装成功！现在可以使用 'cfddns' 命令进入管理界面！${NC}"
    echo ""
    
    read -p "按回车键查看实时日志 (Ctrl+C 退出): " -r
    journalctl -u "$SERVICE_NAME" -f
}

# 检测是否为交互模式
check_interactive() {
    if [[ -t 0 && -t 1 && -t 2 ]]; then
        INTERACTIVE_MODE=true
    else
        INTERACTIVE_MODE=false
        log_warn "检测到非交互模式，将使用默认配置"
        echo "如需自定义配置，请手动运行: sudo ./setup_standalone.sh"
        echo ""
    fi
}

# 非交互模式配置
setup_non_interactive() {
    log_title "非交互模式配置"
    echo ""
    log_error "❌ 当前为非交互模式，无法获取用户输入"
    echo ""
    echo -e "${YELLOW}🔧 请使用以下方式进行交互式安装：${NC}"
    echo ""
    echo "1. 手动下载并运行："
    echo "   wget https://raw.githubusercontent.com/Cd1s/cloudflare_auto_ddns/main/setup_standalone.sh"
    echo "   chmod +x setup_standalone.sh"
    echo "   sudo ./setup_standalone.sh"
    echo ""
    echo "2. 或克隆项目后安装："
    echo "   git clone https://github.com/Cd1s/cloudflare_auto_ddns.git"
    echo "   cd cloudflare-auto-ddns"
    echo "   sudo ./install.sh"
    echo ""
    log_error "安装已取消，请使用交互模式运行"
    exit 1
}

# 主安装流程
main() {
    show_welcome
    check_root
    check_interactive
    
    # 如果非交互模式，显示帮助并退出
    if [[ "$INTERACTIVE_MODE" == "false" ]]; then
        setup_non_interactive
    fi
    
    detect_system
    install_dependencies
    
    # 创建安装目录
    mkdir -p "$INSTALL_DIR"
    
    config_cloudflare
    config_timezone
    config_schedule
    config_domains
    config_advanced
    show_summary
    
    create_main_program
    generate_config
    create_management_script
    create_systemd_service
    create_cfddns_command
    start_service
    show_result
}

# 运行主程序
main "$@"
