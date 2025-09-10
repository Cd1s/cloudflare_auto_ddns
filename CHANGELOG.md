# Changelog

所有重要的变更都会记录在这个文件中。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)，
版本号遵循 [Semantic Versioning](https://semver.org/lang/zh-CN/)。

## [1.0.0] - 2025-01-01

### 新增
- 🚀 智能时间段DNS解析切换功能
- 🎯 精确IP替换，只替换指定IP记录
- 🔄 智能域名发现，自动管理使用目标IP的域名
- 🛡️ 安全保护，完全保留其他DNS记录
- 📊 详细的日志记录和监控
- 🔧 JSON配置文件支持
- 🚀 systemd服务集成
- 📝 完整的安装和管理脚本
- 🌐 支持多域名、多Zone管理
- ⏰ 可配置的检查间隔
- 🔒 安全的API Token认证
- 📖 详细的文档和示例

### 特性
- 支持根据时间段自动切换IP地址
- 智能发现Zone中使用目标IP的所有域名
- 只更新指定的IP记录，保护其他解析
- 完善的错误处理和自动重试机制
- 系统服务集成，支持开机自启
- 详细的操作日志和状态监控

### 支持的系统
- Ubuntu 18.04+
- Debian 9+
- CentOS 7+
- RHEL 7+

### 依赖
- Python 3.7+
- requests >= 2.25.0
- systemd (可选，用于服务管理)
