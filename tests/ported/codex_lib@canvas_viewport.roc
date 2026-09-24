# lib@canvas-viewport
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/lib@canvas-viewport.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     origin: x=250 y=130
#     panned: x=257 y=127
#     rt w=0 s=250 back=0 ok
#     rt w=137 s=387 back=137 ok
#     rt w=-137 s=113 back=-137 ok
#     rt w=137 s=394 back=137 ok
#     zoom in : 100 125 150 175 200 250 300 350 400 450 500 550 600 650 700 750 800
#     zoom out: 100 75 50 40 30 20 10 10 10 10 10
#     fit: zoom=100 panx=0 w=400
#     contains: 49=False 50=True 449=True 450=False
#     snap pos: 0=0 9=0 10=20 25=20 35=40
#     snap neg: -9=0 -10=-20 -25=-20 -35=-40
#     snap g0 : 7=7

app [main!] { cdx: "./codex/main.roc" }

import cdx.Canvas
import cdx.CceText

# CanvasViewport -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

zoom_ladder_up : Canvas.ViewPort, I64, I64, CceText -> CceText
zoom_ladder_up = |vp, i, n, acc| (if (i >= n) { acc } else { ({
	vp2 = Canvas.viewport_zoom_in(vp)
	zoom_ladder_up(vp2, (i + 1), n, CceText.concat(CceText.concat(acc, " "), CceText.show_int(vp2.vp_zoom)))
}) })

zoom_ladder_down : Canvas.ViewPort, I64, I64, CceText -> CceText
zoom_ladder_down = |vp, i, n, acc| (if (i >= n) { acc } else { ({
	vp2 = Canvas.viewport_zoom_out(vp)
	zoom_ladder_down(vp2, (i + 1), n, CceText.concat(CceText.concat(acc, " "), CceText.show_int(vp2.vp_zoom)))
}) })

roundtrip : Canvas.ViewPort, I64 -> CceText
roundtrip = |vp, wx| ({
	s : I64
	s = Canvas.vp_world_to_screen_x(vp, wx)
	w : I64
	w = Canvas.vp_screen_to_world_x(vp, s)
	CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat("w=", CceText.show_int(wx)), " s="), CceText.show_int(s)), " back="), CceText.show_int(w)), (if (w == wx) { " ok" } else { " LOST" }))
})

# --- Entry ---

main! = |_args| {
	({
		vp = Canvas.viewport_new(50, 30, 400, 200)
		panned = Canvas.viewport_pan(vp, 7, (0 - 3))
		fitted = Canvas.viewport_zoom_fit(Canvas.viewport_pan(Canvas.viewport_zoom_in(vp), 99, 99))
		({
			line!(CceText.printed(CceText.concat(CceText.concat(CceText.concat("origin: x=", CceText.show_int(Canvas.vp_world_to_screen_x(vp, 0))), " y="), CceText.show_int(Canvas.vp_world_to_screen_y(vp, 0)))))
			line!(CceText.printed(CceText.concat(CceText.concat(CceText.concat("panned: x=", CceText.show_int(Canvas.vp_world_to_screen_x(panned, 0))), " y="), CceText.show_int(Canvas.vp_world_to_screen_y(panned, 0)))))
			line!(CceText.printed(CceText.concat("rt ", roundtrip(vp, 0))))
			line!(CceText.printed(CceText.concat("rt ", roundtrip(vp, 137))))
			line!(CceText.printed(CceText.concat("rt ", roundtrip(vp, (0 - 137)))))
			line!(CceText.printed(CceText.concat("rt ", roundtrip(panned, 137))))
			line!(CceText.printed(CceText.concat("zoom in : ", zoom_ladder_up(Canvas.viewport_new(0, 0, 100, 100), 0, 16, "100"))))
			line!(CceText.printed(CceText.concat("zoom out: ", zoom_ladder_down(Canvas.viewport_new(0, 0, 100, 100), 0, 10, "100"))))
			line!(CceText.printed(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat("fit: zoom=", CceText.show_int(fitted.vp_zoom)), " panx="), CceText.show_int(fitted.vp_pan_x)), " w="), CceText.show_int(fitted.vp_canvas_w))))
			line!(CceText.printed(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat("contains: 49=", (if Canvas.vp_contains(vp, 49, 100) { "True" } else { "False" })), " 50="), (if Canvas.vp_contains(vp, 50, 100) { "True" } else { "False" })), " 449="), (if Canvas.vp_contains(vp, 449, 100) { "True" } else { "False" })), " 450="), (if Canvas.vp_contains(vp, 450, 100) { "True" } else { "False" }))))
			line!(CceText.printed(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat("snap pos: 0=", CceText.show_int(Canvas.vp_snap_to_grid(0, 20))), " 9="), CceText.show_int(Canvas.vp_snap_to_grid(9, 20))), " 10="), CceText.show_int(Canvas.vp_snap_to_grid(10, 20))), " 25="), CceText.show_int(Canvas.vp_snap_to_grid(25, 20))), " 35="), CceText.show_int(Canvas.vp_snap_to_grid(35, 20)))))
			line!(CceText.printed(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat("snap neg: -9=", CceText.show_int(Canvas.vp_snap_to_grid((0 - 9), 20))), " -10="), CceText.show_int(Canvas.vp_snap_to_grid((0 - 10), 20))), " -25="), CceText.show_int(Canvas.vp_snap_to_grid((0 - 25), 20))), " -35="), CceText.show_int(Canvas.vp_snap_to_grid((0 - 35), 20)))))
			line!(CceText.printed(CceText.concat("snap g0 : 7=", CceText.show_int(Canvas.vp_snap_to_grid(7, 0)))))
		})
	})
	Ok({})
}
