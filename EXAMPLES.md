# 使用示例

本文档提供了各种常见使用场景的配置示例。

## 📋 基本示例

### 1. 单域名切换

适用于只有一个域名需要时间段切换的场景：

```json
{
  "cloudflare": {
    "email": "user@example.com",
    "api_token": "your-api-token"
  },
  "schedule": {
    "day_start_hour": 8,
    "day_end_hour": 20,
    "day_ip": "1.2.3.4",
    "night_ip": "5.6.7.8"
  },
  "domains": [
    {
      "name": "example.com",
      "zone": "example.com",
      "type": "A"
    }
  ],
  "auto_discovery": true,
  "check_interval": 300
}
```

### 2. 多域名统一管理

适用于多个子域名需要统一切换的场景：

```json
{
  "cloudflare": {
    "email": "user@example.com",
    "api_token": "your-api-token"
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
    },
    {
      "name": "api.example.com",
      "zone": "example.com",
      "type": "A"
    },
    {
      "name": "cdn.example.com",
      "zone": "example.com",
      "type": "A"
    }
  ],
  "auto_discovery": true,
  "check_interval": 300
}
```

## 🌐 高级场景

### 3. 多Zone管理

适用于管理多个不同根域名的场景：

```json
{
  "cloudflare": {
    "email": "user@example.com",
    "api_token": "your-api-token"
  },
  "schedule": {
    "day_start_hour": 7,
    "day_end_hour": 19,
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
      "name": "blog.example.com",
      "zone": "example.com",
      "type": "A"
    },
    {
      "name": "mysite.org",
      "zone": "mysite.org",
      "type": "A"
    },
    {
      "name": "api.mysite.org",
      "zone": "mysite.org",
      "type": "A"
    }
  ],
  "auto_discovery": true,
  "check_interval": 300
}
```

### 4. CDN线路切换

适用于CDN线路优化场景：

```json
{
  "cloudflare": {
    "email": "cdn@company.com",
    "api_token": "your-api-token"
  },
  "schedule": {
    "day_start_hour": 9,
    "day_end_hour": 18,
    "day_ip": "203.0.113.1",
    "night_ip": "203.0.113.2"
  },
  "domains": [
    {
      "name": "cdn.example.com",
      "zone": "example.com",
      "type": "A"
    },
    {
      "name": "static.example.com",
      "zone": "example.com",
      "type": "A"
    },
    {
      "name": "img.example.com",
      "zone": "example.com",
      "type": "A"
    }
  ],
  "log": {
    "level": "INFO",
    "file": "/var/log/cdn-auto-ddns.log"
  },
  "check_interval": 180
}
```

### 5. 游戏服务器负载均衡

适用于游戏服务器根据时段切换不同线路：

```json
{
  "cloudflare": {
    "email": "gameops@company.com",
    "api_token": "your-api-token"
  },
  "schedule": {
    "day_start_hour": 12,
    "day_end_hour": 24,
    "day_ip": "198.51.100.10",
    "night_ip": "198.51.100.20"
  },
  "domains": [
    {
      "name": "game.example.com",
      "zone": "example.com",
      "type": "A"
    },
    {
      "name": "asia.game.example.com",
      "zone": "example.com",
      "type": "A"
    },
    {
      "name": "login.game.example.com",
      "zone": "example.com",
      "type": "A"
    }
  ],
  "check_interval": 120
}
```

## 🕐 时间配置示例

### 6. 工作时间切换

白天使用高性能服务器，夜间使用经济型服务器：

```json
{
  "schedule": {
    "day_start_hour": 9,
    "day_end_hour": 18,
    "day_ip": "高性能服务器IP",
    "night_ip": "经济型服务器IP"
  }
}
```

### 7. 高峰时段优化

针对访问高峰期进行优化：

```json
{
  "schedule": {
    "day_start_hour": 10,
    "day_end_hour": 22,
    "day_ip": "高带宽服务器IP",
    "night_ip": "标准服务器IP"
  }
}
```

### 8. 跨时区服务

考虑不同时区用户的访问模式：

```json
{
  "schedule": {
    "day_start_hour": 6,
    "day_end_hour": 20,
    "day_ip": "亚洲优化线路IP",
    "night_ip": "美洲优化线路IP"
  }
}
```

## 🔧 检查间隔配置

### 9. 快速响应（1分钟）

适用于对切换时间要求严格的场景：

```json
{
  "check_interval": 60
}
```

### 10. 标准配置（5分钟）

平衡性能和及时性的推荐配置：

```json
{
  "check_interval": 300
}
```

### 11. 节省资源（10分钟）

适用于对切换时间不敏感的场景：

```json
{
  "check_interval": 600
}
```

## 📝 日志配置示例

### 12. 详细日志

用于调试和详细监控：

```json
{
  "log": {
    "level": "DEBUG",
    "file": "/var/log/cloudflare-auto-ddns-debug.log"
  }
}
```

### 13. 简化日志

只记录重要信息：

```json
{
  "log": {
    "level": "INFO",
    "file": "/var/log/cloudflare-auto-ddns.log"
  }
}
```

### 14. 错误日志

只记录错误信息：

```json
{
  "log": {
    "level": "ERROR",
    "file": "/var/log/cloudflare-auto-ddns-error.log"
  }
}
```

## 🚀 部署建议

### 生产环境配置建议

1. **检查间隔**: 建议设置为300秒（5分钟），平衡及时性和性能
2. **日志级别**: 建议设置为INFO，记录重要操作
3. **权限管理**: 配置文件权限设置为600，仅root可访问
4. **监控**: 配置logrotate进行日志轮转

### 测试环境配置建议

1. **检查间隔**: 可以设置为60秒（1分钟），快速验证功能
2. **日志级别**: 设置为DEBUG，便于调试
3. **域名**: 使用测试域名，避免影响生产环境

### 安全注意事项

1. **API Token**: 使用最小权限原则，只授予必要的DNS编辑权限
2. **配置备份**: 定期备份配置文件
3. **监控告警**: 配置日志监控和告警机制

## 🔍 自动发现功能配置

### 开启自动发现 (推荐)

```json
{
  "cloudflare": {
    "email": "user@example.com",
    "api_token": "your-api-token"
  },
  "schedule": {
    "day_start_hour": 6,
    "day_end_hour": 22,
    "day_ip": "1.2.3.4",
    "night_ip": "5.6.7.8"
  },
  "domains": [],
  "auto_discovery": true,
  "check_interval": 300
}
```

**特点：**
- ✅ 自动扫描所有Zone中使用目标IP的域名
- ✅ 无需手动配置域名列表
- ✅ 新域名自动生效

### 关闭自动发现 (精确控制)

```json
{
  "cloudflare": {
    "email": "user@example.com", 
    "api_token": "your-api-token"
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
  "auto_discovery": false,
  "check_interval": 300
}
```

**特点：**
- 🔒 只管理手动配置的域名
- 🔒 避免意外修改其他域名
- 🔒 适合复杂DNS配置环境

### 混合模式 (推荐)

```json
{
  "cloudflare": {
    "email": "user@example.com",
    "api_token": "your-api-token"
  },
  "schedule": {
    "day_start_hour": 6,
    "day_end_hour": 22,
    "day_ip": "1.2.3.4", 
    "night_ip": "5.6.7.8"
  },
  "domains": [
    {
      "name": "important.example.com",
      "zone": "example.com",
      "type": "A"
    }
  ],
  "auto_discovery": true,
  "check_interval": 300
}
```

**特点：**
- 🎯 手动配置的域名优先处理
- 🔍 自动发现其他相关域名
- ⚖️ 平衡控制和自动化
