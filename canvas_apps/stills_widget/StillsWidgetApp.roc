## The widget for the Safari tutorial's chapter on the stills. Every pose of the
## cat and the bird stands in a grid, drawn by the real StillShapes, and one of them
## stands large with its polygons and points counted. Nothing here moves, so
## there are no video recorder buttons. A click on a small still makes it the large one, and a click
## on the large one shows or hides the outline of each polygon.
import game.BirdStills
import game.Pixels
import game.PosedBird
import game.PosedCat
import game.Screen
import game.StillShapes
import game.Still
import lib.Brush
import lib.RgbColor
import lib.CanvasApp
import lib.Font
import lib.Input
import lib.Mouse
import lib.Shapes
import widget.Click
import widget.ReadoutText
import widget.ScrubWidget

StillsWidgetApp :: [].{

	## A pose of the cat or of the bird, each of which has its own still.
	Pose : [Cat(PosedCat.CatPose), Bird(PosedBird.BirdPose)]

	## The whole state of the widget: the pose shown large, and whether the
	## outlines of its still's polygons show.
	Model : { large_pose : StillsWidgetApp.Pose, outlines : [Hidden, Shown] }

	## Built by hand, not by `ScrubWidget.canvas_app`, because it runs at its own
	## frame rate.
	canvas_app : CanvasApp.CanvasApp(StillsWidgetApp.Model)
	canvas_app = {
		size: { width: ScrubWidget.canvas_width, height: ScrubWidget.canvas_height },
		fps: frames_a_second,
		init: { large_pose: Cat(Rest), outlines: Hidden },
		model_at_next_step: |model, input, _seconds| next_model(model, input),
		frame_shapes: shapes_at,
		sounds: |_model| 0,
		tones: [],
		title: "The stills",
	}
}

## Every frame paints thirteen thousand points again, and at 60 that's most of a
## core for a picture that only changes on a click. This is still quick to answer one.
frames_a_second : U32
frames_a_second = 15

## How far a still reaches in its own units, where its height is 1.
StillExtent : {
	left : F64,
	right : F64,
	bottom : F64,
	top : F64,
}

## One small still: its pose, the area a click on it lands in, and where it
## stands there.
StillCell : {
	pose : StillsWidgetApp.Pose,
	area : Click.Area,
	anchor : StillShapes.Anchor,
}

cat_pose_name : PosedCat.CatPose -> Str
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

bird_pose_name : PosedBird.BirdPose -> Str
bird_pose_name = |pose|
	match pose {
		Perched => "Perched"
		Side(WingsUp) => "Side up"
		Side(WingsDown) => "Side down"
		Away(WingsUp) => "Away up"
		Away(WingsDown) => "Away down"
		Diving => "Diving"
	}

## The name the widget gives a pose.
pose_name : StillsWidgetApp.Pose -> Str
pose_name = |pose|
	match pose {
		Cat(cat_pose) => cat_pose_name(cat_pose)
		Bird(bird_pose) => bird_pose_name(bird_pose)
	}

## A pose's still.
pose_still : StillsWidgetApp.Pose -> Still
pose_still = |pose|
	match pose {
		Cat(cat_pose) => PosedCat.pose_still(cat_pose)
		Bird(bird_pose) => PosedBird.pose_still(bird_pose)
	}

cat_poses : List(StillsWidgetApp.Pose)
cat_poses = [
	Cat(Rest),
	Cat(Stride),
	Cat(Frozen),
	Cat(Coil),
	Cat(Flight),
	Cat(Land),
	Cat(Collapse),
]

bird_poses : List(StillsWidgetApp.Pose)
bird_poses = [
	Bird(Perched),
	Bird(Side(WingsUp)),
	Bird(Side(WingsDown)),
	Bird(Away(WingsUp)),
	Bird(Away(WingsDown)),
	Bird(Diving),
]

