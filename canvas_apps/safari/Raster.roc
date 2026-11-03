## Raster paints a Safari frame into pixels, for a platform that can only show
## pixels (roc-ray as a framebuffer). It does what shapewire.js does with a
## canvas, without one: the sky and grass, the sun, then every command in
## paint order, all turned by the camera's roll about the screen's centre. A
## pixel is painted when its centre is inside; a polygon fills by the nonzero
## rule, as the canvas's does. There is no anti-aliasing. What a command's
## paint means, and the colour it gives a point, is Brush's. The pixels are
## 0xRRGGBB, row-major.
##
## The loops over pixels are `while` and `for` over a `var` list, and every
## store falls back with `crash`: a list threaded down a recursion, or named in
## a store's fallback, is copied on the next store (docs/roc-notes.md, "Speed
## and copying").
import Paint
import Sky
import lib.Brush
import SafariBrush
import Num_

Raster :: [].{

	## What a frame shows, in SafariRide's terms.
	Scene : {
		commands : List(Paint.DrawCmd),
		roll : F64,
		sky_top : I64,
		sky_horizon : I64,
		sun : Sky.SunPos,
	}

	## The cosine and sine of the camera's roll. The canvas translates to the
	## centre, rotates by minus the roll and translates back.
	View : { cos : F64, sin : F64 }

	Pt : { x : F64, y : F64 }

	## The frame: the sky and the grass, the sun, then every command.
	paint : Raster.Scene -> List(U32)
	paint = |scene| {
		view = view_of(scene.roll)
		sky = { top: Brush.opaque(scene.sky_top), horizon: Brush.opaque(scene.sky_horizon) }
		var $px = backdrop(view, sky)
		$px = if scene.sun.visible paint_sun($px, { view, sun: scene.sun }) else $px
		for draw_command in scene.commands {
			$px = command($px, { view, draw_command })
		}
		$px
	}

	view_of : F64 -> Raster.View
	view_of = |roll| { cos: F64.cos(roll), sin: F64.sin(roll) }

	## A disc at an alpha: the pixels whose centres are strictly inside.
	disc : List(U32), { view : Raster.View, center : Raster.Pt, radius : F64, color : Brush.Rgba } -> List(U32)
	disc = |pixels, { view, center, radius, color }| {
		on_screen = to_device(view, center)
		rows = pixels_between({ from: on_screen.y - radius, to: on_screen.y + radius, count: height })
		var $px = pixels
		var $row = rows.first
		while $row <= rows.last {
			dy = pixel_center($row) - on_screen.y
			half_squared = radius * radius - dy * dy
			$px = if half_squared > 0.0 {
				half = F64.sqrt(half_squared)
				span($px, { view, fill: Flat(color), row: $row, from: on_screen.x - half, to: on_screen.x + half })
			} else {
				$px
			}
			$row = $row + 1
		}
		$px
	}

	## A polygon, as scene coordinates x0, y0, x1, y1, ..., filled by the
	## nonzero rule.
	fill_polygon : List(U32), { view : Raster.View, pts : List(F64), fill : Brush.Fill } -> List(U32)
	fill_polygon = |pixels, { view, pts, fill }|
		if pts.len() // 2 < 3 {
			pixels
		} else {
			corners = pts.chunks_of(2).map(
				|pair|
					match pair {
						[x, y] => to_device(view, { x, y })
						_ => crash "Raster.fill_polygon: a polygon's coordinates come in pairs"
					},
			)
			edges = List.map2(corners, corners.drop_first(1).concat(corners.take_first(1)), |from, to| { from, to })
			first_y = (corners.first() ?? crash "Raster.fill_polygon: a polygon has corners").y
			rows = pixels_between({
				from: corners.fold(first_y, |top, corner| F64.min(top, corner.y)),
				to: corners.fold(first_y, |bottom, corner| F64.max(bottom, corner.y)),
				count: height,
			})
			var $px = pixels
			var $row = rows.first
			while $row <= rows.last {
				$px = fill_row($px, { view, fill, row: $row, crossings: row_crossings(edges, pixel_center($row)) })
				$row = $row + 1
			}
			$px
		}
}

