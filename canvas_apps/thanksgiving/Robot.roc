## Robot draws one of the three builds of robot face on, as the army, the
## crowd and the float pushers are drawn, from what it is told: which build
## it is, how it stands, where its feet are on the screen and how many pixels
## a metre is there; SideBody draws a guest at the table side on. A build is
## proportions and two colors, and a pose is numbers, so a robot knows
## nothing of when it walks or lights up. RobotBody draws each part from the proportions; this module says
## which build has which, and puts the parts together back to front. The
## right hand is the one that carries, and `hand_at` says where it is, so a
## dish can be put in it.
import lib.Brush
import lib.Point
import lib.RgbColor
import lib.Shapes
import RobotBody
import RobotHead

Robot :: [].{

	## The builds: a tall thin one, a round one, a tiny one on a wheel, and
	## the tiny one's mother.
	Build : [Tall, Round, Tiny, Mommy]

	## How a robot stands this frame. `phase` is how far through its walk it
	## is, in radians, and `stride` how much it is walking, from 0 to 1. `reach` goes
	## from 0, the right arm at its side, to 1, the right hand held up under a
	## dish. `eye_glow` goes from 0, eyes dark, to 1, lit like the string lights.
	## `look` slides the eyes from 0, straight ahead, to 1, to the screen's right.
	Pose : {
		phase : F64,
		stride : F64,
		reach : F64,
		eye_glow : F64,
		look : F64,
	}

	## Where the right hand is, in metres across from the middle and up from
	## the ground under the robot.
	hand_at : Robot.Build, Robot.Pose -> { across : F64, up : F64 }
	hand_at = |build, pose| RobotBody.right_hand_at(proportions(build), pose)

	## A build's proportions and colors.
	proportions : Robot.Build -> RobotBody.Proportions
	proportions = |build|
		match build {
			Tall => {
				hip: 0.86,
				body_width: 0.3,
				body_height: 0.6,
				torso: Boxy,
				neck: 0.07,
				head_width: 0.24,
				head_height: 0.21,
				upper_arm: 0.3,
				forearm: 0.28,
				limb_width: 0.055,
				moves_on: Legs,
				antenna: 0.12,
				paint: Brush.opaque_rgba(RgbColor.of(0x8FA9C4)),
				trim: Brush.opaque_rgba(RgbColor.of(0x3E536B)),
			}
			Round => {
				hip: 0.36,
				body_width: 0.62,
				body_height: 0.58,
				torso: Barrel,
				neck: 0.03,
				head_width: 0.34,
				head_height: 0.22,
				upper_arm: 0.22,
				forearm: 0.2,
				limb_width: 0.075,
				moves_on: Legs,
				antenna: 0.0,
				paint: Brush.opaque_rgba(RgbColor.of(0xD5884A)),
				trim: Brush.opaque_rgba(RgbColor.of(0x7D4622)),
			}
			Mommy => {
				hip: 0.78,
				body_width: 0.32,
				body_height: 0.55,
				torso: Boxy,
				neck: 0.06,
				head_width: 0.26,
				head_height: 0.22,
				upper_arm: 0.28,
				forearm: 0.26,
				limb_width: 0.05,
				moves_on: Legs,
				antenna: 0.07,
				paint: Brush.opaque_rgba(RgbColor.of(0xD98BB0)),
				trim: Brush.opaque_rgba(RgbColor.of(0x7A3E5C)),
			}
			Tiny => {
				hip: 0.22,
				body_width: 0.24,
				body_height: 0.2,
				torso: Boxy,
				neck: 0.03,
				head_width: 0.3,
				head_height: 0.22,
				upper_arm: 0.13,
				forearm: 0.13,
				limb_width: 0.045,
				moves_on: Wheel,
				antenna: 0.09,
				paint: Brush.opaque_rgba(RgbColor.of(0x63C29E)),
				trim: Brush.opaque_rgba(RgbColor.of(0x2D6B55)),
			}
		}

	## The robot, back to front: antenna, legs or wheel, body, head, eyes,
	## then the arms in front of the body.
	figure_shapes : {
		build : Robot.Build,
		pose : Robot.Pose,
		feet : Point,
		pixels_per_metre : F64,
	} -> List(Shapes.Shape)
	figure_shapes = |{ build, pose, feet, pixels_per_metre }|
		perched_figure_shapes({ build, pose, feet, pixels_per_metre, hips_up: 0.0 })

	## The robot with its hips `hips_up` metres higher than standing puts
	## them, or lower, as a seat puts them: the body, the head and the arms
	## go with the hips, the legs reach from them to the ground, and a wheel
	## hangs from them.
	perched_figure_shapes : {
		build : Robot.Build,
		pose : Robot.Pose,
		feet : Point,
		pixels_per_metre : F64,
		hips_up : F64,
	} -> List(Shapes.Shape)
	perched_figure_shapes = |{ build, pose, feet, pixels_per_metre, hips_up }| {
		standing = proportions(build)
		body = { ..standing, hip: standing.hip + hips_up }
		place = {
			x: feet.x.to_f64(),
			y: feet.y.to_f64(),
			scale: pixels_per_metre,
		}
		hip = RobotBody.hip_height(body, pose)
		top = hip + body.body_height
		head_top = top + body.neck + body.head_height
		[
			RobotHead.antenna_shapes(place, { body, head_top, glow: pose.eye_glow }),
			match body.moves_on {
				Legs => RobotBody.leg_shapes(place, { body, pose, hip })
				Wheel => RobotBody.wheel_shapes(place, { body: standing, pose, hip })
			},
			RobotBody.torso_shapes(place, { body, hip }),
			RobotHead.head_shapes(
				place,
				{
					body,
					top,
					glow: pose.eye_glow,
					look: pose.look,
				},
			),
			RobotBody.arm_shapes(place, { body, pose }),
		].join()
	}
}

standing_still : Robot.Pose
standing_still = {
	phase: 0.0,
	stride: 0.0,
	reach: 0.0,
	eye_glow: 0.0,
	look: 0.0,
}

# A raised hand is above the shoulder, and a lowered one below it, for every
# build.
expect
	[Tall, Round, Tiny].all(
		|build| {
			shoulder = RobotBody.right_shoulder(Robot.proportions(build), standing_still)
			raised = Robot.hand_at(build, { ..standing_still, reach: 1.0 })
			lowered = Robot.hand_at(build, standing_still)
			raised.up > shoulder.up and lowered.up < shoulder.up
		},
	)

# The tall robot stands tallest and the tiny one shortest, standing still.
expect {
	tall = Robot.hand_at(Tall, standing_still)
	round = Robot.hand_at(Round, standing_still)
	tiny = Robot.hand_at(Tiny, standing_still)
	tall.up > round.up and round.up > tiny.up
}

# A figure is drawn at all, and dark eyes add no glow.
expect {
	figure = Robot.figure_shapes({
		build: Round,
		pose: standing_still,
		feet: Point.at(100.0, 200.0),
		pixels_per_metre: 80.0,
	})
	figure.len() > 10 and !figure.contains(Blend(Add))
}
