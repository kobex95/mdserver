#!/usr/bin/env python3
# coding: utf-8

import sys
import os
import json
import re
import time

# 添加web目录到路径
web_dir = os.getcwd() + "/web"
if os.path.exists(web_dir):
    sys.path.append(web_dir)
    os.chdir(web_dir)

import core.mw as mw

class nginx:
    __nginx_dir = '/www/server/nginx'
    __nginx_conf = '/www/server/nginx/conf/nginx.conf'
    
    def __init__(self):
        pass
    
    def getPluginName(self):
        return 'nginx'
    
    def getPluginDir(self):
        return mw.getPluginDir() + '/' + self.getPluginName()
    
    def getServerDir(self):
        return mw.getServerDir() + '/' + self.getPluginName()
    
    def getConf(self):
        return self.__nginx_conf
    
    def getInitDFile(self):
        if mw.isAppleSystem():
            return '/tmp/' + self.getPluginName()
        return '/etc/init.d/' + self.getPluginName()
    
    def getArgs(self):
        args = dict(request.form)
        return args
    
    def status(self):
        data = mw.execShell("ps -ef|grep nginx |grep -v grep | grep -v python | awk '{print $2}'")
        if data[0] == '':
            return 'stop'
        return 'start'
    
    def start(self):
        if mw.isAppleSystem():
            return mw.execShell(self.getServerDir() + '/init.d/nginx start')
        
        # 检查配置文件
        result = mw.execShell(self.getServerDir() + '/sbin/nginx -t')
        if result[1].find('successful') == -1:
            return result[1]
        
        mw.execShell('systemctl start nginx')
        return 'ok'
    
    def stop(self):
        if mw.isAppleSystem():
            return mw.execShell(self.getServerDir() + '/init.d/nginx stop')
        
        mw.execShell('systemctl stop nginx')
        return 'ok'
    
    def restart(self):
        if mw.isAppleSystem():
            return mw.execShell(self.getServerDir() + '/init.d/nginx restart')
        
        # 检查配置文件
        result = mw.execShell(self.getServerDir() + '/sbin/nginx -t')
        if result[1].find('successful') == -1:
            return result[1]
        
        mw.execShell('systemctl restart nginx')
        return 'ok'
    
    def reload(self):
        if mw.isAppleSystem():
            return mw.execShell(self.getServerDir() + '/init.d/nginx reload')
        
        # 检查配置文件
        result = mw.execShell(self.getServerDir() + '/sbin/nginx -t')
        if result[1].find('successful') == -1:
            return result[1]
        
        mw.execShell('systemctl reload nginx')
        return 'ok'
    
    def initdStatus(self):
        if not mw.isAppleSystem():
            initd_path = self.getInitDFile()
            if os.path.exists(initd_path):
                return 'ok'
        return 'fail'
    
    def initdInstall(self):
        import shutil
        if not mw.isAppleSystem():
            source_bin = self.getPluginDir() + '/init.d/nginx'
            initd_bin = self.getInitDFile()
            shutil.copyfile(source_bin, initd_bin)
            mw.execShell('chmod +x ' + initd_bin)
            mw.execShell('systemctl daemon-reload')
            return 'ok'
        return 'fail'
    
    def initdUinstall(self):
        if not mw.isAppleSystem():
            initd_bin = self.getInitDFile()
            os.remove(initd_bin)
            mw.execShell('systemctl daemon-reload')
            return 'ok'
        return 'fail'
    
    def runInfo(self):
        result = {}
        
        # 获取版本
        version_file = self.getServerDir() + '/version.pl'
        if os.path.exists(version_file):
            result['version'] = mw.readFile(version_file)
        else:
            result['version'] = 'Unknown'
        
        # 获取运行状态
        result['status'] = self.status()
        
        # 获取配置信息
        conf = self.getConf()
        if os.path.exists(conf):
            content = mw.readFile(conf)
            
            # 获取worker_processes
            match = re.search(r'worker_processes\s+(\w+);', content)
            if match:
                result['worker_processes'] = match.group(1)
            
            # 获取worker_connections
            match = re.search(r'worker_connections\s+(\d+);', content)
            if match:
                result['worker_connections'] = match.group(1)
        
        return mw.getJson(result)
    
    def conf(self):
        return self.getJson(self.getConf())

if __name__ == "__main__":
    func = sys.argv[1]
    ng = nginx()
    func = getattr(ng, func)
    print(func())
