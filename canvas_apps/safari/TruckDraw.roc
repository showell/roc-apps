# TruckDraw draws the truck ahead on the road: its headlight beams first,
# then its body, then its brake lights, so each paints over the one before.
import Frame
import Paint
import TruckBody
import TruckLights
import TruckShape
import World

TruckDraw :: [].{
	truck_draw_body : List(World.Segment), List(I64), Frame.Pose, I64, F64, F64, Bool, Bool, F64, F64 -> List(Paint.DrawCmd)
	truck_draw_body = |segs, ch, pose, d, center_along, hw, braking, headlights, cf, view_w| (
		{
			bx = TruckShape.truck_box(center_along, hw)
			beams = (
				if headlights {
					TruckLights.truck_wedges(segs, ch, pose, d, bx, cf, view_w)
				} else {
					[]
				}
			)
			body = TruckBody.body(segs, ch, pose, d, bx, cf, view_w)
			lights = (
				if braking {
					TruckLights.brake_lights(segs, ch, pose, d, bx, cf, view_w)
				} else {
					[]
				}
			)
			List.join([beams, body, lights])
		}
	)
}
