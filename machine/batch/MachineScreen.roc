# The screen, for the batch page: what a run leaves in the framebuffer goes to
# the page through the platform's Screen. The doors are
# machine/roc/MachineScreen.roc's.

import pf.Screen

MachineScreen :: [].{
	shown : Bool
	shown = True

	present! : U64, U64, U64, List(U32) => {}
	present! = |width, height, stride, pixels| Screen.present!(width, height, stride, pixels)
}
