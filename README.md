# XG-140G-MD 固件（P3TERX 模板 · ponwrt 源码）

用 [P3TERX/Actions-OpenWrt](https://github.com/P3TERX/Actions-OpenWrt) 风格的工作流，从 [pbs05/ponwrt](https://github.com/pbs05/ponwrt)（ImmortalWrt 6.18 内核，带 Airoha AN7581 PON 支持）编译诺基亚贝尔 **XG-140G-MD** 光猫固件。

## 设备说明

ponwrt 官方设备表只有 `XG-040G-MD (UBI)`。XG-140G-MD 与它是同一块 AN7581 板子（别的源码树里直接把 140G-MD 写成 040G-MD 的 `DEVICE_ALT0_MODEL`）。`diy-part1.sh` 会给镜像补上 140G-MD 的型号声明与 `SUPPORTED_DEVICES`，避免 sysupgrade 拒刷。

- 编译目标：`nokia_xg-040g-md-ubi`
- WAN：`pon0`（接光纤后由 PON 注册上网）
- LAN：`lan1`–`lan4`
- 默认地址：`10.0.0.1`，root 密码 `password`

## 包含的插件

| 功能 | 包 |
|---|---|
| 代理 | `luci-app-homeproxy` + `sing-box`（naive 出站已关闭，避免 libcronet） |
| DDNS | `luci-app-ddns` + `ddns-scripts`，含 aliyun / cloudflare / dnspod / noip / freedns |
| 网盘 | `luci-app-openlist` + `openlist` |
| KMS | `vlmcsd` + `luci-app-vlmcsd` |
| 拨号 | PPPoE / `luci-proto-ppp` / `luci-proto-ipv6` + ponwrt 原生 PON |
| IPv6 | 内核 IPv6、`odhcp6c`、`odhcpd-ipv6only`、dnsmasq DHCPv6 均已开启 |
| USB 存储 | `block-mount` + `automount` + `ntfs-3g`（自动挂载、NTFS 读写） |
| 网络共享 | `samba4-server` + `luci-app-samba4` |
| 下载工具 | `luci-app-transmission` + Transmission daemon/CLI/remote/Web Control；aria2 已移除 |
| 主题 | argon，中文语言 |

其它服务类插件沿用 ponwrt 官方精简配置，均为关闭状态。

## 构建

在 Actions 页面手动运行 **Build XG-140G-MD**（`workflow_dispatch`），或：

```bash
curl -X POST \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Accept: application/vnd.github+json" \
  https://api.github.com/repos/wpm369079365/ponwrt-xg140g/actions/workflows/build.yml/dispatches \
  -d '{"ref":"main"}'
```

固件同时上传为 Artifact 和 GitHub Release。

## 文件结构

- `.config` — 由 ponwrt 官方 `configs/an7581.config` 收敛而来（单设备 + 所需插件）
- `diy-part1.sh` — feeds 更新前：补 140G-MD 设备别名
- `diy-part2.sh` — feeds 安装后：关 naive 出站、注入 LAN IP/密码
- `.github/workflows/build.yml` — 构建流程

## 刷机提醒

刷写光猫固件有风险，可能导致无法注册 PON 或丢失运营商数据。操作前务必备份原厂固件及 `bosa`/`ri` 校准分区。
