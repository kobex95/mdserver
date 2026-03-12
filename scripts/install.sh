#!/bin/bash
# =============================================================================
# mdserver-web 安装脚本
# 一款简单Linux面板服务
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

# GitHub仓库配置
readonly GITHUB_USER="kobex95"
readonly GITHUB_REPO="mdserver"
readonly GITHUB_HOST="github.com/${GITHUB_USER}/${GITHUB_REPO}"
readonly RAW_HOST="raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}"

# 国内镜像代理
GH_PROXIES=(
    "https://gh-proxy.com/"
    "https://ghfast.top/"
    "https://ghproxy.net/"
)

# 日志文件
LOG_FILE="/var/log/mw-install.log"

# 检测是否为国内网络
detect_network() {
    local country
    country=$(curl -fsSL -m 5 -s http://ipinfo.io/json 2>/dev/null | grep -o '"country": "[^"]*"' | cut -d'"' -f4)
    if [[ "$country" == "CN" ]]; then
        echo "cn"
    else
        echo "global"
    fi
}

# 选择GitHub代理
select_proxy() {
    echo -e "${BLUE}正在检测网络环境...${PLAIN}"
    
    if [[ "$NETWORK_TYPE" == "global" ]]; then
        HTTP_PREFIX=""
        echo -e "${SUCCESS} 使用直连访问GitHub(无代理)"
        return 0
    fi
    
    echo -e "${YELLOW}检测到国内网络，将使用镜像加速...${PLAIN}"
    
    # 测试可用的代理
    for proxy in "${GH_PROXIES[@]}"; do
        local domain
        domain=$(echo "$proxy" | sed -E 's|https?://||g' | sed -E 's|/.*||g')
        if ping -c 1 -W 2 "$domain" &>/dev/null; then
            HTTP_PREFIX="$proxy"
            echo -e "${SUCCESS} 使用代理: $proxy"
            return 0
        fi
    done
    
    # 默认使用第一个代理
    HTTP_PREFIX="${GH_PROXIES[0]}"
    echo -e "${YELLOW}警告: 代理测试失败，将尝试使用默认代理${PLAIN}"
}

# 安装基础依赖
install_base_deps() {
    if [[ -f /etc/os-release ]]; then
        local id
        id=$(grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '"')
        case "$id" in
            debian|ubuntu)
                apt-get update > /dev/null 2>&1
                apt-get install -y wget curl zip unzip tar cron python3 python3-venv python3-pip > /dev/null 2>&1
                ;;
            centos|rhel|rocky|almalinux|anolis|fedora)
                yum install -y wget curl zip unzip tar crontabs python3 python3-pip > /dev/null 2>&1
                ;;
            alpine)
                apk update > /dev/null 2>&1
                apk add wget curl zip unzip tar python3 py3-pip > /dev/null 2>&1
                ;;
            opensuse*)
                zypper refresh > /dev/null 2>&1
                zypper install -y cron wget curl zip unzip python3 python3-pip > /dev/null 2>&1
                ;;
            amzn)
                yum install -y wget curl zip unzip tar crontabs python3 python3-pip > /dev/null 2>&1
                ;;
            euler|openeuler)
                yum install -y wget curl zip unzip tar crontabs python3 python3-pip > /dev/null 2>&1
                ;;
        esac
    elif [[ -f /etc/freebsd-version ]]; then
        pkg install -y wget curl zip unzip python3 py38-pip > /dev/null 2>&1
    fi
    
    # 验证Python3安装
    if ! command -v python3 &> /dev/null; then
        echo -e "${ERROR} Python3 安装失败，请手动安装后重试"
        exit 1
    fi
    echo -e "${SUCCESS} Python3 安装完成: $(python3 --version)"
}

# 检测操作系统(只检测，不安装)
detect_os() {
    local os_name="unknow"
    
    if [[ "$(uname)" == "Darwin" ]]; then
        os_name="macos"
    elif [[ -f /etc/os-release ]]; then
        local id
        id=$(grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '"' 2>/dev/null)
        case "$id" in
            debian) os_name="debian" ;;
            ubuntu) os_name="ubuntu" ;;
            centos|rhel|rocky|almalinux|anolis) os_name="rhel" ;;
            fedora) os_name="rhel" ;;
            alpine) os_name="alpine" ;;
            opensuse*) os_name="opensuse" ;;
            amzn) os_name="amazon" ;;
            euler|openeuler) os_name="euler" ;;
        esac
    elif [[ -f /etc/freebsd-version ]]; then
        os_name="freebsd"
    fi
    
    echo "$os_name"
}

# 创建系统用户
create_user() {
    if ! id www &>/dev/null; then
        groupadd www 2>/dev/null || true
        useradd -g www -s /usr/sbin/nologin www 2>/dev/null || true
        echo -e "${SUCCESS} 创建用户 www"
    fi
}

# 创建目录结构
create_directories() {
    local dirs=(
        "/www/server"
        "/www/wwwroot"
        "/www/wwwlogs"
        "/www/backup/database"
        "/www/backup/site"
    )
    
    for dir in "${dirs[@]}"; do
        mkdir -p "$dir"
    done
    
    echo -e "${SUCCESS} 创建目录结构"
}

# 下载并安装面板
download_panel() {
    local install_dir="/www/server/mdserver-web"
    
    if [[ -d "$install_dir" ]]; then
        echo -e "${YELLOW}检测到已存在安装目录，跳过下载${PLAIN}"
        return 0
    fi
    
    echo -e "${BLUE}正在下载面板源码...${PLAIN}"
    
    local download_url="${HTTP_PREFIX}https://${GITHUB_HOST}/archive/refs/heads/master.tar.gz"
    local tmp_file="/tmp/mdserver-master.tar.gz"
    
    if ! curl --insecure -fsSL -o "$tmp_file" "$download_url"; then
        echo -e "${ERROR} 下载失败，请检查网络连接"
        exit 1
    fi
    
    cd /tmp
    tar -zxf "$tmp_file"
    mv -f mdserver-master "$install_dir"
    rm -f "$tmp_file"
    
    echo -e "${SUCCESS} 面板源码下载完成"
}

