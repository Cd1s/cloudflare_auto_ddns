# Cloudflare Auto DDNS

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python 3.7+](https://img.shields.io/badge/python-3.7+-blue.svg)](https://www.python.org/downloads/)

🚀 **智能时间段DNS解析切换工具** - 根据时间段自动切换Cloudflare DNS记录的IP地址

## 🌟 特性

- ⏰ **时间段切换**: 支持按时间段自动切换IP（如白天/夜间不同线路）
- 🎯 **精确替换**: 只替换指定的IP记录，完全保留域名的其他解析记录
- 🔄 **智能同步**: 自动发现并同步所有使用目标IP的域名（包括未配置的域名）
- 🛡️ **安全可靠**: 完整的错误处理和日志记录，不会误删其他DNS记录
- 🔧 **易于配置**: JSON配置文件，支持热更新
- 🚀 **systemd集成**: 作为系统服务运行，开机自启
- 📊 **完善监控**: 详细的日志和状态监控
- 🌐 **多场景支持**: 适用于CDN切换、线路优化、负载均衡等场景

## 🎯 使用场景

- **CDN线路切换**: 白天使用高速线路，夜间使用经济线路
- **负载均衡**: 根据时间段分配不同的服务器
- **网络优化**: 根据网络状况自动切换解析
- **成本控制**: 在不同时段使用不同成本的服务

## 📋 系统要求

- Python 3.7+
- Linux系统（推荐Ubuntu/Debian/CentOS）
- Cloudflare账户和API Token
- systemd支持（可选，用于服务管理）

## 🚀 快速开始

### 方式一：交互式一键安装 (推荐)

```bash
# 克隆项目
git clone https://github.com/your-username/cloudflare-auto-ddns.git
cd cloudflare-auto-ddns

# 运行交互式安装脚本
sudo ./install.sh
```

**安装脚本会引导您完成：**
- 🔑 Cloudflare账户配置 (邮箱 + API Token)
- 🌍 时区选择 (包含北京时间等常用时区)
- ⏰ 时间段设置 (白天/夜间切换时间)
- 🌐 IP地址配置 (白天IP + 夜间IP)
- 📝 域名配置 (可选，支持智能发现)
- ⚙️ 系统设置 (检查间隔等)
- 🚀 自动安装并启动服务

### 方式二：手动配置安装

```bash
# 克隆项目
git clone https://github.com/your-username/cloudflare-auto-ddns.git
cd cloudflare-auto-ddns

# 安装依赖
pip3 install -r requirements.txt

# 复制配置模板并编辑
cp config.example.json config.json
nano config.json

# 运行安装脚本
sudo ./setup.sh
```

配置示例：

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
    "night_ip": "5.6.7.8"
  },
  "domains": [
    {
      "name": "example.com",
      "zone": "example.com",
      "type": "A"
    },
    {
      "name": "www.example.com", 
      "zone": "example.com",
      "type": "A"
    }
  ],
  "check_interval": 300
}
```

### 3. 获取Cloudflare API Token

1. 登录 [Cloudflare Dashboard](https://dash.cloudflare.com/profile/api-tokens)
2. 点击 "Create Token"
3. 使用 "Custom token" 模板
4. 设置权限：
   - Zone: Zone:Read
   - Zone: DNS:Edit
5. 设置Zone Resources：选择您要管理的域名
6. 复制生成的Token

### 4. 运行

#### 手动测试

```bash
# 测试运行
python3 auto_ddns.py config.json
```

#### 安装为系统服务

```bash
# 运行安装脚本
sudo ./setup.sh

# 启动服务
sudo systemctl start cloudflare-auto-ddns
sudo systemctl enable cloudflare-auto-ddns
```

#### 服务管理

**方式一：使用交互式管理脚本 (推荐)**
```bash
# 运行交互式管理工具
sudo ./manage.sh
```

**管理工具功能：**
- 📊 服务管理 (启动/停止/重启/状态/日志)
- ⚙️ 配置管理 (更换IP/修改时间段/管理域名)
- 🔍 自动发现设置 (开启/关闭智能发现)
- 🔧 高级功能 (测试运行/编辑配置/扫描域名)

**方式二：使用systemctl命令**
```bash
# 查看状态
sudo systemctl status cloudflare-auto-ddns

# 查看日志
sudo journalctl -u cloudflare-auto-ddns -f

# 重启服务
sudo systemctl restart cloudflare-auto-ddns