## The screen's size in pixels.
width : I64
width = 960

height : I64
height = 600

## The screen's centre, which the roll turns about.
center : Raster.Pt
center = { x: I64.to_f64(width) / 2.0, y: I64.to_f64(height) / 2.0 }

## The horizon crosses the middle of the screen.
horizon : F64
horizon = center.y

## The grass starts a pixel above the horizon, which the blitter overlaps to
## beat a seam under the roll.
grass_top : F64
grass_top = horizon - 1.0

grass : U32
grass = 0x4a8f43

## Where a row of pixels crosses a polygon's edge, and the way the edge runs:
## 1 down the screen, -1 up it.
Crossing : { x : F64, winding : I64 }

## A polygon's edge, on the screen.
Edge : { from : Raster.Pt, to : Raster.Pt }

## A stretch of a row, from one crossing to the next.
RowSpan : { from : F64, to : F64 }

## A walk along a row's crossings: the winding so far, and the stretches
## found inside.
WindingWalk : { winding : I64, inside : List(RowSpan) }

# --- Geometry -----------------------------------------------------------------

to_device : Raster.View, Raster.Pt -> Raster.Pt
to_device = |view, { x, y }| {
	dx = x - center.x
	dy = y - center.y
	{ x: center.x + dx * view.cos + dy * view.sin, y: center.y - dx * view.sin + dy * view.cos }
}

to_scene : Raster.View, Raster.Pt -> Raster.Pt
to_scene = |view, { x, y }| {
	dx = x - center.x
	dy = y - center.y
	{ x: center.x + dx * view.cos - dy * view.sin, y: center.y + dx * view.sin + dy * view.cos }
}

## The centre of the pixel at `index` in its row or column.
pixel_center : I64 -> F64
pixel_center = |index| I64.to_f64(index) + 0.5

## The first pixel whose centre is at or past `x`.
first_pixel_past : F64 -> I64
first_pixel_past = |x| {
	bounded = if x < -100000.0 {
		-100000.0
	} else if x > 100000.0 {
		100000.0
	} else {
		x
	}
	F64.to_i64_wrap(Num_.ceil_real(bounded - 0.5))
}

## The pixels of a row or a column `count` long whose centres fall in
## [from, to): none when `first` is past `last`.
pixels_between : { from : F64, to : F64, count : I64 } -> { first : I64, last : I64 }
pixels_between = |{ from, to, count }| {
	first: I64.max(0, first_pixel_past(from)),
	last: I64.min(count - 1, first_pixel_past(to) - 1),
}

## Where the pixel at `row` and `column` is in the list.
pixel_index : { row : I64, column : I64 } -> U64
pixel_index = |{ row, column }| I64.to_u64_wrap(row * width + column)

# --- Pixels -------------------------------------------------------------------

byte : F64 -> U32
byte = |v| {
	n = F64.to_i64_wrap(v + 0.5)
	I64.to_u32_wrap(
		if n < 0 {
			0
		} else if n > 255 {
			255
		} else {
			n
		},
	)
}

pack : { r : F64, g : F64, b : F64 } -> U32
pack = |{ r, g, b }| {
	red = byte(r).shl_wrap(16)
	green = byte(g).shl_wrap(8)
	red.bitwise_or(green).bitwise_or(byte(b))
}

## One of a pixel's channels: 16 is red, 8 green and 0 blue.
channel : U32, U8 -> F64
channel = |pixel, shift| U32.to_f64(U32.bitwise_and(U32.shr_wrap(pixel, shift), 255))

## `src` over the opaque pixel `dst`.
over : U32, Brush.Rgba -> U32
over = |dst, src|
	if src.a >= 1.0 {
		pack({ r: src.r, g: src.g, b: src.b })
	} else if src.a <= 0.0 {
		dst
	} else {
		kept = 1.0 - src.a
		pack({
			r: src.r * src.a + channel(dst, 16) * kept,
			g: src.g * src.a + channel(dst, 8) * kept,
			b: src.b * src.a + channel(dst, 0) * kept,
		})
	}

