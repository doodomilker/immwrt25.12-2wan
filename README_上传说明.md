# x86-64 ImmortalWrt 25.12.0 编译上传包

这版按你的要求做：**目标版本是 ImmortalWrt 25.12.0，但配置参照 haiibo/build-openwrt 的 24.10 `x86-64-immwrt.config` 照搬**。

## 核心逻辑

- 源码仓库：`immortalwrt/immortalwrt`
- 默认源码版本：`v25.12.0`
- 架构：`x86-64`
- 配置母版：haiibo 24.10 的 `configs/x86-64-immwrt.config`
- 原 haiibo 24.10 插件：保留
- 新增插件：Docker / Dockerman、PassWall2、SmartDNS
- 新增插件中文包：已加入
- 默认 LAN IP：`10.0.0.2`
- 默认 root 密码：`password`
- Docker 版默认 rootfs：`4096 MB`

## 上传方法

1. 解压这个压缩包。
2. 把解压后文件夹里的全部内容上传到 GitHub 仓库根目录。
3. 进入 GitHub 仓库的 `Actions`。
4. 选择 `build x86/64 openwrt`。
5. 点 `Run workflow`。
6. 默认参数不用改，直接运行。

默认会编译：

```text
repo_branch = v25.12.0
source      = immwrt
target      = x86-64
partsize    = 4096
```

如果你想跟随 25.12 分支最新提交，而不是固定 25.12.0 发布 tag，可以在运行 workflow 时把：

```text
v25.12.0
```

改成：

```text
openwrt-25.12
```

## 相对 haiibo 24.10 基准新增/改动

原 haiibo 24.10 里：

```text
# CONFIG_PACKAGE_luci-app-dockerman is not set
# CONFIG_PACKAGE_luci-app-passwall2 is not set
CONFIG_PACKAGE_luci-app-smartdns=m
# CONFIG_PACKAGE_docker-compose is not set
```

这版改成：

```text
CONFIG_PACKAGE_luci-app-dockerman=y
CONFIG_PACKAGE_luci-app-passwall2=y
CONFIG_PACKAGE_luci-app-smartdns=y
CONFIG_PACKAGE_smartdns=y
CONFIG_PACKAGE_docker=y
CONFIG_PACKAGE_dockerd=y
CONFIG_PACKAGE_docker-compose=y
CONFIG_PACKAGE_containerd=y
CONFIG_PACKAGE_runc=y
CONFIG_PACKAGE_luci-lib-docker=y
```

新增插件中文包：

```text
CONFIG_LUCI_LANG_zh_Hans=y
CONFIG_PACKAGE_luci-i18n-dockerman-zh-cn=y
CONFIG_PACKAGE_luci-i18n-passwall2-zh-cn=y
CONFIG_PACKAGE_luci-i18n-smartdns-zh-cn=y
```

同时保留并尽量加入原有常用插件中文包，例如：

```text
passwall
openclash
nikki
homeproxy
mosdns
alist
ddns-go
samba4
zerotier
ttyd
upnp
```

## 文件说明

```text
.github/workflows/build-x86-64-openwrt.yml   GitHub Actions 编译入口
configs/x86-64-immwrt.config                 haiibo 24.10 配置母版 + 新增插件
immwrt.sh                                    haiibo 风格编译脚本，默认拉 v25.12.0
scripts/init-settings.sh                     首次启动默认设置中文/argon
scripts/preset-clash-core.sh                 OpenClash Meta 核心预置
scripts/preset-adguard-core.sh               AdGuardHome 核心预置
scripts/preset-terminal-tools.sh             终端工具占位脚本
images/bg1.jpg                               argon 背景占位图，避免脚本缺文件失败
CHECKLIST_改动说明.md                        本包核对说明
```

## 注意

25.12.0 相比 24.10 有包名/内核/依赖变化，`make defconfig` 会自动忽略不存在的旧配置项。这个包的策略不是重写配置，而是：**24.10 稳定配置完整迁移到 25.12.0，只额外加你指定的 Docker、PassWall2、SmartDNS 和中文包。**
