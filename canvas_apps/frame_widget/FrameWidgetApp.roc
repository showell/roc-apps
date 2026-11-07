## The widget for the first half of the Safari tutorial, which walks through one
## page of the flipbook a chapter at a time. It holds step 1,570 of the ride, with
## the cat frozen in the road, and shows that frame one layer at a time. The
## shapes are the game's own for that step, sorted into layers and painted in the
## game's order, because depth sorting interleaves the things beside the road.
## The address picks how many layers are on, and from there it's a still picture
## with no controls. The first line of text counts the shapes so far against the
## frame's total, and the second names the last layer on.
import game.Backdrop
import game.RoadAhead
import game.Clock
import game.FrameView
import game.Ground
import game.GroundSighting
import game.Mountains
import game.RiderCamera
import game.SafariApp
import game.Scene
import game.SceneShapes
import game.Screen
import game.Sky
import game.Tour
import lib.Brush
import lib.RgbColor
import lib.CanvasApp
import lib.Input
import lib.Shapes
import widget.ReadoutText
import "page.html" as page_html : Str

FrameWidgetApp :: [].{

	## The whole state of the widget: how many of the layers are on, in the book's
	## order, from one to all of them, and whether that's still being settled.
	Model : { layers_on : U64, opening : [Opening, Opened] }

	canvas_app : CanvasApp.CanvasApp(FrameWidgetApp.Model)
	canvas_app = {
		size: { width: canvas_width, height: canvas_height },
		fps: frames_a_second,
		init: { layers_on: 1, opening: Opening },
		model_at_next_step: |model, input, _seconds| next_model(model, input),
		frame_shapes: shapes_at,
		sounds: |_model| 0,
		tones: [],
		title: "One frame of the ride",
	}
}

## The picture doesn't change once it's open, so a few frames a second will do.
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

## `things` if `layer` is one of `on_layers`, else none.
things_on : List(thing), { on_layers : List(Layer), layer : Layer } -> List(thing)
things_on = |things, { on_layers, layer }|
	if on_layers.contains(layer) {
		things
	} else {
		[]
	}

## The things beside the road on `on_layers`, in the game's paint order. A scene
## that holds only some of the things draws them in the order the whole scene
## does, so the game's own `SceneShapes` orders each layer among the others.
scene_shapes_on : List(Layer) -> List(Shapes.Shape)
scene_shapes_on = |on_layers| {
	only = {
		trees: things_on(paused_scene.trees, { on_layers, layer: Trees }),
		towers: things_on(paused_scene.towers, { on_layers, layer: Towers }),
		billboards: things_on(paused_scene.billboards, { on_layers, layer: Critters }),
		cats: things_on(paused_scene.cats, { on_layers, layer: MovingThings }),
		rails: things_on(paused_scene.rails, { on_layers, layer: Rails }),
		truck: if on_layers.contains(MovingThings) {
			paused_scene.truck
		} else {
			Err(NoTruck)
		},
		birds: things_on(paused_scene.birds, { on_layers, layer: MovingThings }),
	}
	SceneShapes.scene_shapes(only, paused_view)
}

## What `Backdrop.frame_shapes` paints under the ride's shapes: the sky, the grass, and
## what the sun adds when it's in view.
backdrop_pieces : FrameView -> List(Piece)
backdrop_pieces = |view| {
	backdrop = Backdrop.backdrop_shapes({ sky_colors: view.sky_colors, sun_sighting: view.sun_sighting })
	[
		{ layer: Sky, shapes: [backdrop.sky] },
		{ layer: Grass, shapes: [backdrop.grass] },
		{ layer: Sun, shapes: backdrop.sun_shapes },
	]
}

## The camera the ride sees through at the step on show.
paused_camera : RiderCamera
paused_camera = RiderCamera.of(paused_tour.instant.rider, paused_tour.route)

paused_view : RoadAhead.CameraView
paused_view = paused_camera.camera_view(paused_tour.route)

## What the camera shows at the step on show.
paused_frame_view : FrameView
paused_frame_view = Tour.frame_view(paused_tour)