blend : List(U32), { at : U64, color : Brush.Rgba } -> List(U32)
blend = |pixels, { at, color }| {
	dst = pixels.get(at) ?? crash "Raster.blend: a pixel off the screen"
	pixels.set(at, over(dst, color)) ?? crash "Raster.blend: a pixel off the screen"
}

# --- The backdrop and the sun -------------------------------------------------

## The sky band holds the top colour to a fifth of the way down to the
## horizon, then fades to the horizon colour; the grass is below it.
backdrop : Raster.View, { top : Brush.Rgba, horizon : Brush.Rgba } -> List(U32)
backdrop = |view, sky| {
	var $px = List.with_capacity(I64.to_u64_wrap(width * height))
	var $row = 0
	var $column = 0
	while $row < height {
		$column = 0
		while $column < width {
			y = to_scene(view, { x: pixel_center($column), y: pixel_center($row) }).y
			pixel = if y >= grass_top {
				grass
			} else {
				t = Brush.clamp01(y / horizon)
				color = if t <= 0.2 {
					sky.top
				} else {
					Brush.mix(sky.top, sky.horizon, (t - 0.2) / 0.8)
				}
				pack({ r: color.r, g: color.g, b: color.b })
			}
			$px = $px.append(pixel)
			$column = $column + 1
		}
		$row = $row + 1
	}
	$px
}

## The sun's glow fades through these from its inner radius to its outer.
glow : { inner : Brush.Rgba, middle : Brush.Rgba, outer : Brush.Rgba }
glow = {
	inner: { r: 255.0, g: 201.0, b: 128.0, a: 0.85 },
	middle: { r: 255.0, g: 150.0, b: 92.0, a: 0.32 },
	outer: { r: 255.0, g: 150.0, b: 92.0, a: 0.0 },
}

## A warm glow and then the disc, both clipped to the sky, before the
## commands, so the mountains set the sun behind them.
paint_sun : List(U32), { view : Raster.View, sun : Sky.SunPos } -> List(U32)
paint_sun = |pixels, { view, sun }|
	if sun.scale <= 0.0 {
		pixels
	} else {
		glow_inner = 8.0 * sun.scale
		glow_outer = 340.0 * sun.scale
		disc_inner = 4.0 * sun.scale
		disc_outer = 46.0 * sun.scale
		disc_core = Brush.opaque(0xffe6a3)
		disc_rim = Brush.opaque(0xff9d5c)
		screen_width = I64.to_f64(width)
		on_screen = to_device(view, { x: sun.x, y: sun.y })
		rows = pixels_between({ from: on_screen.y - glow_outer, to: on_screen.y + glow_outer, count: height })
		columns = pixels_between({ from: on_screen.x - glow_outer, to: on_screen.x + glow_outer, count: width })
		var $px = pixels
		var $row = rows.first
		var $column = columns.first
		while $row <= rows.last {
			$column = columns.first
			while $column <= columns.last {
				p = to_scene(view, { x: pixel_center($column), y: pixel_center($row) })
				$px = if p.x >= 0.0 and p.x < screen_width and p.y >= 0.0 and p.y < horizon {
					at = pixel_index({ row: $row, column: $column })
					distance = F64.sqrt((p.x - sun.x) * (p.x - sun.x) + (p.y - sun.y) * (p.y - sun.y))
					t = Brush.clamp01((distance - glow_inner) / (glow_outer - glow_inner))
					glow_color = if t <= 0.4 {
						Brush.mix(glow.inner, glow.middle, t / 0.4)
					} else {
						Brush.mix(glow.middle, glow.outer, (t - 0.4) / 0.6)
					}
					lit = blend($px, { at, color: glow_color })
					if distance < disc_outer {
						toward_rim = Brush.clamp01((distance - disc_inner) / (disc_outer - disc_inner))
						blend(lit, { at, color: Brush.mix(disc_core, disc_rim, toward_rim) })
					} else {
						lit
					}
				} else {
					$px
				}
				$column = $column + 1
			}
			$row = $row + 1
		}
		$px
	}

