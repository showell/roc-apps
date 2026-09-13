app [main!] { pf: platform "platform/main.roc" }

import pf.Drive
import pf.Echo

# The platform before the machine: attach the file the command line names as
# the master, and print what the host answers for it and for the empty slave.
main! = |args| {
	path = List.get(args, 0) ?? ""
	opened = Drive.open!(0, path)
	master = Drive.read!(0, 0)
	slave = Drive.read!(1, 0)
	first = U8.to_str(List.get(master, 0) ?? 0)
	empty = U8.to_str(List.get(slave, 0) ?? 0)
	count = U64.to_str(Drive.sector_count!(0))
	Echo.line!("opened ${Str.inspect(opened)} sectors ${count} lba0 ${first} slave ${empty}\n")
	Ok({})
}
