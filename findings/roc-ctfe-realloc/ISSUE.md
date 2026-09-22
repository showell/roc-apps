Compile-time evaluation panics: "compile-time RocOps reallocated unknown pointer"

`roc run main.roc` aborts in the compiler on this program, which builds a two-node trie and collects its keys:

```
thread 3118266 panic: compile-time RocOps reallocated unknown pointer
Cannot print stack trace: stack tracing is disabled
```

```roc
app [main!] {}

Node : { children : List(I64), has_value : Bool }
Trie : { nodes : List(Node) }

empty : Trie
empty = { nodes: [empty_node] }

empty_node : Node
empty_node = { children: [-1, -1, -1, -1], has_value: False }

insert_at : Trie, List(U8), I64, I64, I64 -> Trie
insert_at = |t, key, ki, klen, node_idx| if ki >= klen {
	node = List.get(t.nodes, I64.to_u64_wrap(node_idx)) ?? crash("get")
	{ nodes: List.set(t.nodes, I64.to_u64_wrap(node_idx), { children: node.children, has_value: True }) ?? crash("set") }
} else {
	ch = U8.to_i64(List.get(key, I64.to_u64_wrap(ki)) ?? crash("key"))
	node = List.get(t.nodes, I64.to_u64_wrap(node_idx)) ?? crash("get")
	child_idx = List.get(node.children, I64.to_u64_wrap(ch)) ?? crash("get")
	if child_idx < 0 {
		new_idx = U64.to_i64_wrap(List.len(t.nodes))
		new_children = List.set(node.children, I64.to_u64_wrap(ch), new_idx) ?? crash("set")
		updated = { children: new_children, has_value: node.has_value }
		t2 = { nodes: List.set(List.append(t.nodes, empty_node), I64.to_u64_wrap(node_idx), updated) ?? crash("set") }
		insert_at(t2, key, ki + 1, klen, new_idx)
	} else {
		insert_at(t, key, ki + 1, klen, child_idx)
	}
}

keys : Trie -> List(List(U8))
keys = |t| if List.len(t.nodes) == 0 { [] } else { collect_keys(t, 0, []) }

collect_keys : Trie, I64, List(List(U8)) -> List(List(U8))
collect_keys = |t, node_idx, acc| {
	node = List.get(t.nodes, I64.to_u64_wrap(node_idx)) ?? crash("get")
	acc2 = if node.has_value { List.append(acc, []) } else { acc }
	collect_children(t, node, 0, acc2)
}

collect_children : Trie, Node, I64, List(List(U8)) -> List(List(U8))
collect_children = |t, node, i, acc| if i >= 4 { acc } else {
	child_idx = List.get(node.children, I64.to_u64_wrap(i)) ?? crash("get")
	if child_idx < 0 {
		collect_children(t, node, i + 1, acc)
	} else {
		collect_children(t, node, i + 1, collect_keys(t, child_idx, acc))
	}
}

main! = |_args| {
	t = insert_at(empty, [2], 0, 1, 0)
	echo!(U64.to_str(List.len(keys(t))))
	Ok({})
}
```

It should print `1`. Taking the key from `args` instead of writing it as a literal (`[U64.to_u8_wrap(List.len(args)) + 1]`, the same key when run with no arguments) prints `1`, so the program is fine and the failure is in evaluating it at compile time.

| nightly | literal key | key from `args` |
|---|---|---|
| `nightly-2026-09-12-220fd47` | prints `1` | prints `1` |
| `nightly-2026-09-15-fe09c42` | SIGILL | SIGILL |
| `nightly-2026-09-19-d025939` | **panic above** | prints `1` |

So it regressed between `220fd47` and `fe09c42`. The 09-15 crash hits both forms and is gone by 09-19; the compile-time one is not. The release tarballs from roc-lang/nightlies, x86-64 Linux.

Each of these makes it pass, as far as we reduced it: writing `{ nodes: [empty_node] }` in `main!` instead of naming the `empty` constant; calling `collect_keys(t, 0, [])` directly instead of through `keys`; building the same two nodes by hand instead of with `insert_at`.

We have not tried `main`, which is 241 commits past `d025939` and includes compile-time work (739e00fbc0, d2585908ce), so it may already be fixed.

**Where we hit it.** We compile a Codex test corpus to Roc (https://github.com/showell/roc-apps), and this is a trie test that passed on the 09-12 nightly.

---

Reported by Claude (Anthropic's Claude Code), working with @showell. The files are in https://github.com/showell/roc-apps/tree/master/findings/roc-ctfe-realloc.
