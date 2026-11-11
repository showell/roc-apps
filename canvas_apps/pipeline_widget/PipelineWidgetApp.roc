## The widget for the Safari tutorial's chapter on the pipeline: step 1,529 of
## the ride with only the things the pipeline renders, and no controls. The trees,
## towers, critters, cat and truck in view are each the game's own rendering at
## that step, painted far to near as `Scene.scene_renderings` sorts them. No bird
## is in view at that step. The
## guard rail is left out, because its pieces have no kind, and so are the sky,
## the sun, the grass, the mountains and the road. What's left stands on a plain
## background at the real frame's size, leaned as the game leans the frame.
import game.Clock
import game.FrameView
import game.Rendered
import game.Scene
import game.Screen
import game.Tour
import lib.Brush
import lib.CanvasApp
import lib.Pixels
import lib.Point
import lib.Shapes
import widget.WidgetPage
import widget.WidgetPalette

PipelineWidgetApp :: [].{

	## A fixed picture has no state.
	Model : {}

	canvas_app : CanvasApp.CanvasApp(PipelineWidgetApp.Model)
	canvas_app = {
		..WidgetPage.fixed_picture_app({ title: "What the pipeline renders", shapes: picture_shapes }),
		size: { width: canvas_width, height: canvas_height },
	}
}

## What the camera shows at step 1,529, the step the frame widget holds.
paused_frame_view : FrameView
paused_frame_view = {
	tour = Tour.at_step(Clock.at_step(1529))
	FrameView.frame_view_at(tour.route(), tour.instant())
}

## The paused frame's scene with the guard rail taken out.
pipeline_scene : Scene
pipeline_scene = {
	scene = paused_frame_view.scene
	{
		trees: scene.trees,
		towers: scene.towers,
		billboards: scene.billboards,
		cats: scene.cats,
		rails: [],
		trucks: scene.trucks,
		birds: scene.birds,
	}
}

## The pipeline's things as shapes, far to near.
scene_shapes : List(Shapes.Shape)
scene_shapes = Scene.scene_shape_lists(pipeline_scene).join()

## The real frame's size in pixels.
canvas_width : F64
canvas_width = Screen.width.to_f64()

canvas_height : F64
canvas_height = Screen.height.to_f64()

## Behind the things, where the frame's sky and grass would be.
plain_background : Shapes.Shape
plain_background = Shapes.rectangle({
	top_left: Point.at(0.0, 0.0),
	width: Pixels.of(canvas_width),
	height: Pixels.of(canvas_height),
	fill: Brush.flat(WidgetPalette.frame_background_color),
})

## The background, then the things in the space the game leans the frame in.
picture_shapes : List(Shapes.Shape)
picture_shapes = [plain_background].concat(
	Shapes.shapes_in_space(Screen.leaned_by(paused_frame_view.roll), scene_shapes),
)

## The shapes of `renderings`.
renderings_shapes : List(Rendered) -> List(Shapes.Shape)
renderings_shapes = |renderings| renderings.join_map(|rendering| rendering.sprite().to_shapes())

## The picture's shapes that are drawn, without its background and the marks that
## put them in the leaned space.
drawn_shapes : List(Shapes.Shape)
drawn_shapes = picture_shapes.drop_first(1).keep_if(
	|shape|
		match shape {
			View(_) => False
			_ => True
		},
)

# Every shape drawn comes from the paused frame's own scene, and none from its
# mountains, its road or its backdrop.
expect {
	frame_scene_shapes = Scene.scene_shape_lists(paused_frame_view.scene).join()
	left_out = [
		paused_frame_view.mountain_shapes,
		paused_frame_view.ground_patch_shapes,
		FrameView.backdrop_shapes(paused_frame_view.backdrop),
	].join()
	!drawn_shapes.is_empty()
		and drawn_shapes.all(|shape| frame_scene_shapes.contains(shape))
		and !drawn_shapes.any(|shape| left_out.contains(shape))
}

# The picture holds the truck, every shape of it.
expect {
	truck_shapes = renderings_shapes(paused_frame_view.scene.trucks)
	!truck_shapes.is_empty() and truck_shapes.all(|shape| drawn_shapes.contains(shape))
}

# The frame at this step has a guard rail, and the picture holds none of it.
expect {
	rail_shapes = renderings_shapes(paused_frame_view.scene.rails)
	!rail_shapes.is_empty() and !rail_shapes.any(|shape| drawn_shapes.contains(shape))
}

## Whether `shapes` all come in `frame_shapes`, in the same order.
is_in_order_within : List(Shapes.Shape), List(Shapes.Shape) -> Bool
is_in_order_within = |shapes, frame_shapes| {
	unmatched = frame_shapes.fold(
		shapes,
		|left, shape|
			match left {
				[next, .. as rest] if next == shape => rest
				_ => left
			},
	)
	unmatched.is_empty()
}

# The things are painted in the order the game paints them in its own leaned
# frame, and with the farthest shape moved to the end they are not.
expect is_in_order_within(drawn_shapes, paused_frame_view.leaned_shapes())
expect {
	farthest_last = drawn_shapes.drop_first(1).concat(drawn_shapes.take_first(1))
	!is_in_order_within(farthest_last, paused_frame_view.leaned_shapes())
}
