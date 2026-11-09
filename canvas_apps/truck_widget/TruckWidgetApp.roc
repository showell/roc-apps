## The widget for the Safari tutorial's chapter on the truck: a fixed picture of
## one plain truck seen three ways, in daytime, with no controls. Each truck is
## `TruckBody.body_picture`, drawn from a camera set round it at its own angle, and
## under each is the way it is seen from.
import game.Across
import game.Along
import game.Angle
import game.Clock
import game.Distance
import game.Geom
import game.Lens
import game.Pipeline
import game.SegmentFromRider
import game.Sky
import game.TruckBody
import game.TruckPlacement
import game.TruckShape
import game.TruckSighting
import game.World
import lib.CanvasApp
import lib.Point
import lib.Shapes
import widget.WidgetPage
import widget.WidgetPalette

TruckWidgetApp :: [].{

	## A fixed picture has no state.
	Model : {}

	canvas_app : CanvasApp.CanvasApp(TruckWidgetApp.Model)
	canvas_app = WidgetPage.fixed_picture_app({ title: "A truck three ways", shapes: fixed_picture_shapes })
}

## One truck in the picture: the words under it, how far round toward the
## truck's left side the camera stands, from straight behind it, how far the
## camera stands from the middle of the truck, and the x on the canvas the middle
## of the truck lands on.
TruckView : {
	caption : Str,
	seen_from : Angle.Turn,
	distance : Distance,
	canvas_x : F64,
}

## Each truck has a third of the canvas to itself.
third_width : F64
third_width = WidgetPage.canvas_width / 3.0

## The picture ends `WidgetPage.ground_depth` below the horizon, so a truck's nearest
## tires stand above the panel only once they are far enough ahead of the camera,
## and a truck toward the canvas's edge, seen at a slant, must stand further off
## still. This is far enough for every view, and 32 metres is too near for the
## view from behind, as the expects below hold.
view_distance : Distance
view_distance = Distance.metres(45.0)

## Only the truck's back shows.
behind_view : TruckView
behind_view = {
	caption: "from behind",
	seen_from: Angle.straight_ahead,
	distance: view_distance,
	canvas_x: third_width * 0.5,
}

## The back and the left side both show, with neither seen edge-on.
behind_left_view : TruckView
behind_left_view = {
	caption: "behind and to the left",
	seen_from: Angle.Turn.degrees(40.0),
	distance: view_distance,
	canvas_x: third_width * 1.5,
}

## Only the left side shows, the whole length of the truck, cab and all.
left_side_view : TruckView
left_side_view = {
	caption: "from the left",
	seen_from: Angle.Turn.degrees(90.0),
	distance: view_distance,
	canvas_x: third_width * 2.5,
}

truck_views : List(TruckView)
truck_views = [behind_view, behind_left_view, left_side_view]

## The trailer's centre, where the truck stands: in the middle of the road, and
## as far down the route's first segment as the cameras stand from it, so that
## every camera stands on the segment.
truck_road_point : Geom.RoadPoint
truck_road_point = { along: Along.at(view_distance), across: Across.middle }

## How far ahead of the trailer's centre the middle of the whole truck is, cab
## and all, which is the point every camera looks at.
truck_middle_ahead : Distance
truck_middle_ahead = {
	box = TruckShape.truck_box
	box.rear.plus(box.nose).divided_by(2.0)
}

## The camera for `view`: `view.distance` from the middle of the truck, round
## from behind it by `view.seen_from`, and turned so that the middle of the truck
## lands on `view.canvas_x`.
view_vantage : TruckView -> Geom.Vantage
view_vantage = |view| {
	middle_along = truck_road_point.along.plus(truck_middle_ahead)
	seen_from_radians = view.seen_from.to_radians()
	middle_x = WidgetPage.screen_x_at_canvas_x(view.canvas_x)
	middle_turn = Lens.turn_at_x({ x: middle_x, focal_length: Lens.resting_focal_length })
	{
		along: middle_along.minus(view.distance.times(seen_from_radians.cos())),
		across: Across.left_of_middle(view.distance.times(seen_from_radians.sin())),
		yaw: view.seen_from.minus(middle_turn),
	}
}

