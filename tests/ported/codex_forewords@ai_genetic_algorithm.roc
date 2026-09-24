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

import cdx.CceText
import cdx.GeneticAlgorithm

# FwdGeneticAlgorithmTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

mk_chromo : I64 -> GeneticAlgorithm.GaChromosome
mk_chromo = |v| GeneticAlgorithm.GaChromosome.{ genes: [v, (v + 1), (v + 2)], gene_count: 3 }

head_gene : GeneticAlgorithm.GaChromosome -> I64
head_gene = |c| (List.get(c.genes, I64.to_u64_wrap(0)) ?? crash("list-at out of range"))

head_genes : List(GeneticAlgorithm.GaChromosome), I64, I64, CceText -> CceText
head_genes = |xs, i, n, acc| (if (i >= n) { acc } else { ({
	sep : CceText
	sep = (if (i == 0) { "" } else { " " })
	head_genes(xs, (i + 1), n, CceText.concat(CceText.concat(acc, sep), CceText.show_int(head_gene((List.get(xs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))))))
}) })

# --- Entry ---

main! = |_args| {
	pop = [mk_chromo(11), mk_chromo(22), mk_chromo(33), mk_chromo(44)]
	scores = [1, 9, 3, 7]
	ranked = GeneticAlgorithm.ga_rank(pop, scores)
	kept = GeneticAlgorithm.ga_take(ranked, 2)
	stepped = GeneticAlgorithm.ga_elitist_step(pop, scores, 2, GeneticAlgorithm.ga_chromo_breed, GeneticAlgorithm.ga_chromo_mutate, 5)
	gp = GeneticAlgorithm.GaPopulation.{ individuals: pop, fitness: scores, pop_size: 4, gene_count: 3, generation: 0 }
	evolved = GeneticAlgorithm.ga_evolve_elitist(gp, 2, 5)
	line!(CceText.printed(CceText.concat("ranked:   ", head_genes(ranked, 0, U64.to_i64_wrap(List.len(ranked)), ""))))
	line!(CceText.printed(CceText.concat("kept:     ", head_genes(kept, 0, U64.to_i64_wrap(List.len(kept)), ""))))
	line!(CceText.printed(CceText.concat(CceText.concat("stepped:  ", CceText.show_int(U64.to_i64_wrap(List.len(stepped)))), " individuals")))
	line!(CceText.printed(CceText.concat("elite held: ", head_genes(stepped, 0, 2, ""))))
	line!(CceText.printed(CceText.concat("best-idx: ", CceText.show_int(GeneticAlgorithm.ga_best_idx(gp)))))
	line!(CceText.printed(CceText.concat("best-fit: ", CceText.show_int(GeneticAlgorithm.ga_best_fitness(gp)))))
	line!(CceText.printed(CceText.concat("avg-fit:  ", CceText.show_int(GeneticAlgorithm.ga_avg_fitness(gp)))))
	line!(CceText.printed(CceText.concat("evolved gen: ", CceText.show_int(evolved.generation))))
	line!(CceText.printed(CceText.concat("evolved size: ", CceText.show_int(U64.to_i64_wrap(List.len(evolved.individuals))))))
	Ok({})
}
