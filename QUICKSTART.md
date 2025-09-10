# 快速开始指南

## 🚀 30秒快速安装

### 方式一：独立脚本一键安装 (推荐)

```bash
# 下载并运行独立安装脚本
curl -fsSL https://raw.githubusercontent.com/Cd1s/cloudflare_auto_ddns/main/setup_standalone.sh | sudo bash
```

**或者手动下载运行：**
```bash
# 下载脚本
wget https://raw.githubusercontent.com/Cd1s/cloudflare_auto_ddns/main/setup_standalone.sh
chmod +x setup_standalone.sh

# 运行安装
sudo ./setup_standalone.sh
```

### 方式二：克隆项目安装

```bash
# 克隆项目
git clone https://github.com/Cd1s/cloudflare_auto_ddns.git
cd cloudflare-auto-ddns

# 运行交互式安装
sudo ./install.sh
```

## 📝 配置流程

安装脚本会依次询问：

### 1. Cloudflare账户信息
- 📧 **邮箱**: `your-email@example.com`
- 🔑 **API Token**: [获取方法](https://dash.cloudflare.com/profile/api-tokens)

### 2. 时区选择
- 选择 `1` (北京时间/中国标准时间) [推荐]
- 或选择其他合适的时区

### 3. 时间段和IP配置
- **白天开始**: `6` (早上6点)
- **白天结束**: `22` (晚上10点)
- **白天IP**: `1.2.3.4` (您的白天线路IP)
- **夜间IP**: `5.6.7.8` (您的夜间线路IP)

### 4. 自动发现功能 ⭐ 新功能
- **开启** (推荐): 自动管理所有使用目标IP的域名
- **关闭**: 仅管理手动配置的域名列表

### 5. 域名配置 (可选)
- 如果开启自动发现，可以选择 `N` 完全依赖自动发现
- 或选择 `Y` 手动添加关键域名优先处理

### 6. 检查间隔
- 选择 `2` (5分钟，推荐)

## ✅ 安装完成

- 🏠 **安装目录**: `/etc/cloudflare_auto_ddns`
- 📄 **配置文件**: `/etc/cloudflare_auto_ddns/config.json`
- 📝 **日志文件**: `/var/log/cloudflare-auto-ddns.log`
- 🎮 **管理命令**: `cfddns`

## 🎮 管理命令

安装完成后，使用 `cfddns` 进入交互式管理界面：

```bash
# 进入管理界面
cfddns
```

**管理功能包括：**
- 📊 服务管理 (启动/停止/重启/状态/日志)
- ⚙️ 配置管理 (更换IP/修改时间段/管理域名)  
- 🔍 自动发现设置 (开启/关闭智能发现)
- 🔧 高级功能 (测试运行/编辑配置/扫描域名)

## 🔍 智能发现功能

**核心特性：** 可以选择开启或关闭自动发现

### 🟢 开启自动发现 (推荐)
- ✅ 自动扫描您的Cloudflare账户
- ✅ 发现所有使用您指定IP的域名
- ✅ 自动加入管理并按时间段切换
- ✅ 新域名会自动生效，无需重新配置

### 🔒 关闭自动发现 (精确控制)
- 🔒 只管理手动配置的域名列表
- 🔒 避免意外修改其他域名
- 🔒 适合复杂DNS配置环境

## 🎯 使用场景示例

### CDN线路优化
- **白天 (6:00-22:00)**: 使用高速CDN IP
- **夜间 (22:00-6:00)**: 使用经济CDN IP

### 游戏服务器负载均衡
- **高峰期 (12:00-24:00)**: 使用高性能服务器IP
- **低峰期 (0:00-12:00)**: 使用标准服务器IP

### 国际线路切换
- **亚洲时段 (6:00-18:00)**: 使用亚洲优化线路
- **其他时段 (18:00-6:00)**: 使用全球线路

## ❓ 常见问题

### Q: 如何获取Cloudflare API Token？
A: 访问 https://dash.cloudflare.com/profile/api-tokens → Create Token → Custom token → 设置权限：Zone:Zone:Read, Zone:DNS:Edit

### Q: 智能发现是否会影响其他DNS记录？
A: 不会！系统只会替换您指定的两个IP地址，完全保留其他所有DNS记录。

### Q: 如何添加新域名？
A: 
- **开启自动发现**: 直接在Cloudflare添加域名并设置为您管理的IP，系统会自动发现
- **关闭自动发现**: 使用 `cfddns` 命令进入管理界面手动添加

### Q: 如何修改时间段或IP？
A: 使用 `cfddns` 命令进入管理界面，选择相应的配置管理选项

## 🆘 获取帮助

- 📖 **完整文档**: [README.md](README.md)
- 💡 **使用示例**: [EXAMPLES.md](EXAMPLES.md)  
- ❓ **常见问题**: [FAQ.md](FAQ.md)
- 🐛 **问题反馈**: [GitHub Issues](https://github.com/Cd1s/cloudflare_auto_ddns/issues)

---

**🎉 祝您使用愉快！如有问题随时反馈！**