## These are Joint's checks: a bend's outer edge and its apex.
app [main!] {
	lib: "../lib/main.roc",
}

import Angle
import Frame
import Grade
import Joint

outer_got : List(F64)
outer_got = [Joint.outer_edge(right_turn), Joint.outer_edge(left_turn)]

outer_want : List(F64)
outer_want = [0.0, 4.0]

pose : Frame.Pose
pose = {
	along: 100.0,
	across: 1.0,
	yaw: Angle.Turn.radians(0.2),
	half_width: 2.0,
}

right_turn : Angle.Turn
right_turn = Angle.Turn.radians(0.8726646259971648)

left_turn : Angle.Turn
left_turn = Angle.Turn.radians(0.0 - 1.2217304763960306)

behind_right : Frame.SegmentPlace
behind_right = JustBehind({
	segment_length: 300.0,
	turn: right_turn,
	lane_width: 4.0,
})

behind_left : Frame.SegmentPlace
behind_left = JustBehind({
	segment_length: 300.0,
	turn: left_turn,
	lane_width: 4.0,
})

here : Frame.SegmentPlace
here = InChain(Frame.ChainPosition.first)

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
				turn: right_turn,
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
				turn: left_turn,
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
