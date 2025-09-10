#!/usr/bin/env python3
"""
Cloudflare Auto DDNS - 智能时间段DNS解析切换工具
根据时间段自动切换Cloudflare DNS记录的IP地址
专注于只替换指定的IP记录，完全保留其他解析记录

GitHub: https://github.com/your-username/cloudflare-auto-ddns
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
        print("示例: python3 auto_ddns.py config.json")
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
