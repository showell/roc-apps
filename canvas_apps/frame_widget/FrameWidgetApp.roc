## The widget for the first half of the Safari tutorial, which walks through one
## page of the flipbook a chapter at a time. It holds step 1,529 of the ride, with
## the cat frozen in the road, and shows that frame one layer at a time. The
## shapes are the game's own for that step, sorted into layers and painted in the
## game's order, because depth sorting interleaves the things beside the road.
## The address picks how many layers are on, and from there it's a still picture
## with no controls. The first line of text counts the shapes so far against the
## frame's total, and the second names the last layer on.
import game.RoadAhead
import game.FrameView
import game.Grass
import game.RiderCamera
import game.Scene
import game.Screen
import game.Sky
import game.Sun
import game.Tour
import lib.Brush
import lib.RgbColor
import lib.CanvasApp
import lib.Input
import lib.Shapes
import widget.ReadoutText
import widget.WidgetPage
import "page.html" as page_html : Str

FrameWidgetApp :: [].{

	## The whole state of the widget: the last layer on, in the book's order, with
	## every layer before it on too, and whether that's still being settled.
	Model : { last_layer_on : Layer, opening : [Opening, Opened] }

	canvas_app : CanvasApp.CanvasApp(FrameWidgetApp.Model)
	canvas_app = {
		size: { width: canvas_width, height: canvas_height },
		frames_a_second,
		init: { last_layer_on: Trees, opening: Opening },
		model_at_next_step: |model, input, _seconds| next_model(model, input),
		frame_shapes: shapes_at,
		sounds: |_model| 0,
		tones: [],
		title: "One frame of the ride",
	}
}

## The picture doesn't change once it's open, so a few frames a second will do.
frames_a_second : U32
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
frame_step = 1529

## The ride at `frame_step`.
paused_tour : Tour
paused_tour = Tour.at_step(frame_step)

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
## does, so the game's own `Scene` orders each layer among the others.
scene_shapes_on : List(Layer) -> List(Shapes.Shape)
scene_shapes_on = |on_layers| {
	only = {
		trees: things_on(paused_scene.trees, { on_layers, layer: Trees }),
		towers: things_on(paused_scene.towers, { on_layers, layer: Towers }),
		billboards: things_on(paused_scene.billboards, { on_layers, layer: Critters }),
		cats: things_on(paused_scene.cats, { on_layers, layer: MovingThings }),
		rails: things_on(paused_scene.rails, { on_layers, layer: Rails }),
		trucks: things_on(paused_scene.trucks, { on_layers, layer: MovingThings }),
		birds: things_on(paused_scene.birds, { on_layers, layer: MovingThings }),
	}
	Scene.scene_shapes(only)
}

## The frame's backdrop, layer by layer in `FrameView.backdrop_shapes`'s order:
## the sky, what the sun adds when it's in view, and the grass.
backdrop_pieces : FrameView -> List(Piece)
backdrop_pieces = |view| [
	{ layer: Sky, shapes: [Sky.sky_shape(view.backdrop.sky_colors)] },
	{ layer: Sun, shapes: Sun.sun_shapes(view.backdrop.sun_sighting) },
	{ layer: Grass, shapes: [Grass.grass_shape] },
]

## The camera the ride sees through at the step on show.
paused_camera : RiderCamera
paused_camera = FrameView.camera_at(paused_tour.route(), paused_tour.instant())

## The road ahead of the rider at the step on show.
paused_road : RoadAhead.RoadView
paused_road = RoadAhead.RoadView.ahead_of(paused_tour.route(), paused_camera.route_place.segment_index)

## What the camera shows at the step on show.
paused_frame_view : FrameView
paused_frame_view = FrameView.frame_view_at(paused_tour.route(), paused_tour.instant())

## The things in view at the step on show.
paused_scene : Scene
paused_scene = Scene.scene_in_view(
	paused_road,
	{
		camera: paused_camera.sighting_camera(),
		facts: FrameView.ride_facts(paused_tour.instant()),
	},
)

## The mountains and the road, which `FrameView.frame_view_at` puts under the things
## beside the road, each with its layer.
ground_parts : List(Piece)
ground_parts = {
	skyline = FrameView.skyline_shapes(paused_camera, paused_tour.instant().clock)
	ground = FrameView.ground_shapes(paused_road, paused_camera)
	[{ layer: Mountains, shapes: skyline }, { layer: Road, shapes: ground }]
}

backdrop_parts : List(Piece)
backdrop_parts = backdrop_pieces(paused_frame_view)

## The part of the ride's shapes in `paused_frame_view` on `on_layers`, in
## their order. The frame view keeps them in the lists they are made in, so this
## asks for them one at a time, and an `expect` below holds them to those lists
## joined.
ride_shapes_on : List(Layer) -> List(Shapes.Shape)
ride_shapes_on = |on_layers| piece_shapes(ground_parts, on_layers).concat(scene_shapes_on(on_layers))

## The frame's shapes on `on_layers`, backdrop and all, in paint order.
frame_shapes_on : List(Layer) -> List(Shapes.Shape)
frame_shapes_on = |on_layers| piece_shapes(backdrop_parts, on_layers).concat(ride_shapes_on(on_layers))

## The space the paused frame leans in, which the game puts the whole frame in.
lean_space : Shapes.Space
lean_space = FrameView.lean_space(paused_frame_view.roll)

