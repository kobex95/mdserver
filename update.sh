#!/bin/bash
# MW-Linux面板更新脚本
# 更新源: https://github.com/kobex95/mdserver

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin

PANEL_DIR="/www/server/mdserver-web"
TEMP_DIR="/tmp/mdserver-update"
VERSION="0.18.5"
REPO_URL="https://github.com/kobex95/mdserver/archive/refs/tags/v${VERSION}.zip"

echo "========================================"
echo " MW-Linux面板更新脚本"
echo " 目标版本: ${VERSION}"
echo "========================================"

# 检查面板目录
if [ ! -d "$PANEL_DIR" ]; then
    echo "错误: 面板目录不存在 $PANEL_DIR"
    exit 1
fi

# 创建临时目录
rm -rf $TEMP_DIR
mkdir -p $TEMP_DIR

# 下载新版本
echo "正在下载新版本..."
wget --no-check-certificate -O ${TEMP_DIR}/mw.zip ${REPO_URL}

if [ $? -ne 0 ]; then
    echo "下载失败，请检查网络连接"
    rm -rf $TEMP_DIR
    exit 1
fi

# 解压
echo "正在解压..."
cd $TEMP_DIR
unzip -o mw.zip

if [ $? -ne 0 ]; then
    echo "解压失败"
    rm -rf $TEMP_DIR
    exit 1
fi

# 备份配置文件
echo "正在备份配置文件..."
cp -f $PANEL_DIR/data/default.db $TEMP_DIR/default.db.bak 2>/dev/null
cp -f $PANEL_DIR/data/admin_path.pl $TEMP_DIR/admin_path.pl.bak 2>/dev/null
cp -f $PANEL_DIR/data/port.pl $TEMP_DIR/port.pl.bak 2>/dev/null
cp -rf $PANEL_DIR/ssl $TEMP_DIR/ssl.bak 2>/dev/null

# 复制新文件
echo "正在更新文件..."
cp -rf ${TEMP_DIR}/mdserver-v${VERSION}/* $PANEL_DIR/

# 恢复配置文件
echo "正在恢复配置文件..."
cp -f $TEMP_DIR/default.db.bak $PANEL_DIR/data/default.db 2>/dev/null
cp -f $TEMP_DIR/admin_path.pl.bak $PANEL_DIR/data/admin_path.pl 2>/dev/null
cp -f $TEMP_DIR/port.pl.bak $PANEL_DIR/data/port.pl 2>/dev/null
cp -rf $TEMP_DIR/ssl.bak/* $PANEL_DIR/ssl/ 2>/dev/null

# 更新Python依赖
echo "正在更新Python依赖..."
cd $PANEL_DIR

if [ -f /www/server/mdserver-web/bin/activate ]; then
    source /www/server/mdserver-web/bin/activate
fi

cn=$(curl -fsSL -m 10 http://ipinfo.io/json | grep "\"country\": \"CN\"")
PIPSRC="https://pypi.python.org/simple"
if [ ! -z "$cn" ]; then
    PIPSRC="https://pypi.tuna.tsinghua.edu.cn/simple"
fi

pip3 install -r $PANEL_DIR/requirements.txt -i $PIPSRC

# 清理临时文件
rm -rf $TEMP_DIR

# 重启面板
echo "正在重启面板..."
mw restart

echo "========================================"
echo " 更新完成! 当前版本: ${VERSION}"
echo "========================================"
