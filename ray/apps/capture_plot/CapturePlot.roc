# CapturePlot -- roc-ray's `examples/capture_plot`, as a Movie.
#
# **A SECOND MOVIE, AND SOMEBODY ELSE'S.** Safari drove the seam out and would
# have agreed with anything it was asked; this one was written by Luke Boswell
# for roc-ray, with no idea this existed, which is the only honest test of an
# abstraction. Its own description is "renders an animated bar chart to
# captures/plot.webm, then exits" -- a movie by its author's definition, not
# just ours -- and it takes no input at all.
#
# **WHAT IT COULD NOT SAY, and these are findings rather than complaints:**
#
#   - TEXT. It draws a title, a status line and a frame count, and nothing in
#     this vocabulary drew a glyph. `Font.roc` does now: a letter is a few
#     strokes and a stroke is a polygon, so the words need no new shape and no
#     new wire. It is a plotter's alphabet rather than a typeface.
#   - A LINE WITH A THICKNESS, and A ROUNDED RECTANGLE. Both were missing and
#     both are here now: `Shapes.line` and `Shapes.rounded_rect` build the
#     polygons they always were, so no painter had to learn a new shape.
#
# Everything else went across as it was: a vertical gradient is a Linear brush,
# a bar is a Rect, the pulsing dot is a Disc.
#
# **AND IT MOVES BY A FIXED STEP**, which is what our `advance` is. That is not
# a compromise: its recording is `FixedStep` at 25 fps precisely so every
# captured frame advances the same amount, which is the same reason a movie
# here steps rather than reading a clock.
import Movie
import Shapes
import Brush
import Trig
import Font

