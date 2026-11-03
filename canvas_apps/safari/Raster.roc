## Raster paints a Safari frame into pixels, for a platform that can only show
## pixels (roc-ray as a framebuffer). It does what shapewire.js does with a
## canvas, without one: the sky and grass, the sun, then every command in
## paint order, all turned by the camera's roll about the screen's centre. A
## pixel is painted when its centre is inside; a polygon fills by the nonzero
## rule, as the canvas's does. There is no anti-aliasing. What a command's
## paint means, and the colour it gives a point, is Brush's. The pixels are
## 0xRRGGBB, row-major.
##
## Every write lands in place: the pixels are a `var` list, and every store
## falls back with `crash`. A list threaded down a recursion, or named in a
## store's fallback, would be copied on the next store (docs/roc-notes.md,
## "Speed and copying").
import Paint
import Sky
import lib.Brush
import SafariBrush
import SafariShapes
import Screen
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
	Rotation : { cos : F64, sin : F64 }

	## A point in the scene, before the roll turns it onto the screen.
	ScenePoint := { x : F64, y : F64 }.{
		is_eq : _
	}

	## The frame: the sky and the grass, the sun, then every command.
	paint : Raster.Scene -> List(U32)
	paint = |scene| {
		rotation = rotation_of(scene.roll)
		sky = { top: Brush.opaque(scene.sky_top), horizon: Brush.opaque(scene.sky_horizon) }
		var $px = backdrop(rotation, sky)
		$px = if SafariShapes.is_sun_shown(scene.sun) paint_sun($px, { rotation, sun: scene.sun }) else $px
		for draw_command in scene.commands {
			$px = command($px, { rotation, draw_command })
		}
		$px
	}

	rotation_of : F64 -> Raster.Rotation
	rotation_of = |roll| { cos: F64.cos(roll), sin: F64.sin(roll) }

	## A disc at an alpha: the pixels whose centres are strictly inside.
	disc : List(U32), { rotation : Raster.Rotation, center : Raster.ScenePoint, radius : F64, color : Brush.Rgba } -> List(U32)
	disc = |pixels, { rotation, center, radius, color }| {
		on_screen = to_device(rotation, center)
		rows = pixels_between({ from: on_screen.y - radius, to: on_screen.y + radius, count: Screen.height_px })
		var $px = pixels
		for row in I64.until(rows.start, rows.end) {
			dy = pixel_center(row) - on_screen.y
			half_squared = radius * radius - dy * dy
			$px = if half_squared > 0.0 {
				half = F64.sqrt(half_squared)
				span($px, { rotation, fill: Flat(color), row, from: on_screen.x - half, to: on_screen.x + half })
			} else {
				$px
			}
		}
		$px
	}

	## A polygon, as scene coordinates x0, y0, x1, y1, ..., filled by the
	## nonzero rule.
	fill_polygon : List(U32), { rotation : Raster.Rotation, pts : List(F64), fill : Brush.Fill } -> List(U32)
	fill_polygon = |pixels, { rotation, pts, fill }| {
		corners = pts.chunks_of(2).map(
			|pair|
				match pair {
					[x, y] => to_device(rotation, Raster.ScenePoint.({ x, y }))
					_ => crash "Raster.fill_polygon: a polygon's coordinates come in pairs"
				},
		)
		match corners {
			[first, _, _, ..] => {
				edges = corners.map2(corners.drop_first(1).concat(corners.take_first(1)), |from, to| { from, to })
				rows = pixels_between({
					from: corners.fold(first.y, |top, corner| F64.min(top, corner.y)),
					to: corners.fold(first.y, |bottom, corner| F64.max(bottom, corner.y)),
					count: Screen.height_px,
				})
				var $px = pixels
				for row in I64.until(rows.start, rows.end) {
					$px = fill_row($px, { rotation, fill, row, crossings: row_crossings(edges, pixel_center(row)) })
				}
				$px
			}
			# Fewer than three corners enclose nothing.
			_ => pixels
		}
	}
}

## The screen's centre, which the roll turns about: the same point in the
## scene and on the screen.
center : { x : F64, y : F64 }
center = { x: Screen.width / 2.0, y: Screen.height / 2.0 }

grass_pixel : U32
grass_pixel = I64.to_u32_wrap(SafariShapes.grass_color)

## Where a row of pixels crosses a polygon's edge, and which way the edge
## runs on the screen.
Crossing : { x : F64, direction : [Down, Up] }

## A point on the screen, where the roll has turned a scene point.
DevicePoint := { x : F64, y : F64 }.{
	is_eq : _
}

## Pixels from `start` up to but not including `end`; none when `end` is not
## past `start`.
PixelRange : { start : I64, end : I64 }

## A polygon's edge, on the screen.
Edge : { from : DevicePoint, to : DevicePoint }

## A stretch of a row, from one crossing to the next.
RowSpan : { from : F64, to : F64 }

## A walk along a row's crossings: the winding so far, and the stretches
## found inside.
WindingWalk : { winding : I64, inside : List(RowSpan) }

