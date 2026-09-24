# GeneticAlgorithm -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import CceText
import Prelude
import Random

GeneticAlgorithm :: [].{
	GaChromosome : { genes : List(I64), gene_count : I64 }
	GaPopulation : { individuals : List(GeneticAlgorithm.GaChromosome), fitness : List(I64), pop_size : I64, gene_count : I64, generation : I64 }
	GaConfig : { mutation_rate : I64, crossover_rate : I64, tournament_size : I64, gene_min : I64, gene_max : I64 }

	ga_config_default : GeneticAlgorithm.GaConfig
	ga_config_default = { mutation_rate: 50, crossover_rate: 800, tournament_size: 3, gene_min: 0, gene_max: 1000 }

	ga_random_population : I64, I64, GeneticAlgorithm.GaConfig, I64 -> GeneticAlgorithm.GaPopulation
	ga_random_population = |pop_size, gene_count, cfg, seed| ({
		inds = ga_gen_individuals(pop_size, gene_count, cfg.gene_min, cfg.gene_max, seed, 0, [])
		{ individuals: inds, fitness: ga_zero_fitness(pop_size, 0, []), pop_size: pop_size, gene_count: gene_count, generation: 0 }
	})

	ga_gen_individuals : I64, I64, I64, I64, I64, I64, List(GeneticAlgorithm.GaChromosome) -> List(GeneticAlgorithm.GaChromosome)
	ga_gen_individuals = |n, genes, lo, hi, seed, i, acc| (if (i >= n) { acc } else { ({
		chromo = ga_random_chromo(genes, lo, hi, (seed + (i * 7919)), 0, [])
		ga_gen_individuals(n, genes, lo, hi, seed, (i + 1), List.append(acc, { genes: chromo, gene_count: genes }))
	}) })

	ga_random_chromo : I64, I64, I64, I64, I64, List(I64) -> List(I64)
	ga_random_chromo = |n, lo, hi, seed, i, acc| (if (i >= n) { acc } else { ({
		val = ga_rand_range(seed, i, lo, hi)
		ga_random_chromo(n, lo, hi, seed, (i + 1), List.append(acc, val))
	}) })

	ga_zero_fitness : I64, I64, List(I64) -> List(I64)
	ga_zero_fitness = |n, i, acc| (if (i >= n) { acc } else { ga_zero_fitness(n, (i + 1), List.append(acc, 0)) })

	ga_tournament_select : GeneticAlgorithm.GaPopulation, GeneticAlgorithm.GaConfig, I64 -> I64
	ga_tournament_select = |pop, cfg, seed| ga_tournament_loop(pop, cfg.tournament_size, seed, 0, 0, (0 - 1))

	ga_tournament_loop : GeneticAlgorithm.GaPopulation, I64, I64, I64, I64, I64 -> I64
	ga_tournament_loop = |pop, k, seed, i, best_idx, best_fit| (if (i >= k) { best_idx } else { ({
		idx = ga_rand_range(seed, i, 0, (pop.pop_size - 1))
		fit = (List.get(pop.fitness, I64.to_u64_wrap(idx)) ?? crash("list-at out of range"))
		(if (fit > best_fit) { ga_tournament_loop(pop, k, seed, (i + 1), idx, fit) } else { ga_tournament_loop(pop, k, seed, (i + 1), best_idx, best_fit) })
	}) })

	ga_crossover : GeneticAlgorithm.GaChromosome, GeneticAlgorithm.GaChromosome, I64 -> GeneticAlgorithm.GaChromosome
	ga_crossover = |a, b, seed| ({
		point = ga_rand_range(seed, 0, 1, (a.gene_count - 1))
		{ genes: ga_splice(a.genes, b.genes, point, 0, a.gene_count, []), gene_count: a.gene_count }
	})

	ga_splice : List(I64), List(I64), I64, I64, I64, List(I64) -> List(I64)
	ga_splice = |a, b, point, i, len, acc| (if (i >= len) { acc } else { ({
		val = (if (i < point) { (List.get(a, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) } else { (List.get(b, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) })
		ga_splice(a, b, point, (i + 1), len, List.append(acc, val))
	}) })

	ga_mutate : GeneticAlgorithm.GaChromosome, GeneticAlgorithm.GaConfig, I64 -> GeneticAlgorithm.GaChromosome
	ga_mutate = |chromo, cfg, seed| { genes: ga_mutate_loop(chromo.genes, cfg.mutation_rate, cfg.gene_min, cfg.gene_max, seed, 0, chromo.gene_count, []), gene_count: chromo.gene_count }

	ga_mutate_loop : List(I64), I64, I64, I64, I64, I64, I64, List(I64) -> List(I64)
	ga_mutate_loop = |genes, rate, lo, hi, seed, i, len, acc| (if (i >= len) { acc } else { ({
		r = ga_rand_range(seed, i, 0, 999)
		(if (r < rate) { ga_mutate_loop(genes, rate, lo, hi, seed, (i + 1), len, List.append(acc, ga_rand_range((seed + (i * 31)), i, lo, hi))) } else { ga_mutate_loop(genes, rate, lo, hi, seed, (i + 1), len, List.append(acc, (List.get(genes, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))) })
	}) })

	ga_evolve : GeneticAlgorithm.GaPopulation, GeneticAlgorithm.GaConfig, I64 -> GeneticAlgorithm.GaPopulation
	ga_evolve = |pop, cfg, seed| ({
		new_inds = ga_evolve_loop(pop, cfg, seed, 0, pop.pop_size, [])
		{ individuals: new_inds, fitness: ga_zero_fitness(pop.pop_size, 0, []), pop_size: pop.pop_size, gene_count: pop.gene_count, generation: (pop.generation + 1) }
	})

	ga_evolve_loop : GeneticAlgorithm.GaPopulation, GeneticAlgorithm.GaConfig, I64, I64, I64, List(GeneticAlgorithm.GaChromosome) -> List(GeneticAlgorithm.GaChromosome)
	ga_evolve_loop = |pop, cfg, seed, i, n, acc| (if (i >= n) { acc } else { ({
		p1 = ga_tournament_select(pop, cfg, (seed + (i * 101)))
		p2 = ga_tournament_select(pop, cfg, ((seed + (i * 307)) + 1))
		a = (List.get(pop.individuals, I64.to_u64_wrap(p1)) ?? crash("list-at out of range"))
		b = (List.get(pop.individuals, I64.to_u64_wrap(p2)) ?? crash("list-at out of range"))
		roll = ga_rand_range((seed + (i * 911)), i, 0, 999)
		child = (if (roll < cfg.crossover_rate) { ga_crossover(a, b, (seed + (i * 503))) } else { a })
		mutated = ga_mutate(child, cfg, (seed + (i * 709)))
		ga_evolve_loop(pop, cfg, seed, (i + 1), n, List.append(acc, mutated))
	}) })

	ga_rank : List(a), List(I64) -> List(a)
	ga_rank = |pop, scores| ga_rank_loop(pop, scores, [], U64.to_i64_wrap(List.len(pop)), [])

	ga_rank_loop : List(a), List(I64), List(I64), I64, List(a) -> List(a)
	ga_rank_loop = |pop, scores, used, left, acc| (if (left <= 0) { acc } else { ({
		bi = ga_best_unused(scores, used, 0, U64.to_i64_wrap(List.len(scores)), (0 - 1), 0)
		(if (bi < 0) { acc } else { (if (bi >= U64.to_i64_wrap(List.len(pop))) { acc } else { ga_rank_loop(pop, scores, List.append(used, bi), (left - 1), List.append(acc, (List.get(pop, I64.to_u64_wrap(bi)) ?? crash("list-at out of range")))) }) })
	}) })

	ga_best_unused : List(I64), List(I64), I64, I64, I64, I64 -> I64
	ga_best_unused = |scores, used, i, len, bi, bv| (if (i >= len) { bi } else { (if ga_seen(used, i, 0, U64.to_i64_wrap(List.len(used))) { ga_best_unused(scores, used, (i + 1), len, bi, bv) } else { ({
		v = (List.get(scores, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if (bi < 0) { ga_best_unused(scores, used, (i + 1), len, i, v) } else { (if (v > bv) { ga_best_unused(scores, used, (i + 1), len, i, v) } else { ga_best_unused(scores, used, (i + 1), len, bi, bv) }) })
	}) }) })

	ga_seen : List(I64), I64, I64, I64 -> Bool
	ga_seen = |xs, v, i, len| (if (i >= len) { False } else { (if ((List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")) == v) { True } else { ga_seen(xs, v, (i + 1), len) }) })

	ga_take : List(a), I64 -> List(a)
	ga_take = |xs, n| ga_take_loop(xs, n, 0, [])

	ga_take_loop : List(a), I64, I64, List(a) -> List(a)
	ga_take_loop = |xs, n, i, acc| (if (i >= n) { acc } else { (if (i >= U64.to_i64_wrap(List.len(xs))) { acc } else { ga_take_loop(xs, n, (i + 1), List.append(acc, (List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))) }) })

	ga_offspring : List(a), I64, (a, a, I64 -> a), (a, I64 -> a), I64 -> List(a)
	ga_offspring = |parents, want, breed, mutate, seed| ga_offspring_loop(parents, want, breed, mutate, seed, 0, [])

	ga_offspring_loop : List(a), I64, (a, a, I64 -> a), (a, I64 -> a), I64, I64, List(a) -> List(a)
	ga_offspring_loop = |parents, want, breed, mutate, seed, i, acc| (if (i >= want) { acc } else { ({
		np = U64.to_i64_wrap(List.len(parents))
		(if (np <= 0) { acc } else { ({
			m = (List.get(parents, I64.to_u64_wrap(Prelude.int_mod(i, np))) ?? crash("list-at out of range"))
			f = (List.get(parents, I64.to_u64_wrap(Prelude.int_mod((i + 1), np))) ?? crash("list-at out of range"))
			child = mutate(breed(m, f, (seed + (i * 503))), (seed + (i * 709)))
			ga_offspring_loop(parents, want, breed, mutate, seed, (i + 1), List.append(acc, child))
		}) })
	}) })

	ga_elitist_step : List(a), List(I64), I64, (a, a, I64 -> a), (a, I64 -> a), I64 -> List(a)
	ga_elitist_step = |pop, scores, elite, breed, mutate, seed| ({
		ranked = ga_rank(pop, scores)
		keep = ga_take(ranked, elite)
		List.concat(keep, ga_offspring(keep, (U64.to_i64_wrap(List.len(pop)) - elite), breed, mutate, seed))
	})

	ga_chromo_breed : GeneticAlgorithm.GaChromosome, GeneticAlgorithm.GaChromosome, I64 -> GeneticAlgorithm.GaChromosome
	ga_chromo_breed = |a, b, seed| ga_crossover(a, b, seed)

	ga_chromo_mutate : GeneticAlgorithm.GaChromosome, I64 -> GeneticAlgorithm.GaChromosome
	ga_chromo_mutate = |c, seed| ga_mutate(c, ga_config_default, seed)

	ga_evolve_elitist : GeneticAlgorithm.GaPopulation, I64, I64 -> GeneticAlgorithm.GaPopulation
	ga_evolve_elitist = |pop, elite, seed| { individuals: ga_elitist_step(pop.individuals, pop.fitness, elite, ga_chromo_breed, ga_chromo_mutate, seed), fitness: ga_zero_fitness(pop.pop_size, 0, []), pop_size: pop.pop_size, gene_count: pop.gene_count, generation: (pop.generation + 1) }

	ga_set_fitness : GeneticAlgorithm.GaPopulation, List(I64) -> GeneticAlgorithm.GaPopulation
	ga_set_fitness = |pop, fit| { individuals: pop.individuals, fitness: fit, pop_size: pop.pop_size, gene_count: pop.gene_count, generation: pop.generation }

	ga_best_idx : GeneticAlgorithm.GaPopulation -> I64
	ga_best_idx = |pop| ga_find_best(pop.fitness, 0, pop.pop_size, 0, (0 - 1))

	ga_find_best : List(I64), I64, I64, I64, I64 -> I64
	ga_find_best = |fit, i, len, best_idx, best_val| (if (i >= len) { best_idx } else { ({
		v = (List.get(fit, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if (v > best_val) { ga_find_best(fit, (i + 1), len, i, v) } else { ga_find_best(fit, (i + 1), len, best_idx, best_val) })
	}) })

	ga_best_fitness : GeneticAlgorithm.GaPopulation -> I64
	ga_best_fitness = |pop| (List.get(pop.fitness, I64.to_u64_wrap(ga_best_idx(pop))) ?? crash("list-at out of range"))

	ga_best_individual : GeneticAlgorithm.GaPopulation -> GeneticAlgorithm.GaChromosome
	ga_best_individual = |pop| (List.get(pop.individuals, I64.to_u64_wrap(ga_best_idx(pop))) ?? crash("list-at out of range"))

	ga_avg_fitness : GeneticAlgorithm.GaPopulation -> I64
	ga_avg_fitness = |pop| I64.div_trunc_by(ga_sum_fitness(pop.fitness, 0, pop.pop_size, 0), pop.pop_size)

	ga_sum_fitness : List(I64), I64, I64, I64 -> I64
	ga_sum_fitness = |fit, i, len, acc| (if (i >= len) { acc } else { ga_sum_fitness(fit, (i + 1), len, (acc + (List.get(fit, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))) })

	ga_rand_range : I64, I64, I64, I64 -> I64
	ga_rand_range = |seed, idx, lo, hi| Random.rand_in_range(seed, idx, lo, hi)

	format_chromosome : GeneticAlgorithm.GaChromosome -> CceText
	format_chromosome = |c| ga_fmt_genes(c.genes, 0, c.gene_count, "")

	ga_fmt_genes : List(I64), I64, I64, CceText -> CceText
	ga_fmt_genes = |genes, i, len, acc| (if (i >= len) { acc } else { ({
		sep = (if (i == 0) { "" } else { "," })
		ga_fmt_genes(genes, (i + 1), len, CceText.concat(CceText.concat(acc, sep), CceText.show_int((List.get(genes, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))))
	}) })
}
