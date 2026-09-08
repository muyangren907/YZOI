#!/bin/sh
# 转换为适配 Alpine Linux (OpenRC) 的脚本

set -e

# Alpine 推荐使用 id -u 检查 root
if [ "$(id -u)" -ne 0 ]; then
    echo "请使用 root 运行"
    exit 1
fi

echo "======================================="
echo " Check Agent 一键安装脚本 (Alpine 版)"
echo "======================================="

# Alpine 使用 musl libc。如果 agent 是普通 glibc 编译的二进制文件，需要 libc6-compat
# 此外安装 coreutils 以支持 date +%s%N 命令
echo "检查并安装必要依赖..."
apk add -q curl tar coreutils libc6-compat

DOWNLOAD_URL="https://www.kkce.com/ads/20260908152044_agent_amd64_branch-1.6.0-e1242d4.tar.gz"

TMP_DIR="/tmp/check_agent_install"
INSTALL_DIR="/opt/check_agent"

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


# --------------------------
# 配置文件
# --------------------------
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
  ip: ""
  checker_token: "1bc8f444d1af940afc12e26ff5798545"
log:
  level: debug
EOF

# --------------------------
# 清理旧版本服务 (OpenRC 方式)
# --------------------------
echo "清理旧服务..."

rc-service vsping-check-agent stop 2>/dev/null || true
rc-update del vsping-check-agent default 2>/dev/null || true
rm -f /etc/init.d/vsping-check-agent

rc-service check-agent stop 2>/dev/null || true
rc-update del check-agent default 2>/dev/null || true
rm -f /etc/init.d/check-agent

# --------------------------
# OpenRC 服务配置
# --------------------------
echo "创建 check-agent 服务..."

cat > /etc/init.d/check-agent << 'EOF'
#!/sbin/openrc-run

name="check-agent"
description="Check Agent Service"
command="/opt/check_agent/agent"
command_args="-c ./configs"
command_background="yes"
directory="/opt/check_agent"
pidfile="/run/${RC_SVCNAME}.pid"
output_log="/var/log/${RC_SVCNAME}.log"
error_log="/var/log/${RC_SVCNAME}.log"

depend() {
    need net
    after firewall
}
EOF

chmod +x /etc/init.d/check-agent

# --------------------------
# 启动服务
# --------------------------
echo "设置开机自启并启动服务..."

rc-update add check-agent default
rc-service check-agent restart

# --------------------------
# 清理临时文件
# --------------------------
rm -rf "$TMP_DIR"

echo
echo "======================================="
echo "安装完成"
echo "======================================="
echo

rc-service check-agent status || true

# 重新生成 Device ID 并重启 (移除 sudo，因为本身已经是 root)
mkdir -p /var/lib/check-agent
echo "$(date +%s%N)" > /var/lib/check-agent/device-id
rc-service check-agent restart

echo
echo "常用命令："
echo
echo "启动服务:   rc-service check-agent start"
echo "停止服务:   rc-service check-agent stop"
echo "重启服务:   rc-service check-agent restart"
echo "查看状态:   rc-service check-agent status"
echo "查看日志:   tail -f /var/log/check-agent.log"