## The layers up to `last`, and `last` itself.
layers_through : Layer -> List(Layer)
layers_through = |last|
	match layers.find_first_index(|layer| layer == last) {
		Ok(index) => layers.take_first(index + 1)
		Err(NotFound) => crash "FrameWidgetApp.layers_through: every layer is in the list"
	}

## The layer after `layer` in the book's order. The last has none after it, so
## it stays.
layer_after : Layer -> Layer
layer_after = |layer|
	match layers.drop_first(layers_through(layer).len()) {
		[next, ..] => next
		[] => layer
	}

## The shapes of `parts` in `on_layers`, in paint order.
piece_shapes : List(Piece), List(Layer) -> List(Shapes.Shape)
piece_shapes = |parts, on_layers|
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
	fill: Brush.flat(WidgetPage.panel_color),
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
				{ ..model, last_layer_on: layer_after(model.last_layer_on) }
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
status_lines = |{ last_layer_on, .. }| {
	so_far = ReadoutText.count_text(ride_count(layers_through(last_layer_on)))
	total = ReadoutText.count_text(ride_count(layers))
	["Shapes so far: ${so_far} of ${total}", "Added: ${layer_name(last_layer_on)}"]
}

## The panel's rows of text, in type sized for the whole frame, larger than a
## widget page's.
status_readout : WidgetPage.ReadoutStyle
status_readout = {
	x: WidgetPage.side_margin,
	first_baseline: picture_height + 40.0,
	row_spacing: 36.0,
	size: 22.0,
	align: Left,
}

status_line : Str, U64 -> Shapes.Shape
status_line = |text, row| WidgetPage.readout({ text, color: WidgetPage.ink_color, row, style: status_readout })
## The layers on, in the game's paint order.
picture_shapes : List(Layer) -> List(Shapes.Shape)
picture_shapes = |on_layers| Shapes.shapes_in_space(lean_space, frame_shapes_on(on_layers))

## Everything on the canvas.
shapes_at : FrameWidgetApp.Model -> List(Shapes.Shape)
shapes_at = |model|
	[
		[plain_background],
		picture_shapes(layers_through(model.last_layer_on)),
		[panel],
		status_lines(model).map_with_index(status_line),
	].join()

# All the layers on is the game's own frame, shape for shape and in its order.
expect picture_shapes(layers) == paused_frame_view.framed_shapes(lean_space)

# The ride's parts are the game's own shapes, in the game's order.
expect ride_shapes_on(layers) == paused_frame_view.ride_shape_lists.join()

# The backdrop's parts are the game's own backdrop, in its order.
expect piece_shapes(backdrop_parts, layers) == FrameView.backdrop_shapes(paused_frame_view)

# The frame's total is the game's own count of its shapes.
expect ride_count(layers) == paused_frame_view.ride_shape_lists.join().len()

# Every layer has shapes of its own at this step but the sun, which is behind the
# rider.
expect layers.keep_if(|layer| frame_shapes_on([layer]).is_empty()) == [Sun]
expect paused_frame_view.backdrop.sun_sighting == OutOfView

# The backdrop stays out of the running count.
expect ride_count([Grass, Sun, Sky]) == 0

# A layer with shapes of its own always changes the picture, and the sun doesn't.
expect picture_shapes(layers_through(Trees)) != picture_shapes(layers_through(Grass))
expect picture_shapes(layers_through(Grass)) == picture_shapes(layers_through(Sun))
expect picture_shapes(layers_through(Sun)) != picture_shapes(layers_through(Sky))
expect picture_shapes(layers_through(Critters)) != picture_shapes(layers_through(MovingThings))

# The first layer alone is the lean and the trees, in the game's order.
expect picture_shapes([Trees]) == Shapes.shapes_in_space(lean_space, ride_shapes_on([Trees]))

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
all_on = { last_layer_on: MovingThings, opening: Opened }

right_press : Input.Snapshot
right_press = Input.none.with_key_pressed(KeyRight)

## The model once the page has pressed Right `count` times and a frame has gone
## by.
opened_after : U64 -> FrameWidgetApp.Model
opened_after = |count| next_model(
	List.repeat(right_press, count).fold(start, next_model),
	Input.none,
)

# An address with no word opens on the trees alone, the last word opens on every
# layer, and a press past the last layer leaves every layer on.
expect opened_after(0) == { last_layer_on: Trees, opening: Opened }
expect opened_after(5) == { last_layer_on: Road, opening: Opened }
expect opened_after(layers.len() - 1) == all_on
expect opened_after(layers.len()) == all_on

# Once it's open, the arrow keys change nothing.
expect next_model(opened_after(0), right_press) == opened_after(0)
expect next_model(all_on, Input.none.with_key_pressed(KeyLeft)) == all_on

# A press of any other key during the opening doesn't count as a layer.
expect next_model(start, Input.none.with_key_pressed(KeyLeft)) == opened_after(0)

expect
	status_lines(start)
		== ["Shapes so far: 1,656 of 2,474", "Added: Trees"]

# The canvas answers the layers, and the panel stays over whatever leans past it.
expect shapes_at(start) != shapes_at(all_on)
expect
	shapes_at(all_on).first() == Ok(plain_background)
		and shapes_at(all_on).contains(panel)
		and shapes_at(all_on).contains(View(Screen))
