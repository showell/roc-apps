## The widget for the Safari tutorial's chapter on the stills. Every pose of the
## cat and the bird stands in a grid, drawn by the real StillDraw, and one of them
## stands large with its polygons and points counted. Nothing here moves, so
## there's no ruler. A click on a small still makes it the large one, and a click
## on the large one shows or hides the outline of each polygon.
import game.BirdFlight
import game.BirdStills
import game.Cat
import game.CatStills
import game.Pixels
import game.Screen
import game.StillDraw
import game.Stills
import lib.Brush
import lib.CanvasApp
import lib.Font
import lib.Input
import lib.Mouse
import lib.Shapes
import widget.ScrubWidget

StillsWidgetApp :: [].{

	## A pose's still: the pose's name, and its polygons.
	PoseStill : { name : Str, polygons : List(Stills.StillPolygon) }

	## The whole state of the widget: the still shown large, and whether the
	## outlines of its polygons show.
	Model : { large_still : StillsWidgetApp.PoseStill, outlines : [Hidden, Shown] }

	canvas_app : CanvasApp.CanvasApp(StillsWidgetApp.Model)
	canvas_app = {
		size: { width: ScrubWidget.canvas_width, height: ScrubWidget.canvas_height },
		fps: frames_a_second,
		init: { large_still: cat_still(Rest), outlines: Hidden },
		advance: |model, input, _seconds| next_model(model, input),
		frame: frame_at,
		sounds: |_model| 0,
		tones: [],
		title: "The stills",
	}
}

## Every frame paints thirteen thousand points again, and at 60 that's most of a
## core for a picture that only changes on a click. This is still quick to answer one.
frames_a_second : I32
frames_a_second = 15

## A part of the canvas, in pixels.
Area : {
	left : F64,
	top : F64,
	width : F64,
	height : F64,
}

## How far a still reaches in its own units, where its height is 1.
StillExtent : {
	left : F64,
	right : F64,
	bottom : F64,
	top : F64,
}

## One small still: the area a click on it lands in, and where it stands there.
StillCell : {
	still : StillsWidgetApp.PoseStill,
	area : Area,
	anchor : StillDraw.Anchor,
}

cat_pose_name : Cat.Pose -> Str
cat_pose_name = |pose|
	match pose {
		Rest => "Rest"
		Stride => "Stride"
		Frozen => "Frozen"
		Coil => "Coil"
		Flight => "Flight"
		Land => "Land"
		Collapse => "Collapse"
	}

bird_pose_name : BirdFlight.Pose -> Str
bird_pose_name = |pose|
	match pose {
		Perched => "Perched"
		Side(WingsUp) => "Side up"
		Side(WingsDown) => "Side down"
		Away(WingsUp) => "Away up"
		Away(WingsDown) => "Away down"
		Diving => "Diving"
	}

cat_still : Cat.Pose -> StillsWidgetApp.PoseStill
cat_still = |pose| { name: cat_pose_name(pose), polygons: CatStills.pose_polygons(pose) }

bird_still : BirdFlight.Pose -> StillsWidgetApp.PoseStill
bird_still = |pose| { name: bird_pose_name(pose), polygons: BirdStills.pose_polygons(pose) }

cat_stills : List(StillsWidgetApp.PoseStill)
cat_stills =
	[
		Rest,
		Stride,
		Frozen,
		Coil,
		Flight,
		Land,
		Collapse,
	].map(cat_still)

bird_stills : List(StillsWidgetApp.PoseStill)
bird_stills =
	[
		Perched,
		Side(WingsUp),
		Side(WingsDown),
		Away(WingsUp),
		Away(WingsDown),
		Diving,
	].map(bird_still)

extent_of : List(Stills.StillPolygon) -> StillExtent
extent_of = |polygons|
	match polygons.join_map(|polygon| polygon.points) {
		[first, .. as rest] =>
			rest.fold(
				{
					left: first.x,
					right: first.x,
					bottom: first.y,
					top: first.y,
				},
				|extent, point| {
					left: extent.left.min(point.x),
					right: extent.right.max(point.x),
					bottom: extent.bottom.min(point.y),
					top: extent.top.max(point.y),
				},
			)
		[] => crash "StillsWidgetApp.extent_of: every still has points"
	}

