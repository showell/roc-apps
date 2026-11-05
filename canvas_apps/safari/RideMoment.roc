# RideMoment -- originally emitted from Codex by rocemit; the Roc is the
# program now and this file is edited here (safari/README.md).
import Clock
import Frame
import Ground
import GroundSighting
import ItemDraw
import Mountains
import Pose
import Render
import RideFocal
import Rider
import Sky
import Truck
import ViewYaw
import World
import lib.Shapes

## One moment of the ride, and all that is kept from one step to the next: the
## rider and the truck, each moved once a step from where it was, and the
## clock, which counts the steps. Everything else that changes is worked out
## from these three.
RideMoment := {
	rider : Pose.RiderState,
	truck : Truck.TruckState,
	clock : Clock,
}.{

	initial : RideMoment
	initial = {
		rider: Pose.initial_rider_state,
		truck: Truck.initial_truck,
		clock: Clock.start,
	}

	next : List(World.Segment), RideMoment -> RideMoment
	next = |w, moment| (
		if Rider.is_finished(moment.rider, w) {
			initial
		} else {
			step(w, moment)
		}
	)

	step : List(World.Segment), RideMoment -> RideMoment
	step = |w, moment| (
		{
			nx = Rider.advance(moment.rider, w)
			dist = World.distance_along_route(w, { index: nx.segment, along: nx.along })
			{
				rider: nx,
				truck: Truck.advance(
					moment.truck,
					{
						rider_distance: dist,
						world: w,
						route_length: World.route_length(w),
					},
				),
				clock: moment.clock.next(),
			}
		}
	)

	## Which of the truck's lights are on: its headlights once the sun is behind
	## the mountains, and its brake lights as its last step left them.
	truck_lights : RideMoment -> Truck.Lights
	truck_lights = |moment| {
		headlights: if (Mountains.is_sun_behind_mountains(moment.clock)) On else Off,
		brake_lights: moment.truck.brake_lights,
	}

	frame : List(World.Segment), RideMoment -> List(Shapes.Shape)
	frame = |w, moment| (
		{
			s = moment.rider
			view = {
				road: {
					world: w,
					chain: Frame.chain_ahead(w, s.segment),
					pose: ViewYaw.pose_for(s),
				},
				cam_focal: RideFocal.ride_focal(w, s),
			}
			scene = Render.collect(
				view,
				{
					speed: s.speed,
					truck: {
						route_position: moment.truck.route_position,
						lights: truck_lights(moment),
					},
					clock: moment.clock,
				},
			)
			ground = GroundSighting.in_view(view.road)
			[
				Mountains.draw({
					heading: ViewYaw.heading_for(s),
					dusk: Sky.dusk_at(moment.clock),
					cam_focal: view.cam_focal,
				}),
				ground.join_map(|patch| Ground.draw(patch, view.cam_focal)),
				ItemDraw.draw(scene, view),
			].join()
		}
	)

	sun : List(World.Segment), RideMoment -> Sky.SunPos
	sun = |w, moment| (
		{
			cf = RideFocal.ride_focal(w, moment.rider)
			Sky.sun_pos({
				heading: ViewYaw.heading_for(moment.rider),
				clock: moment.clock,
				cam_focal: cf,
			})
		}
	)
}
