**简体中文** · [English](README.en.md)

# dropbox-setup

在 Linux 服务器上一键安装 Dropbox，并通过 `rsync` + `cron` 定时把指定的本地文件夹**单向同步**到 Dropbox 云盘。

## 简介

`setup_dropbox_sync.sh` 是一个交互式 Bash 脚本，提供菜单，可以完成以下工作：

1. 下载并运行 Dropbox 守护进程（`dropboxd`），关联你的 Dropbox 账户；
2. 生成同步脚本 `~/sync_to_dropbox.sh`，并添加定时任务（crontab）；
3. 启动 Dropbox 并立即执行一次同步。

脚本默认的本地目录是 `~/ceremonyclient/node/.config`（Quilibrium `ceremonyclient` 节点的配置目录），适合把节点配置备份到 Dropbox。你也可以改成任意目录。

## 功能

- 首次运行时自动安装依赖 `wget`、`rsync`（之后不再重复安装）
- 下载官方 Dropbox Linux 守护进程（x86_64）并引导你完成账户关联
- 安装 Dropbox 官方命令行工具 `dropbox`（`dropbox.py`）到 `/usr/local/bin/dropbox`
- 自定义本地源目录和 Dropbox 目标目录
- 三档同步频率：每 10 分钟、每 1 小时、每天 0 点
- 同步前检查 Dropbox 是否在运行，未运行时自动启动
- 添加开机自启任务，服务器重启后自动启动 Dropbox
- 重复运行选项 2 不会产生重复的定时任务（会替换旧任务）

## 环境要求

- 基于 Debian/Ubuntu 的 Linux 发行版（脚本使用 `apt-get`）
- x86_64（amd64）架构（脚本下载的是 `lnx.x86_64` 版本）
- root 权限（脚本会检查，非 root 直接退出）
- 已安装 `python3`（`dropbox` 命令行工具是 Python 脚本，脚本本身不会安装它）
- 可以访问 `dropbox.com` 的网络
- 一个 Dropbox 账户

## 安装与使用

### 1. 下载脚本

```bash
wget -O setup_dropbox_sync.sh https://raw.githubusercontent.com/darktuJJ/dropbox-setup/main/setup_dropbox_sync.sh
chmod +x setup_dropbox_sync.sh
```

### 2. 选项 1：运行 Dropbox 并关联账户

```bash
sudo ./setup_dropbox_sync.sh
# 输入 1
```

终端会输出一个关联链接，在浏览器中打开并登录 Dropbox 完成授权。终端显示关联成功（出现你的用户名）后，按 `Ctrl+C` 返回命令行。

完成后应生成 `~/Dropbox` 目录（以 root 运行时即 `/root/Dropbox`）。

### 3. 选项 2：配置同步脚本和定时任务

```bash
sudo ./setup_dropbox_sync.sh
# 输入 2
```

按提示依次输入：

| 提示 | 默认值 | 说明 |
| --- | --- | --- |
| 服务器默认目录 | `~/ceremonyclient/node/.config` | 要备份的本地目录 |
| Dropbox 默认目录 | `~/Dropbox/666` | 云盘中的目标目录。**多台服务器请为每台设置不同的目录**，否则会互相覆盖 |
| 同步频率 | — | `1` 每 10 分钟，`2` 每 1 小时，`3` 每天 0 点 |

该步骤会：

- 安装 `dropbox` 命令行工具到 `/usr/local/bin/dropbox`
- 创建 Dropbox 目标目录
- 生成同步脚本 `~/sync_to_dropbox.sh`
- 在当前用户（root）的 crontab 中写入两条任务：按所选频率执行的同步任务，以及开机自启任务 `@reboot /usr/local/bin/dropbox start`

重复运行选项 2 时，会先删除旧的同步任务和开机自启任务再重新写入，可用于修改目录或同步频率。crontab 中的其他任务不受影响。

### 4. 选项 3：启动 Dropbox 并立即同步一次

```bash
sudo ./setup_dropbox_sync.sh
# 输入 3
```

脚本会执行 `dropbox start`，然后运行一次 `~/sync_to_dropbox.sh`。

## 配置说明

### 同步方式

同步脚本使用的命令是：

```bash
rsync -av --delete $LOCAL_DIR/ $DROPBOX_DIR/
```

- **单向同步**：只从本地目录同步到 Dropbox 目录，不会把云端的改动同步回本地。
- **`--delete`**：本地已删除的文件，也会从 Dropbox 目标目录中删除。请不要在目标目录里存放其他文件。

### 修改配置

- **修改目录**：编辑 `~/sync_to_dropbox.sh` 中的 `LOCAL_DIR` 和 `DROPBOX_DIR`。
- **修改频率**：重新运行选项 2 即可；也可以执行 `crontab -e`，手动修改 `sync_to_dropbox.sh` 那一行的时间表达式。
- **查看定时任务**：`crontab -l`

### 常用 Dropbox 命令

```bash
dropbox status   # 查看运行和同步状态
dropbox start    # 启动 Dropbox
dropbox stop     # 停止 Dropbox
```

## 常见问题

**Q：选项 1 结束后提示“Dropbox 文件夹未创建”？**
A：说明账户关联没有完成。请重新运行选项 1，确认浏览器中授权成功、终端显示用户名后再按 `Ctrl+C`。

**Q：定时任务没有执行？**
A：先执行 `crontab -l`，确认存在 `sync_to_dropbox.sh` 那一行；再手动执行 `bash ~/sync_to_dropbox.sh`，查看输出中的报错。同步脚本已显式设置 `PATH`，cron 中也能找到 `dropbox` 命令。

**Q：服务器重启后 Dropbox 会自动启动吗？**
A：会。选项 2 会写入 `@reboot /usr/local/bin/dropbox start` 开机自启任务。

**Q：输入了菜单以外的内容会怎样？**
A：脚本会提示“无效的选择。退出。”并退出，不会执行任何操作。

**Q：`dropbox` 命令报错？**
A：请确认已安装 `python3`，例如 `apt-get install -y python3`。

**Q：支持 ARM 服务器或 CentOS 吗？**
A：目前不支持。脚本只下载 x86_64 版本的 Dropbox，且使用 `apt-get` 安装依赖。

**Q：想重新安装依赖？**
A：删除标志文件 `/root/.dropbox_setup_done` 后重新运行脚本即可。

## 卸载

```bash
dropbox stop
crontab -e                      # 删除包含 sync_to_dropbox.sh 的行，以及 @reboot /usr/local/bin/dropbox start 这一行
rm -f ~/sync_to_dropbox.sh /usr/local/bin/dropbox /root/.dropbox_setup_done
rm -rf ~/.dropbox-dist ~/.dropbox
# 如需删除本地的 Dropbox 同步文件夹（不会删除云端文件）：
# rm -rf ~/Dropbox
```

## 许可证

本项目采用 [MIT 许可证](LICENSE)。
