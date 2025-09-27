#!/bin/bash

unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
unset LD_PRELOAD

# goodies
export XKL_XMODMAP_DISABLE=1
export XDG_RUNTIME_DIR="/tmp/runtime-cuda"
export VK_ICD_FILENAMES="/etc/vulkan/icd.d/nvidia_icd.json"

# desktop configuration
export XDG_SESSION_TYPE=x11
export XDG_CURRENT_DESKTOP=XFCE
export DESKTOP_SESSION=xfce
export XAUTHORITY="$HOME/.Xauthority"  # fixed path

# display things
export DISPLAY=":12"
export USE_DISPLAY=""

BASHRC="$HOME/.bashrc"
echo "unset LD_PRELOAD=$CORRECT_PRELOAD" >> "$BASHRC"

[ -x /etc/vnc/xstartup ] && exec /etc/vnc/xstartup
[ -r "$HOME/.Xresources" ] && xrdb "$HOME/.Xresources"

xfconf-query -c xfce4-session -p /general/LockCommand -s ""
xfconf-query -c xfce4-session -p /general/LogoutCommand -s ""
xfconf-query -c xfce4-session -p /general/LockScreen -s false

xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/blank-on-ac -s 0
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/blank-on-battery -s 0
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/lock-on-suspend -s false

if [ -n "$USE_DISPLAY" ]; then
    exec vglrun -q 80 -d "$USE_DISPLAY" dbus-launch --exit-with-session startxfce4
else
    exec vglrun -q 80 dbus-launch --exit-with-session startxfce4
fi
