# The screen: what a run leaves in the framebuffer codex-vm scans out, for a
# platform that shows it. Here nothing is shown, so `shown` tells the machine
# not to read the framebuffer at all; machine/batch/MachineScreen.roc hands
# it to the page.
MachineScreen :: [].{
	shown : Bool
	shown = False

	# Width and height in pixels, the stride in pixels a row, and the bytes:
	# stride times height rows of four bytes a pixel (blue, green, red, unused).
	present! : U64, U64, U64, List(U8) => {}
	present! = |_width, _height, _stride, _pixels| {}
}