# 安装acme.sh
install_acme() {
    if [[ -d /root/.acme.sh ]]; then
        echo -e "${SUCCESS} acme.sh 已安装"
        return 0
    fi
    
    echo -e "${BLUE}正在安装 acme.sh...${PLAIN}"
    
    if [[ "$NETWORK_TYPE" == "cn" ]]; then
        local acme_url="${HTTP_PREFIX}https://github.com/acmesh-official/acme.sh/archive/refs/heads/master.tar.gz"
        curl --insecure -fsSL -o /tmp/acme.sh.tar.gz "$acme_url"
        tar -zxf /tmp/acme.sh.tar.gz -C /tmp
        cd /tmp/acme.sh-master
        bash acme.sh install
        rm -rf /tmp/acme.sh.tar.gz /tmp/acme.sh-master
    else
        curl -fsSL https://get.acme.sh | bash
    fi
    
    echo -e "${SUCCESS} acme.sh 安装完成"
}

# 安装依赖库
install_libs() {
    echo -e "${BLUE}正在安装依赖库...${PLAIN}"
    cd /www/server/mdserver-web
    bash scripts/lib.sh
}

# 安装系统特定组件
install_system_components() {
    echo -e "${BLUE}正在安装 ${OSNAME} 系统组件...${PLAIN}"
    cd /www/server/mdserver-web
    bash "scripts/install/${OSNAME}.sh"
}

# 启动面板
start_panel() {
    echo -e "${BLUE}正在启动面板...${PLAIN}"
    cd /www/server/mdserver-web
    bash cli.sh start
    
    # 等待启动完成
    local n=0
    while [[ ! -f /etc/rc.d/init.d/mw ]]; do
        echo -n "."
        sleep 1
        ((n++))
        if [[ $n -gt 30 ]]; then
            echo -e "\n${ERROR} 面板启动超时"
            exit 1
        fi
    done
    
    # 重启以确保正常运行
    bash /etc/rc.d/init.d/mw stop &>/dev/null || true
    sleep 2
    bash /etc/rc.d/init.d/mw start
    bash /etc/rc.d/init.d/mw default
    
    # 创建快捷命令
    if [[ ! -e /usr/bin/mw ]]; then
        ln -sf /etc/rc.d/init.d/mw /usr/bin/mw
        echo -e "${SUCCESS} 创建快捷命令: mw"
    fi
}

# 设置motd
setup_motd() {
    if [[ -f /etc/motd ]]; then
        echo "Welcome to mdserver-web panel" > /etc/motd
    fi
}

# 打印安装完成信息
print_completion() {
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - START_TIME))
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))
    
    echo -e "\n${GREEN}============================================${PLAIN}"
    echo -e "${GREEN}  mdserver-web 安装完成!${PLAIN}"
    echo -e "${GREEN}============================================${PLAIN}"
    echo -e "安装耗时: ${minutes}分${seconds}秒"
    echo -e "\n常用命令:"
    echo -e "  mw start    - 启动面板"
    echo -e "  mw stop     - 停止面板"
    echo -e "  mw restart  - 重启面板"
    echo -e "  mw default  - 显示登录信息"
    echo -e "\n日志文件: ${LOG_FILE}"
    echo -e "${GREEN}============================================${PLAIN}\n"
}

# 主函数
main() {
    START_TIME=$(date +%s)
    
    # 检查root权限
    if [[ $EUID -ne 0 ]] && [[ "$(uname)" != "Darwin" ]]; then
        echo -e "${ERROR} 请使用 root 用户运行此脚本"
        exit 1
    fi
    
    # 检查是否已安装
    if [[ -f /www/server/mdserver-web/tools.py ]]; then
        echo -e "${YELLOW}检测到已存在的安装${PLAIN}"
        echo "如需重新安装，请先执行: rm -rf /www/server/mdserver-web"
        exit 0
    fi
    
    echo -e "${GREEN}============================================${PLAIN}"
    echo -e "${GREEN}  mdserver-web 安装程序${PLAIN}"
    echo -e "${GREEN}============================================${PLAIN}\n"
    
    # 检测网络环境
    NETWORK_TYPE=$(detect_network)
    select_proxy
    
    # 检测操作系统
    OSNAME=$(detect_os)
    echo -e "${SUCCESS} 检测到操作系统: ${OSNAME}"
    
    # macOS特殊处理
    if [[ "$OSNAME" == "macos" ]]; then
        echo -e "${BLUE}macOS 系统，使用远程安装脚本...${PLAIN}"
        curl --insecure -fsSL "${HTTP_PREFIX}https://${RAW_HOST}/master/scripts/install/macos.sh" | bash
        exit 0
    fi
    
    # 安装基础依赖(Python3等)
    echo -e "${BLUE}正在安装基础依赖...${PLAIN}"
    install_base_deps
    
    # 创建用户和目录
    create_user
    create_directories
    
    # 下载面板
    download_panel
    
    # 安装acme.sh
    install_acme
    
    # 安装依赖
    install_libs
    
    # 安装系统组件
    install_system_components
    
    # 设置motd
    setup_motd
    
    # 启动面板
    start_panel
    
    # 打印完成信息
    print_completion
}

# 运行主函数
main "$@" 2>&1 | tee -a "$LOG_FILE"
