-- layouts.lua
hl.config({
	dwindle = {
		preserve_split = true,
	},
	master = {
		new_status = "master",
	},

	-- Layout scrolling (tipo PaperWM). Desde Hyprland 0.54 viene en el core,
	-- NO es plugin: no hay que instalar ni cargar nada.
	-- Aquí solo se configura; se activa por workspace con SUPER+SPACE (ver binds.lua).
	scrolling = {
		-- Ancho de cada columna, fracción de la pantalla. 0.5 = media pantalla.
		column_width = 0.5,

		-- Si solo hay una columna en el workspace, que ocupe todo el ancho.
		fullscreen_on_one_column = true,

		-- Al enfocar una columna, cómo traerla a la vista. 0 = centrar, 1 = encajar.
		focus_fit_method = 1,

		-- Que la cinta se mueva sola para seguir a la ventana enfocada.
		follow_focus = true,

		-- Fracción mínima visible de la ventana para que el foco la siga.
		follow_min_visible = 0.4,

		-- Anchos que cicla "colresize +conf" / "-conf" (ALT+SHIFT+p en binds.lua).
		explicit_column_widths = "0.333, 0.5, 0.667, 1.0",

		-- Hacia dónde crece la cinta y aparecen las ventanas nuevas.
		direction = "right",

		-- Que el foco y el intercambio de columnas den la vuelta en los extremos.
		wrap_focus = true,
		wrap_swapcol = true,
	},
})
