## A value meant to have one owner, so every write into it is in place: an
## opt-in marker for a hot list (docs/roc-notes.md, "Speed and copying",
## "The Unique marker"). Its API is closed: nothing reaches the value but
## these functions, so a checker can know every write by name.
##
## **THE MARKER PREVENTS NOTHING BY ITSELF.** Roc doesn't know about it: a
## read of the old value after a write copies exactly as on a bare list
## (copy-shapes' `unique-get-after-set`). The guarantee is the checker's
## (Shale's cookbook/roc/find_uses_after_a_consume.shale), and it holds only
## where a gate runs the checker. It costs nothing at run time: copy-shapes'
## `unique-*` shapes allocate as the bare list's do.
##
## The rule it asks for: a read (`len`, `get`) is free anywhere before the
## binding's next write; a write (`set`, `append`, `update`, `take_from`,
## `unwrap`) ends the binding, and the old one is never used again.
Unique(a) :: a.{

	## A value given its one owner.
	wrap : a -> Unique(a)
	wrap = |value| Unique.(value)

	## The value handed back to plain Roc: it ends the discipline.
	unwrap : Unique(a) -> a
	unwrap = |Unique.(value)| value

	## How many entries the list has. A read.
	len : Unique(List(a)) -> U64
	len = |Unique.(items)| items.len()

	## The entry at an index, which must be in the list. A read.
	get : Unique(List(a)), U64 -> a
	get = |Unique.(items), at| items.get(at) ?? crash "Unique.get: the index is past the end"

	## The list with the entry at an index replaced. A write.
	set : Unique(List(a)), U64, a -> Unique(List(a))
	set = |
		Unique.(items),
		at,
		entry,
	| Unique.(items.set(at, entry) ?? crash "Unique.set: the index is past the end")

	## The list with an entry added at its end. A write.
	append : Unique(List(a)), a -> Unique(List(a))
	append = |Unique.(items), entry| Unique.(items.append(entry))

	## The list with the entry at an index given to `change`, unshared, and
	## replaced by what it gives. A write.
	update : Unique(List(a)), U64, (a -> a) -> Unique(List(a))
	update = |
		Unique.(items),
		at,
		change,
	| Unique.(items.update(at, change) ?? crash "Unique.update: the index is past the end")

	## The value under a key taken out of a dict, and the dict without it: the
	## value got, then the key removed, so the dict no longer holds it when
	## it is written. A write of the dict.
	take_from : Dict(k, Unique(v)),
	k -> Try(
		{ dict : Dict(k, Unique(v)), value : Unique(v) },
		[KeyNotFound],
	)
		where [k.is_eq : k, k -> Bool, k.to_hash : k, Hasher -> Hasher]
	take_from = |dict, key|
		match dict.get(key) {
			Ok(value) => Ok({ dict: dict.remove(key), value })
			Err(_) => Err(KeyNotFound)
		}
}
