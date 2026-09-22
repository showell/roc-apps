# History -- undo, from History.elm.
#
# `states` is a stack whose head is the last known good state. An undo pops
# the first state that differs from the present one, so a state saved twice
# over costs nothing.
History :: [].{
	History(a) : { states : List(a) }

	init : History.History(a)
	init = { states: [] }

	prior_states : History.History(a), a -> List(a) where [a.is_eq : a, a -> Bool]
	prior_states = |history, state|
		match List.find_first_index(history.states, |s| s != state) {
			Ok(i) => List.drop_first(history.states, i)
			Err(_) => []
		}

	update : History.History(a), a -> History.History(a) where [a.is_eq : a, a -> Bool]
	update = |history, state| { states: List.prepend(prior_states(history, state), state) }

	reset : a -> History.History(a)
	reset = |state| { states: [state] }

	can_undo : History.History(a), a -> Bool where [a.is_eq : a, a -> Bool]
	can_undo = |history, state| !List.is_empty(prior_states(history, state))

	## With nothing to undo this answers the state unchanged; the page hides
	## the button then anyway.
	undo : History.History(a), a -> (History.History(a), a) where [a.is_eq : a, a -> Bool]
	undo = |history, state|
		match prior_states(history, state) {
			[] => (history, state)
			[head, .. as rest] => ({ states: rest }, head)
		}
}

expect History.can_undo(History.reset(1), 1) == Bool.False
expect History.can_undo(History.update(History.reset(1), 2), 2)
expect History.undo(History.update(History.update(History.reset(1), 1), 2), 3) == ({ states: [1] }, 2)