extent_of : Still -> StillExtent
extent_of = |still|
	match still.polygons().join_map(|polygon| polygon.points) {
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
name_size = 13.0

## From the top of a still's name to its baseline.
name_rise : F64
name_rise = 10.0

## The height on screen that lets every still of a row fit a cell `cell_width`
## wide. A row shares one height, so a pose keeps its true size beside the
## others.
row_height_on_screen : List(StillsWidgetApp.Pose), F64 -> Pixels
row_height_on_screen = |poses, cell_width| {
	extents = poses.map(|pose| extent_of(pose_still(pose)))
	widest = extents.fold(0.0, |most, extent| most.max(extent_width(extent)))
	tallest = extents.fold(0.0, |most, extent| most.max(extent.top))
	Pixels.of(F64.min((cell_width - 2.0 * cell_padding) / widest, (cell_ground - cell_padding) / tallest))
}

## Where a still stands with its middle at `mid_x` and its y 0 at `ground_y`.
standing_at : Still,
{
	mid_x : F64,
	ground_y : F64,
	height_on_screen : Pixels,
} -> StillShapes.Anchor
standing_at = |still, { mid_x, ground_y, height_on_screen }| {
	extent = extent_of(still)
	{
		feet: Screen.point(mid_x - height_on_screen.to_f64() * (extent.left + extent.right) / 2.0, ground_y),
		flip: AsDrawn,
		height_on_screen,
	}
}

## A row of stills across the canvas, between its side margins.
row_cells : List(StillsWidgetApp.Pose), F64 -> List(StillCell)
row_cells = |poses, row_top| {
	cell_width = ScrubWidget.panel_width / poses.len().to_f64()
	height_on_screen = row_height_on_screen(poses, cell_width)
	poses.map_with_index(
		|pose, column| {
			left = ScrubWidget.side_margin + column.to_f64() * cell_width
			{
				pose,
				area: {
					left,
					top: row_top,
					width: cell_width,
					height: cell_height,
				},
				anchor: standing_at(
					pose_still(pose),
					{
						mid_x: left + cell_width / 2.0,
						ground_y: row_top + cell_ground,
						height_on_screen,
					},
				),
			}
		},
	)
}

## The cat's poses on the first row, and the bird's on the second.
cells : List(StillCell)
cells =
	row_cells(cat_poses, ScrubWidget.picture_bottom_y)
		.concat(row_cells(bird_poses, ScrubWidget.picture_bottom_y + cell_height))

## Where the words stop and the large still starts.
large_area_left : F64
large_area_left = 264.0

## What the large still keeps clear of the top of the canvas and of the panel.
large_area_margin : F64
large_area_margin = 10.0

## Where the large still may reach, to the right of the words.
large_area : Click.Area
large_area = {
	left: large_area_left,
	top: large_area_margin,
	width: ScrubWidget.canvas_width - ScrubWidget.side_margin - large_area_left,
	height: ScrubWidget.picture_bottom_y - 2.0 * large_area_margin,
}

## A still as large as `large_area` holds it, in the middle of that area.
large_anchor : Still -> StillShapes.Anchor
large_anchor = |still| {
	extent = extent_of(still)
	height_px = F64.min(
		large_area.width / extent_width(extent),
		large_area.height / (extent.top - extent.bottom),
	)
	middle = middle_of(large_area)
	standing_at(
		still,
		{
			mid_x: middle.x,
			ground_y: middle.y + height_px * (extent.top + extent.bottom) / 2.0,
			height_on_screen: Pixels.of(height_px),
		},
	)
}

middle_of : Click.Area -> { x : F64, y : F64 }
middle_of = |area| { x: area.left + area.width / 2.0, y: area.top + area.height / 2.0 }

## `model` after a click at `spot`, which does nothing off the stills.
model_after_click : StillsWidgetApp.Model, { x : F64, y : F64 } -> StillsWidgetApp.Model
model_after_click = |model, spot|
	match cells.find_first(|cell| cell.area.contains(spot)) {
		Ok(cell) => { ..model, large_pose: cell.pose }
		Err(NotFound) =>
			if large_area.contains(spot) {
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
	match Click.click_point(input) {
		Ok(spot) => model_after_click(model, spot)
		Err(NoClick) => model
	}

picture_color : RgbColor
picture_color = RgbColor.of(0xf7f5ef)

ink : Brush.Rgba
ink = Brush.opaque(ScrubWidget.ink_color)

point_count : Still -> U64
point_count = |still| still.polygons().fold(0, |sum, polygon| sum + polygon.points.len())

## What a pose's still is made of, a line each.
read_out_lines : StillsWidgetApp.Pose -> List(Str)
read_out_lines = |pose| {
	still = pose_still(pose)
	[
		pose_name(pose),
		"${ReadoutText.count_text(still.polygons().len())} polygons",
		"${ReadoutText.count_text(point_count(still))} points",
	]
}

read_out_size : F64
read_out_size = 18.0

read_out_line : Str, U64 -> Shapes.Shape
read_out_line = |text, row|
	ScrubWidget.readout({
		text,
		color: ScrubWidget.ink_color,
		row,
		style: { ..ScrubWidget.panel_readout, first_baseline: 42.0, size: read_out_size },
	})

hint_lines : List(Str)
hint_lines = ["Click a still below.", "Click the large one", "to outline its polygons."]

hint_line : Str, U64 -> Shapes.Shape
hint_line = |text, row|
	ScrubWidget.label({
		text,
		x: ScrubWidget.side_margin,
		y: 138.0 + row.to_f64() * 18.0,
	})

## The lines round one polygon. A still repeats a point here and there, and the
## line between two such points is empty.
outline_shapes : StillShapes.Anchor, Still.Polygon -> List(Shapes.Shape)
outline_shapes = |anchor, polygon| {
	corners = StillShapes.screen_points(anchor, polygon.points)
	# A baked still repeats some corners, and a repeated corner has no edge.
	corners
		.map2(corners.drop_first(1).concat(corners.take_first(1)), |from, to| { from, to })
		.keep_if(|{ from, to }| from != to)
		.map(
			|{ from, to }|
				Shapes.line(
					{
						from: { x: from.x.to_f64(), y: from.y.to_f64() },
						to: { x: to.x.to_f64(), y: to.y.to_f64() },
						width: 1.0,
					},
					Flat(ink),
				),
		)
}

## The large still, with the outlines of its polygons if they show.
large_shapes : StillsWidgetApp.Model -> List(Shapes.Shape)
large_shapes = |{ large_pose, outlines }| {
	still = pose_still(large_pose)
	anchor = large_anchor(still)
	drawn = StillShapes.still_shapes(anchor, still)
	match outlines {
		Hidden => drawn
		Shown => {
			outline = still.polygons().join_map(|polygon| outline_shapes(anchor, polygon))
			drawn.concat(outline)
		}
	}
}

## The words and the large still, above the panel.
picture_shapes : StillsWidgetApp.Model -> List(Shapes.Shape)
picture_shapes = |model|
	[
		[ScrubWidget.picture_backdrop(picture_color)],
		read_out_lines(model.large_pose).map_with_index(read_out_line),
		hint_lines.map_with_index(hint_line),
		large_shapes(model),
	].join()

## One small still with its pose's name under it.
cell_shapes : StillCell -> List(Shapes.Shape)
cell_shapes = |{ pose, area, anchor }|
	StillShapes.still_shapes(anchor, pose_still(pose)).append(
		Text({
			text: pose_name(pose),
			x: area.left + area.width / 2.0,
			y: area.top + cell_name_top + name_rise,
			size: name_size,
			face: Prose,
			align: Center,
			color: ink,
		}),
	)

## The grid never changes, so it's worked out once, when the widget is built.
grid_shapes : List(Shapes.Shape)
grid_shapes = cells.join_map(cell_shapes)

## The cell of the pose shown large, lit as the picture above it is.
mark_shapes : StillsWidgetApp.Pose -> List(Shapes.Shape)
mark_shapes = |large_pose|
	cells.keep_if(|cell| cell.pose == large_pose).map(
		|{ area, .. }|
			Rect({
				x: area.left,
				y: area.top,
				width: area.width,
				height: area.height,
				fill: Brush.flat(picture_color),
			}),
	)

## Everything on the canvas.
shapes_at : StillsWidgetApp.Model -> List(Shapes.Shape)
shapes_at = |model|
	ScrubWidget.frame_shapes({ picture_shapes: picture_shapes(model), status_lines: [] })
		.concat(mark_shapes(model.large_pose))
		.concat(grid_shapes)

## Where a point of a still lands, as plain numbers.
landing_spot : StillShapes.Anchor, Still.Vertex -> { x : F64, y : F64 }
landing_spot = |anchor, point| {
	on_screen = StillShapes.screen_point(anchor, point)
	{ x: on_screen.x.to_f64(), y: on_screen.y.to_f64() }
}

## Whether every point of a still lands in `area`.
stays_in : StillShapes.Anchor, { still : Still, area : Click.Area } -> Bool
stays_in = |anchor, { still, area }|
	still.polygons().all(|polygon| polygon.points.all(|point| area.contains(landing_spot(anchor, point))))

first_cell : StillCell
first_cell = cells.first() ?? crash "StillsWidgetApp.first_cell: the grid has cells"

last_cell : StillCell
last_cell = cells.last() ?? crash "StillsWidgetApp.last_cell: the grid has cells"

start : StillsWidgetApp.Model
start = StillsWidgetApp.canvas_app.init

## A left click at `spot` from `model`.
left_click : StillsWidgetApp.Model, { x : F64, y : F64 } -> StillsWidgetApp.Model
left_click = |model, spot| next_model(model, Click.click_at(spot))

## Whether `model` is unchanged from the start.
is_as_started : StillsWidgetApp.Model -> Bool
is_as_started = |model| model == start

# Every pose is in the grid, the cat's first, and no two share a cell.
expect cat_poses.len() == 7
expect bird_poses.len() == 6
expect cells.len() == 13
expect cells.map(|cell| cell.pose).take_first(2) == [Cat(Rest), Cat(Stride)]
expect cells.all(|cell| cells.keep_if(|other| other.pose == cell.pose).len() == 1)

# Each pose has its own still.
expect pose_still(Cat(Frozen)).polygons().len() == PosedCat.pose_still(Frozen).polygons().len()
expect point_count(pose_still(Bird(Diving))) == point_count(BirdStills.diving_still)

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
		|cell| cells.keep_if(|other| other.area.contains(middle_of(cell.area))).len() == 1,
	)

# A row shares one height, and no still leaves its cell or crosses its name.
expect cells.take_first(7).all(|cell| cell.anchor.height_on_screen == first_cell.anchor.height_on_screen)
expect cells.drop_first(7).all(|cell| cell.anchor.height_on_screen == last_cell.anchor.height_on_screen)
expect cells.all(|{ pose, area, anchor }| stays_in(anchor, { still: pose_still(pose), area }))
expect
	cells.all(
		|{ pose, area, anchor }| {
			above_name = { ..area, height: cell_name_top }
			stays_in(anchor, { still: pose_still(pose), area: above_name })
		},
	)

## Whether a cell's still fills the cell's width, up to the padding.
is_full_width : StillCell -> Bool
is_full_width = |{ pose, area, anchor }| {
	still_width = anchor.height_on_screen.to_f64() * extent_width(extent_of(pose_still(pose)))
	area.width - still_width <= 2.0 * cell_padding + 0.000001
}

# The widest still of each row just fits, so no row is smaller than it must be.
expect cells.take_first(7).any(is_full_width)
expect cells.drop_first(7).any(is_full_width)
expect !is_full_width(first_cell)

# Each name fits its cell, and one much longer would not.
expect cells.all(|{ pose, area, .. }| Font.room_for(pose_name(pose), name_size) <= area.width)
expect Font.room_for("Collapse, and then some", name_size) > first_cell.area.width

# The words all fit left of the large still.
expect
	cells.all(
		|{ pose, .. }|
			read_out_lines(pose).all(
				|line| {
					line_end = ScrubWidget.side_margin + Font.room_for(line, read_out_size)
					line_end <= large_area.left
				},
			),
	)
expect
	hint_lines.all(
		|line| ScrubWidget.side_margin + Font.room_for(line, ScrubWidget.label_size) <= large_area.left,
	)

## The large area with its far edges inside it, which a still may touch.
large_area_edges_held : Click.Area
large_area_edges_held = {
	..large_area,
	width: large_area.width + 0.001,
	height: large_area.height + 0.001,
}

# The large still stays in its area, for every still, and touches two of its sides.
expect
	cells.all(
		|{ pose, .. }| {
			still = pose_still(pose)
			stays_in(large_anchor(still), { still, area: large_area_edges_held })
		},
	)
expect
	cells.all(
		|{ pose, .. }| {
			extent = extent_of(pose_still(pose))
			height = large_anchor(pose_still(pose)).height_on_screen.to_f64()
			wide_room = large_area.width - height * extent_width(extent)
			tall_room = large_area.height - height * (extent.top - extent.bottom)
			wide_room.min(tall_room).abs() <= 0.000001
		},
	)

# Its middle is the area's, either way.
expect
	cells.all(
		|{ pose, .. }| {
			anchor = large_anchor(pose_still(pose))
			extent = extent_of(pose_still(pose))
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
	frozen = extent_of(PosedCat.pose_still(Frozen))
	frozen.top > 1.0 and frozen.bottom < 0.0 and frozen.left < 0.0 and frozen.right > 1.0
}
expect
	extent_of(
		Still.of([
			{
				fill: Flat(RgbColor.of(0)),
				points: [{ x: 0.5, y: 0.25 }, { x: -1.0, y: 2.0 }],
			},
			{
				fill: Flat(RgbColor.of(0)),
				points: [{ x: 3.0, y: -4.0 }],
			},
		]),
	)
		== {
			left: -1.0,
			right: 3.0,
			bottom: -4.0,
			top: 2.0,
		}

# The widget starts on the cat at rest, with no outlines.
expect start.large_pose == Cat(Rest)
expect start.outlines == Hidden

# A click on any cell shows that still large.
expect
	cells.all(
		|cell| left_click(start, middle_of(cell.area)).large_pose == cell.pose,
	)

# So does a click at a cell's corner, and the corner just past it is the next cell's.
expect {
	corner = { x: last_cell.area.left, y: last_cell.area.top }
	model_after_click(start, corner).large_pose == Bird(Diving)
		and model_after_click(start, { ..corner, x: corner.x - 1.0 }).large_pose == Bird(Away(WingsDown))
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
expect left_click(start, middle_of(large_area)).large_pose == Cat(Rest)

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
	right = Input.none.with_mouse(Mouse.of({ held: 2, struck: 2, at: { x: spot.x.to_f32_wrap(), y: spot.y.to_f32_wrap() }, wheel: 0.0 }))
	[Click.held_at(spot), right, Input.none].all(|input| is_as_started(next_model(start, input)))
}

expect toggled_outlines(Hidden) == Shown
expect toggled_outlines(Shown) == Hidden

# The read-out names the pose and counts its still, with commas.
expect read_out_lines(Cat(Rest)) == ["Rest", "46 polygons", "2,198 points"]

# The outlines add one line for each edge between two different corners, and
# none when hidden.
expect large_shapes(start).len() == pose_still(start.large_pose).polygons().len()
expect {
	edge_count = pose_still(start.large_pose).polygons().fold(
		0,
		|sum, polygon| {
			points = polygon.points
			ends = points.drop_first(1).concat(points.take_first(1))
			sum + points.map2(ends, |from, to| from != to).keep_if(|differ| differ).len()
		},
	)
	large_shapes({ ..start, outlines: Shown }).len() == pose_still(start.large_pose).polygons().len() + edge_count
}

# A polygon's outline closes: its last line ends where its first starts.
expect {
	square = {
		fill: Flat(RgbColor.of(0)),
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
		height_on_screen: Pixels.of(10.0),
	}
	match outline_shapes(anchor, square) {
		[_, _, _, Poly({ coordinates, .. })] => coordinates == [-0.5, 0.0, -0.5, 10.0, 0.5, 10.0, 0.5, 0.0]
		_ => False
	}
}

# A repeated corner makes no line, so a still of one point has no outline, and
# one of two points has a line there and one back.
expect {
	anchor = {
		feet: Screen.point(0.0, 0.0),
		flip: AsDrawn,
		height_on_screen: Pixels.of(10.0),
	}
	outline_of = |points| outline_shapes(anchor, { fill: Flat(RgbColor.of(0)), points })
	outline_of([{ x: 1.0, y: 1.0 }]) == [] and outline_of([{ x: 1.0, y: 1.0 }, { x: 1.0, y: 0.0 }]).len() == 2
}

# The picture answers each click.
expect shapes_at(start) != shapes_at(left_click(start, middle_of(last_cell.area)))
expect shapes_at(start) != shapes_at(left_click(start, middle_of(large_area)))
expect shapes_at(start) == shapes_at(left_click(start, { x: 100.0, y: 60.0 }))

# One cell is lit, the one shown large.
expect mark_shapes(Cat(Land)).len() == 1
expect mark_shapes(Bird(Diving)).len() == 1
expect mark_shapes(Cat(Land)) != mark_shapes(Bird(Diving))
