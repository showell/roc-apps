# MachineMedia -- the drives a booted machine attaches: nothing on either
# position of the primary channel. The ladder writes its own beside each unit
# it runs, importing the test's .disk and .disk2 as files.
import MachineDisk

MachineMedia :: [].{
	drives : List(MachineDisk.Drive)
	drives = [Absent, Absent]
}
