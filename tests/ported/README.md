# Codex tests, ported to Roc

104 programs from [Cobblestone](https://github.com/damiant3/Cobblestone)'s own test suite, machine-translated
from Codex to Roc and checked against the output Cobblestone records for
each one.

104 of the 137 the emitter runs to their verdict are here: a Codex
chapter can be 28 KB and needed by exactly one program, so a test is left
out when it would add more than 8 KB of chapter text nobody else
needs. The rest are in [roc-apps](https://github.com/showell/roc-apps).

**These were not written for Roc.** They are one compiler's test suite for
another language, translated; they may or may not be valuable here, and
they are offered rather than recommended. What they are is ordinary
programs that must print an exact thing: arithmetic, lists, records,
tagged unions, pattern matching, recursion, text and a private character
alphabet, in shapes nobody designing a Roc test would have chosen.

## The shape

`codex/` is a package of the 38 Codex chapters the tests are
emitted from (92 KB), and each test is a short app over it
(178 KB for all 104):

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

6 seconds for all 104 on one core, median 44 ms. Every one of
them RUNS in about 3 ms; the rest is the compiler. The slowest:

| test | ms |
|---|---|
| `bloom-spread` | 580 |
| `consistent-hash-balance` | 167 |
| `cms-spread` | 166 |
| `carddeck-shuffle` | 128 |
| `particle-spread` | 109 |

The compiler EVALUATES a call whose arguments are known, so for these
programs the compile time is largely the program's own work and the run is
then a few milliseconds. `ttt-perfect`, outside the default cap, is the
clearest case: 2.7 seconds to check, because the compiler plays the
whole-tree tic-tac-toe search, and 3 ms to run, because by then the answer
is a constant. See roc-apps `findings/roc-check-hang`.

## The tests

| file | lines | ms |
|---|---|---|
| `codex_amp_after_call.roc` | 29 | 57 |
| `codex_arith_operand_order.roc` | 35 | 54 |
| `codex_arm64_boot_test.roc` | 28 | 47 |
| `codex_bezier_identity.roc` | 64 | 53 |
| `codex_bitop_if_cond.roc` | 36 | 64 |
| `codex_ble_att_encode.roc` | 57 | 46 |
| `codex_bloom_spread.roc` | 59 | 580 |
| `codex_bounded_sig_runtime.roc` | 34 | 51 |
| `codex_bs3_smoke.roc` | 79 | 59 |
| `codex_call_clobber.roc` | 39 | 61 |
| `codex_canopen_encode.roc` | 53 | 94 |
| `codex_cap_manifest_derived.roc` | 26 | 50 |
| `codex_carddeck_shuffle.roc` | 93 | 128 |
| `codex_chapter_pages.roc` | 32 | 40 |
| `codex_circbuf_test.roc` | 83 | 73 |
| `codex_cite_override_quire.roc` | 28 | 41 |
| `codex_cms_spread.roc` | 80 | 166 |
| `codex_consistent_hash_balance.roc` | 62 | 167 |
| `codex_convolution_identity.roc` | 50 | 57 |
| `codex_ctor_narrow_warn.roc` | 43 | 48 |
| `codex_dnp3_encode.roc` | 69 | 43 |
| `codex_effect_dotted_allow.roc` | 32 | 42 |
| `codex_effect_widen_arg.roc` | 32 | 46 |
| `codex_enip_encode.roc` | 60 | 40 |
| `codex_eq_generic_fields.roc` | 66 | 53 |
| `codex_eq_generic_recursive.roc` | 86 | 55 |
| `codex_eq_plain_sum.roc` | 66 | 53 |
| `codex_eventbus_test.roc` | 75 | 79 |
| `codex_fins_encode.roc` | 56 | 41 |
| `codex_frameless_leaf_probe.roc` | 58 | 58 |
| `codex_hart_encode.roc` | 61 | 41 |
| `codex_ieee802154_encode.roc` | 53 | 42 |
| `codex_if_in_arith.roc` | 33 | 46 |
| `codex_inline_cost_based.roc` | 55 | 39 |
| `codex_inline_single_caller.roc` | 50 | 44 |
| `codex_int_literal_underscore.roc` | 34 | 44 |
| `codex_j1939_encode.roc` | 51 | 77 |
| `codex_knx_encode.roc` | 53 | 41 |
| `codex_leaf_let_if.roc` | 36 | 55 |
| `codex_leaf_mispredict.roc` | 34 | 40 |
| `codex_let_else_scope.roc` | 42 | 40 |
| `codex_let_shadow_scope.roc` | 36 | 40 |
| `codex_linear_branch.roc` | 44 | 45 |
| `codex_linear_mint_container.roc` | 35 | 39 |
| `codex_linear_poly_freeze.roc` | 28 | 41 |
| `codex_linear_smoke.roc` | 44 | 39 |
| `codex_lir_binop_cross.roc` | 76 | 42 |
| `codex_lir_branch_cross.roc` | 118 | 68 |
| `codex_lir_call_cross.roc` | 77 | 59 |
| `codex_lir_check.roc` | 184 | 66 |
| `codex_lir_frame_cross.roc` | 58 | 60 |
| `codex_lir_join_cross.roc` | 73 | 45 |
| `codex_lir_load_cross.roc` | 128 | 43 |
| `codex_lir_nullary_cross.roc` | 69 | 51 |
| `codex_lir_selector_smoke.roc` | 74 | 42 |
| `codex_lir_test_cross.roc` | 74 | 47 |
| `codex_list_pattern.roc` | 62 | 42 |
| `codex_literal_subpattern.roc` | 133 | 44 |
| `codex_match_arms_per_line.roc` | 59 | 43 |
| `codex_mbus_encode.roc` | 53 | 43 |
| `codex_melsec_encode.roc` | 56 | 42 |
| `codex_mix_bits.roc` | 69 | 99 |
| `codex_mod_bound_return.roc` | 44 | 43 |
| `codex_modprobe.roc` | 45 | 43 |
| `codex_mut_borrow_transitive.roc` | 39 | 40 |
| `codex_neg_int_parse.roc` | 26 | 37 |
| `codex_negation_abutment.roc` | 63 | 42 |
| `codex_particle_spread.roc` | 54 | 109 |
| `codex_path_real.roc` | 34 | 93 |
| `codex_prose_smoke.roc` | 66 | 38 |
| `codex_punctual_smoke.roc` | 44 | 38 |
| `codex_real_literal_boundary.roc` | 34 | 38 |
| `codex_reservoir_uniform.roc` | 94 | 100 |
| `codex_roc_early_return_predicate.roc` | 29 | 45 |
| `codex_roc_fold_count.roc` | 38 | 38 |
| `codex_roc_fold_empty.roc` | 38 | 38 |
| `codex_roc_fold_product.roc` | 38 | 41 |
| `codex_roc_fold_sum.roc` | 38 | 41 |
| `codex_roc_recursive_var.roc` | 35 | 39 |
| `codex_rv_arg_order.roc` | 46 | 42 |
| `codex_rv_big_literal.roc` | 44 | 43 |
| `codex_rv_frameless_imm.roc` | 79 | 67 |
| `codex_rv_frameless_temp.roc` | 49 | 64 |
| `codex_rv_param_bind.roc` | 49 | 40 |
| `codex_rv_param_order.roc` | 59 | 42 |
| `codex_s7comm_encode.roc` | 84 | 41 |
| `codex_scope_console.roc` | 34 | 39 |
| `codex_scope_let_arm_global.roc` | 38 | 39 |
| `codex_simplify_check.roc` | 105 | 90 |
| `codex_sixlowpan_encode.roc` | 53 | 90 |
| `codex_sntp_encode.roc` | 66 | 99 |
| `codex_string_escape_quote.roc` | 29 | 42 |
| `codex_tco_bitop_loop.roc` | 86 | 65 |
| `codex_tco_direct_arg_reads.roc` | 36 | 41 |
| `codex_tco_framed_append.roc` | 54 | 56 |
| `codex_tco_nested_if.roc` | 36 | 48 |
| `codex_tco_shuffle_spill.roc` | 48 | 44 |
| `codex_text_eq_branches.roc` | 90 | 40 |
| `codex_tvar_in_declared_type.roc` | 33 | 38 |
| `codex_ui_sound_test.roc` | 100 | 83 |
| `codex_when_arm_tail_call.roc` | 70 | 55 |
| `codex_when_bool_cross.roc` | 59 | 44 |
| `codex_when_bool_pattern.roc` | 77 | 50 |
| `codex_zigbee_encode.roc` | 53 | 41 |
