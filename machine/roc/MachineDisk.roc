# Drives: each a whole image as bytes, sized from the image (sectors of 512),
# and the drive a block read addresses. A read past the end answers zeros, as
# the wasm plug's host does; codex-vm's IDE model sets an error status there,
# which this does not model yet.

MachineDisk :: [].{
	Drives : { images : List(List(U8)), selected : U64 }

	with_image : List(U8) -> MachineDisk.Drives
	with_image = |bytes| { images: [bytes], selected: 0 }

	image : MachineDisk.Drives -> List(U8)
	image = |ds| List.get(ds.images, ds.selected) ?? []

	sector_count : MachineDisk.Drives -> U64
	sector_count = |ds| U64.div_trunc_by(List.len(MachineDisk.image(ds)), 512)

	sector : MachineDisk.Drives, U64 -> List(U8)
	sector = |ds, lba| {
		img = MachineDisk.image(ds)
		start = lba * 512
		if start + 512 <= List.len(img) {
			List.sublist(img, { start: start, len: 512 })
		} else {
			List.repeat(0.U8, 512)
		}
	}
}
