-- animations.lua
hl.config({
	animations = { enabled = true },
})

hl.curve("myBezier", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })

-- easeOutQuint. Arranca rápido y frena largo, SIN el overshoot de myBezier
-- (que remata en 1.05 y por eso rebota). Esta es la que hace que la cinta del
-- layout scrolling se deslice en vez de teletransportarse.
hl.curve("smoothScroll", { type = "bezier", points = { { 0.23, 1.0 }, { 0.32, 1.0 } } })

hl.animation({ leaf = "windows", enabled = true, speed = 7, bezier = "myBezier" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 7, bezier = "default", style = "popin 80%" })

-- windowsMove = toda reubicación de ventana ya existente. Antes heredaba de
-- "windows" (speed 7 + myBezier), que llega al 90% del recorrido en el primer
-- 5% del tiempo: por eso se sentía rígido. Con speed 4 (400ms) y easeOutQuint
-- el movimiento se ve completo. Afecta también a dwindle, no solo a scrolling.
hl.animation({ leaf = "windowsMove", enabled = true, speed = 4, bezier = "smoothScroll" })
hl.animation({ leaf = "border", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 8, bezier = "default" })
hl.animation({ leaf = "fade", enabled = true, speed = 7, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 6, bezier = "default" })
