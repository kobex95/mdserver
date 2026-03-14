#!/bin/bash

# 面板更新脚本
# 用法: bash update.sh

set -e

# 面板安装目录
PANEL_DIR="/www/server/mdserver-web"
TEMP_DIR="/tmp/mdserver_update"
BACKUP_DIR="/tmp/mdserver_backup_$(date +%Y%m%d_%H%M%S)"

# 颜色输出
red() { echo -e "\033[31m$1\033[0m"; }
green() { echo -e "\033[32m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }

# 检查是否以root运行
if [ "$EUID" -ne 0 ]; then
    red "请使用 root 用户运行此脚本"
    exit 1
fi

# 检查面板是否已安装
if [ ! -d "$PANEL_DIR" ]; then
    red "面板未安装在 $PANEL_DIR"
    exit 1
fi

# 下载最新代码
REPO_URL="https://github.com/kobex95/mdserver/archive/refs/heads/master.zip"

green "正在下载最新版本..."
rm -rf ${TEMP_DIR}
mkdir -p ${TEMP_DIR}
cd ${TEMP_DIR}

if ! wget --no-check-certificate -O master.zip ${REPO_URL} 2>/dev/null; then
    red "下载失败，请检查网络连接"
    exit 1
fi

# 解压
green "正在解压..."
unzip -q master.zip

# 备份当前配置
green "正在备份配置文件..."
mkdir -p ${BACKUP_DIR}
if [ -f ${PANEL_DIR}/web/version.py ]; then
    cp ${PANEL_DIR}/web/version.py ${BACKUP_DIR}/
fi
if [ -d ${PANEL_DIR}/data ]; then
    cp -r ${PANEL_DIR}/data ${BACKUP_DIR}/ 2>/dev/null || true
fi
if [ -d ${PANEL_DIR}/ssl ]; then
    cp -r ${PANEL_DIR}/ssl ${BACKUP_DIR}/ 2>/dev/null || true
fi

# 停止面板
green "正在停止面板服务..."
mw stop 2>/dev/null || true

# 更新文件
green "正在更新文件..."
cd ${TEMP_DIR}/mdserver-master

# 保留数据目录，只更新代码
rsync -av --exclude='data/*' --exclude='ssl/*' --exclude='logs/*' --exclude='*.pyc' \
    ./ ${PANEL_DIR}/

# 恢复版本文件（保留原版本号）
if [ -f ${BACKUP_DIR}/version.py ]; then
    cp ${BACKUP_DIR}/version.py ${PANEL_DIR}/web/version.py
fi

# 清理临时文件
rm -rf ${TEMP_DIR}

# 设置权限
chmod -R 755 ${PANEL_DIR}
find ${PANEL_DIR} -name "*.sh" -exec chmod +x {} \;

# 启动面板
green "正在启动面板..."
mw start 2>/dev/null || true

green "更新完成！"
green "备份文件位于: ${BACKUP_DIR}"
echo ""
echo "如需查看更新日志: cat ${PANEL_DIR}/logs/update.log"
