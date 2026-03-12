#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os
import sys

base_dir = r'd:\代码\K-Vault\zu-server'
extensions = ['.py', '.sh', '.html', '.json', '.md', '.txt', '.js', '.css']
modified_files = []

def process_file(filepath):
    try:
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
        
        if 'midoks/mdserver-web' in content:
            new_content = content.replace('midoks/mdserver-web', 'kobex95/mdserver')
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(new_content)
            modified_files.append(filepath)
            print(f'[OK] {filepath}')
            return True
    except Exception as e:
        print(f'[ERROR] {filepath}: {e}')
    return False

# 遍历目录
for root, dirs, files in os.walk(base_dir):
    # 跳过 .git 目录
    if '.git' in root:
        continue
    
    for file in files:
        filepath = os.path.join(root, file)
        
        # 检查文件扩展名或特殊文件名
        if file == 'Dockerfile' or any(file.endswith(ext) for ext in extensions):
            process_file(filepath)

print(f'\n========================================')
print(f'共修改 {len(modified_files)} 个文件')
print(f'========================================')
