# Texture -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

Texture :: [].{
	EngineTexture := { etx_width : I64, etx_height : I64, etx_pixels : List(I64) }.{
		is_eq : Texture.EngineTexture, Texture.EngineTexture -> Bool
		is_eq = |a, b| eq_EngineTexture(a, b)
	}
	SampleMode : [NearestNeighbor, Bilinear]
	WrapMode : [WrapRepeat, WrapClamp, WrapMirror]

	etx_get : Texture.EngineTexture, I64, I64 -> I64
	etx_get = |tex, x, y| (if (x < 0) { 0 } else { (if (y < 0) { 0 } else { (if (x >= tex.etx_width) { 0 } else { (if (y >= tex.etx_height) { 0 } else { (List.get(tex.etx_pixels, I64.to_u64_wrap(((y * tex.etx_width) + x))) ?? crash("list-at out of range")) }) }) }) })

	eq_EngineTexture : Texture.EngineTexture, Texture.EngineTexture -> Bool
	eq_EngineTexture = |ex, ey| (((ex.etx_width == ey.etx_width) and (ex.etx_height == ey.etx_height)) and (ex.etx_pixels == ey.etx_pixels))

	eq_SampleMode : Texture.SampleMode, Texture.SampleMode -> Bool
	eq_SampleMode = |ex, ey| (match ex {
		NearestNeighbor => (match ey {
			NearestNeighbor => True
			_ => False
		})
		Bilinear => (match ey {
			Bilinear => True
			_ => False
		})
	})

	eq_WrapMode : Texture.WrapMode, Texture.WrapMode -> Bool
	eq_WrapMode = |ex, ey| (match ex {
		WrapRepeat => (match ey {
			WrapRepeat => True
			_ => False
		})
		WrapClamp => (match ey {
			WrapClamp => True
			_ => False
		})
		WrapMirror => (match ey {
			WrapMirror => True
			_ => False
		})
	})
}
