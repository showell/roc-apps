# Graph -- walks over a graph given as a neighbours function, from Graph.elm.
Graph :: [].{
	get_nodes_n_edges_away : (a -> List(a)), I64, a -> List(a)
	get_nodes_n_edges_away = |get_neighbors, n, node|
		if n == 0 {
			[node]
		} else {
			List.join_map(get_neighbors(node), |neighbor| get_nodes_n_edges_away(get_neighbors, n - 1, neighbor))
		}

	can_travel_n_edges : (a -> List(a)), I64, a -> Bool
	can_travel_n_edges = |get_neighbors, n, node|
		if n <= 0 {
			Bool.True
		} else {
			List.any(get_neighbors(node), |neighbor| can_travel_n_edges(get_neighbors, n - 1, neighbor))
		}
}