## How the truck is drawn for `view`: its spot and its heading as that view's
## camera sees them.
view_setting : TruckView -> TruckPlacement.TruckSetting
view_setting = |view| {
	vantage = view_vantage(view)
	place = Ahead(SegmentFromRider.Position.first)
	placed_truck : Geom.Placed({})
	placed_truck = { road_point: truck_road_point, lift: Distance.zero, kind: {} }
	sighting_result = Pipeline.sighting_of(
		placed_truck,
		{ road: World.road_at_start, vantage, place },
	)
	match sighting_result {
		Ok(sighting) => {
			spot: sighting.spot,
			heading: TruckSighting.road_heading(
				World.road_at_start,
				{ vantage, place, road_point: truck_road_point },
			),
			focal_length: Lens.resting_focal_length,
		}
		Err(BehindCamera) => crash "TruckWidgetApp.view_setting: every camera faces the truck"
	}
}

truck_shapes : TruckView -> List(Shapes.Shape)
truck_shapes = |view| TruckBody.body_picture(view_setting(view)).to_shapes()

## The words under a truck, centered on it, on the panel's first row.
caption_shape : TruckView -> Shapes.Shape
caption_shape = |view|
	WidgetPage.readout_line({
		text: view.caption,
		color: WidgetPalette.ink_color,
		row: 0,
		style: { ..WidgetPage.panel_rows, x: view.canvas_x, align: Center },
	})

fixed_picture_shapes : List(Shapes.Shape)
fixed_picture_shapes = {
	picture_shapes = WidgetPage.picture_shapes({
		backdrop: { sky_colors: Sky.colors_at(Clock.start), sun_sighting: OutOfView },
		ride_shapes: truck_views.join_map(truck_shapes),
	})
	WidgetPage.frame_shapes({
		picture_shapes,
		status_lines: [],
	}).concat(truck_views.map(caption_shape))
}

## The coordinates of each polygon among `shapes`, in the ride's screen pixels.
polygon_coordinates : List(Shapes.Shape) -> List(List(F64))
polygon_coordinates = |shapes|
	shapes.keep_oks(
		|shape|
			match shape {
				Poly({ coordinates, .. }) => Ok(coordinates)
				Text(_) | Disc(_) | Rect(_) | Blend(_) | View(_) | Image(_) => Err(NotPoly)
			},
	)

## The corners of the polygons among `shapes`, on the canvas.
canvas_corners : List(Shapes.Shape) -> List(Point.Point)
canvas_corners = |shapes| {
	corner_of = |pair|
		match pair {
			[x, y] => WidgetPage.canvas_point_of_screen({ x, y })
			_ => crash "TruckWidgetApp.canvas_corners: a polygon's coordinates come in pairs"
		}
	polygon_coordinates(shapes).join_map(|coordinates| coordinates.chunks_of(2).map(corner_of))
}

## Whether `view`'s truck is all in the picture, above the panel and inside its
## own third of the canvas.
is_in_its_third : TruckView -> Bool
is_in_its_third = |view| {
	half_third = third_width / 2.0
	is_inside = |corner|
		WidgetPage.is_in_picture(corner)
			and (corner.x - view.canvas_x).abs() <= half_third
	corners = canvas_corners(truck_shapes(view))
	!corners.is_empty() and corners.all(is_inside)
}

# Each truck draws its six faces and its ten tires, none of them clipped away,
# and the picture holds those three trucks' polygons and no others.
expect truck_views.all(|view| truck_shapes(view).len() == 16)
expect polygon_coordinates(fixed_picture_shapes).len() == 3 * 16

# Every truck is all in its third, above the panel. A truck nearer than the
# views' distance loses its tires under the panel, and one seen from the side
# much nearer runs out of its third.
expect truck_views.all(is_in_its_third)
expect !is_in_its_third({ ..behind_view, distance: Distance.metres(32.0) })
expect !is_in_its_third({ ..left_side_view, distance: Distance.metres(20.0) })