## The things in view at the step on show.
paused_scene : Scene
paused_scene = {
	instant = paused_tour.instant
	Scene.scene_in_view(
		paused_view,
		{
			speed: instant.rider.motorcycle.speed,
			truck: {
				route_position: instant.truck.route_position,
				lit_truck: FrameView.lit_truck(instant),
			},
			clock: instant.clock,
		},
	)
}

## The mountains and the road, which `FrameView.frame_view_at` puts under the things
## beside the road, each with its layer.
ground_parts : List(Piece)
ground_parts = {
	skyline = Mountains.mountain_shapes(paused_camera, Sky.dusk_at(paused_tour.instant.clock))
	ground = GroundSighting.patches_in_view(paused_view.road).keep_oks(
		|patch| Ground.patch_shape(patch, paused_camera.cam_focal),
	)
	[{ layer: Mountains, shapes: skyline }, { layer: Road, shapes: ground }]
}

backdrop_parts : List(Piece)
backdrop_parts = backdrop_pieces(paused_frame_view)

## The part of `Tour.frame_view(tour).shapes` on `on_layers`, in its order.
## `FrameView.frame_view_at` joins its parts into one list, so this asks for them one
## at a time, and an `expect` below holds the join to the real list.
ride_shapes_on : List(Layer) -> List(Shapes.Shape)
ride_shapes_on = |on_layers| shapes_in(ground_parts, on_layers).concat(scene_shapes_on(on_layers))

## The frame's shapes on `on_layers`, backdrop and all, in paint order.
frame_shapes_on : List(Layer) -> List(Shapes.Shape)
frame_shapes_on = |on_layers| shapes_in(backdrop_parts, on_layers).concat(ride_shapes_on(on_layers))

## The space the paused frame leans in, which `SafariApp.frame_shapes` puts
## the whole frame in.
lean_space : Shapes.Space
lean_space = SafariApp.lean_space(paused_frame_view.roll)

## The first `count` of the layers.
layers_up_to : U64 -> List(Layer)
layers_up_to = |count| layers.take_first(count)

## The shapes of `parts` in `on_layers`, in paint order.
shapes_in : List(Piece), List(Layer) -> List(Shapes.Shape)
shapes_in = |parts, on_layers|
	parts.keep_if(|piece| on_layers.contains(piece.layer)).join_map(|piece| piece.shapes)

## How many of the ride's shapes are in `on_layers`.
ride_count : List(Layer) -> U64
ride_count = |on_layers| ride_shapes_on(on_layers).len()

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
	width: picture_width,
	height: picture_height,
	fill: Brush.flat(RgbColor.of(0xE8E6DF)),
})

panel : Shapes.Shape
panel = Rect({
	x: 0.0,
	y: picture_height,
	width: canvas_width,
	height: panel_height,
	fill: Brush.flat(RgbColor.of(0xDCECF5)),
})

## An address that names a layer has the page press Right once for each layer
## past the first, before the first frame. The first frame with no press settles
## the picture, so a reader's arrow keys do nothing.
next_model : FrameWidgetApp.Model, Input.Snapshot -> FrameWidgetApp.Model
next_model = |model, input|
	match model.opening {
		Opened => model
		Opening =>
			if input.key_pressed(KeyRight) {
				{ ..model, layers_on: model.layers_on + 1 }
			} else {
				{ ..model, opening: Opened }
			}
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
status_lines = |{ layers_on, .. }| {
	on_layers = layers_up_to(layers_on)
	added = on_layers.last() ?? crash "FrameWidgetApp.status_lines: a layer is always on"
	so_far = ReadoutText.count_text(ride_count(on_layers))
	total = ReadoutText.count_text(ride_count(layers))
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
		color: Brush.opaque(RgbColor.of(0x202020)),
	})

## The layers on, in the game's paint order.
picture_shapes : List(Layer) -> List(Shapes.Shape)
picture_shapes = |on_layers| Shapes.in_space(lean_space, frame_shapes_on(on_layers))

## Everything on the canvas.
shapes_at : FrameWidgetApp.Model -> List(Shapes.Shape)
shapes_at = |model|
	[
		[plain_background],
		picture_shapes(layers_up_to(model.layers_on)),
		[panel],
		status_lines(model).map_with_index(status_line),
	].join()

