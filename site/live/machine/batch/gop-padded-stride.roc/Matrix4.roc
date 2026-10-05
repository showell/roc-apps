# Matrix4 -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

Matrix4 :: [].{
	Mat4 := { m : List(F64) }.{
		is_eq : Matrix4.Mat4, Matrix4.Mat4 -> Bool
		is_eq = |a, b| a.m == b.m
	}
	Vec4 := { v4x : F64, v4y : F64, v4z : F64, v4w : F64 }.{
		is_eq : Matrix4.Vec4, Matrix4.Vec4 -> Bool
		is_eq = |a, b| a.v4x == b.v4x and a.v4y == b.v4y and a.v4z == b.v4z and a.v4w == b.v4w
	}
}
