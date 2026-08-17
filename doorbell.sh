#!/bin/sh

# 1. 检查并安装 adb (Home Assistant 容器为 Alpine 环境)
if ! command -v adb >/dev/null 2>&1; then
    apk add -q --no-cache android-tools
fi

# 2. 定义常量配置
DEVICE_REOLINK="192.168.50.86:554"
DEVICE_X08A="192.168.50.180:5555"
DEVICE_SONY_TV="192.168.50.220:5555"
DEVICE_LENOVO_IDEA_TAB="192.168.50.160"
RTSP_URL="rtsp://admin:XH*8eSPx@${DEVICE_REOLINK}/Preview_01_sub"
RTSP_URL_MAIN="rtsp://admin:XH*8eSPx@${DEVICE_REOLINK}/Preview_01_main"
VLC_ACTIVITY="org.videolan.vlc/org.videolan.vlc.gui.video.VideoPlayerActivity"
INTENT_ACTION="android.intent.action.VIEW"
KEYCODE_HOME=3
KEYCODE_WAKEUP=224

run_vlc() {
    # $1: 设备地址  $2: RTSP URL（可选，默认用 RTSP_URL）
    URL="${2:-$RTSP_URL}"
    adb connect "$1" >/dev/null 2>&1
    # 先唤屏，再等摄像头处理完门铃事件（录制启动、推送通知等）后再建立 RTSP 连接
    adb -s "$1" shell "input keyevent $KEYCODE_HOME && input keyevent $KEYCODE_WAKEUP"
    sleep 3
    adb -s "$1" shell "cmd activity start -f 0x10000000 -n '$VLC_ACTIVITY' -a '$INTENT_ACTION' -d '$URL' --ez 'from_start' true"
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
    run_vlc "$DEVICE_LENOVO_IDEA_TAB" "$RTSP_URL_MAIN" &  # Lenovo 用主码流，避免 sub 流并发超限
    wait
elif [ "$1" = "close" ]; then
    close_vlc "$DEVICE_X08A" &
    close_vlc "$DEVICE_SONY_TV" &
    close_vlc "$DEVICE_LENOVO_IDEA_TAB" &
    wait
fi
