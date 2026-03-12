#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

curPath=`pwd`
rootPath=$(dirname "$curPath")
rootPath=$(dirname "$rootPath")
rootPath=$(dirname "$rootPath")
rootPath=$(dirname "$rootPath")
serverPath=$(dirname "$rootPath")

sysName=`uname`
action=$1

VERSION=1.27.5
nginxDir=${serverPath}/source/nginx

if [ -d $serverPath/nginx ];then
	exit 0
fi

# ----- cpu start ------
if [ -z "${cpuCore}" ]; then
    cpuCore="1"
fi

if [ -f /proc/cpuinfo ];then
	cpuCore=`cat /proc/cpuinfo | grep "processor" | wc -l`
fi

MEM_INFO=$(free -m|grep Mem|awk '{printf("%.f",($2)/1024)}')
if [ "${cpuCore}" != "1" ] && [ "${MEM_INFO}" != "0" ];then
    if [ "${cpuCore}" -gt "${MEM_INFO}" ];then
        cpuCore="${MEM_INFO}"
    fi
fi
# ----- cpu end ------

if [ ! -d $nginxDir ];then
	mkdir -p $nginxDir
fi

HTTP_PREFIX="https://"
LOCAL_ADDR=common
cn=$(curl -fsSL -m 10 http://ipinfo.io/json | grep "\"country\": \"CN\"")
if [ ! -z "$cn" ] || [ "$?" == "0" ] ;then
	LOCAL_ADDR=cn
	HTTP_PREFIX="https://mirror.ghproxy.com/"
fi

if [ ! -f ${nginxDir}/nginx-${VERSION}.tar.gz ];then
	wget --no-check-certificate -O ${nginxDir}/nginx-${VERSION}.tar.gz https://nginx.org/download/nginx-${VERSION}.tar.gz -T 30
fi

if [ ! -d ${nginxDir}/nginx-${VERSION} ];then
	cd ${nginxDir} && tar -zxvf nginx-${VERSION}.tar.gz
fi

# 安装依赖
if [ "${LOCAL_ADDR}" == "cn" ]; then
	apt-get install -y libpcre3 libpcre3-dev zlib1g zlib1g-dev openssl libssl-dev gcc make > /dev/null 2>&1 || \
	yum install -y pcre pcre-devel zlib zlib-devel openssl openssl-devel gcc make > /dev/null 2>&1
fi

OPTIONS='--prefix='${serverPath}'/nginx \
--with-http_ssl_module \
--with-http_v2_module \
--with-http_v3_module \
--with-http_realip_module \
--with-http_addition_module \
--with-http_sub_module \
--with-http_dav_module \
--with-http_flv_module \
--with-http_mp4_module \
--with-http_gunzip_module \
--with-http_gzip_static_module \
--with-http_random_index_module \
--with-http_secure_link_module \
--with-http_stub_status_module \
--with-http_auth_request_module \
--with-threads \
--with-stream \
--with-stream_ssl_module \
--with-stream_realip_module \
--with-http_slice_module \
--with-mail \
--with-mail_ssl_module \
--with-file-aio \
--with-http_image_filter_module \
--user=www \
--group=www'

cd ${nginxDir}/nginx-${VERSION} && ./configure $OPTIONS

cd ${nginxDir}/nginx-${VERSION} && make -j${cpuCore}
cd ${nginxDir}/nginx-${VERSION} && make install

if [ -d $serverPath/nginx ];then
	echo "${VERSION}" > $serverPath/nginx/version.pl
	
	# 创建配置文件
	mkdir -p $serverPath/nginx/conf/vhost
	mkdir -p $serverPath/nginx/logs
	
	# 复制启动脚本
	cp $rootPath/plugins/nginx/init.d/nginx $serverPath/nginx/init.d/nginx
	chmod +x $serverPath/nginx/init.d/nginx
	
	# 创建systemd服务
	cp $rootPath/plugins/nginx/init.d/nginx.service /lib/systemd/system/nginx.service
	systemctl daemon-reload
	
	echo "nginx安装成功"
fi
