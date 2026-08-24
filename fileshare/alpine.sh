#!/bin/sh

set -e

if [ "$EUID" -ne 0 ]; then
    echo "请使用 root 运行"
    exit 1
fi

# 1. 安装 komari-agent (原有逻辑)
bash <(curl -sL https://cors.isteed.cc/raw.githubusercontent.com/komari-monitor/komari-agent/refs/heads/main/install.sh) -e https://node-monitor.kkufu.com --auto-discovery X4pdmTkrganMYbnUILbDCbwt --install-ghproxy https://cors.isteed.cc

DOWNLOAD_URL="https://www.kkce.com/ads/20260717-x86.tar.gz"
TMP_DIR="/tmp/check_agent_install"
INSTALL_DIR="/opt/check_agent"

echo "======================================="
echo " Check Agent 一键安装脚本 (Alpine版)"
echo "======================================="

rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

echo "下载程序..."
curl -k -L --retry 3 -o "$TMP_DIR/agent.tar.gz" "$DOWNLOAD_URL"

cd "$TMP_DIR"

echo "解压程序..."
tar zxf agent.tar.gz

if [ ! -d checker ]; then
    echo "未找到 checker 目录"
    exit 1
fi

mkdir -p "$INSTALL_DIR"

echo "安装程序..."
install -m 755 checker/agent "$INSTALL_DIR/agent"

# 获取公网 IPv4（仅使用 ipify，失败则为空）
PUBLIC_IP=""
PUBLIC_IP=$(curl -4 -fsS --connect-timeout 5 https://api.ipify.org 2>/dev/null || true)

if echo "$PUBLIC_IP" | grep -Eq '^([0-9]{1,3}\.){3}[0-9]{1,3}$'; then
    echo "检测到公网 IP: $PUBLIC_IP"
else
    PUBLIC_IP=""
    echo "警告: 未获取到公网 IP，将使用空值"
fi

# 配置文件
mkdir -p "$INSTALL_DIR/configs"

cat > "$INSTALL_DIR/configs/config.yaml" << EOF
check_servers:
  - endpoint: "node.kkce.com:10094"
    timeout: 20
    jwt_secret_key: "kkce-service"
  - endpoint: "node.vsping.com:10094"
    timeout: 20
    jwt_secret_key: "vsping-service"

node:
  type: "normal"
  ip: "$PUBLIC_IP"
  checker_token: "1bc8f444d1af940afc12e26ff5798545"
log:
  level: debug
EOF

# 清理旧版本服务 (OpenRC)
echo "清理旧服务..."
if [ -f "/etc/init.d/vsping-check-agent" ]; then
    rc-service vsping-check-agent stop 2>/dev/null || true
    rc-update del vsping-check-agent 2>/dev/null || true
    rm -f /etc/init.d/vsping-check-agent
fi

if [ -f "/etc/init.d/check-agent" ]; then
    rc-service check-agent stop 2>/dev/null || true
    rc-update del check-agent 2>/dev/null || true
    rm -f /etc/init.d/check-agent
fi

# 创建 OpenRC 服务脚本
echo "创建 check-agent 服务 (OpenRC)..."

cat > /etc/init.d/check-agent << 'EOF'
#!/sbin/openrc-run

name="Check Agent"
description="Check Agent Service"
command="/opt/check_agent/agent"
command_args="-c /opt/check_agent/configs"
directory="/opt/check_agent"
pidfile="/run/${RC_SVCNAME}.pid"
command_user="root"

depend() {
    need net
    use logger
}

start_pre() {
    # 确保目录存在
    if [ ! -d "/opt/check_agent" ]; then
        eerror "目录 /opt/check_agent 不存在"
        return 1
    fi
    if [ ! -x "/opt/check_agent/agent" ]; then
        eerror "可执行文件 /opt/check_agent/agent 不存在或无执行权限"
        return 1
    fi
}

stop() {
    ebegin "停止 ${name}"
    start-stop-daemon --stop --quiet --pidfile "${pidfile}" --retry 5
    eend $?
}
EOF

# 设置服务脚本权限
chmod +x /etc/init.d/check-agent

# 启动服务
echo "配置并启动 check-agent 服务..."
rc-update add check-agent default
rc-service check-agent restart

# 清理临时文件
rm -rf "$TMP_DIR"

echo
echo "======================================="
echo "安装完成"
echo "======================================="
echo

rc-service check-agent status

echo
echo "常用命令 (Alpine OpenRC)："
echo
echo "启动服务:   rc-service check-agent start"
echo "停止服务:   rc-service check-agent stop"
echo "重启服务:   rc-service check-agent restart"
echo "查看状态:   rc-service check-agent status"
echo "查看日志:   tail -f /var/log/messages 或 journalctl -u check-agent (需安装)"
echo "开机自启:   rc-update add check-agent default"
echo "取消自启:   rc-update del check-agent"
echo
echo "配置文件:"
echo "  $INSTALL_DIR/configs/config.yaml"
echo
echo "程序目录:"
echo "  $INSTALL_DIR"
