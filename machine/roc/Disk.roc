# Drives: each a whole image as bytes, sized from the image (sectors of 512),
# and the drive a block read addresses. A read past the end answers zeros, as
# the wasm plug's host does; codex-vm's IDE model sets an error status there,
# which this does not model yet.

Disk :: [].{
	Drives : { images : List(List(U8)), selected : U64 }

	with_image : List(U8) -> Disk.Drives
	with_image = |bytes| { images: [bytes], selected: 0 }

	image : Disk.Drives -> List(U8)
	image = |ds| List.get(ds.images, ds.selected) ?? []

	sector_count : Disk.Drives -> U64
	sector_count = |ds| U64.div_trunc_by(List.len(Disk.image(ds)), 512)

	sector : Disk.Drives, U64 -> List(U8)
	sector = |ds, lba| {
		img = Disk.image(ds)
		start = lba * 512
		if start + 512 <= List.len(img) {
			List.sublist(img, { start: start, len: 512 })
		} else {
			List.repeat(0.U8, 512)
		}
	}
}
