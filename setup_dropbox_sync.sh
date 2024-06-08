#!/bin/bash

# 确保以 root 身份运行此脚本
if [ "$(id -u)" -ne 0 ]; then
  echo "请以 root 身份运行此脚本。"
  exit 1
fi

# 标志文件，用于记录是否已安装必要的软件包
FLAG_FILE="/root/.dropbox_setup_done"

if [ ! -f "$FLAG_FILE" ]; then
  # 更新包列表并安装必要的软件包（仅在第一次运行时执行）
  apt-get update
  apt-get install -y wget rsync

  # 创建标志文件
  touch "$FLAG_FILE"
fi

# 提供选项
echo "请选择操作："
echo "1) 运行 Dropbox 并关联账户"
echo "2) 配置同步脚本和定时任务"
echo "3) 启动 Dropbox 并立即同步一次"
echo "4) 退出脚本"
read -p "请输入选择 (1, 2, 3 或 4): " choice

if [ "$choice" -eq 1 ]; then
  # 下载并安装 Dropbox 守护进程
  cd "$HOME"
  wget -O - "https://www.dropbox.com/download?plat=lnx.x86_64" | tar xzf -

  # 运行 Dropbox 守护进程
  cd "$HOME/.dropbox-dist"
  ./dropboxd &

  # 提示用户完成浏览器中的 Dropbox 账户关联
  echo "请在浏览器中完成 Dropbox 账户关联。关联成功后会显示你的用户名，然后按 Ctrl+C 返回命令行。"
  wait $!

  # 检查 Dropbox 文件夹是否创建成功
  if [ ! -d "$HOME/Dropbox" ]; then
    echo "Dropbox 文件夹未创建。请确保已成功完成账户关联。"
    exit 1
  fi

  echo "Dropbox 账户关联成功。请重新运行脚本并选择选项 2 配置同步脚本和定时任务。"
  exit 0
fi

if [ "$choice" -eq 2 ]; then
  # 询问服务器默认目录和 Dropbox 默认目录
  read -p "请输入服务器默认目录,如无需求改，请直接按Enter  (默认: $HOME/ceremonyclient/node/.config): " LOCAL_DIR
  LOCAL_DIR=${LOCAL_DIR:-$HOME/ceremonyclient/node/.config}

  read -p "请输入 Dropbox 默认目录,每台服务器配置不同的目录，请自行修改 (默认: $HOME/Dropbox/666): " DROPBOX_DIR
  DROPBOX_DIR=${DROPBOX_DIR:-$HOME/Dropbox/666}

  # 安装 Dropbox CLI
  wget -O /usr/local/bin/dropbox "https://www.dropbox.com/download?dl=packages/dropbox.py"
  chmod +x /usr/local/bin/dropbox

  # 创建 Dropbox 同步文件夹
  mkdir -p "$DROPBOX_DIR"

  # 创建同步脚本
  SYNC_SCRIPT=$HOME/sync_to_dropbox.sh
  cat <<EOL > $SYNC_SCRIPT
#!/bin/bash

# 本地目录路径
LOCAL_DIR=$LOCAL_DIR

# Dropbox 目标目录路径
DROPBOX_DIR=$DROPBOX_DIR

# 输出当前时间
echo "Current date and time: \$(date)"

# 确保 Dropbox 目标目录存在
mkdir -p \$DROPBOX_DIR

# 检查 Dropbox 的运行状态
status=\$(dropbox status)
if [[ "\$status" == "Dropbox isn't running!" ]]; then
  echo "Dropbox isn't running. Starting Dropbox..."
  dropbox start
fi

# 使用 rsync 同步本地目录到 Dropbox 目录
rsync -av --delete \$LOCAL_DIR/ \$DROPBOX_DIR/
EOL

  # 赋予脚本执行权限
  chmod +x $SYNC_SCRIPT

  # 配置定时任务
  echo "请选择您希望同步的频率："
  echo "1) 每隔10分钟同步一次"
  echo "2) 每隔1小时同步一次"
  echo "3) 每隔1天同步一次"
  read -p "请输入选择 (1, 2 或 3): " sync_choice

  case $sync_choice in
    1)
      CRON_SCHEDULE="*/10 * * * *"
      ;;
    2)
      CRON_SCHEDULE="0 * * * *"
      ;;
    3)
      CRON_SCHEDULE="0 0 * * *"
      ;;
    *)
      echo "无效的选择。退出。"
      exit 1
      ;;
  esac

  (crontab -l 2>/dev/null; echo "$CRON_SCHEDULE $HOME/sync_to_dropbox.sh") | crontab -

  echo "配置完成。您的目录将根据您选择的频率同步到 Dropbox，请重新启动脚本运行选项3，启动dropbox，并完成第一次同步。"
  exit 0
fi

if [ "$choice" -eq 3 ]; then
  # 启动 Dropbox
  dropbox start

  # 检查 Dropbox 的运行状态
  status=$(dropbox status)
  if [[ "$status" == "Dropbox isn't running!" ]]; then
    echo "Dropbox isn't running. Starting Dropbox..."
    dropbox start
  fi

  # 立即执行一次同步
  SYNC_SCRIPT=$HOME/sync_to_dropbox.sh
  if [ -f $SYNC_SCRIPT ]; then
    echo "立即执行同步脚本..."
    bash $SYNC_SCRIPT
    echo "同步完成。"
  else
    echo "同步脚本不存在。请先配置同步脚本和定时任务（选项 2）。"
    exit 1
  fi
  exit 0
fi

if [ "$choice" -eq 4 ]; then
  echo "退出脚本。"
  exit 0
fi

echo "无效的选择。退出。"
exit 1
