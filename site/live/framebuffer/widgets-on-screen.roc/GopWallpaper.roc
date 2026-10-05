# GopWallpaper -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import BoxModel
import CceText
import Mem

GopWallpaper :: [].{
	WallpaperBitmap := { wb_buffer : I64, wb_offset : I64, wb_width : I64, wb_height : I64, wb_stride : I64, wb_bytes : I64, wb_top : Bool }.{
		is_eq : GopWallpaper.WallpaperBitmap, GopWallpaper.WallpaperBitmap -> Bool
		is_eq = |a, b| eq_WallpaperBitmap(a, b)
	}
	WallpaperRead : [WallpaperBmp(GopWallpaper.WallpaperBitmap), WallpaperReadRefused(CceText)]
	WallpaperFrame := { wf_buffer : I64, wf_width : I64, wf_height : I64, wf_x : I64, wf_y : I64, wf_w : I64, wf_h : I64 }.{
		is_eq : GopWallpaper.WallpaperFrame, GopWallpaper.WallpaperFrame -> Bool
		is_eq = |a, b| eq_WallpaperFrame(a, b)
	}
	WallpaperFit : [WallpaperReady(GopWallpaper.WallpaperFrame), WallpaperFitRefused(CceText)]

	gwp_copy_row! : Mem.Mem, I64, I64, I64, I64 => (Mem.Mem, I64)
	gwp_copy_row! = |mem, src, dest, at, limit| (if (at >= limit) { (mem, 0) } else { (if ((at + 8) <= limit) { ({
		(mem2, _copied) = ({
			(mem1, mem__1) = Mem.load!(mem, src, at, 8)
			Mem.store!(mem1, dest, at, mem__1, 8)
		})
		gwp_copy_row!(mem2, src, dest, (at + 8), limit)
	}) } else { ({
		(mem3, mem__2) = Mem.load!(mem, src, at, 4)
		Mem.store!(mem3, dest, at, mem__2, 4)
	}) }) })

	gwp_copy_rows! : Mem.Mem, GopWallpaper.WallpaperFrame, I64, I64, BoxModel.LayoutRect, I64 => (Mem.Mem, I64)
	gwp_copy_rows! = |mem, f, dest, stride, r, y| (if (y >= (r.lr_y + r.lr_h)) { (mem, 0) } else { ({
		(mem1, _copied) = gwp_copy_row!(mem, (f.wf_buffer + (((y * f.wf_width) + r.lr_x) * 4)), (dest + (((y * stride) + r.lr_x) * 4)), 0, (r.lr_w * 4))
		gwp_copy_rows!(mem1, f, dest, stride, r, (y + 1))
	}) })

	gwp_blit! : Mem.Mem, GopWallpaper.WallpaperFrame, I64, I64, I64, BoxModel.LayoutRect => (Mem.Mem, I64)
	gwp_blit! = |mem, f, dest, stride, rows, clip| ({
		x : I64
		x = BoxModel.box_max(0, BoxModel.box_max(f.wf_x, clip.lr_x))
		y : I64
		y = BoxModel.box_max(0, BoxModel.box_max(f.wf_y, clip.lr_y))
		right : I64
		right = BoxModel.box_min(stride, BoxModel.box_min((f.wf_x + f.wf_w), (clip.lr_x + clip.lr_w)))
		bottom : I64
		bottom = BoxModel.box_min(rows, BoxModel.box_min((f.wf_y + f.wf_h), (clip.lr_y + clip.lr_h)))
		(if ((right <= x) or (bottom <= y)) { (mem, 0) } else { gwp_copy_rows!(mem, f, dest, stride, BoxModel.layout_rect(x, y, (right - x), (bottom - y)), y) })
	})

	gwp_state_frame! : Mem.Mem, I64 => (Mem.Mem, GopWallpaper.WallpaperFrame)
	gwp_state_frame! = |mem, s| ({
		(mem1, mem__1) = Mem.load!(mem, s, 0, 8)
		(mem2, mem__2) = Mem.load!(mem1, s, 8, 8)
		(mem3, mem__3) = Mem.load!(mem2, s, 16, 8)
		(mem4, mem__4) = Mem.load!(mem3, s, 24, 8)
		(mem5, mem__5) = Mem.load!(mem4, s, 32, 8)
		(mem6, mem__6) = Mem.load!(mem5, s, 40, 8)
		(mem7, mem__7) = Mem.load!(mem6, s, 48, 8)
		(mem7, GopWallpaper.WallpaperFrame.{ wf_buffer: mem__1, wf_width: mem__2, wf_height: mem__3, wf_x: mem__4, wf_y: mem__5, wf_w: mem__6, wf_h: mem__7 })
	})

	gwp_paint! : Mem.Mem, I64, I64, I64, I64, BoxModel.LayoutRect => (Mem.Mem, I64)
	gwp_paint! = |mem, s, dest, stride, rows, clip| (if (s == 0) { (mem, 0) } else { ({
		(mem1, mem__1) = Mem.load!(mem, s, 56, 8)
		(if (mem__1 == 0) { (mem1, 0) } else { ({
		(mem2, mem__2) = gwp_state_frame!(mem1, s)
		gwp_blit!(mem2, mem__2, dest, stride, rows, clip)
	}) })
	}) })

	eq_WallpaperBitmap : GopWallpaper.WallpaperBitmap, GopWallpaper.WallpaperBitmap -> Bool
	eq_WallpaperBitmap = |ex, ey| (((((((ex.wb_buffer == ey.wb_buffer) and (ex.wb_offset == ey.wb_offset)) and (ex.wb_width == ey.wb_width)) and (ex.wb_height == ey.wb_height)) and (ex.wb_stride == ey.wb_stride)) and (ex.wb_bytes == ey.wb_bytes)) and (ex.wb_top == ey.wb_top))

	eq_WallpaperRead : GopWallpaper.WallpaperRead, GopWallpaper.WallpaperRead -> Bool
	eq_WallpaperRead = |ex, ey| (match ex {
		WallpaperBmp(exf0) => (match ey {
			WallpaperBmp(eyf0) => eq_WallpaperBitmap(exf0, eyf0)
			_ => False
		})
		WallpaperReadRefused(exf0) => (match ey {
			WallpaperReadRefused(eyf0) => (exf0 == eyf0)
			_ => False
		})
	})

	eq_WallpaperFrame : GopWallpaper.WallpaperFrame, GopWallpaper.WallpaperFrame -> Bool
	eq_WallpaperFrame = |ex, ey| (((((((ex.wf_buffer == ey.wf_buffer) and (ex.wf_width == ey.wf_width)) and (ex.wf_height == ey.wf_height)) and (ex.wf_x == ey.wf_x)) and (ex.wf_y == ey.wf_y)) and (ex.wf_w == ey.wf_w)) and (ex.wf_h == ey.wf_h))

	eq_WallpaperFit : GopWallpaper.WallpaperFit, GopWallpaper.WallpaperFit -> Bool
	eq_WallpaperFit = |ex, ey| (match ex {
		WallpaperReady(exf0) => (match ey {
			WallpaperReady(eyf0) => eq_WallpaperFrame(exf0, eyf0)
			_ => False
		})
		WallpaperFitRefused(exf0) => (match ey {
			WallpaperFitRefused(eyf0) => (exf0 == eyf0)
			_ => False
		})
	})
}
