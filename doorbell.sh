#!/bin/sh

# 1. 检查并安装 adb (Home Assistant 容器为 Alpine 环境)
if ! command -v adb >/dev/null 2>&1; then
    apk add -q --no-cache android-tools
fi

# 2. 定义常量配置
DEVICE_X08A="192.168.50.180:5555"
DEVICE_SONY_TV="192.168.50.220:5555"
RTSP_URL="rtsp://admin:XH*8eSPx@192.168.50.190:554/Preview_01_sub"
VLC_ACTIVITY="org.videolan.vlc/org.videolan.vlc.gui.video.VideoPlayerActivity"
INTENT_ACTION="android.intent.action.VIEW"
KEYCODE_BACK=4

# 连接设备
adb connect "$DEVICE_X08A"
adb connect "$DEVICE_SONY_TV"

run_vlc() {
    # 添加了 -f 0x10000000 (FLAG_ACTIVITY_NEW_TASK) 确保以全新独立全屏任务启动
    adb -s "$1" shell cmd activity start -f 0x10000000 -n "$VLC_ACTIVITY" -a "$INTENT_ACTION" -d "$RTSP_URL" --ez "from_start" true
}

close_vlc() {
    adb -s "$1" shell input keyevent "$KEYCODE_BACK"
}

# 3. 根据传入的参数执行对应的操作
if [ "$1" = "show" ]; then
    run_vlc "$DEVICE_X08A"
    run_vlc "$DEVICE_SONY_TV"
elif [ "$1" = "close" ]; then
    close_vlc "$DEVICE_X08A"
    close_vlc "$DEVICE_SONY_TV"
fi
