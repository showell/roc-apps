# Codex tests, ported to Roc

103 programs from [Cobblestone](https://github.com/damiant3/Cobblestone)'s own test suite, machine-translated
from Codex to Roc and checked against the output Cobblestone records for
each one.

103 of the 137 the emitter runs to their verdict are here. Two kinds
are left out. Eleven take more than a quarter of a second, and the reason
is the compiler rather than the program -- ten of them in compile-time
evaluation and one in the allocator -- so they are held back by name
rather than being a performance report inside a regression suite. The
rest are left out on size: a Codex chapter can be 28 KB and needed by
exactly one program, so a test goes when it would add more than 8 KB
of chapter text nobody else needs. Everything is in [roc-apps](https://github.com/showell/roc-apps).

**These were not written for Roc.** They are one compiler's test suite for
another language, translated; they may or may not be valuable here, and
they are offered rather than recommended. What they are is ordinary
programs that must print an exact thing: arithmetic, lists, records,
tagged unions, pattern matching, recursion, text and a private character
alphabet, in shapes nobody designing a Roc test would have chosen.

## The shape

`codex/` is a package of the 37 Codex chapters the tests are
emitted from (87 KB), and each test is a short app over it
(176 KB for all 103):

    app [main!] { cdx: "./codex/main.roc" }
    import cdx.ListUtils

A Codex program carries every chapter it cites, so the 137 units carried
137 copies of the same chapters; a chapter's emitted text is identical
wherever it appears, which is what lets them be shared here. Nothing was
edited by hand, and every app was run and compared with its expected
output before it was kept.

## Where they come from

Each app is one Codex program from `codex/test/` in
[Cobblestone](https://github.com/damiant3/Cobblestone), emitted by `rocemit`, the Codex-to-Roc emitter in
[roc-apps](https://github.com/showell/roc-apps). The header of every file names its source and the
bytes it must print; `expected/<name>.txt` holds those bytes exactly.

## Running them

    roc run codex_neg_int_parse.roc

`runner_rows.zig` holds one generated row per test in the shape
`src/cli/test/parallel_cli_runner.zig` uses, with the expected text as a
const, if wiring them into that table is how you would take them.

## What they cost

5 seconds for all 103 on one core, median 43 ms. Every one of
them RUNS in about 3 ms; the rest is the compiler. The slowest:

| test | ms |
|---|---|
| `cms-spread` | 157 |
| `consistent-hash-balance` | 146 |
| `carddeck-shuffle` | 141 |
| `reservoir-uniform` | 103 |
| `particle-spread` | 101 |

The compiler EVALUATES a call whose arguments are known, so for these
programs the compile time is largely the program's own work and the run is
then two or three milliseconds. The eleven where that adds up to more than
a quarter of a second are held back by name, and the slowest of them,
`ttt-perfect`, is the clearest case: 2.5 seconds to compile, because the
compiler plays the whole-tree tic-tac-toe search, and 3 ms to run, because
by then the answer is a constant.

## The tests

| file | lines | ms |
|---|---|---|
| `codex_amp_after_call.roc` | 29 | 43 |
| `codex_arith_operand_order.roc` | 35 | 51 |
| `codex_arm64_boot_test.roc` | 28 | 52 |
| `codex_bezier_identity.roc` | 64 | 72 |
| `codex_bitop_if_cond.roc` | 36 | 72 |
| `codex_ble_att_encode.roc` | 57 | 40 |
| `codex_bounded_sig_runtime.roc` | 34 | 39 |
| `codex_bs3_smoke.roc` | 79 | 47 |
| `codex_call_clobber.roc` | 39 | 46 |
| `codex_canopen_encode.roc` | 53 | 80 |
| `codex_cap_manifest_derived.roc` | 26 | 52 |
| `codex_carddeck_shuffle.roc` | 93 | 141 |
| `codex_chapter_pages.roc` | 32 | 41 |
| `codex_circbuf_test.roc` | 83 | 75 |
| `codex_cite_override_quire.roc` | 28 | 41 |
| `codex_cms_spread.roc` | 80 | 157 |
| `codex_consistent_hash_balance.roc` | 62 | 146 |
| `codex_convolution_identity.roc` | 50 | 48 |
| `codex_ctor_narrow_warn.roc` | 43 | 44 |
| `codex_dnp3_encode.roc` | 69 | 40 |
| `codex_effect_dotted_allow.roc` | 32 | 39 |
| `codex_effect_widen_arg.roc` | 32 | 41 |
| `codex_enip_encode.roc` | 60 | 39 |
| `codex_eq_generic_fields.roc` | 66 | 51 |
| `codex_eq_generic_recursive.roc` | 86 | 55 |
| `codex_eq_plain_sum.roc` | 66 | 46 |
| `codex_eventbus_test.roc` | 75 | 69 |
| `codex_fins_encode.roc` | 56 | 40 |
| `codex_frameless_leaf_probe.roc` | 58 | 55 |
| `codex_hart_encode.roc` | 61 | 38 |
| `codex_ieee802154_encode.roc` | 53 | 39 |
| `codex_if_in_arith.roc` | 33 | 38 |
| `codex_inline_cost_based.roc` | 55 | 37 |
| `codex_inline_single_caller.roc` | 50 | 43 |
| `codex_int_literal_underscore.roc` | 34 | 38 |
| `codex_j1939_encode.roc` | 51 | 74 |
| `codex_knx_encode.roc` | 53 | 39 |
| `codex_leaf_let_if.roc` | 36 | 37 |
| `codex_leaf_mispredict.roc` | 34 | 43 |
| `codex_let_else_scope.roc` | 42 | 40 |
| `codex_let_shadow_scope.roc` | 36 | 40 |
| `codex_linear_branch.roc` | 44 | 40 |
| `codex_linear_mint_container.roc` | 35 | 37 |
| `codex_linear_poly_freeze.roc` | 28 | 39 |
| `codex_linear_smoke.roc` | 44 | 40 |
| `codex_lir_binop_cross.roc` | 76 | 41 |
| `codex_lir_branch_cross.roc` | 118 | 50 |
| `codex_lir_call_cross.roc` | 77 | 46 |
| `codex_lir_check.roc` | 184 | 56 |
| `codex_lir_frame_cross.roc` | 58 | 46 |
| `codex_lir_join_cross.roc` | 73 | 43 |
| `codex_lir_load_cross.roc` | 128 | 42 |
| `codex_lir_nullary_cross.roc` | 69 | 43 |
| `codex_lir_selector_smoke.roc` | 74 | 46 |
| `codex_lir_test_cross.roc` | 74 | 57 |
| `codex_list_pattern.roc` | 62 | 46 |
| `codex_literal_subpattern.roc` | 133 | 44 |
| `codex_match_arms_per_line.roc` | 59 | 38 |
| `codex_mbus_encode.roc` | 53 | 39 |
| `codex_melsec_encode.roc` | 56 | 38 |
| `codex_mix_bits.roc` | 69 | 80 |
| `codex_mod_bound_return.roc` | 44 | 40 |
| `codex_modprobe.roc` | 45 | 43 |
| `codex_mut_borrow_transitive.roc` | 39 | 37 |
| `codex_neg_int_parse.roc` | 26 | 37 |
| `codex_negation_abutment.roc` | 63 | 44 |
| `codex_particle_spread.roc` | 54 | 101 |
| `codex_path_real.roc` | 34 | 97 |
| `codex_prose_smoke.roc` | 66 | 41 |
| `codex_punctual_smoke.roc` | 44 | 57 |
| `codex_real_literal_boundary.roc` | 34 | 44 |
| `codex_reservoir_uniform.roc` | 94 | 103 |
| `codex_roc_early_return_predicate.roc` | 29 | 48 |
| `codex_roc_fold_count.roc` | 38 | 43 |
| `codex_roc_fold_empty.roc` | 38 | 39 |
| `codex_roc_fold_product.roc` | 38 | 40 |
| `codex_roc_fold_sum.roc` | 38 | 39 |
| `codex_roc_recursive_var.roc` | 35 | 38 |
| `codex_rv_arg_order.roc` | 46 | 38 |
| `codex_rv_big_literal.roc` | 44 | 42 |
| `codex_rv_frameless_imm.roc` | 79 | 63 |
| `codex_rv_frameless_temp.roc` | 49 | 61 |
| `codex_rv_param_bind.roc` | 49 | 39 |
| `codex_rv_param_order.roc` | 59 | 39 |
| `codex_s7comm_encode.roc` | 84 | 41 |
| `codex_scope_console.roc` | 34 | 38 |
| `codex_scope_let_arm_global.roc` | 38 | 37 |
| `codex_simplify_check.roc` | 105 | 62 |
| `codex_sixlowpan_encode.roc` | 53 | 68 |
| `codex_sntp_encode.roc` | 66 | 90 |
| `codex_string_escape_quote.roc` | 29 | 39 |
| `codex_tco_bitop_loop.roc` | 86 | 61 |
| `codex_tco_direct_arg_reads.roc` | 36 | 39 |
| `codex_tco_framed_append.roc` | 54 | 54 |
| `codex_tco_nested_if.roc` | 36 | 43 |
| `codex_tco_shuffle_spill.roc` | 48 | 40 |
| `codex_text_eq_branches.roc` | 90 | 38 |
| `codex_tvar_in_declared_type.roc` | 33 | 37 |
| `codex_ui_sound_test.roc` | 100 | 68 |
| `codex_when_arm_tail_call.roc` | 70 | 41 |
| `codex_when_bool_cross.roc` | 59 | 42 |
| `codex_when_bool_pattern.roc` | 77 | 47 |
| `codex_zigbee_encode.roc` | 53 | 42 |
