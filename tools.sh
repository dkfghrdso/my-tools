#!/bin/bash

# 检测操作系统
if [ -f /etc/redhat-release ]; then
    # CentOS 或 RHEL
    PACKAGE_MANAGER="yum"
    INSTALL_CMD="$PACKAGE_MANAGER install -y"
elif [ -f /etc/debian_version ]; then
    # Debian 或 Ubuntu
    PACKAGE_MANAGER="apt"
    INSTALL_CMD="apt install -y"
else
    echo "不支持的操作系统。"
    exit 1
fi

# 更新系统
if [ "$PACKAGE_MANAGER" == "yum" ]; then
    sudo yum update -y
elif [ "$PACKAGE_MANAGER" == "apt" ]; then
    sudo apt update && sudo apt upgrade -y
fi

# 安装基本工具
sudo $INSTALL_CMD \
    tar \
    git \
    wget \
    curl \
    vim \
    nano \
    net-tools \
    htop \
    ncdu \
    traceroute \
    zip \
    unzip \
    firewalld \
    fail2ban \
    nmap

# 安装完成提示
echo "基础工具安装完成！"