extent_width : StillExtent -> F64
extent_width = |extent| extent.right - extent.left

## How high a cell is. Two rows of them fill the panel under the picture.
cell_height : F64
cell_height = (ScrubWidget.canvas_height - ScrubWidget.picture_bottom_y) / 2.0

## How far down a cell the stills stand, which leaves room under them for a name.
cell_ground : F64
cell_ground = 54.0

## How far down a cell a name starts.
cell_name_top : F64
cell_name_top = 57.0

## What a still keeps clear of its neighbours, on each side and above.
cell_padding : F64
cell_padding = 2.0

name_size : F64
name_size = 10.0

## The height that lets every still of a row fit a cell `cell_width` wide. A row
## shares one height, so a pose keeps its true size beside the others.
row_height_px : List(StillsWidgetApp.PoseStill), F64 -> F64
row_height_px = |stills, cell_width| {
	extents = stills.map(|still| extent_of(still.polygons))
	widest = extents.fold(0.0, |most, extent| most.max(extent_width(extent)))
	tallest = extents.fold(0.0, |most, extent| most.max(extent.top))
	F64.min((cell_width - 2.0 * cell_padding) / widest, (cell_ground - cell_padding) / tallest)
}

## Where a still stands with its middle at `mid_x` and its y 0 at `ground_y`.
standing_at : List(Stills.StillPolygon),
{
	mid_x : F64,
	ground_y : F64,
	height_px : F64,
} -> StillDraw.Anchor
standing_at = |polygons, { mid_x, ground_y, height_px }| {
	extent = extent_of(polygons)
	{
		feet: Screen.point(mid_x - height_px * (extent.left + extent.right) / 2.0, ground_y),
		flip: AsDrawn,
		height_px: Pixels.of(height_px),
	}
}

## A row of stills across the canvas, between its side margins.
row_cells : List(StillsWidgetApp.PoseStill), F64 -> List(StillCell)
row_cells = |stills, row_top| {
	cell_width = ScrubWidget.ruler_length / stills.len().to_f64()
	height_px = row_height_px(stills, cell_width)
	stills.map_with_index(
		|still, column| {
			left = ScrubWidget.side_margin + column.to_f64() * cell_width
			{
				still,
				area: {
					left,
					top: row_top,
					width: cell_width,
					height: cell_height,
				},
				anchor: standing_at(
					still.polygons,
					{
						mid_x: left + cell_width / 2.0,
						ground_y: row_top + cell_ground,
						height_px,
					},
				),
			}
		},
	)
}

## The cat's poses on the first row, and the bird's on the second.
cells : List(StillCell)
cells =
	row_cells(cat_stills, ScrubWidget.picture_bottom_y)
		.concat(row_cells(bird_stills, ScrubWidget.picture_bottom_y + cell_height))

## Where the words stop and the large still starts.
large_area_left : F64
large_area_left = 264.0

## What the large still keeps clear of the top of the canvas and of the panel.
large_area_margin : F64
large_area_margin = 10.0

## Where the large still may reach, to the right of the words.
large_area : Area
large_area = {
	left: large_area_left,
	top: large_area_margin,
	width: ScrubWidget.canvas_width - ScrubWidget.side_margin - large_area_left,
	height: ScrubWidget.picture_bottom_y - 2.0 * large_area_margin,
}

## A still as large as `large_area` holds it, in the middle of that area.
large_anchor : List(Stills.StillPolygon) -> StillDraw.Anchor
large_anchor = |polygons| {
	extent = extent_of(polygons)
	height_px = F64.min(
		large_area.width / extent_width(extent),
		large_area.height / (extent.top - extent.bottom),
	)
	middle = middle_of(large_area)
	standing_at(
		polygons,
		{
			mid_x: middle.x,
			ground_y: middle.y + height_px * (extent.top + extent.bottom) / 2.0,
			height_px,
		},
	)
}

