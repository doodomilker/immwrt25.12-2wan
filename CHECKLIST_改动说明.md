# 改动核对说明

## 目标

- 目标源码版本：ImmortalWrt `v25.12.0`
- 配置基准：haiibo/build-openwrt 的 `configs/x86-64-immwrt.config`
- 新增：Docker / Dockerman、PassWall2、SmartDNS
- 新增插件中文包：已加入

## 关键核对

### 1. 版本不是 24.10

`immwrt.sh` 已改为：

```bash
REPO_BRANCH="${REPO_BRANCH:-v25.12.0}"
```

workflow 默认输入也是：

```text
repo_branch: v25.12.0
```

所以默认编译的是 ImmortalWrt 25.12.0 tag，不是 24.10。

### 2. 配置仍然按 haiibo 24.10 照搬

`configs/x86-64-immwrt.config` 保留 haiibo 原 24.10 的 x86-64 目标、固件类型、应用、主题、IPv6、基础工具等配置。

### 3. 只新增/强化以下内容

```text
luci-app-dockerman
luci-lib-docker
docker
dockerd
docker-compose
containerd
runc
luci-app-passwall2
luci-app-smartdns
smartdns
```

### 4. 中文包

新增插件中文包已写入：

```text
CONFIG_PACKAGE_luci-i18n-dockerman-zh-cn=y
CONFIG_PACKAGE_luci-i18n-passwall2-zh-cn=y
CONFIG_PACKAGE_luci-i18n-smartdns-zh-cn=y
```

LuCI 简体中文：

```text
CONFIG_LUCI_LANG_zh_Hans=y
CONFIG_PACKAGE_luci-i18n-base-zh-cn=y
```

## 运行建议

第一次编译建议不改参数，直接运行。Docker 固件建议保留默认 `partsize=4096`。
