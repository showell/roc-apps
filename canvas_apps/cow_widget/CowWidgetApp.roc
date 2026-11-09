## The widget that opens the Safari tutorial's chapter on the things beside the
## road: a fixed picture of one cow on the grass to the left of the road, with
## the road running past it to the horizon, and no controls. The cow is a herd of
## one from CowHerd, and the sky, the grass, the road and the cow are the shapes
## the ride draws for them, on a canvas the size of the ride's screen, because
## the widget page's strip of ground is too shallow to stand a cow on.
import game.Across
import game.Along
import game.Angle
import game.Billboard
import game.Clock
import game.CowHerd
import game.Distance
import game.FrameView
import game.Geom
import game.Lens
import game.Pipeline
import game.Screen
import game.SegmentFromRider
import game.Sky
import game.World
import lib.CanvasApp
import lib.Point
import lib.Shapes
import widget.WidgetPage

CowWidgetApp :: [].{

	## A fixed picture has no state.
	Model : {}

	canvas_app : CanvasApp.CanvasApp(CowWidgetApp.Model)
	canvas_app = {
		size: { width: canvas_width, height: canvas_height },
		frames_a_second: WidgetPage.fixed_picture_frames_a_second,
		init: {},
		model_at_next_step: |model, _input, _seconds| model,
		frame_shapes: |_model| picture_shapes,
		sounds: |_model| 0,
		tones: [],
		title: "A cow by the road",
	}
}

canvas_width : F64
canvas_width = Screen.width.to_f64()

canvas_height : F64
canvas_height = Screen.height.to_f64()

## The ride's cow. A herd of one with no bull holds just the cow a herd starts
## with, a grown one, facing the road.
cow : Billboard
cow = {
	herd = CowHerd.herd({ cow_count: 1, rows_behind_front: 0 })
	match herd.herd_cows({ herd_along: Along.start, bull: NoBull }) {
		[only_cow] => only_cow.kind
		_ => crash "CowWidgetApp.cow: a herd of one cow and no bull holds one billboard"
	}
}

## Three metres off the road's left edge, so the road runs clear of the cow.
cow_across : Across
cow_across = Across.left_of_middle(Distance.metres(5.0))

## Near enough to fill a good part of the frame, and far enough that all of it
## is in view.
cow_forward : Distance
cow_forward = Distance.metres(10.0)

## The cow on the grass, `forward` down the road from the camera.
cow_at : Distance -> Geom.Placed(Billboard)
cow_at = |forward| {
	road_point: { along: Along.at(forward), across: cow_across },
	lift: Distance.zero,
	kind: cow,
}

## The camera, at the start of the road, looking down it through the lens at
## rest.
camera : Pipeline.SightingCamera
camera = {
	vantage: {
		along: Along.start,
		across: Across.middle,
		yaw: Angle.straight_ahead,
	},
	focal_length: Lens.resting_focal_length,
}

## A cow as the ride sights a billboard, which drops one too small to see.
cow_sighting : Geom.Placed(Billboard) -> Try(Pipeline.Sighted(Billboard), _)
cow_sighting = |placed_cow|
	Pipeline.scenery_sighting_of(
		placed_cow,
		{
			road: World.road_at_start,
			camera,
			from_rider: Ahead(SegmentFromRider.Position.first),
		},
	)

## What the camera shows of a cow, or nothing if the ride wouldn't draw it.
cow_shapes_at : Distance -> List(Shapes.Shape)
cow_shapes_at = |forward|
	match cow_sighting(cow_at(forward)) {
		Ok(sighting) => {
			rendered = Pipeline.rendering_of(
				sighting,
				{ focal_length: camera.focal_length, context: {} },
			)
			rendered.sprite().to_shapes()
		}
		Err(BehindCamera) | Err(BelowHorizon) | Err(TooSmall) => []
	}

cow_shapes : List(Shapes.Shape)
cow_shapes = cow_shapes_at(cow_forward)

## The road ahead as the ride draws its ground.
road_shapes : List(Shapes.Shape)
road_shapes = FrameView.ground_shapes(World.road_at_start, camera)

## The ride's sky at the start of the ride, with the sun out of the picture.
backdrop : FrameView.Backdrop
backdrop = { sky_colors: Sky.colors_at(Clock.start), sun_sighting: OutOfView }

## The ride's space for a frame with no roll.
upright_space : Shapes.Space
upright_space = Screen.leaned_by(Angle.upright)

## The cow over the road, as the ride paints a frame: nearer things last.
picture_shapes : List(Shapes.Shape)
picture_shapes = FrameView.painted_shapes({
	backdrop,
	ride_shape_lists: [road_shapes, cow_shapes],
	space: upright_space,
})

## Every corner of `shapes`' polygons, or none if any shape isn't a polygon.
polygon_corners : List(Shapes.Shape) -> Try(List(Point.Point), [NotPolygon])
polygon_corners = |shapes| {
	polygons = shapes.keep_oks(
		|shape|
			match shape {
				Triangle(t) => Ok([t.first, t.second, t.third])
				Polygon({ corners, .. }) => Ok(corners)
				Text(_) | Disc(_) | Rectangle(_) | Blend(_) | View(_) | Image(_) => Err(NotPolygon)
			},
	)
	if polygons.len() == shapes.len() {
		Ok(polygons.join())
	} else {
		Err(NotPolygon)
	}
}

## Whether the cow at `forward` is drawn, all of it on the canvas, and at least
## 80 pixels from its top to its feet.
is_plain_to_see : Distance -> Bool
is_plain_to_see = |forward| {
	shapes = cow_shapes_at(forward)
	match polygon_corners(shapes) {
		Ok(corners) => {
			is_on_canvas = |corner| {
				x = corner.x.to_f64()
				y = corner.y.to_f64()
				x >= 0.0 and x <= canvas_width and y >= 0.0 and y <= canvas_height
			}
			ys = corners.map(|corner| corner.y.to_f64())
			match (ys.min(), ys.max()) {
				(Ok(top), Ok(bottom)) => corners.all(is_on_canvas) and bottom - top >= 80.0
				_ => False
			}
		}
		Err(NotPolygon) => False
	}
}

# The cow is all in the picture and a good size. Much farther and it is small,
# and nearer it leaves the canvas at the left.
expect is_plain_to_see(cow_forward)
expect !is_plain_to_see(Distance.metres(20.0))
expect !is_plain_to_see(Distance.metres(6.0))

# The cow stands left of the middle of the screen, where the road runs.
expect
	match polygon_corners(cow_shapes) {
		Ok(corners) => corners.all(|corner| corner.x < Screen.center_x)
		Err(NotPolygon) => False
	}

# The cow's shapes are those its billboard gives at its spot.
expect
	match cow_sighting(cow_at(cow_forward)) {
		Ok(sighting) => {
			setting = { spot: sighting.spot, focal_length: camera.focal_length, context: {} }
			sprite_shapes = cow.scenery_sprite(setting).to_shapes()
			!sprite_shapes.is_empty() and cow_shapes == sprite_shapes
		}
		Err(_) => False
	}

# The picture is the backdrop, the road and the cow, and nothing else.
expect !road_shapes.is_empty()
expect
	picture_shapes
		== Shapes.lists_in_space(
			upright_space,
			[FrameView.backdrop_shapes(backdrop), road_shapes, cow_shapes],
		)
