## The widget for the first half of the Safari tutorial, which walks through one
## page of the flipbook a chapter at a time. It holds step 1,570 of the ride, with
## the cat frozen in the road, and shows that frame one layer at a time. The
## shapes are the game's own for that step, sorted into layers and painted in the
## game's order, because depth sorting interleaves the things beside the road.
## Back and Next, or the arrow keys, take a layer off or put one on. The first line
## of text counts the shapes so far against the frame's total, and the second names
## the layer just added.
import game.Backdrop
import game.Chain
import game.Clock
import game.DepthSort
import game.Ground
import game.GroundSighting
import game.Mountains
import game.RideFocal
import game.RideInstant
import game.SafariApp
import game.Scene
import game.SceneDraw
import game.Screen
import game.Sky
import game.Tour
import game.ViewYaw
import lib.Brush
import lib.CanvasApp
import lib.Input
import lib.Mouse
import lib.Shapes
import widget.ScrubWidget
import "page.html" as page_html : Str

FrameWidgetApp :: [].{

	## The whole state of the widget: how many of the layers are on, in the book's
	## order, from one to all of them.
	Model : { layers_on : U64 }

	canvas_app : CanvasApp.CanvasApp(FrameWidgetApp.Model)
	canvas_app = {
		size: { width: canvas_width, height: canvas_height },
		fps: frames_a_second,
		init: { layers_on: 1 },
		advance: |model, input, _seconds| next_model(model, input),
		frame: frame_at,
		sounds: |_model| 0,
		tones: [],
		title: "One frame of the ride",
	}
}

## The picture only changes on a click, and this is still quick to answer one.
frames_a_second : I32
frames_a_second = 15

## What can be switched on, in the order the book's chapters come to it.
Layer : [
	Trees,
	Grass,
	Sun,
	Sky,
	Mountains,
	Road,
	Rails,
	Towers,
	Critters,
	MovingThings,
]

layers : List(Layer)
layers = [
	Trees,
	Grass,
	Sun,
	Sky,
	Mountains,
	Road,
	Rails,
	Towers,
	Critters,
	MovingThings,
]

## Some of the frame in paint order, all of it from one layer.
Piece : { layer : Layer, shapes : List(Shapes.Shape) }

## The step on show.
frame_step : U32
frame_step = 1570

## The ride at `frame_step`, with no history to step back through.
paused_tour : Tour
paused_tour = {
	var $tour = Tour.initial
	while $tour.instant.clock != Clock.at_step(frame_step) {
		$tour = Tour.step_forward($tour)
	}
	{ ..$tour, past_instants: [] }
}

## The layer a thing beside the road belongs to.
subject_layer : DepthSort.Subject -> Layer
subject_layer = |subject|
	match subject {
		Tree(_) => Trees
		Tower(_) => Towers
		Cutout(_) => Critters
		Rail(_) => Rails
		Cat(_) | Truck | Bird(_) => MovingThings
	}

## What `Backdrop.behind` paints under the ride's shapes: the sky, the grass, and
## what the sun adds when it's in view.
backdrop_pieces : Tour -> List(Piece)
backdrop_pieces = |tour| {
	backdrop = Backdrop.behind(
		[],
		{
			sky_top_color: Tour.sky_top_color(tour),
			sky_horizon_color: Tour.sky_horizon_color(tour),
			sun_sighting: Tour.sun(tour),
		},
	)
	[
		{ layer: Sky, shapes: backdrop.take_first(1) },
		{ layer: Grass, shapes: backdrop.drop_first(1).take_first(1) },
		{ layer: Sun, shapes: backdrop.drop_first(2) },
	]
}

## `Tour.shapes(tour)`, each part with its layer. `RideInstant.shapes` joins its
## parts into one list, so this asks for them one at a time, and an `expect` below
## holds the join to the real list.
ride_pieces : Tour -> List(Piece)
ride_pieces = |tour| {
	instant = tour.instant
	rider = instant.rider
	view = {
		road: {
			route: tour.route,
			chain: Chain.chain_ahead(tour.route, rider.segment_index),
			vantage: ViewYaw.vantage_for(rider),
		},
		cam_focal: RideFocal.ride_focal(tour.route, rider),
	}
	scene = Scene.in_view(
		view,
		{
			speed: rider.speed,
			truck: {
				route_position: instant.truck.route_position,
				lights: RideInstant.truck_lights(instant),
			},
			clock: instant.clock,
		},
	)
	skyline = Mountains.draw({
		heading: ViewYaw.heading_for(rider),
		dusk: Sky.dusk_at(instant.clock),
		cam_focal: view.cam_focal,
	})
	ground = GroundSighting.in_view(view.road).join_map(|patch| Ground.draw(patch, view.cam_focal))
	[
		[{ layer: Mountains, shapes: skyline }, { layer: Road, shapes: ground }],
		scene.order.map(
			|depth_key| {
				layer: subject_layer(depth_key.subject),
				shapes: SceneDraw.draw({ ..scene, order: [depth_key] }, view),
			},
		),
	].join()
}

