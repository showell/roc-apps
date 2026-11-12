## The widget for the Safari tutorial's chapter on asking a kind: a fixed picture
## of five kinds of thing beside the road, side by side, and no controls. From
## left to right they are a green conifer, a cow, a radio tower, the cat and the
## bird, each in its own fifth of the picture. Every one is drawn by
## `Pipeline.rendering_of`, which asks its kind for its own `scenery_sprite`.
## They differ wildly in size, so each stands at its own distance down the road,
## all through the ride's lens at rest, chosen so each stands about a third of
## the picture's height. None is drawn at its real size beside the others.
import game.Across
import game.Along
import game.Angle
import game.Beacon
import game.Billboard
import game.Bird
import game.Camera
import game.Cat
import game.Clock
import game.Conifer
import game.CowHerd
import game.Distance
import game.FrameView
import game.Geom
import game.Lens
import game.Pipeline
import game.Rendered
import game.Route
import game.Screen
import game.SegmentFromRider
import game.Sky
import game.Sprite
import game.Tower
import game.World
import lib.CanvasApp
import lib.Pixels
import lib.Point
import lib.Shapes
import widget.WidgetPage

KindsWidgetApp :: [].{

	## A fixed picture has no state.
	Model : {}

	canvas_app : CanvasApp.CanvasApp(KindsWidgetApp.Model)
	canvas_app = {
		..WidgetPage.fixed_picture_app({ title: "Five kinds", shapes: picture_shapes }),
		size: { width: WidgetPage.canvas_width, height: canvas_height },
	}
}

## The picture alone, with no panel under it. The book's frame for this widget
## has the same aspect.
canvas_height : F64
canvas_height = 240.0

## The ride's own lens at rest. A longer one would need the tower farther off
## than the horizon, which would hide its foot.
focal_length : Pixels
focal_length = Lens.resting_focal_length

## One thing in the picture: its kind, how far down the road it stands, and the
## x on the canvas of its foot, the middle of its fifth unless it says why not.
Stand(kind) : {
	kind : kind,
	forward : Distance,
	canvas_x : F64,
}

tree_stand : Stand(Conifer)
tree_stand = {
	kind: Conifer.Green,
	forward: Distance.metres(35.0),
	canvas_x: 64.0,
}

## The ride's cow, a herd of one with no bull: a grown cow seen side on.
cow : Billboard
cow = {
	herd = CowHerd.herd({ cow_count: 1, rows_behind_front: 0 })
	match herd.herd_cows({ herd_along: Along.start, bull: NoBull }) {
		[only_cow] => only_cow.kind
		_ => crash "KindsWidgetApp.cow: a herd of one cow and no bull holds one billboard"
	}
}

cow_stand : Stand(Billboard)
cow_stand = {
	kind: cow,
	forward: Distance.metres(7.0),
	canvas_x: 192.0,
}

## A tower square with the road, as the ride turns the one halfway along a long
## segment. Its beacon is the first segment's end tower's at the start of the
## ride, which is dark.
tower : Tower
tower = Tower.standing({
	yaw: Angle.straight_ahead,
	beacon: Beacon.at({ segment: Route.SegmentIndex.first, place: AtEnd }, Clock.start),
})

tower_stand : Stand(Tower)
tower_stand = {
	kind: tower,
	forward: Distance.metres(400.0),
	canvas_x: 320.0,
}

## The cat in mid stride, which is side on.
cat : Cat
cat = { pose: Stride }

## A striding cat is nearly twice as wide as it is tall, so it stands farther
## off than the cow to fit its fifth. Its still reaches farther right of its
## feet, where its tail is, than left, so its feet stand left of its fifth's
## middle.
cat_stand : Stand(Cat)
cat_stand = {
	kind: cat,
	forward: Distance.metres(12.5),
	canvas_x: 436.0,
}

## The bird perched, the pose it holds on a treetop before the rider comes.
bird : Bird
bird = { pose: Perched }

bird_stand : Stand(Bird)
bird_stand = {
	kind: bird,
	forward: Distance.metres(12.0),
	canvas_x: 576.0,
}

## The camera, at the start of the road, looking down it.
eye : Geom.Vantage
eye = {
	along: Along.start,
	across: Across.middle,
	yaw: Angle.straight_ahead,
}

