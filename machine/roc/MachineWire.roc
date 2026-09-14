# The wire between the NE2000 and the NAT behind it: every frame the program
# transmits and every frame the NAT answers with passes these doors. Here they
# keep nothing, for the ladder and the native platform;
# machine/batch/MachineWire.roc hands each frame to the page.
MachineWire :: [].{
	sent! : List(U8) => {}
	sent! = |_frame| {}

	answered! : List(U8) => {}
	answered! = |_frame| {}
}
