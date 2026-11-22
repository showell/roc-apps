## Backtrack is depth-first search, a transition at a time, for any puzzle that
## says where the option at an index leads from a state. Each frame is a state
## and where its parent resumes; states are values, so backing up drops a frame.
Backtrack(state) :: { frames : List({ state : state, after : U64 }), next : U64 }.{

	## A puzzle: the state an option leads to, refused, or no option at the index.
	Puzzle(state) : state, U64 -> [Child(state), Refused, NoMore]

	## A state entered, the top state left, or the root out of options.
	Step(state) : [Entered(state), Left(state), Exhausted]

	## The search from its root, `state`.
	start : state -> Backtrack(state)
	start = |state| Backtrack.({ frames: [{ state, after: 0 }], next: 0 })

	## The search one transition on, and the transition.
	step : Backtrack(state), Backtrack.Puzzle(state) -> (Backtrack(state), Backtrack.Step(state))
	step = |Backtrack.({ frames, next }), puzzle| {
		top = frames.last() ?? crash "Backtrack.step: a search holds its root"
		match puzzle(top.state, next) {
			Child(state) => {
				entered = frames.append({ state, after: next + 1 })
				(Backtrack.({ frames: entered, next: 0 }), Entered(state))
			}
			Refused => Backtrack.({ frames, next: next + 1 }).step(puzzle)
			NoMore if frames.len() == 1 => (Backtrack.({ frames, next }), Exhausted)
			NoMore => (Backtrack.({ frames: frames.drop_last(1), next: top.after }), Left(top.state))
		}
	}
}