## The light at the start of the ride, which is day.
lens_and_light : Sprite.LensAndLight
lens_and_light = { focal_length, darkness: Sky.darkness_at(Clock.start) }

## How far right of the camera a stand's thing must be to land on its
## `canvas_x`.
right_of : Stand(kind) -> Distance
right_of = |stand| {
	screen_x = WidgetPage.screen_x_at_canvas_x(stand.canvas_x)
	stand.forward.times(Lens.slope_at_x({ x: screen_x, focal_length }))
}

## A stand's thing as the camera sees it, on the ground at its spot.
stand_sighting : Stand(kind) -> Pipeline.Sighted(kind)
stand_sighting = |stand| {
	placed : Geom.Placed(kind)
	placed = {
		road_point: {
			along: Along.at(stand.forward),
			across: Across.right_of_middle(right_of(stand)),
		},
		lift: Distance.zero,
		kind: stand.kind,
	}
	match Pipeline.sighting_of(
		placed,
		{
			road: World.road_at_start,
			vantage: eye,
			from_rider: Ahead(SegmentFromRider.Position.first),
		},
	) {
		Ok(sighting) => sighting
		Err(OutOfSight) => crash "KindsWidgetApp.stand_sighting: each stand is ahead"
	}
}

## A stand's thing as the ride renders it.
stand_rendering : Stand(kind) -> Rendered
	where [kind.scenery_sprite : kind, Sprite.Setting -> Sprite]
stand_rendering = |stand| Pipeline.rendering_of(stand_sighting(stand), lens_and_light)

tree_shapes : List(Shapes.Shape)
tree_shapes = stand_rendering(tree_stand).sprite().to_shapes()

cow_shapes : List(Shapes.Shape)
cow_shapes = stand_rendering(cow_stand).sprite().to_shapes()

tower_shapes : List(Shapes.Shape)
tower_shapes = stand_rendering(tower_stand).sprite().to_shapes()

cat_shapes : List(Shapes.Shape)
cat_shapes = stand_rendering(cat_stand).sprite().to_shapes()

bird_shapes : List(Shapes.Shape)
bird_shapes = stand_rendering(bird_stand).sprite().to_shapes()

## The five drawings from left to right.
kind_shape_lists : List(List(Shapes.Shape))
kind_shape_lists = [tree_shapes, cow_shapes, tower_shapes, cat_shapes, bird_shapes]

## How many canvas pixels the picture gives a pixel of the ride's screen, as on
## every widget page.
canvas_per_screen : F64
canvas_per_screen = WidgetPage.canvas_width / Screen.width.to_f64()

## Where the horizon crosses the canvas: halfway up, which leaves room above it
## for the tower's tip and below it for the cow's feet.
canvas_horizon_y : F64
canvas_horizon_y = 120.0

## The ride's screen at the widget pages' scale, moved so its horizon crosses
## the canvas at `canvas_horizon_y`.
picture_space : Shapes.Space
picture_space = Shapes.world_space({
	target: { x: Pixels.zero, y: Screen.horizon_y },
	offset: Point.at(0.0, canvas_horizon_y),
	rotation: 0.0,
	zoom: canvas_per_screen,
})

## Where `picture_space` puts a point of the ride's screen on the canvas.
canvas_point_of_screen : Point -> Point
canvas_point_of_screen = |{ x, y }| {
	x: x.times(canvas_per_screen),
	y: Pixels.of(canvas_horizon_y).plus(y.minus(Screen.horizon_y).times(canvas_per_screen)),
}

## The ride's sky at the start of the ride, with the sun out of the picture.
backdrop : FrameView.Backdrop
backdrop = {
	sky_colors: Sky.colors_at(Clock.start),
	sun_sighting: OutOfView,
	darkness: Sky.darkness_at(Clock.start),
}

picture_shapes : List(Shapes.Shape)
picture_shapes = FrameView.painted_shapes({
	backdrop,
	ride_shape_lists: kind_shape_lists,
	space: picture_space,
})

## Where on the canvas a drawing reaches.
Extent : {
	left : F64,
	right : F64,
	top : F64,
	bottom : F64,
}

