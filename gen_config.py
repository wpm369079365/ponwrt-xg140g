#!/usr/bin/env python3
"""从 ponwrt 官方 an7581.config 生成 XG-140G-MD 专用配置。"""
import re
from pathlib import Path

CFG = Path(__file__).parent / ".config"
lines = CFG.read_text(encoding="utf-8").splitlines()

TARGET = "CONFIG_TARGET_DEVICE_airoha_an7581_DEVICE_nokia_xg-040g-md-ubi"
WANTED_Y = [
    "CONFIG_PACKAGE_luci-app-homeproxy",
    "CONFIG_PACKAGE_sing-box",
    "CONFIG_PACKAGE_luci-app-ddns",
    "CONFIG_PACKAGE_ddns-scripts",
    "CONFIG_PACKAGE_ddns-scripts-services",
    "CONFIG_PACKAGE_luci-app-openlist",
    "CONFIG_PACKAGE_openlist",
    "CONFIG_PACKAGE_vlmcsd",
    "CONFIG_PACKAGE_luci-app-vlmcsd",
    "CONFIG_PACKAGE_ppp",
    "CONFIG_PACKAGE_ppp-mod-pppoe",
    "CONFIG_PACKAGE_luci-proto-ppp",
    "CONFIG_PACKAGE_luci-proto-ipv6",
    "CONFIG_PACKAGE_luci-theme-argon",
    "CONFIG_LUCI_LANG_zh_Hans",
    "CONFIG_PACKAGE_ddns-scripts-aliyun",
    "CONFIG_PACKAGE_ddns-scripts-cloudflare",
    "CONFIG_PACKAGE_ddns-scripts-dnspod",
    "CONFIG_PACKAGE_ddns-scripts-noip",
    "CONFIG_PACKAGE_ddns-scripts-freedns",
]
WANTED_N = [
    "CONFIG_SING_BOX_BUILD_NAIVE_OUTBOUND",
    "CONFIG_SING_BOX_TINY_BUILD_NAIVE_OUTBOUND",
]
DEVICE_RE = re.compile(r"^CONFIG_TARGET_DEVICE_airoha_an7581_DEVICE_[A-Za-z0-9_.-]+$")

out = []
seen = set()
for line in lines:
    m = re.match(r"^(# )?(CONFIG_[A-Za-z0-9_.-]+)( is not set|=.*)$", line)
    if m:
        sym = m.group(2)
        if sym == TARGET:
            out.append(f"{TARGET}=y")
            seen.add(sym)
            continue
        # 收敛到单设备：其它 airoha/an7581 设备统一关掉
        if DEVICE_RE.match(sym) and sym != TARGET:
            out.append(f"# {sym} is not set")
            continue
        if sym in WANTED_Y:
            out.append(f"{sym}=y")
            seen.add(sym)
            continue
        if sym in WANTED_N:
            out.append(f"# {sym} is not set")
            seen.add(sym)
            continue
    out.append(line)

# 追加官方 .config 中尚不存在的符号（feeds install 后 make defconfig 可识别）
tail = [s for s in WANTED_Y if s not in seen]
for s in tail:
    out.append(f"{s}=y")
for s in WANTED_N:
    if s not in seen:
        out.append(f"# {s} is not set")

CFG.write_text("\n".join(out) + "\n", encoding="utf-8")

# 校验
txt = CFG.read_text(encoding="utf-8")
assert f"{TARGET}=y" in txt
for s in WANTED_Y:
    assert f"{s}=y" in txt, s
for s in WANTED_N:
    assert f"# {s} is not set" in txt, s
devs = [l for l in txt.splitlines() if DEVICE_RE.match(l.split("=")[0]) and l.endswith("=y")]
print("target devices =y:", devs)
print("wanted plugins: OK", len(WANTED_Y), "| disabled:", len(WANTED_N))
print("lines:", len(out))
