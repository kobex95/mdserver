#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin:/opt/homebrew/bin
export PATH

# cd /www/server/mdserver-web/plugins/nginx && bash install.sh install 1.24.0

curPath=`pwd`
rootPath=$(dirname "$curPath")
rootPath=$(dirname "$rootPath")
serverPath=$(dirname "$rootPath")

sysName=`uname`
action=$1
type=$2

VERSION=$2
nginxDir=${serverPath}/source/nginx

if id www &> /dev/null ;then 
    echo "www uid is `id -u www`"
else
    groupadd www
	useradd -g www -s /bin/bash www
fi

if [ "${2}" == "" ];then
	echo '缺少安装脚本版本...'
	exit 0
fi 

if [ "${action}" == "uninstall" ];then
	if [ -f /usr/lib/systemd/system/nginx.service ] || [ -f /lib/systemd/system/nginx.service ];then
		systemctl stop nginx
		rm -rf /usr/systemd/system/nginx.service
		rm -rf /lib/systemd/system/nginx.service
		systemctl daemon-reload
	fi

	if [ -f $serverPath/nginx/init.d/nginx ];then
		$serverPath/nginx/init.d/nginx stop
	fi

	rm -rf $serverPath/nginx
	echo "卸载Nginx成功"
fi

if [ "${action}" == "install" ];then
	bash $curPath/versions/$2/install.sh $1
fi
