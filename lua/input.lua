-- input.lua
hl.config({
	input = {
		kb_layout = "latam",
		follow_mouse = 1,
		sensitivity = 0,
		repeat_rate = 50,
		repeat_delay = 300,
		touchpad = {
			natural_scroll = true,
		},
	},
})

hl.gesture({
	fingers = 3,
	direction = "horizontal",
	action = "workspace",
})

hl.device({
	name = "epic-mouse-v1",
	sensitivity = -0.5,
})