ride_parts : List(Piece)
ride_parts = ride_pieces(paused_tour)

frame_parts : List(Piece)
frame_parts = backdrop_pieces(paused_tour).concat(ride_parts)

## The camera's roll, which `SafariApp.frame` puts first.
lean_mark : Shapes.Shape
lean_mark =
	SafariApp.frame(paused_tour).first()
		?? crash "FrameWidgetApp.lean_mark: a frame starts with its lean"

## The first `count` of the layers.
layers_up_to : U64 -> List(Layer)
layers_up_to = |count| layers.take_first(count)

## The shapes of `parts` in `on`, in paint order.
shapes_in : List(Piece), List(Layer) -> List(Shapes.Shape)
shapes_in = |parts, on|
	parts.keep_if(|piece| on.contains(piece.layer)).join_map(|piece| piece.shapes)

## How many of the ride's shapes are in `on`.
ride_count : List(Layer) -> U64
ride_count = |on| shapes_in(ride_parts, on).len()

## The real frame's size in pixels, and the panel's below it.
picture_width : F64
picture_width = Screen.width.to_f64()

picture_height : F64
picture_height = Screen.height.to_f64()

panel_height : F64
panel_height = 100.0

canvas_width : F64
canvas_width = picture_width

canvas_height : F64
canvas_height = picture_height + panel_height

## Behind whatever is on, so a frame with no sky has something to be seen against.
plain_background : Shapes.Shape
plain_background = Rect({
	x: 0.0,
	y: 0.0,
	w: picture_width,
	h: picture_height,
	fill: ScrubWidget.flat(0xe8e6df),
})

panel : Shapes.Shape
panel = Rect({
	x: 0.0,
	y: picture_height,
	w: canvas_width,
	h: panel_height,
	fill: ScrubWidget.flat(0xdcecf5),
})

## A button's place on the canvas.
Area : {
	left : F64,
	top : F64,
	width : F64,
	height : F64,
}

back_area : Area
back_area = {
	left: 680.0,
	top: 618.0,
	width: 120.0,
	height: 64.0,
}

next_area : Area
next_area = { ..back_area, left: 816.0 }

is_inside : Area, { x : F64, y : F64 } -> Bool
is_inside = |area, { x, y }|
	x >= area.left
		and x < area.left + area.width
		and y >= area.top
		and y < area.top + area.height

button : Area, Str -> List(Shapes.Shape)
button = |area, label|
	[
		Rect({
			x: area.left,
			y: area.top,
			w: area.width,
			h: area.height,
			fill: ScrubWidget.flat(0x303030),
		}),
		Text({
			text: label,
			x: area.left + area.width / 2.0,
			y: area.top + area.height / 2.0 + 8.0,
			size: 24.0,
			face: Prose,
			align: Center,
			color: Brush.opaque(0xf7f5f0),
		}),
	]

## One layer on from `model`, round to the first after the last.
one_layer_on : FrameWidgetApp.Model -> FrameWidgetApp.Model
one_layer_on = |{ layers_on }|
	if layers_on == layers.len() {
		{ layers_on: 1 }
	} else {
		{ layers_on: layers_on + 1 }
	}

## One layer off from `model`, round to the last before the first.
one_layer_off : FrameWidgetApp.Model -> FrameWidgetApp.Model
one_layer_off = |{ layers_on }|
	if layers_on == 1 {
		{ layers_on: layers.len() }
	} else {
		{ layers_on: layers_on - 1 }
	}

## `model` after a click at `spot`, which does nothing off the buttons.
after_click : FrameWidgetApp.Model, { x : F64, y : F64 } -> FrameWidgetApp.Model
after_click = |model, spot|
	if is_inside(next_area, spot) {
		one_layer_on(model)
	} else if is_inside(back_area, spot) {
		one_layer_off(model)
	} else {
		model
	}

next_model : FrameWidgetApp.Model, Input.Snapshot -> FrameWidgetApp.Model
next_model = |model, input|
	if input.key_pressed(KeyRight) {
		one_layer_on(model)
	} else if input.key_pressed(KeyLeft) {
		one_layer_off(model)
	} else if input.mouse.button_pressed(Left) {
		position = input.mouse.position()
		after_click(model, { x: position.x.to_f64(), y: position.y.to_f64() })
	} else {
		model
	}

