#!/bin/bash
# =============================================================================
# mdserver-web 一键卸载脚本
# =============================================================================

set -e

# 基础配置
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# 颜色定义
readonly RED='\033[31m'
readonly GREEN='\033[32m'
readonly YELLOW='\033[33m'
readonly BLUE='\033[34m'
readonly PLAIN='\033[0m'
readonly SUCCESS="[${GREEN}OK${PLAIN}]"
readonly ERROR="[${RED}ERROR${PLAIN}]"
readonly WARN="[${YELLOW}WARN${PLAIN}]"

# 面板安装目录
MW_DIR="/www/server/mdserver-web"
SERVER_DIR="/www/server"

# 检查root权限
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${ERROR} 请使用 root 用户运行此脚本"
        exit 1
    fi
}

# 确认卸载
confirm_uninstall() {
    echo -e "${RED}============================================${PLAIN}"
    echo -e "${RED}  警告: 这将卸载 mdserver-web 面板及其组件${PLAIN}"
    echo -e "${RED}============================================${PLAIN}"
    echo -e "\n${YELLOW}以下数据将被删除:${PLAIN}"
    echo "  - 面板程序文件"
    echo "  - OpenResty/Nginx"
    echo "  - PHP 环境"
    echo "  - MySQL/MariaDB 数据"
    echo "  - Redis/Memcached"
    echo "  - 所有插件"
    echo -e "\n${YELLOW}以下数据将保留:${PLAIN}"
    echo "  - 网站文件 (/www/wwwroot)"
    echo "  - 备份文件 (/www/backup)"
    echo -e "\n${RED}此操作不可恢复!${PLAIN}"
    
    read -p "请输入 'yes' 确认卸载: " confirm
    if [[ "$confirm" != "yes" ]]; then
        echo -e "\n${WARN} 已取消卸载"
        exit 0
    fi
}

# 停止所有服务
stop_services() {
    echo -e "${BLUE}正在停止所有服务...${PLAIN}"
    
    # 停止面板
    if [[ -f /etc/init.d/mw ]] || [[ -f /etc/rc.d/init.d/mw ]]; then
        mw stop 2>/dev/null || true
    fi
    
    # 停止 OpenResty
    if [[ -f $SERVER_DIR/openresty/init.d/openresty ]]; then
        $SERVER_DIR/openresty/init.d/openresty stop 2>/dev/null || true
    fi
    
    # 停止 PHP
    for ver in 53 54 55 56 70 71 72 73 74 80 81 82 83 84; do
        if [[ -f $SERVER_DIR/php/init.d/php$ver ]]; then
            $SERVER_DIR/php/init.d/php$ver stop 2>/dev/null || true
        fi
    done
    
    # 停止 MySQL
    if [[ -f $SERVER_DIR/mysql/init.d/mysql ]]; then
        $SERVER_DIR/mysql/init.d/mysql stop 2>/dev/null || true
    fi
    
    # 停止 Redis
    if [[ -f $SERVER_DIR/redis/init.d/redis ]]; then
        $SERVER_DIR/redis/init.d/redis stop 2>/dev/null || true
    fi
    
    # 停止 Memcached
    if [[ -f $SERVER_DIR/memcached/init.d/memcached ]]; then
        $SERVER_DIR/memcached/init.d/memcached stop 2>/dev/null || true
    fi
    
    # 使用 systemctl 停止服务
    systemctl stop openresty 2>/dev/null || true
    systemctl stop php* 2>/dev/null || true
    systemctl stop mysql 2>/dev/null || true
    systemctl stop redis 2>/dev/null || true
    systemctl stop memcached 2>/dev/null || true
    
    echo -e "${SUCCESS} 所有服务已停止"
}

