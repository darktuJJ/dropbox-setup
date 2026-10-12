[简体中文](README.md) · **English**

# dropbox-setup

Install Dropbox on a Linux server in one step, and use `rsync` + `cron` to periodically **one-way sync** a chosen local folder to Dropbox.

## Introduction

`setup_dropbox_sync.sh` is an interactive Bash script with a menu that does the following:

1. Downloads and runs the Dropbox daemon (`dropboxd`) and links your Dropbox account;
2. Generates a sync script `~/sync_to_dropbox.sh` and adds scheduled jobs (crontab);
3. Starts Dropbox and runs one sync immediately.

The script's default local folder is `~/ceremonyclient/node/.config` (the config folder of a Quilibrium `ceremonyclient` node), which makes it handy for backing up node configs to Dropbox. You can change it to any folder.

## Features

- Installs the dependencies `wget` and `rsync` automatically on first run (not repeated afterwards)
- Downloads the official Dropbox Linux daemon (x86_64) and guides you through account linking
- Installs the official Dropbox CLI `dropbox` (`dropbox.py`) to `/usr/local/bin/dropbox`
- Custom local source folder and Dropbox target folder
- Three sync frequencies: every 10 minutes, every hour, daily at 00:00
- Checks whether Dropbox is running before syncing, and starts it if not
- Adds a startup job so Dropbox starts automatically after the server reboots
- Re-running option 2 does not create duplicate scheduled jobs (old jobs are replaced)

## Requirements

- A Debian/Ubuntu-based Linux distribution (the script uses `apt-get`)
- x86_64 (amd64) architecture (the script downloads the `lnx.x86_64` build)
- root privileges (the script checks and exits if not root)
- `python3` installed (the `dropbox` CLI is a Python script; the script does not install it)
- Network access to `dropbox.com`
- A Dropbox account

## Installation and Usage

### 1. Download the script

```bash
wget -O setup_dropbox_sync.sh https://raw.githubusercontent.com/darktuJJ/dropbox-setup/main/setup_dropbox_sync.sh
chmod +x setup_dropbox_sync.sh
```

### 2. Option 1: Run Dropbox and link your account

```bash
sudo ./setup_dropbox_sync.sh
# 输入 1
```

The terminal prints a link. Open it in a browser and sign in to Dropbox to authorize. Once the terminal shows the link succeeded (your username appears), press `Ctrl+C` to return to the shell.

Afterwards a `~/Dropbox` folder should exist (`/root/Dropbox` when run as root).

### 3. Option 2: Configure the sync script and scheduled jobs

```bash
sudo ./setup_dropbox_sync.sh
# 输入 2
```

Enter the following when prompted:

| Prompt | Default | Description |
| --- | --- | --- |
| Server folder | `~/ceremonyclient/node/.config` | Local folder to back up |
| Dropbox folder | `~/Dropbox/666` | Target folder in Dropbox. **Use a different folder for each server**, otherwise they overwrite each other |
| Sync frequency | — | `1` every 10 minutes, `2` every hour, `3` daily at 00:00 |

This step will:

- Install the `dropbox` CLI to `/usr/local/bin/dropbox`
- Create the Dropbox target folder
- Generate the sync script `~/sync_to_dropbox.sh`
- Write two jobs into the current user's (root) crontab: the sync job at the chosen frequency, and the startup job `@reboot /usr/local/bin/dropbox start`

When option 2 is run again, it first removes the old sync job and startup job and then writes them again, so you can use it to change folders or frequency. Other jobs in the crontab are not affected.

### 4. Option 3: Start Dropbox and sync once now

```bash
sudo ./setup_dropbox_sync.sh
# 输入 3
```

The script runs `dropbox start`, then runs `~/sync_to_dropbox.sh` once.

## Configuration

### How syncing works

The sync script uses this command:

```bash
rsync -av --delete $LOCAL_DIR/ $DROPBOX_DIR/
```

- **One-way sync**: only syncs from the local folder to the Dropbox folder; changes in the cloud are not synced back.
- **`--delete`**: files deleted locally are also deleted from the Dropbox target folder. Do not keep other files in the target folder.

### Changing settings

- **Change folders**: edit `LOCAL_DIR` and `DROPBOX_DIR` in `~/sync_to_dropbox.sh`.
- **Change frequency**: just run option 2 again; or run `crontab -e` and edit the schedule on the `sync_to_dropbox.sh` line by hand.
- **View scheduled jobs**: `crontab -l`

### Common Dropbox commands

```bash
dropbox status   # 查看运行和同步状态
dropbox start    # 启动 Dropbox
dropbox stop     # 停止 Dropbox
```

## FAQ

**Q: After option 1 it says "Dropbox 文件夹未创建" (Dropbox folder not created)?**
A: Account linking did not finish. Run option 1 again, and only press `Ctrl+C` after the browser authorization succeeds and the terminal shows your username.

**Q: The scheduled job doesn't run?**
A: First run `crontab -l` and confirm the `sync_to_dropbox.sh` line exists; then run `bash ~/sync_to_dropbox.sh` manually and check the output for errors. The sync script sets `PATH` explicitly, so the `dropbox` command is found under cron too.

**Q: Will Dropbox start automatically after the server reboots?**
A: Yes. Option 2 writes the startup job `@reboot /usr/local/bin/dropbox start`.

**Q: What happens if I enter something not on the menu?**
A: The script prints "无效的选择。退出。" (invalid choice, exiting) and exits without doing anything.

**Q: The `dropbox` command errors out?**
A: Make sure `python3` is installed, e.g. `apt-get install -y python3`.

**Q: Are ARM servers or CentOS supported?**
A: Not currently. The script only downloads the x86_64 build of Dropbox and uses `apt-get` to install dependencies.

**Q: How do I reinstall the dependencies?**
A: Delete the flag file `/root/.dropbox_setup_done` and run the script again.

## Uninstall

```bash
dropbox stop
crontab -e                      # 删除包含 sync_to_dropbox.sh 的行，以及 @reboot /usr/local/bin/dropbox start 这一行
rm -f ~/sync_to_dropbox.sh /usr/local/bin/dropbox /root/.dropbox_setup_done
rm -rf ~/.dropbox-dist ~/.dropbox
# 如需删除本地的 Dropbox 同步文件夹（不会删除云端文件）：
# rm -rf ~/Dropbox
```

## License

This repository does not currently include a license file. If you want it to be open source, consider adding a `LICENSE` (e.g. MIT).
