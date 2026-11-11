## The widget for the Safari tutorial's chapter on nature types: a fixed picture of
## the four kinds of conifer side by side, in the order the type lists them, and no
## controls. All four stand equally far down the road and are drawn through the
## same long lens, so each tree's height and color come from its kind alone. The
## sightings are the ride's, and so are the drawings: each conifer's own
## `scenery_sprite`, handed the longer focal length.
import game.Across
import game.Along
import game.Angle
import game.Clock
import game.Conifer
import game.Distance
import game.Geom
import game.Lens
import game.Pipeline
import game.SegmentFromRider
import game.Sky
import game.TreeShapes
import game.World
import lib.CanvasApp
import lib.Pixels
import lib.Point
import lib.Shapes
import widget.WidgetPage

ConifersWidgetApp :: [].{

	## A fixed picture has no state.
	Model : {}

	canvas_app : CanvasApp.CanvasApp(ConifersWidgetApp.Model)
	canvas_app = {
		..WidgetPage.fixed_picture_app({ title: "Four conifers", shapes: picture_shapes }),
		size: { width: WidgetPage.canvas_width, height: canvas_height },
	}
}

## The picture alone, with no panel under it: a strip of grass below the trees'
## feet, and the sky over the tallest tip. The book's frame for this widget has
## the same aspect.
canvas_height : F64
canvas_height = 240.0

## Just past the reach of the cones, so every crown is flat triangles.
forward : Distance
forward = Distance.metres(210.0)

## Six times the ride's lens at rest, which puts the tallest tip near the top of
## the picture.
focal_length : Pixels
focal_length = Lens.resting_focal_length.times(6.0)

## A tree in the picture: its kind, and the x on the canvas of its foot.
Stand : { kind : Conifer, canvas_x : F64 }

## One of each kind, in the order the type lists them, each in the middle of its
## own quarter of the picture.
stands : List(Stand)
stands = [
	{ kind: Conifer.Green, canvas_x: 80.0 },
	{ kind: Conifer.SmallGreen, canvas_x: 240.0 },
	{ kind: Conifer.Red, canvas_x: 400.0 },
	{ kind: Conifer.Gold, canvas_x: 560.0 },
]

## The camera, at the start of the road, looking down it.
eye : Geom.Vantage
eye = {
	along: Along.start,
	across: Across.middle,
	yaw: Angle.straight_ahead,
}

## How far right of the camera a stand's tree must be to land on its `canvas_x`
## through the long lens.
right_of : Stand -> Distance
right_of = |stand| {
	screen_x = WidgetPage.screen_x_at_canvas_x(stand.canvas_x)
	forward.times(Lens.slope_at_x({ x: screen_x, focal_length }))
}

## A stand's tree as the camera sees it, on the ground `forward` down the road.
stand_sighting : Stand -> Try(Pipeline.Sighted(Conifer), [BehindCamera])
stand_sighting = |stand| {
	placed_tree : Geom.Placed(Conifer)
	placed_tree = {
		road_point: { along: Along.at(forward), across: Across.right_of_middle(right_of(stand)) },
		lift: Distance.zero,
		kind: stand.kind,
	}
	Pipeline.sighting_of(
		placed_tree,
		{
			road: World.road_at_start,
			vantage: eye,
			from_rider: Ahead(SegmentFromRider.Position.first),
		},
	)
}

tree_shapes : Stand -> List(Shapes.Shape)
tree_shapes = |stand|
	match stand_sighting(stand) {
		Ok(sighted) =>
			sighted.kind.scenery_sprite({
				spot: sighted.spot,
				focal_length,
				darkness: Sky.darkness_at(Clock.start),
			}).to_shapes()
		Err(BehindCamera) => crash "ConifersWidgetApp.tree_shapes: each tree stands ahead"
	}

picture_shapes : List(Shapes.Shape)
picture_shapes = WidgetPage.picture_shapes({
	backdrop: {
		sky_colors: Sky.colors_at(Clock.start),
		sun_sighting: OutOfView,
		darkness: Sky.darkness_at(Clock.start),
	},
	ride_shapes: stands.join_map(tree_shapes),
})

