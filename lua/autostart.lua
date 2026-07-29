return [[
# =============================================================================
# AUTOSTART
# =============================================================================

exec-once = swayosd-server
exec-once = awww-daemon
exec-once = bash -c 'sleep 1; awww img /home/v3nom/Downloads/Wallpapers/kanji.jpg

exec-once = bluetoothctl power on
exec-once = bluetoothctl scan on

exec-once = bash ~/.config/waybar/scripts/launch.sh
exec-once = mako
exec-once = nm-applet --indicator

exec-once = /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
]]