CapturePlot :: [].{
	# How far into the animation it is. Their model also carries the recording's
	# progress and two prepared labels; a recording is the host's business and
	# the labels need a font.
	Model : { elapsed : F64 }

	# Their window, and so their coordinates.
	width : F64
	width = 640.0
	height : F64
	height = 360.0

	# Their recording runs at 25 frames a second with a fixed step.
	step : F64
	step = 1.0 / 25.0

	# 75 frames, after which their host finalizes the file and the app exits.
	# Ours has no way to say "and now I am done", which is the fourth finding.
	recorded_frames : F64
	recorded_frames = 75.0

	bar_count : I64
	bar_count = 12

	movie : Movie.Movie(CapturePlot.Model)
	movie = {
		size: { width: width, height: height },
		init: { elapsed: 0.0 },
		advance: |m| { elapsed: m.elapsed + step },
		back: |m| { elapsed: if m.elapsed > step { m.elapsed - step } else { 0.0 } },
		# There are no scenes; a skip is a second of them.
		skip: |m| { elapsed: m.elapsed + 1.0 },
		frame: |m| { shapes: shapes(m), roll: 0.0 },
		clock: |m| m.elapsed * 25.0,
		title: "RocRay Capture: Plot",
		stem: "capture-plot",
	}

	# ── their colours, as they wrote them ───────────────────────────────────
	bg_top : Brush.Rgba
	bg_top = Brush.opaque(0x0b0e17)
	bg_bottom : Brush.Rgba
	bg_bottom = Brush.opaque(0x171f31)
	ink : Brush.Rgba
	ink = Brush.opaque(0xe8ecf5)
	muted : Brush.Rgba
	muted = Brush.opaque(0x8a97b0)
	grid : Brush.Rgba
	grid = Brush.with_alpha(0x1affffff)
	axis : Brush.Rgba
	axis = Brush.opaque(0x39445c)
	track : Brush.Rgba
	track = Brush.opaque(0x232c3f)
	rec : Brush.Rgba
	rec = Brush.opaque(0xef7d7d)
	bar_top : Brush.Rgba
	bar_top = Brush.opaque(0x7fd6d0)
	bar_bottom : Brush.Rgba
	bar_bottom = Brush.opaque(0x4667b4)
	bar_cap : Brush.Rgba
	bar_cap = Brush.opaque(0xbdf0ea)

	# A vertical two-stop gradient over a box, which is their
	# `rectangle_gradient_v`.
	down : Brush.Rgba, Brush.Rgba, F64, F64 -> Brush.Fill
	down = |c0, c1, y0, y1|
		Linear({ c0: c0, c1: c1, o0: 0.0, o1: 1.0, ax: 0.0, ay: y0, dx: 0.0, dy: y1 - y0, len2: (y1 - y0) * (y1 - y0) })

	shapes : CapturePlot.Model -> List(Shapes.Shape)
	shapes = |m| {
		baseline = height - 44.0
		var $out = List.with_capacity(I64.to_u64_wrap(6 + 4 * bar_count))
		$out = List.append($out, Rect({ x: 0.0, y: 0.0, w: width, h: height, fill: down(bg_top, bg_bottom, 0.0, height) }))

		# Their title, and the status line beside the indicator.
		$out = List.concat($out, Font.text(Str.to_utf8("Recording a plot"), 32.0, 26.0, 18.0, ink))
		$out = List.concat($out, Font.text(Str.to_utf8("captures/plot.webm"), 52.0, 58.0, 11.0, muted))

		# The recording indicator, pulsing on the same step the frames are
		# captured on.
		pulse = 4.0 + 2.0 * sin(m.elapsed * 6.0)
		$out = List.append($out, Disc({ x: 38.0, y: 66.0, r: pulse, fill: Flat(rec), clip: Anywhere }))

		# How much of the recording is written. Their radius is not available,
		# so these are square.
		frames = F64.to_i64_wrap(m.elapsed * 25.0)
		share = min(I64.to_f64(frames) / recorded_frames, 1.0)
		$out = List.concat(
			$out,
			Font.text(
				Str.to_utf8("${I64.to_str(frames)} / ${I64.to_str(F64.to_i64_wrap(recorded_frames))} frames"),
				width - 232.0,
				34.0,
				10.0,
				muted,
			),
		)
		$out = List.append($out, Shapes.rounded_rect(width - 232.0, 56.0, 200.0, 6.0, 0.5, 6, Flat(track)))
		$out = if share > 0.0 {
			List.append($out, Shapes.rounded_rect(width - 232.0, 56.0, 200.0 * share, 6.0, 0.5, 6, Flat(rec)))
		} else {
			$out
		}

		# Four gridlines behind the bars, so a duplicated frame is easier to
		# spot, and the axis under them.
		var $k = 1
		while $k <= 4 {
			$out = List.append($out, Shapes.line(32.0, baseline - I64.to_f64($k) * 42.0, width - 32.0, baseline - I64.to_f64($k) * 42.0, 1.0, Flat(grid)))
			$k = $k + 1
		}
		$out = List.append($out, Shapes.line(32.0, baseline, width - 32.0, baseline, 1.5, Flat(axis)))

		# The bars: a travelling wave, so every frame differs.
		var $i = 0
		while $i < bar_count {
			offset = I64.to_f64($i)
			phase = m.elapsed * 2.2 + offset * 0.5
			bar_h = 40.0 + 90.0 * (1.0 + sin(phase)) / 2.0
			x = 40.0 + offset * 46.0
			top = baseline - bar_h
			$out = List.append($out, Rect({ x: x, y: top, w: 34.0, h: bar_h, fill: down(bar_top, bar_bottom, top, top + bar_h) }))
			$out = List.append($out, Rect({ x: x, y: top, w: 34.0, h: 3.0, fill: Flat(bar_cap) }))
			$out = List.append($out, Disc({ x: x + 17.0, y: top - 10.0, r: 2.5, fill: Flat({ ..bar_cap, a: 150.0 / 255.0 }), clip: Anywhere }))
			$i = $i + 1
		}
		$out
	}

	min : F64, F64 -> F64
	min = |a, b| if a < b { a } else { b }

	# Their `F32.sin`. Safari's own Trig is the one every other frame in this
	# repository is drawn with, so the wave is the same wave.
	sin : F64 -> F64
	sin = |x| Trig.r_sin(x)
}