# --- The commands -------------------------------------------------------------

command : List(U32), { view : Raster.View, draw_command : Paint.DrawCmd } -> List(U32)
command = |pixels, { view, draw_command }|
	if draw_command.tag == Paint.beacon_tag {
		match draw_command.geom {
			[x, y, radius] => {
				color = Brush.opaque(draw_command.color)
				Raster.disc(pixels, { view, center: { x, y }, radius, color: { ..color, a: draw_command.strength } })
			}
			_ => crash "Raster.command: a beacon's geometry is its x, y and radius"
		}
	} else {
		fill = SafariBrush.of_command(draw_command)
		match fill {
			Skip => pixels
			Flat(_) | Span(_) | Radial(_) | Linear(_) | Ellipse(_) | Glow(_) =>
				Raster.fill_polygon(pixels, { view, pts: draw_command.pts, fill })
			}
	}

## Where the row at `y` crosses the polygon's edges, left to right. An edge
## holds its upper end and not its lower.
row_crossings : List(Edge), F64 -> List(Crossing)
row_crossings = |edges, y|
	edges.join_map(|edge| crossing(edge, y)).sort_with(
		|a, b| if a.x < b.x {
			Before
		} else if a.x > b.x {
			After
		} else {
			Same
		},
	)

crossing : Edge, F64 -> List(Crossing)
crossing = |{ from, to }, y| {
	x = from.x + (y - from.y) * (to.x - from.x) / (to.y - from.y)
	if from.y <= y and y < to.y {
		[{ x, winding: 1 }]
	} else if to.y <= y and y < from.y {
		[{ x, winding: -1 }]
	} else {
		[]
	}
}

## One row of a polygon: the spans between its crossings where the winding is
## not zero.
fill_row : List(U32), { view : Raster.View, fill : Brush.Fill, row : I64, crossings : List(Crossing) } -> List(U32)
fill_row = |pixels, { view, fill, row, crossings }| {
	var $px = pixels
	for inside in inside_spans(crossings) {
		$px = span($px, { view, fill, row, from: inside.from, to: inside.to })
	}
	$px
}

## The stretches between neighbouring crossings, left to right, where the
## winding is not zero.
inside_spans : List(Crossing) -> List(RowSpan)
inside_spans = |crossings| {
	neighbours = List.map2(crossings, crossings.drop_first(1), |enter, leave| { enter, leave })
	neighbours.fold({ winding: 0, inside: [] }, walk_crossing).inside
}

## The walk after one more pair of neighbouring crossings.
walk_crossing : WindingWalk, { enter : Crossing, leave : Crossing } -> WindingWalk
walk_crossing = |so_far, { enter, leave }| {
	winding = so_far.winding + enter.winding
	inside =
		if winding == 0 {
			so_far.inside
		} else {
			so_far.inside.append({ from: enter.x, to: leave.x })
		}
	{ winding, inside }
}

## The pixels of `row` whose centres fall in [from, to).
span : List(U32), { view : Raster.View, fill : Brush.Fill, row : I64, from : F64, to : F64 } -> List(U32)
span = |pixels, { view, fill, row, from, to }| {
	columns = pixels_between({ from, to, count: width })
	y = pixel_center(row)
	var $px = pixels
	var $column = columns.first
	while $column <= columns.last {
		at = pixel_index({ row, column: $column })
		color = match fill {
			Flat(flat) => flat
			Skip | Span(_) | Radial(_) | Linear(_) | Ellipse(_) | Glow(_) => {
				p = to_scene(view, { x: pixel_center($column), y })
				Brush.shade(fill, p.x, p.y)
			}
		}
		$px = blend($px, { at, color })
		$column = $column + 1
	}
	$px
}
