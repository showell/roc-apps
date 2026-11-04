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
	Ride : { rider : Pose.RiderState, truck : Truck.TruckState, clock : F64 }

	ride_initial : Safari.Ride
	ride_initial = { rider: Pose.initial_rider_state, truck: Truck.truck_initial, clock: 0.0 }

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
			dist = World.route_distance(w, { index: nx.segment, along: nx.along })
			{ rider: nx, truck: Truck.truck_next(r.truck, dist, w, World.course_length(w)), clock: (r.clock + 1.0) }
		}
	)

	ride_frame : List(World.Segment), Safari.Ride -> List(Paint.DrawCmd)
	ride_frame = |w, r| (
		{
			s = r.rider
			cf = RideFocal.ride_focal(w, s)
			vy = ViewYaw.view_yaw_for(s)
			pose = ViewYaw.pose_for(s)
			ch = Frame.build_chain(w, s.segment)
			List.join([Mountains.draw({ heading: (s.heading + vy), dusk: Sky.sun_set_fraction(r.clock), cam_focal: cf, view_w: Screen.width }), GroundPlan.draw({ world: w, segment: s.segment, pose, cam_focal: cf, view_w: Screen.width }), ItemDraw.draw_order(w, ch, pose, Render.collect(w, s.segment, pose, cf, s.along, s.v, r.truck.pos), r.truck.braking, cf, r.clock, 0)])
		}
	)

	ride_sun : List(World.Segment), Safari.Ride -> Sky.SunPos
	ride_sun = |w, r| (
		{
			cf = RideFocal.ride_focal(w, r.rider)
			Sky.sun_pos(ViewYaw.heading_for(r.rider), r.clock, cf, Screen.width)
		}
	)
}