middle_of : Area -> { x : F64, y : F64 }
middle_of = |area| { x: area.left + area.width / 2.0, y: area.top + area.height / 2.0 }

is_inside : Area, { x : F64, y : F64 } -> Bool
is_inside = |area, { x, y }|
	x >= area.left and x < area.left + area.width and y >= area.top and y < area.top + area.height

## `model` after a click at `spot`, which does nothing off the stills.
model_after_click : StillsWidgetApp.Model, { x : F64, y : F64 } -> StillsWidgetApp.Model
model_after_click = |model, spot|
	match cells.find_first(|cell| is_inside(cell.area, spot)) {
		Ok(cell) => { ..model, large_still: cell.still }
		Err(NotFound) =>
			if is_inside(large_area, spot) {
				{ ..model, outlines: toggled_outlines(model.outlines) }
			} else {
				model
			}
	}

toggled_outlines : [Hidden, Shown] -> [Hidden, Shown]
toggled_outlines = |outlines|
	match outlines {
		Hidden => Shown
		Shown => Hidden
	}

next_model : StillsWidgetApp.Model, Input.Snapshot -> StillsWidgetApp.Model
next_model = |model, input|
	if input.mouse.button_pressed(Left) {
		{ x, y } = input.mouse.position()
		model_after_click(model, { x: x.to_f64(), y: y.to_f64() })
	} else {
		model
	}

picture_color : I64
picture_color = 0xf7f5ef

ink : Brush.Rgba
ink = Brush.opaque(0x202020)

point_count : List(Stills.StillPolygon) -> U64
point_count = |polygons| polygons.fold(0, |sum, polygon| sum + polygon.points.len())

## What a still is made of, a line each.
read_out : StillsWidgetApp.PoseStill -> List(Str)
read_out = |still| [
	still.name,
	"${ScrubWidget.count_text(still.polygons.len())} polygons",
	"${ScrubWidget.count_text(point_count(still.polygons))} points",
]

read_out_size : F64
read_out_size = 16.0

read_out_line : Str, U64 -> List(Shapes.Shape)
read_out_line = |text, row|
	Font.text(
		text,
		ScrubWidget.side_margin,
		28.0 + row.to_f64() * 26.0,
		read_out_size,
		ink,
	)

hint_lines : List(Str)
hint_lines = ["Click a still below.", "Click the large one", "to outline its polygons."]

hint_line : Str, U64 -> List(Shapes.Shape)
hint_line = |text, row|
	Font.text(
		text,
		ScrubWidget.side_margin,
		128.0 + row.to_f64() * 18.0,
		name_size,
		ink,
	)

## The lines round one polygon. A still repeats a point here and there, and the
## line between two such points is empty.
polygon_outline : StillDraw.Anchor, Stills.StillPolygon -> List(Shapes.Shape)
polygon_outline = |anchor, polygon| {
	corners = StillDraw.screen_points(anchor, polygon.points)
	corners.map2(
		corners.drop_first(1).concat(corners.take_first(1)),
		|from, to|
			Shapes.line(
				from.x.to_f64(),
				from.y.to_f64(),
				to.x.to_f64(),
				to.y.to_f64(),
				1.0,
				Flat(ink),
			),
	)
}

## The large still, with the outlines of its polygons if they show.
large_shapes : StillsWidgetApp.Model -> List(Shapes.Shape)
large_shapes = |{ large_still, outlines }| {
	anchor = large_anchor(large_still.polygons)
	drawn = StillDraw.draw_still(anchor, large_still.polygons)
	match outlines {
		Hidden => drawn
		Shown => {
			outline = large_still.polygons.join_map(|polygon| polygon_outline(anchor, polygon))
			drawn.concat(outline)
		}
	}
}