## Whether `point` is on the canvas, edges included.
is_on_canvas : Point.Point -> Bool
is_on_canvas = |{ x, y }|
	x.to_f64() >= 0.0
		and x.to_f64() <= WidgetPage.canvas_width
		and y.to_f64() >= 0.0
		and y.to_f64() <= canvas_height

## Where a stand's tree has its foot and its tip on the canvas.
canvas_ends : Stand -> Try({ foot : Point.Point, tip : Point.Point }, [BehindCamera])
canvas_ends = |stand| {
	sighting = stand_sighting(stand)?
	outline = TreeShapes.tree_outline(
		sighting.spot.base(),
		{ height: stand.kind.scenery_height(), focal_length },
	)
	Ok({
		foot: WidgetPage.canvas_point_of_screen(outline.foot),
		tip: WidgetPage.canvas_point_of_screen({
			x: outline.foot.x,
			y: outline.foot.y - outline.height_on_screen,
		}),
	})
}

## How much of the canvas's height a stand's tree stands.
share_of_height : Stand -> Try(F64, [BehindCamera])
share_of_height = |stand| {
	{ foot, tip } = canvas_ends(stand)?
	Ok((foot.y.to_f64() - tip.y.to_f64()) / canvas_height)
}

## Whether every corner `shape` is drawn with, given on the ride's screen, is on
## the canvas.
is_shape_on_canvas : Shapes.Shape -> Bool
is_shape_on_canvas = |shape|
	match Shapes.region_corners(shape) {
		Ok(corners) => corners.all(|corner| is_on_canvas(WidgetPage.canvas_point_of_screen(corner)))
		Err(NoCorners) => False
	}

## Whether a stand's tree is drawn whole on the canvas.
is_all_on_canvas : Stand -> Bool
is_all_on_canvas = |stand| {
	shapes = tree_shapes(stand)
	# A trunk and eight tiers, so an empty drawing can't pass.
	shapes.len() == 9 and shapes.all(is_shape_on_canvas)
}

# Every tree is far enough off for a crown of triangles, at the distance its
# drawing picks the crown from.
expect
	stands.all(
		|stand|
			match stand_sighting(stand) {
				Ok(sighting) => TreeShapes.crown_of(sighting.spot.base().forward()) == Triangles
				Err(BehindCamera) => False
			},
	)

# Every tree is drawn whole on the canvas.
expect stands.all(is_all_on_canvas)

# The gold tree, the tallest kind, stands most of the picture's height.
expect
	match stands.keep_if(|stand| stand.kind == Conifer.Gold) {
		[gold_stand] =>
			match share_of_height(gold_stand) {
				Ok(share) => share >= 0.7 and share <= 0.85
				Err(BehindCamera) => False
			}
		_ => False
	}

# The trees stand in the order the type lists the kinds, left to right, each
# foot where its stand puts it.
expect {
	kinds = stands.map(|stand| stand.kind)
	kinds == [Conifer.Green, Conifer.SmallGreen, Conifer.Red, Conifer.Gold]
}
expect
	stands.all(
		|stand|
			match canvas_ends(stand) {
				Ok(ends) => (ends.foot.x.to_f64() - stand.canvas_x).abs() <= 0.000000001
				Err(BehindCamera) => False
			},
	)
expect {
	feet_x = stands.map(|stand| stand.canvas_x)
	feet_x.drop_first(1).map_with_index(
		|x, index|
			match feet_x.get(index) {
				Ok(left_x) => left_x < x
				Err(_) => False
			},
	).all(|is_further_right| is_further_right)
}

# One tree stands taller on the screen than another exactly when its kind is
# taller, for every pair.
expect
	stands.all(
		|first|
			stands.all(
				|second|
					match (share_of_height(first), share_of_height(second)) {
						(Ok(first_share), Ok(second_share)) =>
							(first_share < second_share)
								== (first.kind.scenery_height() < second.kind.scenery_height())
						_ => False
					},
			),
	)
