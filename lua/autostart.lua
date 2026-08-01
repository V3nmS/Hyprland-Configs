-- autostart.lua
hl.on("hyprland.start", function()
	hl.exec_cmd("swayosd-server")
	hl.exec_cmd("awww-daemon")
	hl.exec_cmd("bash -c 'sleep 1; awww img /home/v3nom/Downloads/Wallpapers/zombies.png
	hl.exec_cmd("bluetoothctl power on")
	hl.exec_cmd("bluetoothctl scan on")
	hl.exec_cmd("bash ~/.config/waybar/scripts/launch.sh")
	hl.exec_cmd("mako")
	hl.exec_cmd("nm-applet --indicator")
	hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
end)
