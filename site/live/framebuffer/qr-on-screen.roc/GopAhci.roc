# GopAhci -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Mem

GopAhci :: [].{
	AhciHba := { hba_ok : Bool, hba_abar : I64, hba_port : I64 }.{
		is_eq : GopAhci.AhciHba, GopAhci.AhciHba -> Bool
		is_eq = |a, b| eq_AhciHba(a, b)
	}
	AhciRead := { ar_ok : Bool, ar_buf : I64 }.{
		is_eq : GopAhci.AhciRead, GopAhci.AhciRead -> Bool
		is_eq = |a, b| eq_AhciRead(a, b)
	}

	align_up : I64, I64 -> I64
	align_up = |v, a| ({
		m : I64
		m = (a - 1)
		((v + m) - I64.bitwise_and((v + m), m))
	})

	alloc_zeroed! : Mem.Mem, I64, I64 => (Mem.Mem, I64)
	alloc_zeroed! = |mem, size, align| ({
		(mem4, mem__1) = ({
		(mem1, raw) = Mem.mark(mem)
		(mem2, _adv) = Mem.advance(mem1, (size + align))
		base : I64
		base = align_up(raw, align)
		(mem3, _z) = zero_dwords!(mem2, base, 0, I64.div_trunc_by(size, 4))
		(mem3, base)
	})
		(mem4, mem__1)
	})

	zero_dwords! : Mem.Mem, I64, I64, I64 => (Mem.Mem, I64)
	zero_dwords! = |mem, addr, i, n| (if (i >= n) { (mem, 0) } else { ({
		(mem1, _p) = Mem.store!(mem, addr, (i * 4), 0, 4)
		zero_dwords!(mem1, addr, (i + 1), n)
	}) })

	eq_AhciHba : GopAhci.AhciHba, GopAhci.AhciHba -> Bool
	eq_AhciHba = |ex, ey| (((ex.hba_ok == ey.hba_ok) and (ex.hba_abar == ey.hba_abar)) and (ex.hba_port == ey.hba_port))

	eq_AhciRead : GopAhci.AhciRead, GopAhci.AhciRead -> Bool
	eq_AhciRead = |ex, ey| ((ex.ar_ok == ey.ar_ok) and (ex.ar_buf == ey.ar_buf))
}
