# MachineMedia -- what a run brings with it: the images the modelled disk
# attaches, nothing on either position of the primary channel here, and the
# keystrokes typed during the run, none here. The ladder writes its own beside
# each unit it runs, importing the test's .disk, .disk2 and .keys as files.

MachineMedia :: [].{
	drives : List([Attached(List(U8)), Absent])
	drives = [Absent, Absent]

	# A .keys timeline, as codex-vm's -keys-file reads it.
	keys : List(U8)
	keys = []
}