## The words and the large still, above the panel.
picture : StillsWidgetApp.Model -> List(Shapes.Shape)
picture = |model|
	[
		[
			Rect({
				x: 0.0,
				y: 0.0,
				w: ScrubWidget.canvas_width,
				h: ScrubWidget.picture_bottom_y,
				fill: ScrubWidget.flat(picture_color),
			}),
		],
		read_out(model.large_still).map_with_index(read_out_line).join(),
		hint_lines.map_with_index(hint_line).join(),
		large_shapes(model),
	].join()

## One small still with its pose's name under it.
cell_shapes : StillCell -> List(Shapes.Shape)
cell_shapes = |{ still, area, anchor }|
	StillDraw.draw_still(anchor, still.polygons).concat(
		Font.centered(
			still.name,
			area.left + area.width / 2.0,
			area.top + cell_name_top,
			name_size,
			ink,
		),
	)

## The grid never changes, so it's worked out once, when the widget is built.
grid : List(Shapes.Shape)
grid = cells.join_map(cell_shapes)

## The cell of the still shown large, lit as the picture above it is.
large_still_mark : StillsWidgetApp.PoseStill -> List(Shapes.Shape)
large_still_mark = |large_still|
	cells.keep_if(|cell| cell.still.name == large_still.name).map(
		|{ area, .. }|
			Rect({
				x: area.left,
				y: area.top,
				w: area.width,
				h: area.height,
				fill: ScrubWidget.flat(picture_color),
			}),
	)

## Everything on the canvas.
frame_at : StillsWidgetApp.Model -> List(Shapes.Shape)
frame_at = |model|
	ScrubWidget.still_frame_shapes({ picture: picture(model), status: [] })
		.concat(large_still_mark(model.large_still))
		.concat(grid)

## Where a point of a still lands, as plain numbers.
landing_spot : StillDraw.Anchor, Stills.StillPt -> { x : F64, y : F64 }
landing_spot = |anchor, point| {
	on_screen = StillDraw.screen_point(anchor, point)
	{ x: on_screen.x.to_f64(), y: on_screen.y.to_f64() }
}

## Whether every point of a still lands in `area`.
stays_in : StillDraw.Anchor, { polygons : List(Stills.StillPolygon), area : Area } -> Bool
stays_in = |anchor, { polygons, area }|
	polygons.all(|polygon| polygon.points.all(|point| is_inside(area, landing_spot(anchor, point))))

first_cell : StillCell
first_cell = cells.first() ?? crash "StillsWidgetApp.first_cell: the grid has cells"

last_cell : StillCell
last_cell = cells.last() ?? crash "StillsWidgetApp.last_cell: the grid has cells"

start : StillsWidgetApp.Model
start = StillsWidgetApp.canvas_app.init

## A snapshot with the pointer at (`x`, `y`) and the buttons `held`, of which
## those in `struck` were pressed just now.
pointer_at : {
	x : F64,
	y : F64,
	held : U32,
	struck : U32,
} -> Input.Snapshot
pointer_at = |{ x, y, held, struck }|
	Input.none.with_mouse(Mouse.of(held, struck, x.to_f32_wrap(), y.to_f32_wrap(), 0.0))

## A left click at `spot` from `model`.
left_click : StillsWidgetApp.Model, { x : F64, y : F64 } -> StillsWidgetApp.Model
left_click = |model, { x, y }|
	next_model(
		model,
		pointer_at({
			x,
			y,
			held: 1,
			struck: 1,
		}),
	)

## Whether `model` is unchanged from the start.
is_as_started : StillsWidgetApp.Model -> Bool
is_as_started = |{ large_still, outlines }|
	large_still.name == start.large_still.name and outlines == start.outlines

# Every pose is in the grid, the cat's first, and no two share a name.
expect cat_stills.len() == 7
expect bird_stills.len() == 6
expect cells.len() == 13
expect cells.map(|cell| cell.still.name).take_first(2) == ["Rest", "Stride"]
expect cells.all(|cell| cells.keep_if(|other| other.still.name == cell.still.name).len() == 1)

