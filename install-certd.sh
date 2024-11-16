#!/bin/bash

# 设置颜色输出
GREEN='\033[0;32m'
NC='\033[0m'
RED='\033[0;31m'

echo -e "${GREEN}开始安装 Certd...${NC}"

# 检查并安装 curl
check_curl() {
    if ! command -v curl &> /dev/null; then
        echo -e "${RED}curl 未安装，正在安装 curl...${NC}"
        if command -v apt &> /dev/null; then
            apt update && apt install -y curl
        elif command -v dnf &> /dev/null; then
            dnf install -y curl
        elif command -v yum &> /dev/null; then
            yum install -y curl
        else
            echo -e "${RED}无法安装 curl，请手动安装后重试${NC}"
            exit 1
        fi
        
        if ! command -v curl &> /dev/null; then
            echo -e "${RED}curl 安装失败，请手动安装后重试${NC}"
            exit 1
        fi
    else
        echo -e "${GREEN}curl 已安装${NC}"
    fi
}

# 检查并安装 Docker
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Docker 未安装，正在安装 Docker...${NC}"
        # 使用 LinuxMirrors 的 Docker 安装脚本
        curl -sSL https://raw.githubusercontent.com/SuperManito/LinuxMirrors/main/DockerInstallation.sh | bash
        if [ $? -ne 0 ]; then
            echo -e "${RED}Docker 安装失败，请检查网络连接或手动安装 Docker${NC}"
            exit 1
        fi
    else
        echo -e "${GREEN}Docker 已安装${NC}"
    fi
}

# 检查 Docker Compose
check_docker_compose() {
    if ! command -v docker compose &> /dev/null; then
        echo -e "${RED}Docker Compose 未安装，正在安装...${NC}"
        # 优先使用包管理器安装
        if command -v apt &> /dev/null; then
            apt update && apt install -y docker-compose-plugin
        elif command -v dnf &> /dev/null; then
            dnf install -y docker-compose-plugin
        elif command -v yum &> /dev/null; then
            yum install -y docker-compose-plugin
        else
            # 如果包管理器安装失败，则使用二进制安装
            DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
            curl -SL "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
            chmod +x /usr/local/bin/docker-compose
            ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
        fi
    else
        echo -e "${GREEN}Docker Compose 已安装${NC}"
    fi
}

# 获取服务器IP地址
get_server_ip() {
    # 尝试多个IP获取服务
    SERVER_IP=$(curl -s ip.sb || curl -s ifconfig.me || curl -s icanhazip.com)
    if [ -z "$SERVER_IP" ]; then
        SERVER_IP="your-ip"
        echo -e "${RED}无法自动获取服务器IP地址，请手动替换 your-ip${NC}"
    fi
}

# 其他函数保持不变...
create_directories() {
    mkdir -p /data/certd
    echo -e "${GREEN}创建数据目录: /data/certd${NC}"
}

create_docker_compose() {
    cat > /data/certd/docker-compose.yml << 'EOF'
version: '3'
services:
  certd:
    image: registry.cn-shenzhen.aliyuncs.com/handsfree/certd:latest
    container_name: certd
    restart: always
    ports:
      - "9999:9999"
    volumes:
      - /data/certd:/app/data
      # 如果需要自动部署到本机，需要挂载以下目录
      - /etc/ssl:/etc/ssl
      - /usr/share/nginx/html:/usr/share/nginx/html
      # 如果需要自动重启nginx，需要挂载以下文件
      - /var/run/docker.sock:/var/run/docker.sock
EOF
    echo -e "${GREEN}创建 docker-compose.yml 配置文件${NC}"
}

start_service() {
    cd /data/certd
    docker compose up -d
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Certd 服务已成功启动${NC}"
    else
        echo -e "${RED}Certd 服务启动失败，请检查日志${NC}"
        exit 1
    fi
}

check_system() {
    if [ "$(id -u)" != "0" ]; then
        echo -e "${RED}错误: 请使用 root 权限运行此脚本${NC}"
        exit 1
    fi
}

# 主函数
main() {
    check_system
    check_curl
    check_docker
    check_docker_compose
    create_directories
    create_docker_compose
    start_service
    get_server_ip
    
    echo -e "\n${GREEN}安装完成！${NC}"
    echo -e "${GREEN}请访问 http://${SERVER_IP}:9999 来使用 Certd${NC}"
    echo -e "${GREEN}默认管理员账号: admin${NC}"
    echo -e "${GREEN}默认管理员密码: 123456${NC}"
    echo -e "${RED}请及时修改默认密码！${NC}"
}

# 执行主函数
main
