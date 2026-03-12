# mdserver-web

一款简单的 Linux 服务器管理面板

## 功能特性

- 🔧 Web 界面管理服务器
- 🌐 网站管理（OpenResty + PHP）
- 🗄️ 数据库管理（MySQL/MariaDB/PostgreSQL/MongoDB）
- 🔒 SSL 证书自动申请
- 📦 插件化架构
- 🖥️ SSH 终端

## 系统要求

- **推荐系统**: Debian 11/12, Ubuntu 22.04
- **其他支持**: CentOS 7/8, Rocky Linux, AlmaLinux
- **架构**: x86_64
- **内存**: 建议 1GB+

## 一键安装

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/kobex95/mdserver/master/scripts/install.sh)
```

安装完成后访问：`http://服务器IP:7200`

## 常用命令

| 命令 | 说明 |
|------|------|
| `mw start` | 启动面板 |
| `mw stop` | 停止面板 |
| `mw restart` | 重启面板 |
| `mw default` | 显示登录信息 |

## 更新面板

```bash
mw update
```

或

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/kobex95/mdserver/master/scripts/update.sh)
```

## 卸载

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/kobex95/mdserver/master/scripts/uninstall.sh)
```

## 目录结构

```
/www/server/mdserver-web    # 面板目录
/www/wwwroot                # 网站目录
/www/server                 # 服务目录
```

## 插件列表

- OpenResty / Nginx
- PHP (5.3 - 8.4)
- MySQL / MariaDB
- PostgreSQL / MongoDB
- Redis / Memcached
- phpMyAdmin
- 更多插件请查看面板插件页面

## 开源协议

[Apache License 2.0](LICENSE)

---

**注意**: 本项目由 kobex95 维护，是 mdserver-web 的分支版本。
