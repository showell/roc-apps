# forewords@ai-genetic-algorithm
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/forewords@ai-genetic-algorithm.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     ranked:   22 44 33 11
#     kept:     22 44
#     stepped:  4 individuals
#     elite held: 22 44
#     best-idx: 1
#     best-fit: 9
#     avg-fit:  5
#     evolved gen: 1
#     evolved size: 4

app [main!] { cdx: "./codex/main.roc" }

import cdx.GeneticAlgorithm
import cdx.Text

# FwdGeneticAlgorithmTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

mk_chromo : I64 -> GeneticAlgorithm.GaChromosome
mk_chromo = |v| { genes: [v, (v + 1), (v + 2)], gene_count: 3 }

head_gene : GeneticAlgorithm.GaChromosome -> I64
head_gene = |c| (List.get(c.genes, I64.to_u64_wrap(0)) ?? crash("list-at out of range"))

head_genes : List(GeneticAlgorithm.GaChromosome), I64, I64, List(U8) -> List(U8)
head_genes = |xs, i, n, acc| (if (i >= n) { acc } else { ({
	sep = (if (i == 0) { [] } else { [2] })
	head_genes(xs, (i + 1), n, List.concat(List.concat(acc, sep), Text.show_int(head_gene((List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))))))
}) })

# --- Entry ---

main! = |_args| {
	pop = [mk_chromo(11), mk_chromo(22), mk_chromo(33), mk_chromo(44)]
	scores = [1, 9, 3, 7]
	ranked = GeneticAlgorithm.ga_rank(pop, scores)
	kept = GeneticAlgorithm.ga_take(ranked, 2)
	stepped = GeneticAlgorithm.ga_elitist_step(pop, scores, 2, GeneticAlgorithm.ga_chromo_breed, GeneticAlgorithm.ga_chromo_mutate, 5)
	gp = { individuals: pop, fitness: scores, pop_size: 4, gene_count: 3, generation: 0 }
	evolved = GeneticAlgorithm.ga_evolve_elitist(gp, 2, 5)
	line!(Text.printed(List.concat([21, 15, 18, 34, 13, 22, 69, 2, 2, 2], head_genes(ranked, 0, U64.to_i64_wrap(List.len(ranked)), []))))
	line!(Text.printed(List.concat([34, 13, 31, 14, 69, 2, 2, 2, 2, 2], head_genes(kept, 0, U64.to_i64_wrap(List.len(kept)), []))))
	line!(Text.printed(List.concat(List.concat([19, 14, 13, 31, 31, 13, 22, 69, 2, 2], Text.show_int(U64.to_i64_wrap(List.len(stepped)))), [2, 17, 18, 22, 17, 33, 17, 22, 25, 15, 23, 19])))
	line!(Text.printed(List.concat([13, 23, 17, 14, 13, 2, 20, 13, 23, 22, 69, 2], head_genes(stepped, 0, 2, []))))
	line!(Text.printed(List.concat([32, 13, 19, 14, 73, 17, 22, 36, 69, 2], Text.show_int(GeneticAlgorithm.ga_best_idx(gp)))))
	line!(Text.printed(List.concat([32, 13, 19, 14, 73, 28, 17, 14, 69, 2], Text.show_int(GeneticAlgorithm.ga_best_fitness(gp)))))
	line!(Text.printed(List.concat([15, 33, 29, 73, 28, 17, 14, 69, 2, 2], Text.show_int(GeneticAlgorithm.ga_avg_fitness(gp)))))
	line!(Text.printed(List.concat([13, 33, 16, 23, 33, 13, 22, 2, 29, 13, 18, 69, 2], Text.show_int(evolved.generation))))
	line!(Text.printed(List.concat([13, 33, 16, 23, 33, 13, 22, 2, 19, 17, 38, 13, 69, 2], Text.show_int(U64.to_i64_wrap(List.len(evolved.individuals))))))
	Ok({})
}
