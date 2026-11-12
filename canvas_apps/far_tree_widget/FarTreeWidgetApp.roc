## The widget for the Safari tutorial's chapter on the far tree: a fixed picture of
## one gold conifer far down the road, straight ahead, and no controls. A tree that
## far is a speck through the ride's lens, so the picture draws it through a lens
## six times as long. The sighting is the ride's, and so is the drawing: the
## conifer's own `scenery_sprite`, handed the longer focal length.
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

FarTreeWidgetApp :: [].{

	## A fixed picture has no state.
	Model : {}

	canvas_app : CanvasApp.CanvasApp(FarTreeWidgetApp.Model)
	canvas_app = {
		..WidgetPage.fixed_picture_app({ title: "A far tree", shapes: picture_shapes }),
		size: { width: WidgetPage.canvas_width, height: canvas_height },
	}
}

## The picture alone, with no panel under it: a strip of grass below the tree's
## foot, and the sky over its tip. The book's frame for this widget has the same
## aspect.
canvas_height : F64
canvas_height = 240.0

## Just past the reach of the cones, so the crown is flat triangles.
forward : Distance
forward = Distance.metres(210.0)

## The tallest kind, so the tree fills the most of the picture.
conifer : Conifer
conifer = Conifer.Gold

## Six times the ride's lens at rest, which puts the tree's tip near the top of
## the picture.
focal_length : Pixels
focal_length = Lens.resting_focal_length.times(6.0)

## The camera, at the start of the road, looking down it.
eye : Geom.Vantage
eye = {
	along: Along.start,
	across: Across.middle,
	yaw: Angle.straight_ahead,
}

## The tree as the camera sees it, straight ahead on the ground `ahead` down the
## road.
tree_sighting : Distance -> Try(Pipeline.Sighted(Conifer), [OutOfSight])
tree_sighting = |ahead| {
	placed_tree : Geom.Placed(Conifer)
	placed_tree = {
		road_point: { along: Along.at(ahead), across: Across.middle },
		lift: Distance.zero,
		kind: conifer,
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

tree_shapes : List(Shapes.Shape)
tree_shapes =
	match tree_sighting(forward) {
		Ok(sighted) =>
			sighted.kind.scenery_sprite({
				spot: sighted.spot,
				focal_length,
				darkness: Sky.darkness_at(Clock.start),
			}).to_shapes()
		Err(OutOfSight) => crash "FarTreeWidgetApp.tree_shapes: the tree stands ahead of the camera"
	}

picture_shapes : List(Shapes.Shape)
picture_shapes = WidgetPage.picture_shapes({
	backdrop: {
		sky_colors: Sky.colors_at(Clock.start),
		sun_sighting: OutOfView,
		darkness: Sky.darkness_at(Clock.start),
	},
	ride_shapes: tree_shapes,
})

## Whether `point` is on the canvas, edges included.
is_on_canvas : Point -> Bool
is_on_canvas = |{ x, y }|
	x.to_f64() >= 0.0
		and x.to_f64() <= WidgetPage.canvas_width
		and y.to_f64() >= 0.0
		and y.to_f64() <= canvas_height

## How much of the canvas's height the tree `ahead` down the road stands through
## a lens of `lens`, if its foot and its tip are both on the canvas.
share_of_height : { ahead : Distance, lens : Pixels } -> Try(F64, [OffCanvas, OutOfSight])
share_of_height = |{ ahead, lens }| {
	sighting = tree_sighting(ahead)?
	outline = TreeShapes.tree_outline(
		sighting.spot.base(),
		{ height: conifer.scenery_height(), focal_length: lens },
	)
	foot = WidgetPage.canvas_point_of_screen(outline.foot)
	tip = WidgetPage.canvas_point_of_screen({
		x: outline.foot.x,
		y: outline.foot.y - outline.height_on_screen,
	})
	if is_on_canvas(foot) and is_on_canvas(tip) {
		Ok((foot.y.to_f64() - tip.y.to_f64()) / canvas_height)
	} else {
		Err(OffCanvas)
	}
}

# The tree is far enough off for a crown of triangles, and a nearer one gets
# cones, so the distance matters.
expect TreeShapes.crown_of(forward) == Triangles
expect
	match TreeShapes.crown_of(Distance.metres(150.0)) {
		Cones(_) => True
		Triangles => False
	}

# Through the long lens the whole tree is on the canvas and stands most of its
# height. Through the ride's own lens it is far too small, and through a lens a
# sixth longer still its tip is off the top.
expect
	match share_of_height({ ahead: forward, lens: focal_length }) {
		Ok(share) => share >= 0.7 and share <= 0.85
		Err(_) => False
	}
expect
	match share_of_height({ ahead: forward, lens: Lens.resting_focal_length }) {
		Ok(share) => share < 0.2
		Err(_) => False
	}
expect
	match share_of_height({ ahead: forward, lens: Lens.resting_focal_length.times(7.0) }) {
		Err(OffCanvas) => True
		Ok(_) | Err(OutOfSight) => False
	}

# The tree stands in the middle of the picture.
expect
	match tree_sighting(forward) {
		Ok(sighting) => {
			outline = TreeShapes.tree_outline(
				sighting.spot.base(),
				{ height: conifer.scenery_height(), focal_length },
			)
			foot = WidgetPage.canvas_point_of_screen(outline.foot)
			(foot.x.to_f64() - WidgetPage.canvas_width / 2.0).abs() <= 0.000000001
		}
		Err(OutOfSight) => False
	}

# The tree is drawn: a trunk and eight tiers.
expect tree_shapes.len() == 9
