## Backtrack is depth-first search, a transition at a time, for any puzzle that
## lists its options from a state and gives the state each leads to, or refuses
## it. Each frame is a state, the choice that reached it and the index after that
## choice in its parent's options. States are values: backing up drops a frame.
Backtrack(state, choice) :: { frames : List({ state : state, choice : choice, after : U64 }), next : U64 }.{

	## A puzzle: its options from a state, in the order tried, and where each leads.
	Puzzle(state, choice) : { options : state -> List(choice), child : state, choice -> Try(state, [Refused]) }

	## An option entered, the top frame left, or the root out of options.
	Step(choice) : [Entered(choice), Left(choice), Exhausted(choice)]

	## The search from the root `state`, reached by `choice`.
	start : state, choice -> Backtrack(state, choice)
	start = |state, choice| Backtrack.({ frames: [{ state, choice, after: 0 }], next: 0 })

	## The search one transition on: the top frame's next option the puzzle admits.
	step : Backtrack(state, choice), Backtrack.Puzzle(state, choice) -> (Backtrack(state, choice), Backtrack.Step(choice))
	step = |Backtrack.({ frames, next }), { options, child }| {
		top = frames.last() ?? crash "Backtrack.step: a search holds its root"
		choices = options(top.state)
		var $after = next
		var $entered = Err(Refused)
		while $after < choices.len() and Try.is_err($entered) {
			choice = choices.get($after) ?? crash "Backtrack.step: the index is inside the options"
			$after = $after + 1
			$entered = child(top.state, choice).map_ok(|state| { state, choice, after: $after })
		}
		match $entered {
			Ok(frame) => (Backtrack.({ frames: frames.append(frame), next: 0 }), Entered(frame.choice))
			Err(Refused) if frames.len() == 1 => (Backtrack.({ frames, next }), Exhausted(top.choice))
			Err(Refused) => (Backtrack.({ frames: frames.drop_last(1), next: top.after }), Left(top.choice))
		}
	}
}
