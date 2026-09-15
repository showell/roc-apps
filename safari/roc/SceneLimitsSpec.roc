# SceneLimitsSpec -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Grade
import SceneLimits
import Text

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

culls_got : List(F64)
culls_got = [SceneLimits.detail_dist, SceneLimits.crown_shade_dist, SceneLimits.min_scenery_px]

culls_want : List(F64)
culls_want = [200.0, 80.0, 2.0]

# --- Entry ---

main! = |_args| {
	line!(Text.printed(Grade.grade_reals([19, 23, 73, 24, 25, 23, 23], culls_got, culls_want, 0.0)))
	Ok({})
}