# 停止服务
sudo systemctl stop cloudflare-auto-ddns
```

**方式三：使用快捷命令**
```bash
# 如果安装时创建了快捷命令
cloudflare-auto-ddns status
cloudflare-auto-ddns logs
cloudflare-auto-ddns restart
```

## ⚙️ 配置说明

### 基本配置

| 字段 | 说明 | 示例 |
|------|------|------|
| `cloudflare.email` | Cloudflare账户邮箱 | `user@example.com` |
| `cloudflare.api_token` | Cloudflare API Token | `your-token` |
| `schedule.day_start_hour` | 白天开始时间（24小时制） | `6` (早上6点) |
| `schedule.day_end_hour` | 白天结束时间（24小时制） | `22` (晚上10点) |
| `schedule.day_ip` | 白天使用的IP地址 | `1.2.3.4` |
| `schedule.night_ip` | 夜间使用的IP地址 | `5.6.7.8` |
| `check_interval` | 检查间隔（秒） | `300` (5分钟) |

### 域名配置

```json
{
  "name": "域名",
  "zone": "根域名",
  "type": "记录类型"
}
```

## 🔧 高级功能

### 🔍 智能发现功能

**可选的智能发现功能！** 系统具有强大的智能发现功能，可以选择开启或关闭：

#### 🟢 开启智能发现 (推荐)
- ✅ **自动扫描**: 扫描您Cloudflare账户中的所有Zone
- ✅ **智能识别**: 自动发现使用目标IP的所有域名
- ✅ **自动管理**: 即使未在配置文件中指定的域名也会被自动管理
- ✅ **实时生效**: 新添加的域名会在下次检查时自动加入管理

#### 🔒 关闭智能发现 (精确控制)
- 🔒 **精确控制**: 只管理手动配置的域名列表
- 🔒 **避免意外**: 避免误操作其他恰好使用相同IP的域名
- 🔒 **复杂环境**: 适合复杂DNS配置环境

#### 📝 配置方式
```json
{
  "auto_discovery": true,   // 开启智能发现
  "auto_discovery": false   // 关闭智能发现
}
```

#### 🎯 使用场景示例
**场景1**: 您有 `1.example.com` 解析到 `2.2.2.2`，同时 `2.example.com` 也恰好解析到 `2.2.2.2`
- **开启智能发现**: 两个域名都会被自动管理
- **关闭智能发现**: 只有手动配置的域名会被管理

**工作原理：**
1. 程序扫描您的所有Cloudflare Zone
2. 查找使用白天IP或夜间IP的A记录
3. 根据设置决定是否自动管理这些域名
4. 按时间段自动切换IP

**例如：** 您在Cloudflare新增了 `new.example.com` 并设置为管理的IP之一：
- 开启智能发现：系统会在5-10分钟内自动发现并开始管理
- 关闭智能发现：需要手动添加到配置文件才会被管理

### 🛡️ 多IP保护

如果域名有多个A记录，系统只会更新包含管理IP的记录，完全保留其他IP解析：

- 只替换指定的白天/夜间IP
- 保留域名的其他IP解析记录  
- 不影响CNAME、MX等其他类型记录
- 支持多IP负载均衡场景

### 🔄 错误恢复

系统具有完善的错误处理机制，遇到网络问题或API错误时会自动重试。

## 📊 监控和日志

### 日志位置

- 系统日志: `/var/log/cloudflare-auto-ddns.log`
- systemd日志: `journalctl -u cloudflare-auto-ddns`

### 日志格式

```
2025-01-01 12:00:00 - INFO - 🚀 Cloudflare Auto DDNS 启动
2025-01-01 12:00:01 - INFO - ✅ 成功更新 example.com: 1.2.3.4 -> 5.6.7.8
2025-01-01 12:00:02 - INFO - ⏰ 每 300 秒检查一次
```

## 🔒 安全注意事项

1. **API Token安全**: 配置文件权限设置为600，仅当前用户可访问
2. **最小权限原则**: API Token只授予必要的DNS编辑权限
3. **日志安全**: 敏感信息不会记录到日志中
4. **网络安全**: 所有API请求使用HTTPS加密

## 🛠️ 故障排除

### 常见问题

1. **API认证失败**
   - 检查API Token是否正确
   - 确认Token权限包含Zone和DNS记录管理

2. **DNS更新失败**
   - 检查域名是否存在于Cloudflare
   - 确认Zone配置正确

3. **服务启动失败**
   - 检查配置文件格式
   - 查看详细错误日志

### 测试命令

```bash
# 验证配置文件
python3 -c "import json; json.load(open('config.json'))"

# 手动测试
python3 auto_ddns.py config.json

# 检查服务状态
systemctl status cloudflare-auto-ddns
```

## 🤝 贡献

欢迎提交Issue和Pull Request！

1. Fork本项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启Pull Request

## 📄 许可证

本项目使用 MIT 许可证。详情请参阅 [LICENSE](LICENSE) 文件。

## 📞 支持

- 🐛 [问题反馈](https://github.com/your-username/cloudflare-auto-ddns/issues)
- 💡 [功能请求](https://github.com/your-username/cloudflare-auto-ddns/issues)
- 📖 [Wiki文档](https://github.com/your-username/cloudflare-auto-ddns/wiki)

## 🙏 致谢

感谢所有贡献者和使用者的支持！

---

**⭐ 如果这个项目对您有帮助，请给个Star！**
