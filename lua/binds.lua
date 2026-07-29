local cfg = {
	binde = {
		-- APLICACIONES
		"ALT, return, exec, kitty",
		"ALT, S, exec, spotify",
		"SUPER, E, exec, nautilus",
		"SUPER SHIFT, D, exec, pkill rofi || rofi -show drun -theme ~/.config/rofi/style-3.rasi",
		"SUPER, W, exec, bash /home/v3nom/.config/hypr/scripts/wallrofi.sh",
		"ALT, F, exec, zen-browser",

		-- GESTIÓN VENTANAS
		"ALT, W, killactive,",
		"ALT, P, layoutmsg, togglepseudotile",
		"ALT, SPACE, layoutmsg, togglesplit",
		"ALT, F11, fullscreen, 0",
		"ALT, R, exec, ~/.config/waybar/scripts/launch.sh",
		"ALT SHIFT, R, exec, ~/.config/hypr/scripts/reload.sh",

		-- WORKSPACES TAB
		"ALT, X, workspace, +1",
		"ALT, less, workspace, -1",

		-- bluetooth o wifi
		"SUPER SHIFT, B, exec, ~/.config/rofi/scripts/bluetooth.sh",
		"SUPER SHIFT, W, exec, networkmanager_dmenu -dmenu 'rofi -dmenu -i -theme /home/v3nom/.config/rofi/style-3.rasi'",

		-- FOCUS
		"ALT, l, movefocus, l",
		"ALT, h, movefocus, r",
		"ALT, k, movefocus, u",
		"ALT, j, movefocus, d",

		-- RESIZE
		"ALT SHIFT, l, resizeactive, 30 0",
		"ALT SHIFT, h, resizeactive, -30 0",
		"ALT SHIFT, k, resizeactive, 0 -30",
		"ALT SHIFT, j, resizeactive, 0 30",

		-- SCROLL WORKSPACES
		"ALT, mouse_down, workspace, e+1",
		"ALT, mouse_up, workspace, e-1",

		-- SCREENSHOT
		", Print, exec, grim ~/Pictures/screenshot_$(date +%F_%T).png",
		'SHIFT, Print, exec, grim -g "$(slurp)" ~/Pictures/screenshot_$(date +%F_%T).png',
	},

	bind = {
		-- OPACIDAD
		"ALT, O, exec, hyprctl keyword decoration:active_opacity 1.0 && hyprctl keyword decoration:inactive_opacity 1.0",
		"ALT SHIFT, O, exec, hyprctl keyword decoration:active_opacity 1.00 && hyprctl keyword decoration:inactive_opacity 0.90",

		-- LOCK / LOGOUT
		"SUPER, Escape, exec, wlogout --protocol layer-shell -b 3 --css ~/.config/wlogout/style.css --layout ~/.config/wlogout/layout",
		"SUPER, L, exec, hyprlock",

		-- FLOATING
		"ALT, V, togglefloating",
		"CTRL, TAB, alterzorder, bottom",
		-- "CTRL, TAB, alterzorder, top",

		-- SCREENSHOT REGIÓN
		'SUPER SHIFT, S, exec, grim -g "$(slurp)" - | wl-copy',

		-- VOLUMEN F8 / F9 / F7
		", F9, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+",
		", F8, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-",
		", F7, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle",

		-- VOLUMEN MULTIMEDIA DELL
		", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+",
		", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-",
		", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle",

		-- BRILLO F10 / F11
		", F11, exec, brightnessctl set 5%+",
		", F10, exec, brightnessctl set 5%-",

		-- BRILLO MULTIMEDIA DELL
		", XF86MonBrightnessUp, exec, brightnessctl set 5%+",
		", XF86MonBrightnessDown, exec, brightnessctl set 5%-",
	},

	bindm = {
		"ALT, mouse:272, movewindow",
		"ALT, mouse:273, resizewindow",
	},
}

return cfg
