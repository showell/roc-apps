# JointSpec -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
app [main!] {
	lib: "../lib/main.roc",
}

import Frame
import Grade
import Joint

outer_got : List(F64)
outer_got = [Joint.outer_cu(True), Joint.outer_cu(False)]

outer_want : List(F64)
outer_want = [0.0, 4.0]

pose : Frame.Pose
pose = {
	along: 100.0,
	across: 1.0,
	yaw: 0.2,
	hw: 2.0,
}

behind_right : Frame.Mapper
behind_right = {
	is_chain: False,
	d: 0,
	prev_len: 300.0,
	prev_angle: 0.8726646259971648,
	prev_right: True,
	prev_w: 4.0,
}

behind_left : Frame.Mapper
behind_left = {
	is_chain: False,
	d: 0,
	prev_len: 300.0,
	prev_angle: 1.2217304763960306,
	prev_right: False,
	prev_w: 4.0,
}

here : Frame.Mapper
here = Frame.chain_map(0)

apex_got : List(F64)
apex_got = (
	{
		r = Joint.joint_apex(
			{
				world: [],
				chain: [],
				pose: pose,
			},
			{
				before: behind_right,
				after: here,
				length_before: 300.0,
				exit_right: True,
			},
		)
		l = Joint.joint_apex(
			{
				world: [],
				chain: [],
				pose: pose,
			},
			{
				before: behind_left,
				after: here,
				length_before: 300.0,
				exit_right: False,
			},
		)
		[
			r.right,
			r.forward,
			l.right,
			l.forward,
		]
	}
)

apex_want : List(F64)
apex_want = [
	17.297297467543466,
	(-100.43071597950589),
	21.403438709482494,
	(-100.55298847633645),
]

# --- Entry ---

main! = |_args| {
	verdicts = [
		Grade.reals({
			name: "jt-outer",
			got: outer_got,
			want: outer_want,
			tol: 0.0,
		}),
		Grade.rel({
			name: "jt-apex ",
			got: apex_got,
			want: apex_want,
			tol: F64.from_bits(4502148214488346440),
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
