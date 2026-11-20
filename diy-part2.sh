#!/bin/bash
# diy-part2.sh — 在 feeds install、.config 载入之后执行
# 工作目录: openwrt/

# 关闭 sing-box naive 出站（避免 libcronet/gn 交叉编译失败）
if [ -f .config ]; then
    sed -i 's/^CONFIG_SING_BOX_BUILD_NAIVE_OUTBOUND=y/# CONFIG_SING_BOX_BUILD_NAIVE_OUTBOUND is not set/' .config
    sed -i 's/^CONFIG_SING_BOX_TINY_BUILD_NAIVE_OUTBOUND=y/# CONFIG_SING_BOX_TINY_BUILD_NAIVE_OUTBOUND is not set/' .config
fi

# ---------------------------------------------------------------------------
# 默认设置：只改 LAN IP 和 root 密码，绝不覆盖整个 /etc/config/network。
# 040G-MD 是光猫，官方 board.d/02_network 把 pon0 设为 WAN、lan1-lan4 为 LAN，
# 直接覆盖 network 会丢掉 pon0，导致光猫无法注册/拨号。这里用 uci-defaults
# 在首次启动时改 LAN 地址，保留官方生成的 pon0 WAN 与 PON 校准数据。
# ---------------------------------------------------------------------------
mkdir -p files/etc/uci-defaults

cat > files/etc/uci-defaults/99-xg140g-settings <<'EOF'
#!/bin/sh
# LAN 地址改为 10.0.0.1（保留官方生成的 pon0 WAN 与 lan 口布局）
if [ -f /etc/config/network ]; then
    uci -q set network.lan.ipaddr='10.0.0.1'
    uci -q set network.lan.netmask='255.255.255.0'
    uci -q commit network
fi

# root 密码设为 password（md5crypt hash，覆盖 ponwrt 的 50-root-passwd）
echo 'root:$1$xg140g$gIXN4WOFLjad9ZLoIyvf./:0:0:99999:7:::' > /etc/shadow
chmod 600 /etc/shadow
exit 0
EOF
chmod +x files/etc/uci-defaults/99-xg140g-settings

echo "diy-part2: settings injected (LAN 10.0.0.1 / root password, pon0 WAN preserved)"
