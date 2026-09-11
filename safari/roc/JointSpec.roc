# JointSpec -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Frame
import Grade
import Joint

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

outer_got : List(F64)
outer_got = [Joint.outer_cu(True, 4.0), Joint.outer_cu(False, 4.0), Joint.outer_cu(True, 7.5), Joint.outer_cu(False, 7.5)]

outer_want : List(F64)
outer_want = [0.0, 4.0, 0.0, 7.5]

pose : Frame.Pose
pose = { along: 100.0, across: 1.0, yaw: 0.2, hw: 2.0 }

behind_right : Frame.Mapper
behind_right = { is_chain: False, d: 0, prev_len: 300.0, prev_angle: 0.8726646259971648, prev_right: True, prev_w: 4.0 }

behind_left : Frame.Mapper
behind_left = { is_chain: False, d: 0, prev_len: 300.0, prev_angle: 1.2217304763960306, prev_right: False, prev_w: 4.0 }

here : Frame.Mapper
here = Frame.chain_map(0)

apex_got : List(F64)
apex_got = ({
	r = Joint.joint_apex([], [], pose, behind_right, here, 300.0, 4.0, 4.0, True)
	l = Joint.joint_apex([], [], pose, behind_left, here, 300.0, 4.0, 4.0, False)
	[r.right, r.forward, l.right, l.forward]
})

apex_want : List(F64)
apex_want = [17.297297467543466, (-100.43071597950589), 21.403438709482494, (-100.55298847633645)]

# --- Entry ---

main! = |_args| {
	line!(Grade.grade_reals("jt-outer", outer_got, outer_want, 0.0))
	line!(Grade.grade_rel("jt-apex ", apex_got, apex_want, F64.from_bits(4502148214488346440)))
	Ok({})
}
