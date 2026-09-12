# Codex tests, ported to Roc

124 programs from [Cobblestone](https://github.com/damiant3/Cobblestone)'s own test suite, machine-translated
from Codex to Roc and checked against the output Cobblestone records for
each one.

124 of the 173 the emitter runs to their verdict are here. Two kinds
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

`codex/` is a package of the 43 Codex chapters the tests are
emitted from (111 KB), and each test is a short app over it
(212 KB for all 124):

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

7 seconds for all 124 on one core, median 48 ms. Every one of
them RUNS in about 3 ms; the rest is the compiler. The slowest:

| test | ms |
|---|---|
| `cms-spread` | 166 |
| `consistent-hash-balance` | 158 |
| `carddeck-shuffle` | 127 |
| `particle-spread` | 126 |
| `mix-bits` | 121 |

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
| `codex_act_let_scope.roc` | 74 | 45 |
| `codex_amp_after_call.roc` | 29 | 45 |
| `codex_approx_eq.roc` | 43 | 53 |
| `codex_arith_operand_order.roc` | 35 | 43 |
| `codex_arithmetic.roc` | 88 | 61 |
| `codex_arm64_boot_test.roc` | 28 | 41 |
| `codex_bezier_identity.roc` | 64 | 57 |
| `codex_bitop_if_cond.roc` | 36 | 58 |
| `codex_ble_att_encode.roc` | 57 | 54 |
| `codex_bounded_sig_runtime.roc` | 34 | 52 |
| `codex_bs3_smoke.roc` | 79 | 53 |
| `codex_call_clobber.roc` | 39 | 47 |
| `codex_canopen_encode.roc` | 53 | 72 |
| `codex_cap_manifest_derived.roc` | 26 | 38 |
| `codex_carddeck_shuffle.roc` | 93 | 127 |
| `codex_chapter_pages.roc` | 32 | 44 |
| `codex_circbuf_test.roc` | 83 | 78 |
| `codex_cite_override_quire.roc` | 28 | 47 |
| `codex_cms_spread.roc` | 80 | 166 |
| `codex_consistent_hash_balance.roc` | 62 | 158 |
| `codex_convolution_identity.roc` | 50 | 52 |
| `codex_ctor_narrow_warn.roc` | 43 | 62 |
| `codex_dnp3_encode.roc` | 69 | 43 |
| `codex_effect_dotted_allow.roc` | 32 | 40 |
| `codex_effect_positive.roc` | 49 | 42 |
| `codex_effect_row_var_syntax.roc` | 45 | 44 |
| `codex_effect_widen_arg.roc` | 32 | 55 |
| `codex_effect_widen_scope.roc` | 36 | 54 |
| `codex_enip_encode.roc` | 60 | 56 |
| `codex_eq_generic_fields.roc` | 66 | 70 |
| `codex_eq_generic_recursive.roc` | 86 | 77 |
| `codex_eq_plain_sum.roc` | 66 | 56 |
| `codex_eventbus_test.roc` | 75 | 71 |
| `codex_factorial.roc` | 143 | 89 |
| `codex_field_cache_text_lit.roc` | 39 | 45 |
| `codex_fins_encode.roc` | 56 | 40 |
| `codex_frameless_leaf_probe.roc` | 58 | 60 |
| `codex_hart_encode.roc` | 61 | 43 |
| `codex_ieee802154_encode.roc` | 53 | 40 |
| `codex_if_in_arith.roc` | 33 | 41 |
| `codex_inline_cost_based.roc` | 55 | 42 |
| `codex_inline_single_caller.roc` | 50 | 42 |
| `codex_int_literal_underscore.roc` | 34 | 38 |
| `codex_iterate_test.roc` | 61 | 43 |
| `codex_iterate_zip_test.roc` | 60 | 71 |
| `codex_j1939_encode.roc` | 51 | 84 |
| `codex_knx_encode.roc` | 53 | 39 |
| `codex_leaf_let_if.roc` | 36 | 39 |
| `codex_leaf_mispredict.roc` | 34 | 45 |
| `codex_let_else_scope.roc` | 42 | 42 |
| `codex_let_shadow_scope.roc` | 36 | 44 |
| `codex_linear_branch.roc` | 44 | 42 |
| `codex_linear_mint_container.roc` | 35 | 40 |
| `codex_linear_poly_freeze.roc` | 28 | 40 |
| `codex_linear_smoke.roc` | 44 | 40 |
| `codex_lir_binop_cross.roc` | 76 | 44 |
| `codex_lir_branch_cross.roc` | 118 | 58 |
| `codex_lir_call_cross.roc` | 77 | 42 |
| `codex_lir_check.roc` | 184 | 59 |
| `codex_lir_frame_cross.roc` | 58 | 43 |
| `codex_lir_join_cross.roc` | 73 | 59 |
| `codex_lir_load_cross.roc` | 128 | 63 |
| `codex_lir_nullary_cross.roc` | 69 | 48 |
| `codex_lir_selector_smoke.roc` | 74 | 47 |
| `codex_lir_test_cross.roc` | 74 | 44 |
| `codex_list_pattern.roc` | 62 | 43 |
| `codex_list_tail_empty.roc` | 46 | 48 |
| `codex_literal_subpattern.roc` | 133 | 61 |
| `codex_match_arms_per_line.roc` | 59 | 45 |
| `codex_mbus_encode.roc` | 53 | 45 |
| `codex_melsec_encode.roc` | 56 | 48 |
| `codex_mix_bits.roc` | 69 | 121 |
| `codex_mod_bound_return.roc` | 44 | 58 |
| `codex_modprobe.roc` | 45 | 58 |
| `codex_mut_borrow_transitive.roc` | 39 | 44 |
| `codex_neg_int_parse.roc` | 26 | 48 |
| `codex_negation_abutment.roc` | 63 | 55 |
| `codex_particle_spread.roc` | 54 | 126 |
| `codex_path_real.roc` | 34 | 110 |
| `codex_prose_consistency.roc` | 72 | 57 |
| `codex_prose_smoke.roc` | 66 | 57 |
| `codex_punctual_iot.roc` | 118 | 76 |
| `codex_punctual_smoke.roc` | 44 | 39 |
| `codex_real_literal_boundary.roc` | 34 | 38 |
| `codex_reservoir_uniform.roc` | 94 | 101 |
| `codex_revised_narrow.roc` | 57 | 40 |
| `codex_roc_early_return_predicate.roc` | 29 | 47 |
| `codex_roc_fold_count.roc` | 38 | 41 |
| `codex_roc_fold_empty.roc` | 38 | 41 |
| `codex_roc_fold_product.roc` | 38 | 42 |
| `codex_roc_fold_sum.roc` | 38 | 40 |
| `codex_roc_recursive_var.roc` | 35 | 40 |
| `codex_rv_arg_order.roc` | 46 | 42 |
| `codex_rv_big_literal.roc` | 44 | 43 |
| `codex_rv_frameless_imm.roc` | 79 | 68 |
| `codex_rv_frameless_temp.roc` | 49 | 63 |
| `codex_rv_param_bind.roc` | 49 | 42 |
| `codex_rv_param_order.roc` | 59 | 52 |
| `codex_s7comm_encode.roc` | 84 | 42 |
| `codex_scope_console.roc` | 34 | 43 |
| `codex_scope_let_arm_global.roc` | 38 | 39 |
| `codex_sensor_data.roc` | 49 | 58 |
| `codex_simplify_check.roc` | 105 | 64 |
| `codex_sixlowpan_encode.roc` | 53 | 73 |
| `codex_sntp_encode.roc` | 66 | 87 |
| `codex_sort_test.roc` | 67 | 72 |
| `codex_string_escape_quote.roc` | 29 | 40 |
| `codex_tco_bitop_loop.roc` | 86 | 83 |
| `codex_tco_direct_arg_reads.roc` | 36 | 43 |
| `codex_tco_framed_append.roc` | 54 | 63 |
| `codex_tco_nested_if.roc` | 36 | 41 |
| `codex_tco_shuffle_spill.roc` | 48 | 51 |
| `codex_text_eq_branches.roc` | 90 | 50 |
| `codex_text_fold_indexed.roc` | 57 | 47 |
| `codex_tuple_syntax.roc` | 72 | 54 |
| `codex_tvar_in_declared_type.roc` | 33 | 39 |
| `codex_ui_sound_test.roc` | 100 | 73 |
| `codex_wavelet_sort_aliasing.roc` | 41 | 65 |
| `codex_when_arm_nontail.roc` | 81 | 52 |
| `codex_when_arm_tail_call.roc` | 70 | 47 |
| `codex_when_bool_cross.roc` | 59 | 50 |
| `codex_when_bool_pattern.roc` | 77 | 53 |
| `codex_when_generic_field.roc` | 71 | 65 |
| `codex_zigbee_encode.roc` | 53 | 41 |
