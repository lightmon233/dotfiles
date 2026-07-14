#!/bin/bash

# 1. 延迟 0.5 秒启动，避开开机时 Hyprland 刚初始化的真空期
sleep 0.5

# 2. 严格的清理机制：脚本退出时自动杀掉后台的 cava 并清理临时文件
cleanup() {
    # 杀掉脚本产生的所有后台任务（即 cava）
    kill $(jobs -p) 2>/dev/null
    rm -f "/tmp/cava.fifo"
    rm -f "/tmp/waybar_cava_config"
}
trap cleanup EXIT INT TERM

# 检查并杀掉系统里可能残留的旧 cava 进程
if pgrep -x "cava" >/dev/null; then
    killall -9 cava 2>/dev/null
fi

bar="▁▂▃▄▅▆▇█"
dict="s/;//g;"

# 创建替换字符的“字典”
i=0
while [ $i -lt ${#bar} ]
do
    dict="${dict}s/$i/${bar:$i:1}/g;"
    i=$((i=i+1))
done

# 确保清理并重新创建 FIFO 管道
pipe="/tmp/cava.fifo"
rm -f $pipe
mkfifo $pipe

# 写入 cava 临时配置文件
config_file="/tmp/waybar_cava_config"
echo "
[general]
bars = 12
[output]
method = raw
raw_target = $pipe
data_format = ascii
ascii_max_range = 7
" > $config_file

# 3. 关键改动：使用 >/dev/null 2>&1 且将后台进程的 stdin 重定向为 /dev/null
# 这样能彻底防止 cava 在后台尝试去读写终端（防止产生 TTY 控制字符）
cava -p "$config_file" >/dev/null 2>&1 < /dev/null &

# 读取管道并输出
while read -r cmd; do
    echo "$cmd" | sed "$dict"
done < "$pipe"
