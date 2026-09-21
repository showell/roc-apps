# Stills -- originally emitted from Codex by rocemit; the Roc is the program now
# and this file is edited here (safari/README.md).

Stills :: [].{
	StillPt : { x : F64, y : F64 }
	StillGrad : { kind : I64, rgba0 : I64, rgba1 : I64, off0 : F64, off1 : F64, ax : F64, ay : F64, bx : F64, by : F64, cx : F64, cy : F64, ux : F64, uy : F64, vx : F64, vy : F64 }
	StillPoly : { color : I64, grad : List(Stills.StillGrad), pts : List(Stills.StillPt) }
}
