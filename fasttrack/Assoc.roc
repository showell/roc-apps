# Assoc -- pzp1997/assoc-list's Dict and erlandsona/assoc-set's Set, the
# parts elm-fasttrack uses.
#
# **THE ORDER IS THE POINT.** Both are association lists: `insert` removes the
# key and PREPENDS it, so iteration is most-recent-first, and `set_from_list`
# answers its input reversed. That order decides the order of the legal moves,
# and Elm's `==` on either compares the lists, order included, which is what
# History's undo check sees. Roc's `Dict` and `Set` keep another order.
Assoc :: [].{
	AssocDict(k, v) : List({ key : k, value : v })

	AssocSet(a) : List(a)

	dict_get : Assoc.AssocDict(k, v), k -> Try(v, [NotFound]) where [k.is_eq : k, k -> Bool]
	dict_get = |dict, key|
		match List.find_first(dict, |entry| entry.key == key) {
			Ok(entry) => Ok(entry.value)
			Err(_) => Err(NotFound)
		}

	dict_insert : Assoc.AssocDict(k, v), k, v -> Assoc.AssocDict(k, v) where [k.is_eq : k, k -> Bool]
	dict_insert = |dict, key, value| List.prepend(dict_remove(dict, key), { key, value })

	dict_remove : Assoc.AssocDict(k, v), k -> Assoc.AssocDict(k, v) where [k.is_eq : k, k -> Bool]
	dict_remove = |dict, key| List.drop_if(dict, |entry| entry.key == key)

	dict_keys : Assoc.AssocDict(k, v) -> List(k)
	dict_keys = |dict| List.map(dict, |entry| entry.key)

	set_insert : Assoc.AssocSet(a), a -> Assoc.AssocSet(a) where [a.is_eq : a, a -> Bool]
	set_insert = |set, item| List.prepend(List.drop_if(set, |other| other == item), item)

	set_from_list : List(a) -> Assoc.AssocSet(a) where [a.is_eq : a, a -> Bool]
	set_from_list = |items| List.fold(items, [], |set, item| set_insert(set, item))

	set_member : Assoc.AssocSet(a), a -> Bool where [a.is_eq : a, a -> Bool]
	set_member = |set, item| List.contains(set, item)
}

expect Assoc.set_from_list([1, 2, 3, 2]) == [2, 3, 1]
expect Assoc.dict_keys(Assoc.dict_insert(Assoc.dict_insert(Assoc.dict_insert([], "a", 1), "b", 2), "a", 3)) == ["a", "b"]
expect Assoc.dict_get(Assoc.dict_insert([], "a", 1), "a") == Ok(1)
expect Assoc.dict_get(Assoc.dict_insert([], "a", 1), "b") == Err(NotFound)