# Each tag has its own name, and each pose its own still.
expect
	[
		(Rest, "Rest"),
		(Stride, "Stride"),
		(Frozen, "Frozen"),
		(Coil, "Coil"),
		(Flight, "Flight"),
		(Land, "Land"),
		(Collapse, "Collapse"),
	].all(|(pose, name)| cat_pose_name(pose) == name)
expect
	[
		(Perched, "Perched"),
		(Side(WingsUp), "Side up"),
		(Side(WingsDown), "Side down"),
		(Away(WingsUp), "Away up"),
		(Away(WingsDown), "Away down"),
		(Diving, "Diving"),
	].all(|(pose, name)| bird_pose_name(pose) == name)
expect cat_still(Frozen).polygons.len() == CatStills.pose_polygons(Frozen).len()
expect point_count(bird_still(Diving).polygons) == point_count(BirdStills.diving)

# The rows fill the space between the side margins, end to end.
expect first_cell.area.left == ScrubWidget.side_margin
expect (last_cell.area.left + last_cell.area.width - 616.0).abs() <= 0.000001
expect (first_cell.area.width - 592.0 / 7.0).abs() <= 0.000001
expect (last_cell.area.width - 592.0 / 6.0).abs() <= 0.000001

# The two rows fill the panel, top to bottom, and no two cells overlap.
expect first_cell.area.top == ScrubWidget.picture_bottom_y
expect last_cell.area.top + last_cell.area.height == ScrubWidget.canvas_height
expect
	cells.all(
		|cell| cells.keep_if(|other| is_inside(other.area, middle_of(cell.area))).len() == 1,
	)

# A row shares one height, and no still leaves its cell or crosses its name.
expect cells.take_first(7).all(|cell| cell.anchor.height_px == first_cell.anchor.height_px)
expect cells.drop_first(7).all(|cell| cell.anchor.height_px == last_cell.anchor.height_px)
expect cells.all(|{ still, area, anchor }| stays_in(anchor, { polygons: still.polygons, area }))
expect
	cells.all(
		|{ still, area, anchor }| {
			above_name = { ..area, height: cell_name_top }
			stays_in(anchor, { polygons: still.polygons, area: above_name })
		},
	)

## Whether a cell's still fills the cell's width, up to the padding.
is_full_width : StillCell -> Bool
is_full_width = |{ still, area, anchor }| {
	still_width = anchor.height_px.to_f64() * extent_width(extent_of(still.polygons))
	area.width - still_width <= 2.0 * cell_padding + 0.000001
}

# The widest still of each row just fits, so no row is smaller than it must be.
expect cells.take_first(7).any(is_full_width)
expect cells.drop_first(7).any(is_full_width)
expect !is_full_width(first_cell)

# Each name fits its cell, and the longest one fits with little to spare.
expect cells.all(|{ still, area, .. }| Font.width_of(still.name, name_size) <= area.width)
expect Font.width_of("Collapse", name_size) > 592.0 / 7.0 - name_size

# The words all fit left of the large still.
expect
	cells.all(
		|{ still, .. }|
			read_out(still).all(
				|line| {
					line_end = ScrubWidget.side_margin + Font.width_of(line, read_out_size)
					line_end <= large_area.left
				},
			),
	)
expect
	hint_lines.all(
		|line| ScrubWidget.side_margin + Font.width_of(line, name_size) <= large_area.left,
	)

## The large area with its far edges inside it, which a still may touch.
large_area_edges_held : Area
large_area_edges_held = {
	..large_area,
	width: large_area.width + 0.001,
	height: large_area.height + 0.001,
}

# The large still stays in its area, for every still, and touches two of its sides.
expect
	cells.all(
		|{ still, .. }|
			stays_in(
				large_anchor(still.polygons),
				{ polygons: still.polygons, area: large_area_edges_held },
			),
	)
