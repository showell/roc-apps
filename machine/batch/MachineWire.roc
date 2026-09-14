# The wire between the NE2000 and the NAT behind it, for the batch page: each
# frame the program transmits (direction 0) and each frame the NAT answers
# with (direction 1) goes to the page through the platform's Wire. The doors
# are machine/roc/MachineWire.roc's.

import pf.Wire

MachineWire :: [].{
	sent! : List(U8) => {}
	sent! = |frame| Wire.frame!(0, frame)

	answered! : List(U8) => {}
	answered! = |frame| Wire.frame!(1, frame)
}
