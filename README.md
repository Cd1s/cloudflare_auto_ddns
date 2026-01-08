# Cloudflare Auto DDNS

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python 3.7+](https://img.shields.io/badge/python-3.7+-blue.svg)](https://www.python.org/downloads/)

🚀 **智能时间段DNS解析切换工具** - 根据时间段自动切换Cloudflare DNS记录的IP地址

## 🌟 特性

- ⏰ **时间段切换**: 支持按时间段自动切换IP（如白天/夜间不同线路）
- 🎯 **精确替换**: 只替换指定的IP记录，完全保留域名的其他解析记录
- 🔄 **智能扫描**: 三种域名管理模式 - 全局扫描/指定Zone/指定域名
- 🛡️ **安全可靠**: 完整的错误处理和日志记录，不会误删其他DNS记录
- 🔧 **易于管理**: 使用 `cfddns` 命令进入美化的管理界面
- 🚀 **systemd集成**: 作为系统服务运行，开机自启
- 📊 **完善监控**: 详细的日志和状态监控

## 🎯 使用场景

- **CDN线路切换**: 白天使用经济线路，夜间使用高速线路
- **负载均衡**: 根据时间段分配不同的服务器
- **网络优化**: 根据网络状况自动切换解析
- **成本控制**: 在不同时段使用不同成本的服务

## 📋 系统要求

- Python 3.7+
- Linux系统（推荐Ubuntu/Debian/CentOS）
- Cloudflare账户和API Token
- systemd支持

## 🚀 一键安装

```bash
wget https://raw.githubusercontent.com/Cd1s/cloudflare_auto_ddns/main/setup_standalone.sh
chmod +x setup_standalone.sh
sudo ./setup_standalone.sh
```

**✨ 安装完成后使用 `cfddns` 命令进入管理界面！**

## 🎮 管理界面

安装完成后，运行 `cfddns` 进入交互式管理界面：

```
============================================================
🚀 Cloudflare Auto DDNS 管理工具
============================================================

📊 服务管理:
  1) 查看服务状态
  2) 查看实时日志
  3) 重启服务
  4) 启动服务
  5) 停止服务

⚙️ 配置管理:
  6) 查看当前配置
  7) 更换IP地址
  8) 修改时间段
  9) 管理域名

🔧 系统管理:
  10) 更新程序
  11) 卸载程序
  0) 退出
```

## 📖 配置说明

### 域名扫描模式

程序支持三种域名管理模式：

#### 1. 全局扫描模式（推荐）
- `target_zones` 和 `target_domains` 都为空
- 自动扫描您Cloudflare账户下所有Zone
- 识别所有使用目标IP的域名并自动更换

```json
{
  "target_zones": [],
  "target_domains": []
}
```

#### 2. 指定Zone扫描模式
- 只扫描指定的Zone（根域名）
- 更换该Zone下所有使用目标IP的域名

```json
{
  "target_zones": ["example.com", "mysite.org"],
  "target_domains": []
}
```

#### 3. 指定域名模式
- 只更换指定的具体域名
- 最精确的控制方式

```json
{
  "target_zones": [],
  "target_domains": [
    {"name": "www.example.com", "zone": "example.com"},
    {"name": "api.example.com", "zone": "example.com"}
  ]
}
```

### 完整配置示例

```json
{
  "cloudflare": {
    "email": "your-email@example.com",
    "api_token": "your-cloudflare-api-token"
  },
  "schedule": {
    "day_start_hour": 6,
    "day_end_hour": 22,
    "day_ip": "1.2.3.4",
    "night_ip": "5.6.7.8",
    "_comment": "时间使用时区: Asia/Shanghai"
  },
  "target_zones": [],
  "target_domains": [],
  "log": {
    "level": "INFO",
    "file": "/var/log/cloudflare-auto-ddns.log"
  },
  "check_interval": 300
}
```

## 🔑 获取 Cloudflare API Token

1. 登录 [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. 点击右上角头像 → **My Profile**
3. 左侧菜单选择 **API Tokens**
4. 点击 **Create Token**
5. 使用模板 **Edit zone DNS** 或自定义权限：
   - Zone:Zone:Read
   - Zone:DNS:Edit
6. 选择要管理的 Zone
7. 创建并复制 Token

## 📊 服务管理

```bash
# 查看服务状态
sudo systemctl status cloudflare-auto-ddns

# 启动服务
sudo systemctl start cloudflare-auto-ddns

# 停止服务
sudo systemctl stop cloudflare-auto-ddns

# 重启服务
sudo systemctl restart cloudflare-auto-ddns

# 查看实时日志
sudo journalctl -u cloudflare-auto-ddns -f

# 或使用管理命令
cfddns
```

## 🔄 更新程序

```bash
# 使用管理命令更新
cfddns
# 然后选择 "10) 更新程序"

# 或手动更新
wget https://raw.githubusercontent.com/Cd1s/cloudflare_auto_ddns/main/setup_standalone.sh
chmod +x setup_standalone.sh
sudo ./setup_standalone.sh
```

## 🗑️ 卸载程序

```bash
# 使用管理命令卸载
cfddns
# 然后选择 "11) 卸载程序"

# 或手动卸载
sudo systemctl stop cloudflare-auto-ddns
sudo systemctl disable cloudflare-auto-ddns
sudo rm -f /etc/systemd/system/cloudflare-auto-ddns.service
sudo rm -rf /etc/cloudflare_auto_ddns
sudo rm -f /usr/local/bin/cfddns
sudo systemctl daemon-reload
```

## 🐛 故障排查

### 查看日志
```bash
# 查看服务日志
sudo journalctl -u cloudflare-auto-ddns -n 100

# 查看完整日志文件
sudo tail -f /var/log/cloudflare-auto-ddns.log
```

### 常见问题

**Q: 服务无法启动？**
A: 检查配置文件格式是否正确，API Token是否有效

**Q: 域名没有被更新？**
A: 确认域名模式配置正确，查看日志了解扫描情况

**Q: 如何测试配置？**
A: 使用 `cfddns` 命令中的"手动测试运行"功能

## 📝 更新日志

查看 [CHANGELOG.md](CHANGELOG.md) 了解版本更新详情

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

MIT License - 查看 [LICENSE](LICENSE) 文件了解详情

## 🔗 相关链接

- [GitHub Repository](https://github.com/Cd1s/cloudflare_auto_ddns)
- [Cloudflare API文档](https://developers.cloudflare.com/api/)
- [问题反馈](https://github.com/Cd1s/cloudflare_auto_ddns/issues)

---

⭐ 如果这个项目对您有帮助，请给个 Star！