expect
	cells.all(
		|{ still, .. }| {
			extent = extent_of(still.polygons)
			height = large_anchor(still.polygons).height_px.to_f64()
			wide_room = large_area.width - height * extent_width(extent)
			tall_room = large_area.height - height * (extent.top - extent.bottom)
			wide_room.min(tall_room).abs() <= 0.000001
		},
	)

# Its middle is the area's, either way.
expect
	cells.all(
		|{ still, .. }| {
			anchor = large_anchor(still.polygons)
			extent = extent_of(still.polygons)
			low = landing_spot(anchor, { x: extent.left, y: extent.bottom })
			high = landing_spot(anchor, { x: extent.right, y: extent.top })
			middle = middle_of(large_area)
			miss_x = (low.x + high.x) / 2.0 - middle.x
			miss_y = (low.y + high.y) / 2.0 - middle.y
			miss_x.abs() <= 0.000001 and miss_y.abs() <= 0.000001
		},
	)

# Stills that reach past 1 and below 0 are measured from their points.
expect {
	frozen = extent_of(CatStills.pose_polygons(Frozen))
	frozen.top > 1.0 and frozen.bottom < 0.0 and frozen.left < 0.0 and frozen.right > 1.0
}
expect
	extent_of([
		{
			color: 0,
			gradient: [],
			points: [{ x: 0.5, y: 0.25 }, { x: -1.0, y: 2.0 }],
		},
		{
			color: 0,
			gradient: [],
			points: [{ x: 3.0, y: -4.0 }],
		},
	])
		== {
			left: -1.0,
			right: 3.0,
			bottom: -4.0,
			top: 2.0,
		}

## An area whose edges a click can be tried on.
sample_area : Area
sample_area = {
	left: 10.0,
	top: 20.0,
	width: 30.0,
	height: 40.0,
}

# An area holds its top left corner and stops short of its far edges.
expect is_inside(sample_area, { x: 10.0, y: 20.0 })
expect is_inside(sample_area, { x: 39.0, y: 59.0 })
expect !is_inside(sample_area, { x: 40.0, y: 20.0 })
expect !is_inside(sample_area, { x: 10.0, y: 60.0 })
expect !is_inside(sample_area, { x: 9.0, y: 20.0 })
expect !is_inside(sample_area, { x: 10.0, y: 19.0 })

# The widget starts on the cat at rest, with no outlines.
expect start.large_still.name == "Rest"
expect start.outlines == Hidden

# A click on any cell shows that still large.
expect
	cells.all(
		|cell| left_click(start, middle_of(cell.area)).large_still.name == cell.still.name,
	)

# So does a click at a cell's corner, and the corner just past it is the next cell's.
expect {
	corner = { x: last_cell.area.left, y: last_cell.area.top }
	model_after_click(start, corner).large_still.name == "Diving"
		and model_after_click(start, { ..corner, x: corner.x - 1.0 }).large_still.name == "Away down"
}

# A click on a cell leaves the outlines as they were, shown or hidden.
expect left_click({ ..start, outlines: Shown }, middle_of(last_cell.area)).outlines == Shown
expect left_click(start, middle_of(last_cell.area)).outlines == Hidden

# A click on the large still shows the outlines, and another hides them.
expect left_click(start, middle_of(large_area)).outlines == Shown
expect {
	shown = left_click(start, middle_of(large_area))
	left_click(shown, middle_of(large_area)).outlines == Hidden
}
expect left_click(start, middle_of(large_area)).large_still.name == "Rest"

# The large still's area ends where the words and the panel start.
expect left_click(start, { x: large_area.left, y: large_area.top }).outlines == Shown
expect is_as_started(left_click(start, { x: large_area.left - 1.0, y: large_area.top }))
expect is_as_started(left_click(start, { x: 620.0, y: 100.0 }))
expect is_as_started(left_click(start, { x: 400.0, y: 5.0 }))

# A click anywhere else does nothing: on the words, past either end of a row.
expect is_as_started(left_click(start, { x: 100.0, y: 60.0 }))
expect is_as_started(left_click(start, { x: 10.0, y: 300.0 }))
expect is_as_started(left_click(start, { x: 630.0, y: 300.0 }))

