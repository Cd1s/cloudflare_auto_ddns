# 贡献指南

感谢您对 Cloudflare Auto DDNS 项目的关注！我们欢迎各种形式的贡献。

## 🤝 如何贡献

### 报告问题
- 使用 [GitHub Issues](https://github.com/Cd1s/cloudflare_auto_ddns/issues) 报告bug
- 提供详细的错误信息和复现步骤
- 包含系统环境信息

### 功能请求
- 在 [GitHub Issues](https://github.com/Cd1s/cloudflare_auto_ddns/issues) 中使用 "Feature Request" 标签
- 详细描述所需功能和使用场景
- 说明为什么这个功能对项目有价值

### 代码贡献
1. Fork 本项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 进行更改并测试
4. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
5. 推送到分支 (`git push origin feature/AmazingFeature`)
6. 开启 Pull Request

## 📝 开发指南

### 环境设置
```bash
# 克隆项目
git clone https://github.com/Cd1s/cloudflare_auto_ddns.git
cd cloudflare-auto-ddns

# 安装依赖
pip3 install -r requirements.txt

# 创建测试配置
cp config.example.json config.test.json
# 编辑 config.test.json 填入测试信息
```

### 代码规范
- 使用 Python 3.7+ 语法
- 遵循 PEP 8 编码规范
- 添加适当的注释和文档字符串
- 保持函数功能单一和清晰

### 测试
```bash
# 语法检查
python3 -m py_compile auto_ddns.py

# 功能测试
python3 auto_ddns.py config.test.json
```

### 提交信息格式
使用清晰的提交信息：
- `feat: 添加新功能`
- `fix: 修复bug`
- `docs: 更新文档`
- `style: 代码格式化`
- `refactor: 重构代码`
- `test: 添加测试`

## 🐛 问题报告模板

### Bug 报告
```
**描述问题**
简洁清晰地描述问题。

**复现步骤**
1. 步骤1
2. 步骤2
3. 出现错误

**期望行为**
描述您期望发生的情况。

**实际行为**
描述实际发生的情况。

**环境信息**
- 操作系统: [如 Ubuntu 20.04]
- Python版本: [如 Python 3.8.5]
- 项目版本: [如 v1.0.0]

**日志信息**
相关的错误日志或输出。

**配置文件**
相关的配置内容（请移除敏感信息）。
```

### 功能请求
```
**功能描述**
简洁清晰地描述您想要的功能。

**使用场景**
描述这个功能的使用场景和价值。

**建议实现**
如果有想法，可以描述建议的实现方式。

**替代方案**
描述您考虑过的其他解决方案。
```

## 📋 开发待办

### 高优先级
- [ ] 支持 IPv6 (AAAA记录)
- [ ] 支持其他DNS记录类型
- [ ] 添加更多错误处理

### 中优先级
- [ ] Web管理界面
- [ ] 配置文件热重载
- [ ] 邮件通知功能

### 低优先级
- [ ] 多时间段支持
- [ ] 其他DNS服务商支持
- [ ] GUI客户端

## 🎯 项目目标

1. **简单易用**: 提供简单的配置和管理方式
2. **稳定可靠**: 确保服务稳定运行，处理各种异常情况
3. **安全性**: 保护用户的API凭据和配置信息
4. **扩展性**: 支持多种使用场景和自定义需求
5. **文档完善**: 提供详细的使用文档和示例

## 📞 联系方式

- 项目主页: [GitHub](https://github.com/Cd1s/cloudflare_auto_ddns)
- 问题反馈: [Issues](https://github.com/Cd1s/cloudflare_auto_ddns/issues)
- 功能讨论: [Discussions](https://github.com/Cd1s/cloudflare_auto_ddns/discussions)

感谢您的贡献！
