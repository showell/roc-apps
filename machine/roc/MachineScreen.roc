# The screen: what a run leaves in the framebuffer codex-vm scans out, for a
# platform that shows it. Here nothing is shown, so `shown` tells the machine
# not to read the framebuffer at all; machine/batch/MachineScreen.roc hands
# it to the page.
MachineScreen :: [].{
	shown : Bool
	shown = False

	# Width and height in pixels, the stride in pixels a row, and the pixels:
	# stride times height words of 0x00RRGGBB.
	present! : U64, U64, U64, List(U32) => {}
	present! = |_width, _height, _stride, _pixels| {}
}
