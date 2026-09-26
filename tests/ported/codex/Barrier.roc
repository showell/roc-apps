# Barrier -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

Barrier :: [].{
	MBarrierState : [MBUninit, MBReady, MBInvalidated]
	MBarrier := { mb_id : I64, mb_expected : I64, mb_state : Barrier.MBarrierState }.{
		is_eq : Barrier.MBarrier, Barrier.MBarrier -> Bool
		is_eq = |a, b| eq_MBarrier(a, b)
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

	eq_MBarrier : Barrier.MBarrier, Barrier.MBarrier -> Bool
	eq_MBarrier = |ex, ey| (((ex.mb_id == ey.mb_id) and (ex.mb_expected == ey.mb_expected)) and eq_MBarrierState(ex.mb_state, ey.mb_state))
}
