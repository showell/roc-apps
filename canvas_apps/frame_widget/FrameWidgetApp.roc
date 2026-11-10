## The widget for the first half of the Safari tutorial, which walks through one
## page of the flipbook a chapter at a time. It holds step 1,529 of the ride, with
## the cat frozen in the road, and shows that frame one layer at a time. The
## shapes are the game's own for that step, sorted into layers and painted in the
## game's order, because depth sorting interleaves the things beside the road.
## The address picks how many layers are on, and from there it's a fixed picture
## with no controls. The book's caption says what's on, so the canvas holds the
## picture alone.
import game.Clock
import game.FrameView
import game.Grass
import game.Screen
import game.Sky
import game.Sun
import game.Tour
import lib.Brush
import lib.RgbColor
import lib.CanvasApp
import lib.Input
import lib.Pixels
import lib.Point
import lib.Shapes
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
frame_clock : Clock
frame_clock = Clock.at_step(1529)

## The ride at `frame_clock`.
paused_tour : Tour
paused_tour = Tour.at_step(frame_clock)

## `things` if `layer` is one of `on_layers`, else none.
things_on : List(thing), { on_layers : List(Layer), layer : Layer } -> List(thing)
things_on = |things, { on_layers, layer }|
	if on_layers.contains(layer) {
		things
	} else {
		[]
	}

## The paused frame's view with only the ride's layers on `on_layers`. A view
## that holds only some of the layers draws them in the order the whole view
## does, so the game's own `FrameView` orders each layer among the others.
view_on : List(Layer) -> FrameView
view_on = |on_layers| {
	view = paused_frame_view
	scene = view.scene
	{
		..view,
		mountain_shapes: things_on(view.mountain_shapes, { on_layers, layer: Mountains }),
		ground_patch_shapes: things_on(view.ground_patch_shapes, { on_layers, layer: Road }),
		scene: {
			trees: things_on(scene.trees, { on_layers, layer: Trees }),
			towers: things_on(scene.towers, { on_layers, layer: Towers }),
			billboards: things_on(scene.billboards, { on_layers, layer: Critters }),
			cats: things_on(scene.cats, { on_layers, layer: MovingThings }),
			rails: things_on(scene.rails, { on_layers, layer: Rails }),
			trucks: things_on(scene.trucks, { on_layers, layer: MovingThings }),
			birds: things_on(scene.birds, { on_layers, layer: MovingThings }),
		},
	}
}

## The frame's backdrop, layer by layer in `FrameView.backdrop_shapes`'s order:
## the sky, what the sun adds when it's in view, and the grass.
backdrop_pieces : FrameView.Backdrop -> List(Piece)
backdrop_pieces = |backdrop| [
	{ layer: Sky, shapes: [Sky.sky_shape(backdrop.sky_colors)] },
	{ layer: Sun, shapes: Sun.sun_shapes(backdrop.sun_sighting) },
	{ layer: Grass, shapes: [Grass.grass_shape(backdrop.darkness)] },
]

## What the camera shows at the step on show.
paused_frame_view : FrameView
paused_frame_view = FrameView.frame_view_at(paused_tour.route(), paused_tour.instant())

backdrop_parts : List(Piece)
backdrop_parts = backdrop_pieces(paused_frame_view.backdrop)

## The part of the ride's shapes in `paused_frame_view` on `on_layers`, in
## the game's paint order.
ride_shapes_on : List(Layer) -> List(Shapes.Shape)
ride_shapes_on = |on_layers| FrameView.ride_shape_lists(view_on(on_layers)).join()

## The frame's shapes on `on_layers`, backdrop and all, in paint order.
frame_shapes_on : List(Layer) -> List(Shapes.Shape)
frame_shapes_on = |on_layers| piece_shapes(
	backdrop_parts,
	on_layers,
).concat(ride_shapes_on(on_layers))

## The space the paused frame leans in, which the game puts the whole frame in.
lean_space : Shapes.Space
lean_space = Screen.leaned_by(paused_frame_view.roll)

## The layers up to `last`, and `last` itself.
layers_to : Layer -> List(Layer)
layers_to = |last|
	match layers.find_first_index(|layer| layer == last) {
		Ok(index) => layers.take_first(index + 1)
		Err(NotFound) => crash "FrameWidgetApp.layers_to: every layer is in the list"
	}

## The layer after `layer` in the book's order. The last has none after it, so
## it stays.
layer_after : Layer -> Layer
layer_after = |layer|
	match layers.drop_first(layers_to(layer).len()) {
		[next, ..] => next
		[] => layer
	}

## The shapes of `parts` in `on_layers`, in paint order.
piece_shapes : List(Piece), List(Layer) -> List(Shapes.Shape)
piece_shapes = |parts, on_layers|
	parts.keep_if(|piece| on_layers.contains(piece.layer)).join_map(|piece| piece.shapes)

## The real frame's size in pixels.
canvas_width : F64
canvas_width = Screen.width.to_f64()

canvas_height : F64
canvas_height = Screen.height.to_f64()

plain_background_color : RgbColor
plain_background_color = RgbColor.of(0xE8E6DF)

## Behind whatever is on, so a frame with no sky has something to be seen against.
plain_background : Shapes.Shape
plain_background = Shapes.rectangle({
	top_left: Point.at(0.0, 0.0),
	width: Pixels.of(canvas_width),
	height: Pixels.of(canvas_height),
	fill: Brush.flat(plain_background_color),
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

## The layers on, in the game's paint order.
picture_shapes : List(Layer) -> List(Shapes.Shape)
picture_shapes = |on_layers| Shapes.shapes_in_space(lean_space, frame_shapes_on(on_layers))

## Everything on the canvas.
shapes_at : FrameWidgetApp.Model -> List(Shapes.Shape)
shapes_at = |model|
	[[plain_background], picture_shapes(layers_to(model.last_layer_on))].join()

# All the layers on is the game's own frame, shape for shape and in its order.
expect picture_shapes(layers) == paused_frame_view.leaned_shapes()

# The backdrop's parts are the game's own backdrop, in its order.
expect piece_shapes(backdrop_parts, layers) == FrameView.backdrop_shapes(paused_frame_view.backdrop)

# Every layer has shapes of its own at this step but the sun, which is behind the
# rider.
expect layers.keep_if(|layer| frame_shapes_on([layer]).is_empty()) == [Sun]
expect paused_frame_view.backdrop.sun_sighting == OutOfView

# A layer with shapes of its own always changes the picture, and the sun doesn't.
expect picture_shapes(layers_to(Trees)) != picture_shapes(layers_to(Grass))
expect picture_shapes(layers_to(Grass)) == picture_shapes(layers_to(Sun))
expect picture_shapes(layers_to(Sun)) != picture_shapes(layers_to(Sky))
expect picture_shapes(layers_to(Critters)) != picture_shapes(layers_to(MovingThings))

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

# The canvas answers the layers.
expect shapes_at(start) != shapes_at(all_on)
expect shapes_at(all_on) == [plain_background].concat(picture_shapes(layers))
