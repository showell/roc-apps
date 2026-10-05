# Color -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

Color :: [].{
	Rgb := { cr : I64, cg : I64, cb : I64 }.{
		is_eq : Color.Rgb, Color.Rgb -> Bool
		is_eq = |a, b| eq_Rgb(a, b)
	}
	Hsl := { ch : I64, cs : I64, cl : I64 }.{
		is_eq : Color.Hsl, Color.Hsl -> Bool
		is_eq = |a, b| eq_Hsl(a, b)
	}
	RainbowPalette : [PalRainbow, PalWarm, PalCool, PalPastel, PalNeon, PalFire, PalOcean, PalForest, PalMiami, PalMatrix, PalSakura, PalAurora]

	eq_Rgb : Color.Rgb, Color.Rgb -> Bool
	eq_Rgb = |ex, ey| (((ex.cr == ey.cr) and (ex.cg == ey.cg)) and (ex.cb == ey.cb))

	eq_Hsl : Color.Hsl, Color.Hsl -> Bool
	eq_Hsl = |ex, ey| (((ex.ch == ey.ch) and (ex.cs == ey.cs)) and (ex.cl == ey.cl))

	eq_RainbowPalette : Color.RainbowPalette, Color.RainbowPalette -> Bool
	eq_RainbowPalette = |ex, ey| (match ex {
		PalRainbow => (match ey {
			PalRainbow => True
			_ => False
		})
		PalWarm => (match ey {
			PalWarm => True
			_ => False
		})
		PalCool => (match ey {
			PalCool => True
			_ => False
		})
		PalPastel => (match ey {
			PalPastel => True
			_ => False
		})
		PalNeon => (match ey {
			PalNeon => True
			_ => False
		})
		PalFire => (match ey {
			PalFire => True
			_ => False
		})
		PalOcean => (match ey {
			PalOcean => True
			_ => False
		})
		PalForest => (match ey {
			PalForest => True
			_ => False
		})
		PalMiami => (match ey {
			PalMiami => True
			_ => False
		})
		PalMatrix => (match ey {
			PalMatrix => True
			_ => False
		})
		PalSakura => (match ey {
			PalSakura => True
			_ => False
		})
		PalAurora => (match ey {
			PalAurora => True
			_ => False
		})
	})
}
