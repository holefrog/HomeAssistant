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
KEYCODE_HOME=3
KEYCODE_WAKEUP=224

run_vlc() {
    # 每次按需连接（静默执行，即便断线也能快速重连）
    adb connect "$1" >/dev/null 2>&1
    adb -s "$1" shell input keyevent "$KEYCODE_HOME"
    sleep 0.2
    # 将多次 adb 通信合并为一次执行，降低网络延迟开销
    adb -s "$1" shell "input keyevent $KEYCODE_WAKEUP && cmd activity start -f 0x10000000 -n '$VLC_ACTIVITY' -a '$INTENT_ACTION' -d '$RTSP_URL' --ez 'from_start' true"
}

close_vlc() {
    adb connect "$1" >/dev/null 2>&1
    adb -s "$1" shell input keyevent "$KEYCODE_HOME"
}

# 3. 根据传入的参数执行对应的操作
if [ "$1" = "show" ]; then
    # 使用 & 放入后台并发执行两台设备，最后 wait 同步退出
    run_vlc "$DEVICE_X08A" &
    run_vlc "$DEVICE_SONY_TV" &
    wait
elif [ "$1" = "close" ]; then
    close_vlc "$DEVICE_X08A" &
    close_vlc "$DEVICE_SONY_TV" &
    wait
fi
