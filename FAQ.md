# 常见问题解答 (FAQ)

## 🚀 安装和配置

### Q: 为什么通过管道安装 `| bash` 会卡住？
A: 脚本需要交互式配置，通过管道运行时无法接收用户输入。

**正确的安装方式：**
```bash
# 下载脚本
wget https://raw.githubusercontent.com/Cd1s/cloudflare_auto_ddns/main/setup_standalone.sh
chmod +x setup_standalone.sh

# 运行安装
sudo ./setup_standalone.sh
```

**错误的方式：**
```bash
# ❌ 这样会卡住
curl -fsSL ... | sudo bash
```

### Q: 支持哪些操作系统？
A: 支持以下系统：
- Ubuntu 18.04+
- Debian 9+
- CentOS 7+
- RHEL 7+
- 其他支持Python 3.7+和systemd的Linux发行版

### Q: 如何获取Cloudflare API Token？
A: 按以下步骤获取：
1. 登录 [Cloudflare Dashboard](https://dash.cloudflare.com/profile/api-tokens)
2. 点击 "Create Token"
3. 选择 "Custom token" 模板
4. 设置权限：
   - Zone: Zone:Read
   - Zone: DNS:Edit
5. 设置Zone Resources：选择要管理的域名
6. 点击 "Continue to summary" 然后 "Create Token"
7. 复制生成的Token

### Q: 配置文件放在哪里？
A: 
- 使用独立脚本安装：`/etc/cloudflare_auto_ddns/config.json`
- 使用git克隆安装：`/etc/cloudflare-auto-ddns/config.json`
- 手动运行：当前目录下的 `config.json`

### Q: 如何验证配置文件格式？
A: 运行以下命令：
```bash
python3 -c "import json; json.load(open('config.json'))"
```

## ⏰ 时间和切换

### Q: 系统使用什么时间？
A: 使用运行程序的服务器本地时间。确保服务器时间设置正确。

### Q: 切换时间精确吗？
A: 切换时间取决于检查间隔（check_interval）。例如：
- 检查间隔5分钟：最大延迟5分钟
- 检查间隔1分钟：最大延迟1分钟

### Q: 可以设置多个时间段吗？
A: 当前版本只支持两个时间段（白天/夜间）。如需更复杂的时间段，请提交Feature Request。

### Q: 如何测试时间切换？
A: 
1. 临时修改配置文件的时间设置
2. 重启服务
3. 观察日志输出
4. 恢复原始配置

## 🌐 域名和DNS

### Q: 支持哪些DNS记录类型？
A: 当前版本只支持A记录。如需支持其他类型（AAAA、CNAME等），请提交Feature Request。

### Q: 域名有多个A记录怎么办？
A: 系统会智能处理：
- 只更新包含管理IP的记录
- 完全保留其他IP的A记录
- 不会影响其他类型的DNS记录

### Q: 如何添加新域名？
A: 两种方式：
1. **手动配置**：编辑config.json，添加到domains数组
2. **智能发现**：直接在Cloudflare添加域名并设置为管理的IP，系统会自动发现

### Q: 智能发现是什么？
A: 系统会自动扫描Zone中所有A记录，发现使用目标IP的域名并自动管理，无需手动配置。

### Q: 支持多个Zone吗？
A: 支持。可以在domains数组中配置不同zone的域名。

## 🔧 运行和管理

### Q: 如何查看运行状态？
A: 
```bash
# 查看服务状态
cloudflare-auto-ddns status

# 查看实时日志
cloudflare-auto-ddns logs

# 或使用systemctl
systemctl status cloudflare-auto-ddns
```

### Q: 如何修改配置？
A: **推荐使用 cfddns 命令：**
```bash
cfddns
```
进入交互式管理界面，可以修改所有配置项。

**其他方式：**
```bash
# 手动编辑配置文件
sudo nano /etc/cloudflare_auto_ddns/config.json

# 重启服务应用配置
sudo systemctl restart cloudflare-auto-ddns
```

### Q: 程序会自动重启吗？
A: 是的，systemd服务配置了自动重启，程序异常退出后会自动重启。

### Q: 如何更新IP地址？
A: 
1. 编辑配置文件，修改day_ip和night_ip
2. 重启服务：`cloudflare-auto-ddns restart`

## 🐛 故障排除

### Q: API认证失败怎么办？
A: 检查以下项目：
1. API Token是否正确
2. Token权限是否包含Zone:Read和DNS:Edit
3. Token是否对目标Zone有权限

### Q: DNS更新失败怎么办？
A: 
1. 检查域名是否存在于Cloudflare
2. 确认Zone配置正确
3. 检查API Token权限
4. 查看详细错误日志

### Q: 服务启动失败怎么办？
A: 
1. 检查配置文件格式：`python3 -c "import json; json.load(open('config.json'))"`
2. 查看systemd日志：`journalctl -u cloudflare-auto-ddns -n 50`
3. 手动测试：`cloudflare-auto-ddns test`

### Q: 日志在哪里？
A: 
- 应用日志：`/var/log/cloudflare-auto-ddns.log`
- systemd日志：`journalctl -u cloudflare-auto-ddns`

### Q: 如何调试问题？
A: 
1. 设置日志级别为DEBUG
2. 手动运行程序观察输出
3. 检查网络连接
4. 验证Cloudflare API连接

## 🔒 安全

### Q: 配置文件安全吗？
A: 是的：
- 配置文件权限设置为600（仅root可访问）
- API Token不会记录到日志中
- 所有API请求使用HTTPS加密

### Q: 如何保护API Token？
A: 
1. 使用最小权限原则
2. 定期轮换Token
3. 不要在公共场所存储配置文件
4. 使用专用的DNS管理Token

### Q: 可以在Docker中运行吗？
A: 可以，但需要：
1. 挂载配置文件
2. 挂载日志目录
3. 正确设置时区

## 📊 性能

### Q: 对Cloudflare API有频率限制吗？
A: Cloudflare有API频率限制，但正常使用不会触及。建议检查间隔不要设置太短（推荐5分钟）。

### Q: 程序占用多少资源？
A: 非常轻量：
- 内存：通常<20MB
- CPU：几乎不占用
- 网络：每次检查仅几KB流量

### Q: 如何优化性能？
A: 
1. 适当增加检查间隔
2. 减少不必要的域名配置
3. 使用DEBUG日志级别可能影响性能

## 🆕 功能请求

### Q: 如何请求新功能？
A: 在GitHub项目页面提交Issue，选择Feature Request模板。

### Q: 计划支持哪些新功能？
A: 可能的功能包括：
- 支持IPv6 (AAAA记录)
- 支持其他DNS记录类型
- Web管理界面
- 多时间段支持
- 其他DNS服务商支持

### Q: 如何贡献代码？
A: 
1. Fork项目
2. 创建功能分支
3. 提交Pull Request
4. 参与代码审查

## 📞 获取帮助

### Q: 在哪里获取支持？
A: 
- GitHub Issues：问题反馈和功能请求
- GitHub Discussions：社区讨论
- Wiki文档：详细使用指南

### Q: 如何报告Bug？
A: 在GitHub提交Issue，包含：
1. 系统信息
2. 配置文件（去除敏感信息）
3. 错误日志
4. 复现步骤

## 🔍 自动发现功能

### Q: 什么是自动发现功能？
A: 自动发现功能可以：
- ✅ 自动扫描您Cloudflare账户中的所有Zone
- ✅ 发现所有使用目标IP的域名  
- ✅ 自动加入管理列表进行时间段切换
- ✅ 新域名会自动生效，无需手动配置

### Q: 如何控制自动发现功能？
A: 使用 `cfddns` 命令进入管理界面：
1. 选择 "10) 自动发现设置"
2. 选择开启或关闭自动发现
3. 系统会自动重启服务应用新设置

### Q: 开启自动发现安全吗？
A: 非常安全：
- 🔒 只会替换您指定的两个IP地址
- 🔒 完全保留域名的其他DNS记录
- 🔒 不会影响CNAME、MX等其他类型记录
- 🔒 支持精确控制，可随时关闭

### Q: 什么时候该关闭自动发现？
A: 以下情况建议关闭：
- 🎯 只想管理特定的几个域名
- 🎯 账户中有其他服务使用相同IP
- 🎯 需要精确控制避免意外修改
- 🎯 复杂的DNS配置环境

### Q: 自动发现会影响性能吗？
A: 影响很小：
- ⚡ 只在配置的检查间隔时执行扫描
- ⚡ 使用API批量获取，效率很高
- ⚡ 有缓存机制，避免重复请求
- ⚡ 可以通过关闭功能完全避免扫描

## 🎮 cfddns 管理命令

### Q: cfddns 命令有什么功能？
A: cfddns 提供完整的交互式管理界面：
- 📊 服务管理 (启动/停止/重启/状态/日志)
- ⚙️ 配置管理 (更换IP/修改时间段/管理域名)
- 🔍 自动发现设置 (开启/关闭智能发现)
- 🔧 高级功能 (测试运行/编辑配置/扫描域名)

### Q: cfddns 命令安全吗？
A: 是的，完全安全：
- 🔒 需要root权限运行
- 🔒 自动备份配置文件
- 🔒 验证配置格式正确性
- 🔒 确认操作才会执行

### Q: 如果 cfddns 命令不存在怎么办？
A: 可能的原因：
1. **独立脚本安装问题**：重新运行安装脚本
2. **权限问题**：确保使用 `sudo cfddns`
3. **路径问题**：检查 `/usr/local/bin/cfddns` 是否存在

---

**没有找到您的问题？** 请在 [GitHub Issues](https://github.com/Cd1s/cloudflare_auto_ddns/issues) 中提问！
