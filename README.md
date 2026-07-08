# clash-for-ubuntu

Ubuntu 上用于管理 Clash/Mihomo 的命令行快捷工具。

## 功能

安装后会提供 `clash` 命令：

```bash
clash on                  # 开启 Mihomo 并设置 GNOME 系统代理
clash off                 # 关闭 Mihomo 并取消 GNOME 系统代理
clash restart             # 重启 Mihomo 并开启系统代理
clash status              # 查看 Mihomo systemd 用户服务状态
clash list                # 查看 PROXY 代理组节点列表
clash switch [节点编号]   # 切换到 clash list 中对应编号的节点
```

## 前提条件

本项目不包含你的订阅配置，也不包含 Mihomo 内核二进制文件。使用前请确认：

1. 已安装 Mihomo 内核到：

   ```bash
   ~/.local/bin/mihomo
   ```

2. 已准备好 Mihomo 配置目录：

   ```bash
   ~/.config/mihomo
   ```

3. 配置文件中启用了 External Controller，默认端口为 `9097`：

   ```yaml
   external-controller: 127.0.0.1:9097
   ```

4. 配置里有名为 `PROXY` 的代理组。

## 安装

```bash
git clone https://github.com/YOUR_GITHUB_USERNAME/clash-for-ubuntu.git
cd clash-for-ubuntu
./install.sh
source ~/.bash_aliases
```

如果你使用的是 zsh，可手动把 `shell/clash.sh` 加到 `~/.zshrc`。

## 卸载

```bash
./uninstall.sh
```

卸载脚本会移除本项目安装的脚本和 systemd 用户服务，但不会删除你的 Mihomo 配置和内核文件。

## 说明

- 默认代理端口：`7890`
- 默认 API 地址：`http://127.0.0.1:9097`
- 默认代理组：`PROXY`
- systemd 用户服务名：`mihomo.service`

如需修改这些默认值，可以编辑：

- `bin/proxy-on`
- `shell/clash.sh`
- `systemd/user/mihomo.service`
