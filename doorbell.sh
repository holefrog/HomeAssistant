#!/bin/sh

# 1. 检查并安装 adb (Home Assistant 容器为 Alpine 环境)
if ! command -v adb >/dev/null 2>&1; then
    apk add -q --no-cache android-tools
fi

# 2. 定义常量配置
DEVICE="192.168.50.180:5555"
RTSP_URL="rtsp://admin:XH*8eSPx@192.168.50.190:554/Preview_01_sub"
VLC_ACTIVITY="org.videolan.vlc/org.videolan.vlc.gui.video.VideoPlayerActivity"
INTENT_ACTION="android.intent.action.VIEW"
KEYCODE_BACK=4

# 连接设备
adb connect "$DEVICE"

# 3. 根据传入的参数执行对应的操作
if [ "$1" = "show" ]; then
    adb -s "$DEVICE" shell cmd activity start -n "$VLC_ACTIVITY" -a "$INTENT_ACTION" -d "$RTSP_URL" --ez "from_start" true
elif [ "$1" = "close" ]; then
    adb -s "$DEVICE" shell input keyevent "$KEYCODE_BACK"
fi