## How far the drawing `shapes` reaches on the canvas, if it is all polygons.
extent : List(Shapes.Shape) -> Try(Extent, [NoCorners])
extent = |shapes| {
	corner_lists = shapes.keep_oks(Shapes.region_corners)
	if shapes.is_empty() or corner_lists.len() < shapes.len() {
		Err(NoCorners)
	} else {
		corners = corner_lists.join().map(canvas_point_of_screen)
		xs = corners.map(|corner| corner.x.to_f64())
		ys = corners.map(|corner| corner.y.to_f64())
		match (xs.min(), xs.max(), ys.min(), ys.max()) {
			(
				Ok(left),
				Ok(right),
				Ok(top),
				Ok(bottom),
			) => Ok({ left, right, top, bottom })
			_ => Err(NoCorners)
		}
	}
}

## How wide each thing's share of the picture is.
fifth_width : F64
fifth_width = WidgetPage.canvas_width / 5.0

## Whether the drawing `shapes` is all on the canvas, within the fifth at
## `index` from the left, and at least a fifth of the picture's height.
is_plain_in_fifth : List(Shapes.Shape), U64 -> Bool
is_plain_in_fifth = |shapes, index|
	match extent(shapes) {
		Ok(reach) => {
			fifth_left = index.to_f64() * fifth_width
			reach.left >= fifth_left
				and reach.right <= fifth_left + fifth_width
				and reach.top >= 0.0
				and reach.bottom <= canvas_height
				and reach.bottom - reach.top >= 0.2 * canvas_height
		}
		Err(NoCorners) => False
	}

## Whether `shapes` are what a stand's kind draws for itself at its sighting,
## through the long lens by day, and the drawing is not empty.
is_kinds_own_drawing : Stand(kind), List(Shapes.Shape) -> Bool
	where [kind.scenery_sprite : kind, Sprite.Setting -> Sprite]
is_kinds_own_drawing = |stand, shapes| {
	sighting = stand_sighting(stand)
	own_shapes = stand.kind.scenery_sprite({
		spot: sighting.spot,
		focal_length,
		darkness: lens_and_light.darkness,
	}).to_shapes()
	!own_shapes.is_empty() and shapes == own_shapes
}

## Whether a stand's rendering is drawn at the depth of its stand's distance.
is_at_its_distance : Stand(kind) -> Bool
	where [kind.scenery_sprite : kind, Sprite.Setting -> Sprite]
is_at_its_distance = |stand|
	(stand_rendering(stand).depth().to_metres() - stand.forward.to_metres()).abs() <= 0.000001

# Each of the five is wholly on the canvas, inside its own fifth, and stands at
# least a fifth of the picture's height, in the order tree, cow, tower, cat and
# bird from the left.
expect is_plain_in_fifth(tree_shapes, 0)
expect is_plain_in_fifth(cow_shapes, 1)
expect is_plain_in_fifth(tower_shapes, 2)
expect is_plain_in_fifth(cat_shapes, 3)
expect is_plain_in_fifth(bird_shapes, 4)

# Each drawing is what its own kind's `scenery_sprite` gives, which is what
# `Pipeline.rendering_of` asks for, and it is rendered at its stand's distance.
expect is_kinds_own_drawing(tree_stand, tree_shapes)
expect is_kinds_own_drawing(cow_stand, cow_shapes)
expect is_kinds_own_drawing(tower_stand, tower_shapes)
expect is_kinds_own_drawing(cat_stand, cat_shapes)
expect is_kinds_own_drawing(bird_stand, bird_shapes)
expect is_at_its_distance(tree_stand)
expect is_at_its_distance(cow_stand)
expect is_at_its_distance(tower_stand)
expect is_at_its_distance(cat_stand)
expect is_at_its_distance(bird_stand)

# The tower is near enough that none of it is sunk below the horizon: it is
# drawn as tall as its kind's height stands at its distance, to a fiftieth.
expect
	match extent(tower_shapes) {
		Ok(reach) => {
			whole_height = Camera.height_on_screen(
				{ height: tower.scenery_height(), forward: tower_stand.forward },
				focal_length,
			).to_f64() * canvas_per_screen
			((reach.bottom - reach.top) / whole_height - 1.0).abs() <= 0.02
		}
		Err(NoCorners) => False
	}

# The picture is the backdrop and the five drawings, and nothing else.
expect
	picture_shapes
		== Shapes.lists_in_space(
			picture_space,
			[FrameView.backdrop_shapes(backdrop)].concat(kind_shape_lists),
		)
