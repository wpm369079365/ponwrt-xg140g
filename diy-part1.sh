#!/bin/bash
# diy-part1.sh — 在 ponwrt 源码 clone 完成、feeds 更新之前执行
# 工作目录: openwrt/

# ---------------------------------------------------------------------------
# 1) 让 040G-MD-UBI 镜像同时声明支持 XG-140G-MD
#    140G-MD 与 040G-MD 同为 AN7581 同一块板子（bingoguo93 源码里 140G-MD
#    就是 040G-MD 的 DEVICE_ALT0_MODEL，共用 DTS）。ponwrt 官方设备表只列
#    040G-MD-UBI，这里给它补上 140G-MD 别名与 SUPPORTED_DEVICES，避免
#    sysupgrade 时因型号名不匹配被拒刷。
# ---------------------------------------------------------------------------
MK="target/linux/airoha/image/an7581.mk"
if [ -f "$MK" ]; then
    python3 - <<'PY'
from pathlib import Path
p = Path("target/linux/airoha/image/an7581.mk")
s = p.read_text(encoding="utf-8")
anchor = "define Device/nokia_xg-040g-md-ubi\n"
addition = (
    "  DEVICE_ALT0_VENDOR := Nokia Bell\n"
    "  DEVICE_ALT0_MODEL := XG-140G-MD\n"
    "  SUPPORTED_DEVICES += nokia,xg-140g-md\n"
)
if "XG-140G-MD" not in s and anchor in s:
    s = s.replace(anchor, anchor + addition, 1)
    p.write_text(s, encoding="utf-8")
    echo "diy-part1: patched an7581.mk for XG-140G-MD alias"
else:
    echo "diy-part1: XG-140G-MD alias already present or anchor missing (skip)"
PY
else
    echo "diy-part1: WARNING $MK not found"
fi

# ---------------------------------------------------------------------------
# 2) 关闭 sing-box 的 naive 出站（避免引入 libcronet 需要 gn 交叉编译）
#    这里先兜底清一次，.config 里也已写死。
# ---------------------------------------------------------------------------
if [ -f feeds.conf.default ]; then
    sed -i 's/^src-git luci .*/&/' feeds.conf.default
fi
echo "diy-part1: done"