## How the book names a layer: the word after `frame` in a ```widget fence.
layer_word : Layer -> Str
layer_word = |layer|
	match layer {
		Trees => "trees"
		Grass => "grass"
		Sun => "sun"
		Sky => "sky"
		Mountains => "mountains"
		Road => "road"
		Rails => "rails"
		Towers => "towers"
		Critters => "critters"
		MovingThings => "moving"
	}

## What the second line of text calls a layer. The sky, the grass and the sun are
## the backdrop, which the frame's total leaves out.
layer_name : Layer -> Str
layer_name = |layer|
	match layer {
		Trees => "Trees"
		Grass => "Grass, in the backdrop"
		Sun => "The sun, out of view here"
		Sky => "The sky, in the backdrop"
		Mountains => "Mountains and land"
		Road => "The road and pond"
		Rails => "Rails"
		Towers => "Radio towers"
		Critters => "Critters"
		MovingThings => "The moving things"
	}

## The two lines under the picture.
status_lines : FrameWidgetApp.Model -> List(Str)
status_lines = |{ layers_on }| {
	on = layers_up_to(layers_on)
	added = on.last() ?? crash "FrameWidgetApp.status_lines: a layer is always on"
	so_far = ScrubWidget.count_text(ride_count(on))
	total = ScrubWidget.count_text(ride_count(layers))
	["Shapes so far: ${so_far} of ${total}", "Added: ${layer_name(added)}"]
}

status_line : Str, U64 -> Shapes.Shape
status_line = |text, row|
	Text({
		text,
		x: 24.0,
		y: 640.0 + row.to_f64() * 36.0,
		size: 22.0,
		face: Code,
		align: Left,
		color: Brush.opaque(0x202020),
	})

## The layers on, in the game's paint order.
picture : List(Layer) -> List(Shapes.Shape)
picture = |on| shapes_in(frame_parts, on).prepend(lean_mark)

## Everything on the canvas.
frame_at : FrameWidgetApp.Model -> List(Shapes.Shape)
frame_at = |model|
	[
		[plain_background],
		picture(layers_up_to(model.layers_on)),
		[View(Screen), panel],
		button(back_area, "Back"),
		button(next_area, "Next"),
		status_lines(model).map_with_index(status_line),
	].join()

# The step is the one the book holds, and the ride's own record of it.
expect paused_tour.instant.clock == Clock.at_step(frame_step)
expect frame_step == 1570

# All the layers on is the game's own frame, shape for shape and in its order.
expect picture(layers) == SafariApp.frame(paused_tour)

# The ride's parts are the game's own shapes, in the game's order.
expect ride_parts.join_map(|piece| piece.shapes) == Tour.shapes(paused_tour)

# The frame's total is the count the book's table gives for this step.
expect ride_count(layers) == Tour.shapes(paused_tour).len()
expect ride_count(layers) == 2712

# Each layer's own shapes at this step. The sun is behind the rider, so it has none.
expect
	layers.map(|layer| shapes_in(frame_parts, [layer]).len())
		== [1656, 1, 0, 1, 4, 148, 302, 187, 352, 63]
expect Tour.sun(paused_tour) == OutOfView

# The running count at each layer. The backdrop stays out of it.
expect
	List.from_iter(U64.until(1, layers.len() + 1)).map(|count| ride_count(layers_up_to(count)))
		== [1656, 1656, 1656, 1656, 1660, 1808, 2110, 2297, 2649, 2712]

# A layer with shapes of its own always changes the picture, and the sun doesn't.
expect picture(layers_up_to(1)) != picture(layers_up_to(2))
expect picture(layers_up_to(2)) == picture(layers_up_to(3))
expect picture(layers_up_to(3)) != picture(layers_up_to(4))
expect picture(layers_up_to(9)) != picture(layers_up_to(10))

# The first layer alone is the lean and the trees, in the game's order.
expect picture([Trees]) == shapes_in(ride_parts, [Trees]).prepend(lean_mark)

# Sky is painted before grass, whichever the book comes to first.
expect shapes_in(frame_parts, [Grass, Sky]) == shapes_in(frame_parts, [Sky, Grass])
expect
	shapes_in(frame_parts, [Grass, Sky])
		== shapes_in(frame_parts, [Sky]).concat(shapes_in(frame_parts, [Grass]))

# Every thing beside the road has a layer.
expect subject_layer(Tree(0)) == Trees
expect subject_layer(Tower(0)) == Towers
expect subject_layer(Cutout(0)) == Critters
expect subject_layer(Rail(0)) == Rails
expect subject_layer(Cat(0)) == MovingThings
expect subject_layer(Truck) == MovingThings
expect subject_layer(Bird(0)) == MovingThings

# The page's list of words, which a fence's word is looked up in, is the layers'
# own: all of them, in order.
expect {
	quoted_words = layers.map(|layer| "'${layer_word(layer)}'")
	page_html.contains("opensAt: [${Str.join_with(quoted_words, ", ")}],")
}