# --- Geometry -----------------------------------------------------------------

to_device : Raster.Rotation, Raster.ScenePoint -> DevicePoint
to_device = |rotation, Raster.ScenePoint.({ x, y })| {
	dx = x - center.x
	dy = y - center.y
	DevicePoint.({ x: center.x + dx * rotation.cos + dy * rotation.sin, y: center.y - dx * rotation.sin + dy * rotation.cos })
}

to_scene : Raster.Rotation, DevicePoint -> Raster.ScenePoint
to_scene = |rotation, DevicePoint.({ x, y })| {
	dx = x - center.x
	dy = y - center.y
	Raster.ScenePoint.({ x: center.x + dx * rotation.cos - dy * rotation.sin, y: center.y + dx * rotation.sin + dy * rotation.cos })
}

## The centre of the pixel at `index` in its row or column.
pixel_center : I64 -> F64
pixel_center = |index| I64.to_f64(index) + 0.5

## The first pixel whose centre is at or past `x`. A coordinate far off the
## screen (a point projected from just beside the camera) is first clamped to
## ±100000, well past any screen but small enough that its conversion to an
## integer can't wrap round to a pixel on it.
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
## [from, to), as the range from `start` up to but not including `end`.
pixels_between : { from : F64, to : F64, count : I64 } -> PixelRange
pixels_between = |{ from, to, count }| {
	start: I64.max(0, first_pixel_past(from)),
	end: I64.min(count, first_pixel_past(to)),
}

## Where the pixel at `row` and `column` is in the list.
pixel_index : { row : I64, column : I64 } -> U64
pixel_index = |{ row, column }| I64.to_u64_wrap(row * Screen.width_px + column)

# --- Pixels -------------------------------------------------------------------

## A pixel's red, green and blue, each 0 to 255.
Rgb : { r : F64, g : F64, b : F64 }

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

pack : Rgb -> U32
pack = |{ r, g, b }| {
	red = byte(r).shl_wrap(16)
	green = byte(g).shl_wrap(8)
	red.bitwise_or(green).bitwise_or(byte(b))
}

## A pixel's channels: the mirror of `pack`.
unpacked_pixel : U32 -> Rgb
unpacked_pixel = |pixel| {
	r: pixel.shr_wrap(16).bitwise_and(255).to_f64(),
	g: pixel.shr_wrap(8).bitwise_and(255).to_f64(),
	b: pixel.bitwise_and(255).to_f64(),
}

## `src` over the opaque pixel `dst`.
over : U32, Brush.Rgba -> U32
over = |dst, src|
	if src.a >= 1.0 {
		pack({ r: src.r, g: src.g, b: src.b })
	} else if src.a <= 0.0 {
		dst
	} else {
		kept = 1.0 - src.a
		under = unpacked_pixel(dst)
		pack({
			r: src.r * src.a + under.r * kept,
			g: src.g * src.a + under.g * kept,
			b: src.b * src.a + under.b * kept,
		})
	}

blend : List(U32), { at : U64, color : Brush.Rgba } -> List(U32)
blend = |pixels, { at, color }| {
	dst = pixels.get(at) ?? crash "Raster.blend: a pixel off the screen"
	pixels.set(at, over(dst, color)) ?? crash "Raster.blend: a pixel off the screen"
}

# --- The backdrop and the sun -------------------------------------------------

## The sky holds its top colour to SafariShapes' stop on the way down to the
## horizon, then fades to the horizon colour; the grass is below it. The fade
## divides by the horizon rather than shading a Linear brush, whose arithmetic
## rounds differently.
backdrop : Raster.Rotation, { top : Brush.Rgba, horizon : Brush.Rgba } -> List(U32)
backdrop = |rotation, sky| {
	var $px = List.with_capacity(I64.to_u64_wrap(Screen.width_px * Screen.height_px))
	for row in I64.until(0, Screen.height_px) {
		for column in I64.until(0, Screen.width_px) {
			y = to_scene(rotation, DevicePoint.({ x: pixel_center(column), y: pixel_center(row) })).y
			pixel = if y >= Screen.grass_top_y {
				grass_pixel
			} else {
				t = Brush.clamp01(y / Screen.horizon_y)
				stop = SafariShapes.sky_top_stop
				color = if t <= stop {
					sky.top
				} else {
					Brush.mix(sky.top, sky.horizon, (t - stop) / (1.0 - stop))
				}
				pack({ r: color.r, g: color.g, b: color.b })
			}
			$px = $px.append(pixel)
		}
	}
	$px
}

