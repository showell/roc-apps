app [main!] {}

import Cat

Wrapped(kind) : { animal : kind }

wrap : pose -> Wrapped({ pose : pose })
wrap = |pose| { animal: { pose } }

cat : [Sit, Run] -> Wrapped(Cat)
cat = |pose| wrap(pose)

main! = |args| {
	pose = if (args.len() > 1) Run else Sit
	echo!(Str.inspect(cat(pose).animal.pose_of()))
	Ok({})
}