# 卸载插件
uninstall_plugins() {
    echo -e "${BLUE}正在卸载插件...${PLAIN}"
    
    # 卸载 OpenResty
    if [[ -d $SERVER_DIR/openresty ]]; then
        rm -rf $SERVER_DIR/openresty
        rm -f /etc/init.d/openresty
        rm -f /lib/systemd/system/openresty.service
        echo -e "${SUCCESS} 已卸载 OpenResty"
    fi
    
    # 卸载 PHP
    if [[ -d $SERVER_DIR/php ]]; then
        rm -rf $SERVER_DIR/php
        for ver in 53 54 55 56 70 71 72 73 74 80 81 82 83 84; do
            rm -f /etc/init.d/php$ver
            rm -f /lib/systemd/system/php$ver.service
        done
        echo -e "${SUCCESS} 已卸载 PHP"
    fi
    
    # 卸载 MySQL
    if [[ -d $SERVER_DIR/mysql ]]; then
        rm -rf $SERVER_DIR/mysql
        rm -f /etc/init.d/mysql
        rm -f /lib/systemd/system/mysql.service
        echo -e "${SUCCESS} 已卸载 MySQL"
    fi
    
    # 卸载 MariaDB
    if [[ -d $SERVER_DIR/mariadb ]]; then
        rm -rf $SERVER_DIR/mariadb
        rm -f /etc/init.d/mariadb
        rm -f /lib/systemd/system/mariadb.service
        echo -e "${SUCCESS} 已卸载 MariaDB"
    fi
    
    # 卸载 Redis
    if [[ -d $SERVER_DIR/redis ]]; then
        rm -rf $SERVER_DIR/redis
        rm -f /etc/init.d/redis
        rm -f /lib/systemd/system/redis.service
        echo -e "${SUCCESS} 已卸载 Redis"
    fi
    
    # 卸载 Memcached
    if [[ -d $SERVER_DIR/memcached ]]; then
        rm -rf $SERVER_DIR/memcached
        rm -f /etc/init.d/memcached
        rm -f /lib/systemd/system/memcached.service
        echo -e "${SUCCESS} 已卸载 Memcached"
    fi
    
    # 卸载 PureFTPd
    if [[ -d $SERVER_DIR/pureftp ]]; then
        rm -rf $SERVER_DIR/pureftp
        rm -f /etc/init.d/pureftp
        echo -e "${SUCCESS} 已卸载 PureFTPd"
    fi
    
    # 卸载其他插件
    for plugin in $SERVER_DIR/*; do
        if [[ -d "$plugin" ]] && [[ "$plugin" != "$SERVER_DIR/mdserver-web" ]]; then
            local plugin_name=$(basename "$plugin")
            # 保留重要目录
            if [[ "$plugin_name" != "wwwroot" ]] && [[ "$plugin_name" != "backup" ]] && [[ "$plugin_name" != "logs" ]]; then
                rm -rf "$plugin"
                echo -e "${SUCCESS} 已卸载 $plugin_name"
            fi
        fi
    done
}

# 卸载面板
uninstall_panel() {
    echo -e "${BLUE}正在卸载面板...${PLAIN}"
    
    # 删除面板目录
    if [[ -d $MW_DIR ]]; then
        rm -rf $MW_DIR
        echo -e "${SUCCESS} 已删除面板文件"
    fi
    
    # 删除快捷命令
    rm -f /usr/bin/mw
    rm -f /usr/local/bin/mw
    rm -f /etc/init.d/mw
    rm -f /etc/rc.d/init.d/mw
    rm -f /lib/systemd/system/mw.service
    
    # 删除 crontab
    crontab -l 2>/dev/null | grep -v "mdserver-web" | crontab - 2>/dev/null || true
    
    # 重新加载 systemd
    systemctl daemon-reload 2>/dev/null || true
    
    echo -e "${SUCCESS} 已删除面板命令"
}

# 清理其他文件
cleanup() {
    echo -e "${BLUE}正在清理其他文件...${PLAIN}"
    
    # 删除日志
    rm -f /var/log/mw-install.log
    rm -f /var/log/mw-update.log
    
    # 删除 acme.sh（可选）
    read -p "是否删除 acme.sh SSL证书工具? [yes/no]: " del_acme
    if [[ "$del_acme" == "yes" ]]; then
        rm -rf /root/.acme.sh
        echo -e "${SUCCESS} 已删除 acme.sh"
    fi
    
    echo -e "${SUCCESS} 清理完成"
}

# 显示卸载结果
show_result() {
    echo -e "\n${GREEN}============================================${PLAIN}"
    echo -e "${GREEN}  mdserver-web 卸载完成!${PLAIN}"
    echo -e "${GREEN}============================================${PLAIN}"
    echo -e "\n${YELLOW}保留的数据:${PLAIN}"
    echo "  - 网站文件: /www/wwwroot"
    echo "  - 备份文件: /www/backup"
    echo "  - 日志文件: /www/wwwlogs"
    echo -e "\n如需重新安装，请运行:"
    echo "  bash <(curl -fsSL https://raw.githubusercontent.com/kobex95/mdserver/master/scripts/install.sh)"
}

# 主函数
main() {
    check_root
    confirm_uninstall
    stop_services
    uninstall_plugins
    uninstall_panel
    cleanup
    show_result
}

# 运行主函数
main "$@"