# page_check.mjs presses here to learn whether the pointer changes the picture, and
# a page where a finger scrolls has to answer no.
expect is_as_started(left_click(start, { x: 128.0, y: 144.0 }))

# Only a press of the left button is a click: not one held from before, not
# the right button, and not nothing at all.
expect {
	spot = middle_of(last_cell.area)
	held = pointer_at({
		x: spot.x,
		y: spot.y,
		held: 1,
		struck: 0,
	})
	right = pointer_at({
		x: spot.x,
		y: spot.y,
		held: 2,
		struck: 2,
	})
	[held, right, Input.none].all(|input| is_as_started(next_model(start, input)))
}

expect toggled_outlines(Hidden) == Shown
expect toggled_outlines(Shown) == Hidden

# The read-out is the data's, as CatStills and BirdStills hold their own counts.
expect read_out(cat_still(Rest)) == ["Rest", "46 polygons", "2,198 points"]
expect read_out(cat_still(Frozen)) == ["Frozen", "47 polygons", "2,197 points"]
expect read_out(cat_still(Coil)) == ["Coil", "34 polygons", "1,715 points"]
expect read_out(bird_still(Side(WingsUp))) == ["Side up", "6 polygons", "21 points"]
expect read_out(bird_still(Away(WingsDown))) == ["Away down", "4 polygons", "17 points"]
expect read_out(bird_still(Diving)) == ["Diving", "6 polygons", "22 points"]

# StillDraw leaves out what it won't draw, so the counts would lie if it left
# out a polygon of these. It draws every one.
expect
	cells.all(
		|{ still, anchor, .. }| {
			drawn = StillDraw.draw_still(anchor, still.polygons)
			drawn.len() == still.polygons.len()
		},
	)

# The outlines add one line for each point of the still, and none when hidden.
expect large_shapes(start).len() == start.large_still.polygons.len()
expect
	large_shapes({ ..start, outlines: Shown }).len()
		== start.large_still.polygons.len() + point_count(start.large_still.polygons)

# A polygon's outline closes: its last line ends where its first starts.
expect {
	square = {
		color: 0,
		gradient: [],
		points: [
			{ x: 0.0, y: 0.0 },
			{ x: 1.0, y: 0.0 },
			{ x: 1.0, y: 1.0 },
			{ x: 0.0, y: 1.0 },
		],
	}
	anchor = {
		feet: Screen.point(0.0, 10.0),
		flip: AsDrawn,
		height_px: Pixels.of(10.0),
	}
	match polygon_outline(anchor, square) {
		[_, _, _, Poly({ pts, .. })] => pts == [-0.5, 0.0, -0.5, 10.0, 0.5, 10.0, 0.5, 0.0]
		_ => False
	}
}

# A repeated point makes an empty line, and a still of one point none at all.
expect {
	anchor = {
		feet: Screen.point(0.0, 0.0),
		flip: AsDrawn,
		height_px: Pixels.of(10.0),
	}
	polygon_outline(
		anchor,
		{
			color: 0,
			gradient: [],
			points: [{ x: 1.0, y: 1.0 }],
		},
	)
		== [Poly({ pts: [], fill: Flat(ink) })]
}

# The picture answers each click.
expect frame_at(start) != frame_at(left_click(start, middle_of(last_cell.area)))
expect frame_at(start) != frame_at(left_click(start, middle_of(large_area)))
expect frame_at(start) == frame_at(left_click(start, { x: 100.0, y: 60.0 }))

# One cell is lit, the one shown large, and a still not in the grid lights none.
expect large_still_mark(cat_still(Land)).len() == 1
expect large_still_mark(bird_still(Diving)).len() == 1
expect large_still_mark(cat_still(Land)) != large_still_mark(bird_still(Diving))
expect large_still_mark({ name: "None", polygons: [] }).len() == 0
