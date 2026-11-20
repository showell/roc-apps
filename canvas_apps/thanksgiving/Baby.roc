## Baby is the tiny robot, by Seating, with its arms and its turn its own
## until the mother has the pie: it carries the pie in front, dives to catch
## it as it slips, lifts it back up, and then holds it over its head and
## twirls once round for joy, until its mother takes it. Family says when
## everything happens and seats it.
import Ease
import Family
import Figure
import Placing
import Robot
import RobotBody
import Seating
import SideBody

Baby :: [].{

	## The baby at `now`: Seating's, with its arms holding the pie and its
	## twirl.
	baby_at : I64, { look : F64, glow : F64 } -> Seating.Guest
	baby_at = |now, lit| {
		seated = Seating.guest_at(Family.baby_plan, { now, look: lit.look, glow: lit.glow })
		if now >= Family.arms_down_tick + 15 {
			seated
		} else {
			body = Robot.proportions(Tiny)
			hand = baby_hand(body, { hip: seated.pose.hip, now })
			arms_pose = { ..seated.pose, facing: twirl(now) }
			{
				..seated,
				pose: {
					..arms_pose,
					near_arm: SideBody.arm_toward(body, { pose: arms_pose, hand }),
					far_arm: SideBody.arm_toward(
						body,
						{ pose: arms_pose, hand: { ..hand, across: hand.across - 0.03 } },
					),
				},
			}
		}
	}

	## How far the baby is through its slip, fall and catch, as how high its
	## hands are held from 0, dived, to 1, carrying.
	baby_carry : I64 -> F64
	baby_carry = |now| {
		fall_start = Family.slip_tick + Family.slip_frames
		lift_start = fall_start + Family.fall_frames
		if now < fall_start {
			1.0
		} else if now < lift_start {
			dive = Ease.ramp(now - fall_start, Family.fall_frames)
			lowered = 1.0 - (1.0 - dive) * (1.0 - dive)
			1.0 - lowered
		} else {
			Ease.smooth(Ease.ramp(now - lift_start, Family.lift_frames))
		}
	}

}

# The baby's own ticks: the twirl, after the catch, and its arms coming down
# once the pie is taken.
twirl_start : I64
twirl_start = 528

twirl_frames : I64
twirl_frames = 36

# The baby's facing: once round, over its twirl.
twirl : I64 -> F64
twirl = |now| (F64.tau * Ease.smooth(Ease.ramp(now - twirl_start, twirl_frames))).cos()

# Where the baby's hands are, from its spot: carrying the pie in front,
# diving to catch it, lifting it back, then up over its head until the
# mother takes it, then down.
baby_hand : RobotBody.Proportions, { hip : Figure.Spot, now : I64 } -> Figure.Spot
baby_hand = |body, { hip, now }| {
	carry = Placing.carrying_hand(body, hip)
	shoulder = SideBody.shoulder(body, { hip, lean: 0.0 })
	raised = { across: 0.04, up: shoulder.up + 0.22 }
	down = { across: 0.03, up: shoulder.up - 0.9 * (body.upper_arm + body.forearm) }
	held = { ..carry, up: carry.up - 0.18 * (1.0 - Baby.baby_carry(now)) }
	lifted_at = Family.slip_tick + Family.slip_frames + Family.fall_frames + Family.lift_frames
	if now < lifted_at {
		held
	} else if now < Family.arms_down_tick {
		mix(
			carry,
			raised,
			Ease.smooth(Ease.ramp(now - lifted_at, 8)),
		)
	} else {
		mix(
			raised,
			down,
			Ease.smooth(Ease.ramp(now - Family.arms_down_tick, 15)),
		)
	}
}

mix : Figure.Spot, Figure.Spot, F64 -> Figure.Spot
mix = |from, to, fraction| {
	across: from.across + (to.across - from.across) * fraction,
	up: from.up + (to.up - from.up) * fraction,
}
