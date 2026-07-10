return [[
# =============================================================================
# ENVIRONMENT VARIABLES
# =============================================================================

# -- Cursor --
env = XCURSOR_THEME,Adwaita
env = XCURSOR_SIZE,24

cursor {
    no_hardware_cursors = true
}

# -- Backends --
env = GDK_BACKEND,wayland,x11,*
env = QT_QPA_PLATFORM,wayland;xcb
env = SDL_VIDEODRIVER,wayland
env = CLUTTER_BACKEND,wayland

# -- XDG --
env = XDG_CURRENT_DESKTOP,Hyprland
env = XDG_SESSION_TYPE,wayland
env = XDG_SESSION_DESKTOP,Hyprland

# -- QT --
env = QT_QPA_PLATFORMTHEME,qt6ct
env = QT_AUTO_SCREEN_SCALE_FACTOR,1
env = QT_WAYLAND_DISABLE_WINDOWDECORATION,1

# -- NVIDIA --
env = GBM_BACKEND,nvidia-drm
env = LIBVA_DRIVER_NAME,nvidia
env = WLR_NO_HARDWARE_CURSORS,1
]]
