# Screen -- the framebuffer a run left, kept for the page: its width and
# height in pixels, its stride in pixels a row, and stride times height words
# of 0x00RRGGBB, which in the page's little-endian memory are four bytes a pixel
# (blue, green, red, unused).
Screen := [].{
	present! : U64, U64, U64, List(U32) => {}
}
