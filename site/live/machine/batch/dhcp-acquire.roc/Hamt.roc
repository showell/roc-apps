# Hamt -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import CceText

Hamt :: [].{
	HamtEntry(a) : { key : CceText, value : a }
	HamtNode(a) := [HamtEmpty, HamtLeaf(I64, CceText, a), HamtCollision(I64, List(Hamt.HamtEntry(a))), HamtBranch(I64, List(Hamt.HamtNode(a)))].{
		is_eq : Hamt.HamtNode(a), Hamt.HamtNode(a) -> Bool where [a.is_eq : a, a -> Bool]
		is_eq = |a, b| eq_HamtNode(a, b)
	}
	HamtMap(a) : { root : Hamt.HamtNode(a), size : I64 }
	HamtSetResult(a) : { node : Hamt.HamtNode(a), delta : I64 }
	CollisionSetResult(a) : { entries : List(Hamt.HamtEntry(a)), delta : I64 }

	hamt_empty : Hamt.HamtMap(a)
	hamt_empty = { root: HamtEmpty, size: 0 }

	eq_HamtNode : Hamt.HamtNode(a), Hamt.HamtNode(a) -> Bool where [a.is_eq : a, a -> Bool]
	eq_HamtNode = |ex, ey| (match ex {
		HamtEmpty => (match ey {
			HamtEmpty => True
			_ => False
		})
		HamtLeaf(exf0, exf1, exf2) => (match ey {
			HamtLeaf(eyf0, eyf1, eyf2) => (((exf0 == eyf0) and (exf1 == eyf1)) and (exf2 == eyf2))
			_ => False
		})
		HamtCollision(exf0, exf1) => (match ey {
			HamtCollision(eyf0, eyf1) => ((exf0 == eyf0) and (exf1 == eyf1))
			_ => False
		})
		HamtBranch(exf0, exf1) => (match ey {
			HamtBranch(eyf0, eyf1) => ((exf0 == eyf0) and (exf1 == eyf1))
			_ => False
		})
	})
}
