# 快速开始指南

## 🚀 30秒快速安装

### 第一步：下载项目
```bash
git clone https://github.com/your-username/cloudflare-auto-ddns.git
cd cloudflare-auto-ddns
```

### 第二步：运行交互式安装
```bash
sudo ./install.sh
```

### 第三步：按提示配置
安装脚本会依次询问：

1. **Cloudflare账户信息**
   - 📧 邮箱: `your-email@example.com`
   - 🔑 API Token: [获取方法](https://dash.cloudflare.com/profile/api-tokens)

2. **时区选择**
   - 选择 `1` (北京时间/中国标准时间) [推荐]
   - 或选择其他合适的时区

3. **时间段配置**
   - 白天开始: `6` (早上6点)
   - 白天结束: `22` (晚上10点)
   - 白天IP: `1.2.3.4` (您的白天线路IP)
   - 夜间IP: `5.6.7.8` (您的夜间线路IP)

4. **域名配置** (可选)
   - 选择 `N` 完全依赖智能发现
   - 或选择 `Y` 手动添加关键域名

5. **检查间隔**
   - 选择 `2` (5分钟，推荐)

### 第四步：完成！
- ✅ 自动安装并启动服务
- ✅ 显示配置摘要和管理命令
- ✅ 开始自动管理DNS解析

## 🔍 智能发现功能

**关键特性：无需配置所有域名！**

- 系统会自动扫描您的Cloudflare账户
- 发现所有使用您指定IP的域名
- 自动加入管理并按时间段切换
- 新域名会自动生效，无需重新配置

## 📋 常用管理命令

安装完成后可以使用：

```bash
# 查看服务状态
cloudflare-auto-ddns status

# 查看实时日志
cloudflare-auto-ddns logs

# 重启服务
cloudflare-auto-ddns restart

# 查看配置
cloudflare-auto-ddns config

# 测试运行
cloudflare-auto-ddns test
```

## 🎯 使用场景示例

### CDN线路优化
- **白天 (9:00-18:00)**: 使用高速CDN IP
- **夜间 (18:00-9:00)**: 使用经济CDN IP

### 游戏服务器负载均衡
- **高峰期 (12:00-24:00)**: 使用高性能服务器IP
- **低峰期 (0:00-12:00)**: 使用标准服务器IP

### 国际线路切换
- **亚洲时段 (6:00-20:00)**: 使用亚洲优化线路
- **美洲时段 (20:00-6:00)**: 使用美洲优化线路

## ❓ 常见问题

### Q: 如何获取Cloudflare API Token？
A: 访问 https://dash.cloudflare.com/profile/api-tokens → Create Token → Custom token → 设置权限：Zone:Zone:Read, Zone:DNS:Edit

### Q: 智能发现是否会影响其他DNS记录？
A: 不会！系统只会替换您指定的两个IP地址，完全保留其他所有DNS记录。

### Q: 如何添加新域名？
A: 直接在Cloudflare添加域名并设置为您管理的IP之一，系统会在5-10分钟内自动发现并管理。

### Q: 如何修改时间段或IP？
A: 编辑 `/etc/cloudflare-auto-ddns/config.json` 文件，然后运行 `cloudflare-auto-ddns restart`

## 🆘 获取帮助

- 📖 完整文档: [README.md](README.md)
- 💡 使用示例: [EXAMPLES.md](EXAMPLES.md)  
- ❓ 常见问题: [FAQ.md](FAQ.md)
- 🐛 问题反馈: [GitHub Issues](https://github.com/your-username/cloudflare-auto-ddns/issues)

---

**🎉 祝您使用愉快！如有问题随时反馈！**
