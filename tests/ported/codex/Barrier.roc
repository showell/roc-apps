# Barrier -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

Barrier :: [].{
	MBarrierState : [MBUninit, MBReady, MBInvalidated]
	MBarrier := { mb_id : I64, mb_expected : I64, mb_state : Barrier.MBarrierState }.{
		is_eq : Barrier.MBarrier, Barrier.MBarrier -> Bool
		is_eq = |a, b| a.mb_id == b.mb_id and a.mb_expected == b.mb_expected and a.mb_state == b.mb_state
	}

	eq_MBarrierState : Barrier.MBarrierState, Barrier.MBarrierState -> Bool
	eq_MBarrierState = |ex, ey| (match ex {
		MBUninit => (match ey {
			MBUninit => True
			_ => False
		})
		MBReady => (match ey {
			MBReady => True
			_ => False
		})
		MBInvalidated => (match ey {
			MBInvalidated => True
			_ => False
		})
	})
}
