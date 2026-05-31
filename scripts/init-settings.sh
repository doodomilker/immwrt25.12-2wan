#!/bin/bash
# Set default theme to luci-theme-argon
uci set luci.main.mediaurlbase='/luci-static/argon'
uci commit luci

# LuCI language default: Simplified Chinese when available
uci set luci.main.lang='zh-cn'
uci commit luci

# === netdata 默认全功能 — 2026-05-31 ===
# haiibo 原编译里把 /etc/netdata/netdata.conf 大幅裁剪
# (cgroups/apps/python.d/health 全部 =no)，导致 dashboard 图表只剩一半。
# N100 8GB 内存毫无压力，删裁剪版让 netdata 自己跑全功能默认配置。
if [ -f /etc/netdata/netdata.conf ]; then
  cp /etc/netdata/netdata.conf /etc/netdata/netdata.conf.minimal
  rm /etc/netdata/netdata.conf
fi

exit 0
