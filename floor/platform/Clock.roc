# Clock -- the floor's clock, in nanoseconds. It is the host's, not a count of
# the program's own steps, so a Roc layer can say "later" and mean it.
#
# The host runs one of two clocks, chosen when it starts. The **virtual** clock
# moves only where the program asks it to -- `wait!` arrives instantly and the
# run repeats exactly -- and is what a checked run uses. The **wall** clock
# follows the host's monotonic time and actually sleeps, which is what a run on
# real hardware wants.
#
# `wait!` is the door the rest of an operating system is built on: a timeout, a
# retransmit, a quantum, a blocked read. It answers the time it woke, which on
# the wall clock may be past the deadline asked for.
Clock := [].{
	now! : () => U64
	wait! : U64 => U64
}
