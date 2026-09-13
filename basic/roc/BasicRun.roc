# BASIC as a command: the interpreter's batch doors behind one executable,
# built once on Roc's default platform.
#
#   basic-run ecma  "<listing>" "<replies>"
#   basic-run micro "<listing>" "<replies>"
#
# **THE INTERPRETER IS A PURE FUNCTION**, so the command line is all the
# input it needs: a listing and its replies arrive as arguments (cleaned by
# CommandLine), the transcript leaves by `echo!`. Nothing waits and nothing
# sleeps -- the batch doors take every reply up front, and a SLEEP takes no
# time.
import CommandLine
import Machine

main! = |args| {
	dialect = List.get(args, 0) ?? ""
	listing = CommandLine.clean(List.get(args, 1) ?? "")
	replies = CommandLine.lines_of(CommandLine.clean(List.get(args, 2) ?? ""))
	# Every batch run starts from the same seed, so its transcript repeats.
	seed = 1
	r = Machine.run_measured(listing, replies, seed, dialect == "ecma")
	# **THE COUNTS GO TO STDERR** (dbg), so the transcript on stdout stays
	# the program's own: the statements it executed, and the program's size.
	dbg { steps: r.steps, statements: r.statements }
	echo!(r.transcript)
	Ok({})
}