## A snapshot with the buttons in `held` down, those in `struck` pressed just now.
pointer_at : {
	x : F64,
	y : F64,
	held : U32,
	struck : U32,
} -> Input.Snapshot
pointer_at = |{ x, y, held, struck }|
	Input.none.with_mouse(Mouse.of(held, struck, x.to_f32_wrap(), y.to_f32_wrap(), 0.0))

## `model` after a left click at `spot`.
left_click : FrameWidgetApp.Model, { x : F64, y : F64 } -> FrameWidgetApp.Model
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

middle_of : Area -> { x : F64, y : F64 }
middle_of = |area| { x: area.left + area.width / 2.0, y: area.top + area.height / 2.0 }

start : FrameWidgetApp.Model
start = FrameWidgetApp.canvas_app.init

all_on : FrameWidgetApp.Model
all_on = { layers_on: layers.len() }

expect start == { layers_on: 1 }

# Next puts a layer on, Back takes one off, and each goes round at its end.
expect left_click(start, middle_of(next_area)) == { layers_on: 2 }
expect left_click({ layers_on: 2 }, middle_of(back_area)) == start
expect left_click({ layers_on: 9 }, middle_of(next_area)) == all_on
expect left_click(all_on, middle_of(next_area)) == start
expect left_click(start, middle_of(back_area)) == all_on

# The arrow keys do the same, and they're how a page opens partway.
expect next_model(start, Input.none.with_key_pressed(KeyRight)) == { layers_on: 2 }
expect next_model({ layers_on: 2 }, Input.none.with_key_pressed(KeyLeft)) == start
expect next_model(all_on, Input.none.with_key_pressed(KeyRight)) == start
expect next_model(start, Input.none.with_key_pressed(KeyLeft)) == all_on
expect
	List.repeat(Input.none.with_key_pressed(KeyRight), layers.len() - 1).fold(start, next_model)
		== all_on

# A button ends where its area does.
expect is_inside(next_area, { x: next_area.left, y: next_area.top })
expect !is_inside(next_area, { x: next_area.left - 1.0, y: next_area.top })
expect !is_inside(next_area, { x: next_area.left, y: next_area.top - 1.0 })
expect !is_inside(next_area, { x: next_area.left + next_area.width, y: next_area.top })
expect !is_inside(next_area, { x: next_area.left, y: next_area.top + next_area.height })
expect is_inside(next_area, { x: next_area.left + next_area.width - 1.0, y: next_area.top })
expect is_inside(next_area, { x: next_area.left, y: next_area.top + next_area.height - 1.0 })

# Between the buttons and off them, a click does nothing.
expect left_click(start, { x: 808.0, y: 650.0 }) == start
expect left_click(start, { x: 300.0, y: 650.0 }) == start
expect left_click(start, { x: 480.0, y: 300.0 }) == start

# book_check.mjs clicks here, on Next. page_check.mjs presses here to learn whether
# the pointer changes the picture, and a page where a finger scrolls has to answer no.
expect left_click(start, { x: 873.6, y: 651.0 }) == { layers_on: 2 }
expect left_click(start, { x: 192.0, y: 280.0 }) == start

# Only a press of the left button is a click: not one held from before, not
# the right button, and not nothing at all.
expect {
	spot = middle_of(next_area)
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
	[held, right, Input.none].all(|input| next_model(start, input) == start)
}

expect
	status_lines(start)
		== ["Shapes so far: 1,656 of 2,712", "Added: Trees"]
expect
	status_lines({ layers_on: 3 })
		== ["Shapes so far: 1,656 of 2,712", "Added: The sun, out of view here"]
expect
	status_lines({ layers_on: 6 })
		== ["Shapes so far: 1,808 of 2,712", "Added: The road and pond"]
expect
	status_lines(all_on)
		== ["Shapes so far: 2,712 of 2,712", "Added: The moving things"]

expect
	layers.map(layer_name)
		== [
			"Trees",
			"Grass, in the backdrop",
			"The sun, out of view here",
			"The sky, in the backdrop",
			"Mountains and land",
			"The road and pond",
			"Rails",
			"Radio towers",
			"Critters",
			"The moving things",
		]
expect
	layers.map(layer_word)
		== [
			"trees",
			"grass",
			"sun",
			"sky",
			"mountains",
			"road",
			"rails",
			"towers",
			"critters",
			"moving",
		]

# The canvas answers the layers, and the panel stays over whatever leans past it.
expect frame_at(start) != frame_at(all_on)
expect
	frame_at(all_on).first() == Ok(plain_background)
		and frame_at(all_on).contains(panel)
		and frame_at(all_on).contains(View(Screen))
