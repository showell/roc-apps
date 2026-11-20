## Stances builds a robot's pose side on from a few plain wishes, for a
## robot whose steps are not Seating's own: standing still with its hands
## free or held at a spot, walking along a lane, stepping sideways, and the
## facing of a turn about its upright axis. Family's mother is built from
## these between her walk in and her walk to her own chair.
import lib.Eye
import Ease
import Figure
import Robot
import Seating
import SideBody

Stances :: [].{

	## Who is standing, and how they look and are lit.
	Who : {
		build : Robot.Build,
		look : F64,
		glow : F64,
	}

	## A turn about the upright axis, from facing one way to the other, over
	## `frames`.
	turned : I64,
	{
		from : F64,
		start : I64,
		frames : I64,
	} -> F64
	turned = |now, { from, start, frames }| from * (
		F64.pi * Ease.smooth(
			Ease.ramp(now - start, frames),
		)
	).cos()

	## A robot standing at `at`, its hands free or held at a spot, leaning
	## `lean` from the hips.
	standing : {
		build : Robot.Build,
		look : F64,
		glow : F64,
	},
	{
		at : Eye.At,
		facing : F64,
		hand : [Free, Holding(Figure.Spot)],
		lean : F64,
	} -> Seating.Guest
	standing = |{ build, look, glow }, { at, facing, hand, lean }| {
		body = Robot.proportions(build)
		hip = { across: 0.0, up: SideBody.standing_hip(body) }
		pose = {
			hip,
			near_foot: Seating.planted,
			far_foot: { ..Seating.planted, across: -0.05 },
			lean,
			head_tilt: 0.0 - 0.6 * lean,
			near_arm: Seating.hanging,
			far_arm: Seating.hanging,
			wheel_turn: 0.0,
			look,
			glow,
			facing,
		}
		arms =
			match hand {
				Free => { near: Seating.hanging, far: Seating.hanging }
				Holding(spot) => {
					near: SideBody.arm_toward(body, { pose, hand: spot }),
					far: SideBody.arm_toward(
						body,
						{ pose, hand: { ..spot, across: spot.across - 0.04 } },
					),
				}
			}
		{
			at,
			pose: { ..pose, near_arm: arms.near, far_arm: arms.far },
			chair_pulled: 0.0,
			walk_phase: 0.0,
		}
	}

	## Walking along a lane `forward` from one spot to another, facing the way
	## it goes.
	strolling : {
		build : Robot.Build,
		look : F64,
		glow : F64,
	},
	{
		from : F64,
		to : F64,
		forward : F64,
		start : I64,
		frames : I64,
		now : I64,
	} -> Seating.Guest
	strolling = |
		pose,
		{
			from,
			to,
			forward,
			start,
			frames,
			now,
		},
	| {
		progress = Ease.ramp(now - start, frames)
		right = from + (to - from) * Ease.smooth(progress)
		walked = (right - from).abs()
		facing = if to < from {
			-1.0
		} else {
			1.0
		}
		gait = Seating.gait_at(
			pose.build,
			{
				step: 1.0,
				phase: walked * F64.tau,
				stride: (F64.pi * progress).sin(),
			},
		)
		still = Stances.standing(
			pose,
			{
				at: { right, forward, height: 0.0 },
				facing,
				hand: Free,
				lean: 0.04,
			},
		)
		{
			..still,
			pose: {
				..still.pose,
				hip: gait.hip,
				near_foot: gait.near_foot,
				far_foot: gait.far_foot,
			},
		}
	}

	## Small steps sideways, nearer the eye or farther from it, at one spot
	## across.
	sidestepping : {
		build : Robot.Build,
		look : F64,
		glow : F64,
	},
	{
		right : F64,
		from : F64,
		to : F64,
		start : I64,
		frames : I64,
		now : I64,
	} -> Seating.Guest
	sidestepping = |
		pose,
		{
			right,
			from,
			to,
			start,
			frames,
			now,
		},
	| {
		progress = Ease.ramp(now - start, frames)
		forward = from + (to - from) * Ease.smooth(progress)
		gait = Seating.gait_at(
			pose.build,
			{
				step: 0.6,
				phase: 2.0 * F64.tau * progress,
				stride: 0.35 * (F64.pi * progress).sin(),
			},
		)
		still = Stances.standing(
			pose,
			{
				at: { right, forward, height: 0.0 },
				facing: 1.0,
				hand: Free,
				lean: 0.0,
			},
		)
		{
			..still,
			pose: {
				..still.pose,
				hip: gait.hip,
				near_foot: gait.near_foot,
				far_foot: gait.far_foot,
			},
		}
	}
}
