# Safari -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
import Frame
import GroundPlan
import ItemDraw
import Mountains
import Paint
import Pose
import Render
import RideFocal
import Rider
import Screen
import Sky
import Truck
import ViewYaw
import World

Safari :: [].{
	Ride : {
		rider : Pose.RiderState,
		truck : Truck.TruckState,
		clock : F64,
	}

	ride_initial : Safari.Ride
	ride_initial = {
		rider: Pose.initial_rider_state,
		truck: Truck.initial_truck,
		clock: 0.0,
	}

	ride_next : List(World.Segment), Safari.Ride -> Safari.Ride
	ride_next = |w, r| (
		if Rider.is_finished(r.rider, w) {
			ride_initial
		} else {
			ride_step(w, r)
		}
	)

	ride_step : List(World.Segment), Safari.Ride -> Safari.Ride
	ride_step = |w, r| (
		{
			nx = Rider.get_next_rider_state(r.rider, w)
			dist = World.distance_along_route(w, { index: nx.segment, along: nx.along })
			{
				rider: nx,
				truck: Truck.advance(
					r.truck,
					{
						rider_distance: dist,
						world: w,
						route_length: World.route_length(w),
					},
				),
				clock: (r.clock + 1.0),
			}
		}
	)

	ride_frame : List(World.Segment), Safari.Ride -> List(Paint.DrawCmd)
	ride_frame = |w, r| (
		{
			s = r.rider
			cf = RideFocal.ride_focal(w, s)
			pose = ViewYaw.pose_for(s)
			chain = Frame.chain_ahead(w, s.segment)
			scene = Render.collect({
				world: w,
				chain,
				pose,
				cam_focal: cf,
				rider_segment: s.segment,
				rider_along: s.along,
				speed: s.v,
				truck_position: r.truck.route_position,
			})
			roadside = ItemDraw.draw(
				scene,
				{
					world: w,
					chain,
					pose,
					cam_focal: cf,
					clock: r.clock,
					brake_lights: if (r.truck.is_braking) On else Off,
				},
			)
			List.join([
				Mountains.draw({
					heading: ViewYaw.heading_for(s),
					dusk: Sky.sun_set_fraction(r.clock),
					cam_focal: cf,
					view_w: Screen.width,
				}),
				GroundPlan.draw({
					world: w,
					rider_segment: s.segment,
					pose,
					cam_focal: cf,
					view_w: Screen.width,
				}),
				roadside,
			])
		}
	)

	ride_sun : List(World.Segment), Safari.Ride -> Sky.SunPos
	ride_sun = |w, r| (
		{
			cf = RideFocal.ride_focal(w, r.rider)
			Sky.sun_pos({
				heading: ViewYaw.heading_for(r.rider).to_radians(),
				step: r.clock,
				view: { cam_focal: cf, view_w: Screen.width },
			})
		}
	)
}
