#!/bin/bash
# Set default theme to luci-theme-argon
uci set luci.main.mediaurlbase='/luci-static/argon'
uci commit luci

# LuCI language default: Simplified Chinese when available
uci set luci.main.lang='zh-cn'
uci commit luci

exit 0