# The step is the one the book holds, and the ride's own record of it.
expect paused_tour.instant.clock == Clock.at_step(frame_step)
expect frame_step == 1570

# All the layers on is the game's own frame, shape for shape and in its order.
expect picture_shapes(layers) == SafariApp.frame_shapes(paused_tour)

# The ride's parts are the game's own shapes, in the game's order.
expect ride_shapes_on(layers) == paused_frame_view.shapes

# The frame's total is the count the book's table gives for this step.
expect ride_count(layers) == paused_frame_view.shapes.len()
expect ride_count(layers) == 2568

# Each layer's own shapes at this step. The sun is behind the rider, so it has none.
expect
	layers.map(|layer| frame_shapes_on([layer]).len())
		== [1656, 1, 0, 1, 4, 4, 302, 187, 352, 63]
expect paused_frame_view.sun_sighting == OutOfView

# The running count at each layer. The backdrop stays out of it.
expect
	List.from_iter(U64.until(1, layers.len() + 1)).map(|count| ride_count(layers_up_to(count)))
		== [1656, 1656, 1656, 1656, 1660, 1664, 1966, 2153, 2505, 2568]

# A layer with shapes of its own always changes the picture, and the sun doesn't.
expect picture_shapes(layers_up_to(1)) != picture_shapes(layers_up_to(2))
expect picture_shapes(layers_up_to(2)) == picture_shapes(layers_up_to(3))
expect picture_shapes(layers_up_to(3)) != picture_shapes(layers_up_to(4))
expect picture_shapes(layers_up_to(9)) != picture_shapes(layers_up_to(10))

# The first layer alone is the lean and the trees, in the game's order.
expect picture_shapes([Trees]) == Shapes.in_space(lean_space, ride_shapes_on([Trees]))

# Sky is painted before grass, whichever the book comes to first.
expect frame_shapes_on([Grass, Sky]) == frame_shapes_on([Sky, Grass])
expect
	frame_shapes_on([Grass, Sky])
		== frame_shapes_on([Sky]).concat(frame_shapes_on([Grass]))

# The page's list of words, which a fence's word is looked up in, is the layers'
# own: all of them, in order.
expect {
	quoted_words = layers.map(|layer| "'${layer_word(layer)}'")
	page_html.contains("opensAt: [${Str.join_with(quoted_words, ", ")}],")
}

start : FrameWidgetApp.Model
start = FrameWidgetApp.canvas_app.init

all_on : FrameWidgetApp.Model
all_on = { layers_on: layers.len(), opening: Opened }

right_press : Input.Snapshot
right_press = Input.none.with_key_pressed(KeyRight)

## The model once the page has pressed Right `count` times and a frame has gone
## by.
opened_after : U64 -> FrameWidgetApp.Model
opened_after = |count| next_model(
	List.repeat(right_press, count).fold(start, next_model),
	Input.none,
)

# An address with no word opens on the trees alone, and the last word opens on
# every layer.
expect opened_after(0) == { layers_on: 1, opening: Opened }
expect opened_after(5) == { layers_on: 6, opening: Opened }
expect opened_after(layers.len() - 1) == all_on

# Once it's open, the arrow keys change nothing.
expect next_model(opened_after(0), right_press) == opened_after(0)
expect next_model(all_on, Input.none.with_key_pressed(KeyLeft)) == all_on

# A press of any other key during the opening doesn't count as a layer.
expect next_model(start, Input.none.with_key_pressed(KeyLeft)) == opened_after(0)

expect
	status_lines(start)
		== ["Shapes so far: 1,656 of 2,568", "Added: Trees"]
expect
	status_lines(opened_after(2))
		== ["Shapes so far: 1,656 of 2,568", "Added: The sun, out of view here"]
expect
	status_lines(opened_after(5))
		== ["Shapes so far: 1,664 of 2,568", "Added: The road and pond"]
expect
	status_lines(all_on)
		== ["Shapes so far: 2,568 of 2,568", "Added: The moving things"]

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
expect shapes_at(start) != shapes_at(all_on)
expect
	shapes_at(all_on).first() == Ok(plain_background)
		and shapes_at(all_on).contains(panel)
		and shapes_at(all_on).contains(View(Screen))
