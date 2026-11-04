# SceneLimitsSpec -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).
app [main!] {
	lib: "../lib/main.roc",
}

import Grade
import SceneLimits

culls_got : List(F64)
culls_got = [
	SceneLimits.detail_dist,
	SceneLimits.crown_shade_dist,
	SceneLimits.min_scenery_px,
]

culls_want : List(F64)
culls_want = [200.0, 80.0, 2.0]

# --- Entry ---

main! = |_args| {
	verdicts = [
		Grade.reals({
			name: "sl-cull",
			got: culls_got,
			want: culls_want,
			tol: 0.0,
		}),
	]
	for verdict in verdicts {
		echo!(verdict)
	}
	Ok({})
}
