## This module is the bytecode VM's garbage collector, a precise mark and
## sweep that moves nothing. The VM names its roots, the cells its machine
## refers to; `marked` follows every reference from them through the cells,
## and `swept` frees each cell left unmarked, linking it into the free list
## that `Heap.allocated` takes from. A JavaScript reference is a cell's
## index, and a live cell keeps its place, so no reference is rewritten.
##
## **THE MARKS ARE A LIST OF THEIR OWN.** The mark pass reads the cells and
## writes only its marks and its list of cells waiting to be visited, each
## written in place, so it never holds the cells while something writes
## them. The sweep is the one pass that writes the cells, and it takes them
## from the VM with nothing else referring to them.
##
## **A LIVE VALUE THAT NAMES A FREED CELL STOPS THE RUN.** Every cell the
## mark reaches was reached through a reference, so reaching a freed one
## means a root was missed at an earlier collection: the run crashes with
## that reason rather than answer with a cell some later allocation reused.
import Heap

Collector :: [].{

	## Whether a collection found a cell from the roots.
	Mark : [Reached, Unreached]

	## The heap after a sweep: its cells, the free list, and how many cells
	## the roots reach.
	Swept : { cells : List(Heap.Cell), free : Heap.Free, live : U64 }

	## The fewest cells a heap holds before its first collection, and the
	## floor under every later threshold: a program's builtins and a few
	## hundred of its own cells never pay for a collection.
	least_threshold : U64
	least_threshold = 1024

	## The cells `roots` reach, each by reference, through every cell's own.
	marked : List(Heap.Cell), List(U64) -> List(Collector.Mark)
	marked = |cells, roots| {
		var $marks = List.repeat(Unreached, cells.len())
		var $waiting = { ids: roots, count: roots.len() }
		while $waiting.count > 0 {
			id = $waiting.ids.get($waiting.count - 1) ?? crash "Collector.marked: below the waiting cells' count"
			$waiting = { ..$waiting, count: $waiting.count - 1 }
			match $marks.get(id) {
				Ok(Unreached) => {
					$marks = $marks.set(id, Reached) ?? crash "Collector.marked: a mark for every cell"
					$waiting = with_references_of($waiting, Heap.cell_at(cells, id))
				}
				Ok(Reached) => {}
				Err(OutOfBounds) => crash "Collector.marked: a reference names a cell the heap has"
			}
		}
		$marks
	}

	## The heap with every unmarked cell freed: each a `Freed` cell, linked
	## from the last to the first, so the free list starts at the lowest place.
	swept : List(Heap.Cell), List(Collector.Mark) -> Collector.Swept
	swept = |cells, marks| {
		count = cells.len()
		var $cells = cells
		var $free = NoneFree
		var $live = 0
		var $at = count
		while $at > 0 {
			$at = $at - 1
			match marks.get($at) {
				Ok(Reached) => {
					$live = $live + 1
				}
				Ok(Unreached) => {
					$cells = $cells.set($at, Freed($free)) ?? crash "Collector.swept: inside the cells"
					$free = FreeAt($at)
				}
				Err(OutOfBounds) => crash "Collector.swept: a mark for every cell"
			}
		}
		{ cells: $cells, free: $free, live: $live }
	}

	## How many marks say reached.
	reached_count : List(Collector.Mark) -> U64
	reached_count = |marks| marks.count_if(|mark| mark == Reached)

	## The cell a value refers to, put on `ids`: how a root's value joins the
	## roots.
	with_value_root : List(U64), Heap.Value -> List(U64)
	with_value_root = |ids, value|
		match value {
			Reference(id) => ids.append(id)
			_ => ids
		}
}

# The cells waiting to be visited: the first `count` of `ids`, a stack whose
# popped places are written over, so it grows only to its deepest.
Waiting : { ids : List(U64), count : U64 }

waiting_with : Waiting, U64 -> Waiting
waiting_with = |{ ids, count }, id|
	if count < ids.len() {
		{ ids: ids.set(count, id) ?? crash "Collector.waiting_with: below the waiting cells' end", count: count + 1 }
	} else {
		{ ids: ids.append(id), count: count + 1 }
	}

with_value : Waiting, Heap.Value -> Waiting
with_value = |waiting, value|
	match value {
		Reference(id) => waiting_with(waiting, id)
		_ => waiting
	}

with_properties : Waiting, List(Heap.Property) -> Waiting
with_properties = |waiting, properties| {
	var $waiting = waiting
	for property in properties {
		$waiting = with_value($waiting, property.value)
	}
	$waiting
}

with_values : Waiting, List(Heap.Value) -> Waiting
with_values = |waiting, values| {
	var $waiting = waiting
	for value in values {
		$waiting = with_value($waiting, value)
	}
	$waiting
}

with_ids : Waiting, List(U64) -> Waiting
with_ids = |waiting, ids| {
	var $waiting = waiting
	for id in ids {
		$waiting = waiting_with($waiting, id)
	}
	$waiting
}

with_entries : Waiting, List(Heap.Entry) -> Waiting
with_entries = |waiting, entries| {
	var $waiting = waiting
	for entry in entries {
		$waiting = match entry {
			Standing({ key, value }) => with_value(with_value($waiting, key), value)
			Gone => $waiting
		}
	}
	$waiting
}

# Every cell `cell` refers to, waiting.
with_references_of : Waiting, Heap.Cell -> Waiting
with_references_of = |waiting, cell|
	match cell {
		Object(properties) => with_properties(waiting, properties)
		Builtin(_, properties) => with_properties(waiting, properties)
		Namespace(_, properties) => with_properties(waiting, properties)
		Array(items) => with_values(waiting, items)
		# The VM's closure names its environment as its scope.
		Fun({ fun: _, scope }) => waiting_with(waiting, scope)
		Environment({ code: _, boxes }) => with_ids(waiting, boxes)
		Variable(value) => with_value(waiting, value)
		MapOf(_) | SetOf(_) => with_entries(waiting, Heap.table_of(cell).entries)
		Iteration({ source, view: _, next: _ }) => waiting_with(waiting, source)
		UnreadyVariable | TimerHandle(_) | Failure(_, _) => waiting
		Freed(_) => crash "Collector.marked: a live value names a freed cell, so a root was missed"
	}