## The sun's glow and then its disc, as SafariShapes paints them, both
## clipped to the sky, before the commands, so the mountains set the sun
## behind them.
paint_sun : List(U32), { rotation : Raster.Rotation, sun : Sky.SunPos } -> List(U32)
paint_sun = |pixels, { rotation, sun }| {
	fills = SafariShapes.sun_fills(sun)
	on_screen = to_device(rotation, Raster.ScenePoint.({ x: sun.x, y: sun.y }))
	rows = pixels_between({ from: on_screen.y - fills.glow_radius, to: on_screen.y + fills.glow_radius, count: Screen.height_px })
	columns = pixels_between({ from: on_screen.x - fills.glow_radius, to: on_screen.x + fills.glow_radius, count: Screen.width_px })
	var $px = pixels
	for row in I64.until(rows.start, rows.end) {
		for column in I64.until(columns.start, columns.end) {
			p = to_scene(rotation, DevicePoint.({ x: pixel_center(column), y: pixel_center(row) }))
			$px = if p.x >= 0.0 and p.x < Screen.width and p.y >= 0.0 and p.y < Screen.horizon_y {
				at = pixel_index({ row, column })
				lit = blend($px, { at, color: Brush.shade(fills.glow, p.x, p.y) })
				distance = F64.sqrt((p.x - sun.x) * (p.x - sun.x) + (p.y - sun.y) * (p.y - sun.y))
				if distance < fills.disc_radius {
					blend(lit, { at, color: Brush.shade(fills.disc, p.x, p.y) })
				} else {
					lit
				}
			} else {
				$px
			}
		}
	}
	$px
}

# --- The commands -------------------------------------------------------------

command : List(U32), { rotation : Raster.Rotation, draw_command : Paint.DrawCmd } -> List(U32)
command = |pixels, { rotation, draw_command }|
	if draw_command.tag == Paint.beacon_tag {
		match draw_command.geom {
			[x, y, radius] => {
				color = Brush.opaque(draw_command.color)
				Raster.disc(pixels, { rotation, center: Raster.ScenePoint.({ x, y }), radius, color: { ..color, a: draw_command.strength } })
			}
			_ => crash "Raster.command: a beacon's geometry is its x, y and radius"
		}
	} else {
		fill = SafariBrush.of_command(draw_command)
		match fill {
			Skip => pixels
			Flat(_) | Span(_) | Radial(_) | Linear(_) | Ellipse(_) | Glow(_) =>
				Raster.fill_polygon(pixels, { rotation, pts: draw_command.pts, fill })
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
crossing = |edge, y|
	if edge.from.y <= y and y < edge.to.y {
		[{ x: edge_x_at(edge, y), direction: Down }]
	} else if edge.to.y <= y and y < edge.from.y {
		[{ x: edge_x_at(edge, y), direction: Up }]
	} else {
		[]
	}

## Where the edge is across the screen at the height `y`, which is between
## its ends, so the division is by a height that isn't zero.
edge_x_at : Edge, F64 -> F64
edge_x_at = |{ from, to }, y| from.x + (y - from.y) * (to.x - from.x) / (to.y - from.y)

## One row of a polygon: the spans between its crossings where the winding is
## not zero.
fill_row : List(U32), { rotation : Raster.Rotation, fill : Brush.Fill, row : I64, crossings : List(Crossing) } -> List(U32)
fill_row = |pixels, { rotation, fill, row, crossings }| {
	var $px = pixels
	for inside in inside_spans(crossings) {
		$px = span($px, { rotation, fill, row, from: inside.from, to: inside.to })
	}
	$px
}

## The stretches between neighbouring crossings, left to right, where the
## winding is not zero.
inside_spans : List(Crossing) -> List(RowSpan)
inside_spans = |crossings| {
	neighbours = crossings.map2(crossings.drop_first(1), |enter, leave| { enter, leave })
	neighbours.fold({ winding: 0, inside: [] }, walk_crossing).inside
}

## The walk after one more pair of neighbouring crossings.
walk_crossing : WindingWalk, { enter : Crossing, leave : Crossing } -> WindingWalk
walk_crossing = |so_far, { enter, leave }| {
	turn =
		match enter.direction {
			Down => 1
			Up => -1
		}
	winding = so_far.winding + turn
	inside =
		if winding == 0 {
			so_far.inside
		} else {
			so_far.inside.append({ from: enter.x, to: leave.x })
		}
	{ winding, inside }
}

## The pixels of `row` whose centres fall in [from, to).
span : List(U32), { rotation : Raster.Rotation, fill : Brush.Fill, row : I64, from : F64, to : F64 } -> List(U32)
span = |pixels, { rotation, fill, row, from, to }| {
	columns = pixels_between({ from, to, count: Screen.width_px })
	y = pixel_center(row)
	var $px = pixels
	for column in I64.until(columns.start, columns.end) {
		at = pixel_index({ row, column })
		color = match fill {
			Flat(flat) => flat
			Span(_) | Radial(_) | Linear(_) | Ellipse(_) | Glow(_) => {
				p = to_scene(rotation, DevicePoint.({ x: pixel_center(column), y }))
				Brush.shade(fill, p.x, p.y)
			}
			Skip => crash "Raster.span: a Skip brush paints nothing, and no caller fills with one"
		}
		$px = blend($px, { at, color })
	}
	$px
}
