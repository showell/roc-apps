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
import cdx.Text

# CanvasViewport -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

zoom_ladder_up : Canvas.ViewPort, I64, I64, List(U8) -> List(U8)
zoom_ladder_up = |vp, i, n, acc| (if (i >= n) { acc } else { ({
	vp2 = Canvas.viewport_zoom_in(vp)
	zoom_ladder_up(vp2, (i + 1), n, List.concat(List.concat(acc, [2]), Text.show_int(vp2.vp_zoom)))
}) })

zoom_ladder_down : Canvas.ViewPort, I64, I64, List(U8) -> List(U8)
zoom_ladder_down = |vp, i, n, acc| (if (i >= n) { acc } else { ({
	vp2 = Canvas.viewport_zoom_out(vp)
	zoom_ladder_down(vp2, (i + 1), n, List.concat(List.concat(acc, [2]), Text.show_int(vp2.vp_zoom)))
}) })

roundtrip : Canvas.ViewPort, I64 -> List(U8)
roundtrip = |vp, wx| ({
	s = Canvas.vp_world_to_screen_x(vp, wx)
	w = Canvas.vp_screen_to_world_x(vp, s)
	List.concat(List.concat(List.concat(List.concat(List.concat(List.concat([27, 77], Text.show_int(wx)), [2, 19, 77]), Text.show_int(s)), [2, 32, 15, 24, 34, 77]), Text.show_int(w)), (if (w == wx) { [2, 16, 34] } else { [2, 49, 42, 45, 40] }))
})

# --- Entry ---

main! = |_args| {
	({
		vp = Canvas.viewport_new(50, 30, 400, 200)
		panned = Canvas.viewport_pan(vp, 7, (0 - 3))
		fitted = Canvas.viewport_zoom_fit(Canvas.viewport_pan(Canvas.viewport_zoom_in(vp), 99, 99))
		({
			line!(Text.printed(List.concat(List.concat(List.concat([16, 21, 17, 29, 17, 18, 69, 2, 36, 77], Text.show_int(Canvas.vp_world_to_screen_x(vp, 0))), [2, 30, 77]), Text.show_int(Canvas.vp_world_to_screen_y(vp, 0)))))
			line!(Text.printed(List.concat(List.concat(List.concat([31, 15, 18, 18, 13, 22, 69, 2, 36, 77], Text.show_int(Canvas.vp_world_to_screen_x(panned, 0))), [2, 30, 77]), Text.show_int(Canvas.vp_world_to_screen_y(panned, 0)))))
			line!(Text.printed(List.concat([21, 14, 2], roundtrip(vp, 0))))
			line!(Text.printed(List.concat([21, 14, 2], roundtrip(vp, 137))))
			line!(Text.printed(List.concat([21, 14, 2], roundtrip(vp, (0 - 137)))))
			line!(Text.printed(List.concat([21, 14, 2], roundtrip(panned, 137))))
			line!(Text.printed(List.concat([38, 16, 16, 26, 2, 17, 18, 2, 69, 2], zoom_ladder_up(Canvas.viewport_new(0, 0, 100, 100), 0, 16, [4, 3, 3]))))
			line!(Text.printed(List.concat([38, 16, 16, 26, 2, 16, 25, 14, 69, 2], zoom_ladder_down(Canvas.viewport_new(0, 0, 100, 100), 0, 10, [4, 3, 3]))))
			line!(Text.printed(List.concat(List.concat(List.concat(List.concat(List.concat([28, 17, 14, 69, 2, 38, 16, 16, 26, 77], Text.show_int(fitted.vp_zoom)), [2, 31, 15, 18, 36, 77]), Text.show_int(fitted.vp_pan_x)), [2, 27, 77]), Text.show_int(fitted.vp_canvas_w))))
			line!(Text.printed(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat([24, 16, 18, 14, 15, 17, 18, 19, 69, 2, 7, 12, 77], (if Canvas.vp_contains(vp, 49, 100) { [40, 21, 25, 13] } else { [54, 15, 23, 19, 13] })), [2, 8, 3, 77]), (if Canvas.vp_contains(vp, 50, 100) { [40, 21, 25, 13] } else { [54, 15, 23, 19, 13] })), [2, 7, 7, 12, 77]), (if Canvas.vp_contains(vp, 449, 100) { [40, 21, 25, 13] } else { [54, 15, 23, 19, 13] })), [2, 7, 8, 3, 77]), (if Canvas.vp_contains(vp, 450, 100) { [40, 21, 25, 13] } else { [54, 15, 23, 19, 13] }))))
			line!(Text.printed(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat([19, 18, 15, 31, 2, 31, 16, 19, 69, 2, 3, 77], Text.show_int(Canvas.vp_snap_to_grid(0, 20))), [2, 12, 77]), Text.show_int(Canvas.vp_snap_to_grid(9, 20))), [2, 4, 3, 77]), Text.show_int(Canvas.vp_snap_to_grid(10, 20))), [2, 5, 8, 77]), Text.show_int(Canvas.vp_snap_to_grid(25, 20))), [2, 6, 8, 77]), Text.show_int(Canvas.vp_snap_to_grid(35, 20)))))
			line!(Text.printed(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat([19, 18, 15, 31, 2, 18, 13, 29, 69, 2, 73, 12, 77], Text.show_int(Canvas.vp_snap_to_grid((0 - 9), 20))), [2, 73, 4, 3, 77]), Text.show_int(Canvas.vp_snap_to_grid((0 - 10), 20))), [2, 73, 5, 8, 77]), Text.show_int(Canvas.vp_snap_to_grid((0 - 25), 20))), [2, 73, 6, 8, 77]), Text.show_int(Canvas.vp_snap_to_grid((0 - 35), 20)))))
			line!(Text.printed(List.concat([19, 18, 15, 31, 2, 29, 3, 2, 69, 2, 10, 77], Text.show_int(Canvas.vp_snap_to_grid(7, 0)))))
		})
	})
	Ok({})
}
