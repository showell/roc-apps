# MachineMedia -- the images the modelled disk attaches: nothing on either
# position of the primary channel. The ladder writes its own beside each unit
# it runs, importing the test's .disk and .disk2 as files.

MachineMedia :: [].{
	drives : List([Attached(List(U8)), Absent])
	drives = [Absent, Absent]
}
