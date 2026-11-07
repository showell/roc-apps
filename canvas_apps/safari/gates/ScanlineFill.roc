## Polygons and discs filled into a grid of 0xRRGGBB pixels a row at a time.
## A shape's points are in the scene, and a ScreenRoll turns them onto the
## screen. A pixel is painted when its centre is inside the shape, and a
## polygon fills by the nonzero rule, as a canvas fills one. There is no
## anti-aliasing. The colour a point gets is its Brush's.
##
## Every store lands in place: the pixels are a `var` list, and each store is
## PixelGrid's `blend`. A list threaded down a recursion would be copied on
## the next store (docs/roc-notes.md, "Speed and copying").
import lib.Brush
import PixelGrid
import ScreenRoll

ScanlineFill :: [].{

	## A polygon, as scene coordinates x0, y0, x1, y1, ..., filled by the
	## nonzero rule.
	polygon_pixels : List(U32),
	{
		roll : ScreenRoll,
		coordinates : List(F64),
		fill : Brush.Fill,
	} -> List(U32)
	polygon_pixels = |pixels, { roll, coordinates, fill }| {
		corners = coordinates.chunks_of(2).map(
			|pair|
				match pair {
					[x, y] => roll.to_screen(ScreenRoll.ScenePoint.({ x, y }))
					_ => crash "ScanlineFill.polygon_pixels: a polygon's coordinates come in pairs"
				},
		)
		match corners {
			[first, _, _, ..] => {
				next_corners = corners.drop_first(1).concat(corners.take_first(1))
				edges = corners.map2(next_corners, |from, to| { from, to })
				rows = PixelGrid.pixels_between({
					from: corners.fold(first.y, |top, corner| top.min(corner.y)),
					to: corners.fold(first.y, |bottom, corner| bottom.max(corner.y)),
					extent: roll.height_px(),
				})
				var $px = pixels
				for row in rows.start.until(rows.end) {
					edge_crossings = row_edge_crossings(edges, PixelGrid.pixel_center(row))
					$px = row_pixels($px, { roll, fill, row, edge_crossings })
				}
				$px
			}
			# Fewer than three corners enclose nothing.
			_ => pixels
		}
	}

	## A disc of one colour: the pixels whose centres are strictly inside.
	disc_pixels : List(U32),
	{
		roll : ScreenRoll,
		center : ScreenRoll.ScenePoint,
		radius : F64,
		color : Brush.Rgba,
	} -> List(U32)
	disc_pixels = |pixels, { roll, center, radius, color }| {
		on_screen = roll.to_screen(center)
		rows = PixelGrid.pixels_between({
			from: on_screen.y - radius,
			to: on_screen.y + radius,
			extent: roll.height_px(),
		})
		var $px = pixels
		for row in rows.start.until(rows.end) {
			dy = PixelGrid.pixel_center(row) - on_screen.y
			half_squared = radius * radius - dy * dy
			$px = if half_squared > 0.0 {
				half = half_squared.sqrt()
				pixels_with_span(
					$px,
					{
						roll,
						fill: Flat(color),
						row,
						from: on_screen.x - half,
						to: on_screen.x + half,
					},
				)
			} else {
				$px
			}
		}
		$px
	}
}

## Where a row of pixels crosses a polygon's edge, and which way the edge
## runs on the screen.
EdgeCrossing : { x : F64, direction : [Down, Up] }

## A polygon's edge, on the screen.
Edge : { from : ScreenRoll.ScreenPoint, to : ScreenRoll.ScreenPoint }

## A stretch of a row, from one edge crossing to the next.
RowSpan : { from : F64, to : F64 }

## A walk along a row's edge crossings: the winding so far, and the
## stretches found inside.
WindingWalk : { winding : I64, spans : List(RowSpan) }

## Where the row at `y` crosses the polygon's edges, left to right. An edge
## holds its upper end and not its lower.
row_edge_crossings : List(Edge), F64 -> List(EdgeCrossing)
row_edge_crossings = |edges, y|
	edges.keep_oks(|edge| edge_crossing(edge, y)).sort_with(
		|a, b|
			if a.x < b.x {
				Before
			} else if a.x > b.x {
				After
			} else {
				Same
			},
	)

## Where the row at `y` crosses this one edge, if it does.
edge_crossing : Edge, F64 -> Try(EdgeCrossing, [RowMissesEdge])
edge_crossing = |edge, y|
	if edge.from.y <= y and y < edge.to.y {
		Ok({ x: edge_x_at(edge, y), direction: Down })
	} else if edge.to.y <= y and y < edge.from.y {
		Ok({ x: edge_x_at(edge, y), direction: Up })
	} else {
		Err(RowMissesEdge)
	}

## Where the edge is across the screen at the height `y`, which is between
## its ends, so the division is by a height that isn't zero.
edge_x_at : Edge, F64 -> F64
edge_x_at = |{ from, to }, y| from.x + (y - from.y) * (to.x - from.x) / (to.y - from.y)

## One row of a polygon: the spans between its edge crossings where the
## winding is not zero.
row_pixels : List(U32),
{
	roll : ScreenRoll,
	fill : Brush.Fill,
	row : PixelGrid.Coordinate,
	edge_crossings : List(EdgeCrossing),
} -> List(U32)
row_pixels = |pixels, { roll, fill, row, edge_crossings }| {
	var $px = pixels
	for row_span in inside_spans(edge_crossings) {
		$px = pixels_with_span(
			$px,
			{
				roll,
				fill,
				row,
				from: row_span.from,
				to: row_span.to,
			},
		)
	}
	$px
}

## The stretches between neighbouring edge crossings, left to right,
## where the winding is not zero.
inside_spans : List(EdgeCrossing) -> List(RowSpan)
inside_spans = |edge_crossings| {
	neighbours = edge_crossings.map2(edge_crossings.drop_first(1), |left, right| { left, right })
	neighbours.fold({ winding: 0, spans: [] }, walk_edge_crossing).spans
}

## The walk after one more pair of neighbouring edge crossings.
walk_edge_crossing : WindingWalk, { left : EdgeCrossing, right : EdgeCrossing } -> WindingWalk
walk_edge_crossing = |so_far, { left, right }| {
	turn =
		match left.direction {
			Down => 1
			Up => -1
		}
	winding = so_far.winding + turn
	spans =
		if winding == 0 {
			so_far.spans
		} else {
			so_far.spans.append({ from: left.x, to: right.x })
		}
	{ winding, spans }
}

## The pixels of `row` whose centres fall in [from, to).
pixels_with_span : List(U32),
{
	roll : ScreenRoll,
	fill : Brush.Fill,
	row : PixelGrid.Coordinate,
	from : F64,
	to : F64,
} -> List(U32)
pixels_with_span = |pixels, { roll, fill, row, from, to }| {
	columns = PixelGrid.pixels_between({ from, to, extent: roll.width_px() })
	width = roll.width_px()
	var $px = pixels
	for column in columns.start.until(columns.end) {
		at = PixelGrid.pixel_index({ row, column, width })
		color = match fill {
			Flat(flat) => flat
			Span(_) | Radial(_) | Linear(_) | Ellipse(_) | Glow(_) => {
				p = roll.to_scene(ScreenRoll.pixel_point({ row, column }))
				Brush.shade(fill, p.x, p.y)
			}
		}
		$px = PixelGrid.blended_pixels($px, { at, color })
	}
	$px
}
