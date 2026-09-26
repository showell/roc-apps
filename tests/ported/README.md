# Codex tests, ported to Roc

594 programs from [Cobblestone](https://github.com/damiant3/Cobblestone)'s own test suite, machine-translated
from Codex to Roc and checked against the output Cobblestone records for
each one.

594 of the 907 the emitter runs to their verdict are here. Two kinds
are left out. 15 take more than a quarter of a second, and the reason
is the compiler rather than the program, so they are held back by name
rather than being a performance report inside a regression suite. The
rest are left out on size: a Codex chapter can be 28 KB and needed by
exactly one program, so a test goes when it would add more than 16 KB
of chapter text nobody else needs. Everything is in [roc-apps](https://github.com/showell/roc-apps).

**These were not written for Roc.** They are one compiler's test suite for
another language, translated; they may or may not be valuable here, and
they are offered rather than recommended. What they are is ordinary
programs that must print an exact thing: arithmetic, lists, records,
tagged unions, pattern matching, recursion, text and a private character
alphabet, in shapes nobody designing a Roc test would have chosen.

## The shape

`codex/` is a package of the 115 Codex chapters the tests are
emitted from (567 KB), and each test is a short app over it
(1643 KB for all 594):

    app [main!] { cdx: "./codex/main.roc" }
    import cdx.ListUtils

A Codex program carries every chapter it cites, so the 907 units carried
907 copies of the same chapters. A chapter's emitted text depends only on
the chapter, which is what lets them be shared here -- with one exception:
a chapter that reaches a device is emitted over the state its program
threads, so the same chapter is a different module in a program that reaches
the machine. Those programs are all far over the size cap anyway, and a test
whose chapter is already here in another form is dropped rather than given
the wrong one. Nothing was edited by hand, and every app was run and
compared with its expected output before it was kept.

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

56 seconds for all 594 on one core, median 76 ms. Every one of
them RUNS in about 3 ms; the rest is the compiler. The slowest:

| test | ms |
|---|---|
| `const-share` | 746 |
| `hart-encode` | 540 |
| `bacnet-encode` | 478 |
| `iec104-encode` | 445 |
| `stats-wrap-test` | 433 |

The compiler EVALUATES a call whose arguments are known, so for these
programs the compile time is largely the program's own work and the run is
then two or three milliseconds. The 15 where that adds up to more than
a quarter of a second are held back by name, and `ttt-perfect` is the
clearest case: 2.5 seconds to compile, because the
compiler plays the whole-tree tic-tac-toe search, and 3 ms to run, because
by then the answer is a constant.

## The tests

| file | lines | ms |
|---|---|---|
| `codex_act_let_scope.roc` | 84 | 93 |
| `codex_act_unused_bind.roc` | 36 | 80 |
| `codex_amp_after_call.roc` | 31 | 78 |
| `codex_approx_eq.roc` | 44 | 78 |
| `codex_arith_operand_order.roc` | 43 | 73 |
| `codex_arithmetic.roc` | 95 | 116 |
| `codex_arm64_boot_test.roc` | 30 | 81 |
| `codex_asn1_der_write.roc` | 181 | 278 |
| `codex_bacnet_encode.roc` | 69 | 478 |
| `codex_bezier_identity.roc` | 65 | 145 |
| `codex_bitop_if_cond.roc` | 38 | 96 |
| `codex_ble_att_encode.roc` | 57 | 110 |
| `codex_bounded_integer_ops.roc` | 87 | 83 |
| `codex_bounded_sig_runtime.roc` | 36 | 69 |
| `codex_bounds_proof.roc` | 137 | 83 |
| `codex_bounds_prover.roc` | 109 | 77 |
| `codex_bs3_smoke.roc` | 93 | 84 |
| `codex_buf_write_byte_cursor.roc` | 60 | 106 |
| `codex_call_clobber.roc` | 41 | 82 |
| `codex_canopen_encode.roc` | 53 | 54 |
| `codex_cap_heap_poke_pure.roc` | 37 | 69 |
| `codex_cap_manifest_derived.roc` | 28 | 68 |
| `codex_capability_doors.roc` | 188 | 179 |
| `codex_carddeck_shuffle.roc` | 113 | 383 |
| `codex_chapter_pages.roc` | 34 | 83 |
| `codex_circbuf_test.roc` | 85 | 128 |
| `codex_cite_override_quire.roc` | 29 | 91 |
| `codex_cms_spread.roc` | 84 | 136 |
| `codex_color_test.roc` | 93 | 159 |
| `codex_consistent_hash_balance.roc` | 65 | 129 |
| `codex_const_share.roc` | 316 | 746 |
| `codex_convolution_identity.roc` | 51 | 130 |
| `codex_cryptobig.roc` | 80 | 345 |
| `codex_ctor_narrow_warn.roc` | 45 | 69 |
| `codex_dce_reach.roc` | 54 | 97 |
| `codex_deriving_eq_recursive.roc` | 66 | 98 |
| `codex_dnp3_encode.roc` | 69 | 254 |
| `codex_edit_distance_test.roc` | 93 | 207 |
| `codex_effect_dotted_allow.roc` | 34 | 90 |
| `codex_effect_positive.roc` | 51 | 90 |
| `codex_effect_row_var_syntax.roc` | 47 | 89 |
| `codex_effect_widen_arg.roc` | 34 | 72 |
| `codex_effect_widen_scope.roc` | 38 | 80 |
| `codex_enip_encode.roc` | 61 | 343 |
| `codex_eq_generic_fields.roc` | 76 | 147 |
| `codex_eq_generic_recursive.roc` | 88 | 138 |
| `codex_eq_plain_sum.roc` | 68 | 98 |
| `codex_eventbus_test.roc` | 76 | 135 |
| `codex_examples@eight_queens.roc` | 97 | 102 |
| `codex_examples@missile_warning.roc` | 154 | 117 |
| `codex_expr_calculator.roc` | 200 | 155 |
| `codex_factlog_layout.roc` | 227 | 185 |
| `codex_factorial.roc` | 156 | 136 |
| `codex_field_cache_text_lit.roc` | 47 | 91 |
| `codex_fins_encode.roc` | 57 | 95 |
| `codex_forewords@ai_activation.roc` | 28 | 65 |
| `codex_forewords@ai_activation_range.roc` | 110 | 171 |
| `codex_forewords@ai_attention.roc` | 28 | 70 |
| `codex_forewords@ai_clip_interrogator.roc` | 28 | 61 |
| `codex_forewords@ai_control_net.roc` | 28 | 66 |
| `codex_forewords@ai_decision_tree.roc` | 28 | 68 |
| `codex_forewords@ai_diffusion_pipeline.roc` | 28 | 69 |
| `codex_forewords@ai_diffusion_scheduler.roc` | 28 | 68 |
| `codex_forewords@ai_embedding.roc` | 28 | 70 |
| `codex_forewords@ai_flux_pipeline.roc` | 28 | 70 |
| `codex_forewords@ai_genetic_algorithm.roc` | 65 | 186 |
| `codex_forewords@ai_gguf.roc` | 28 | 68 |
| `codex_forewords@ai_gpu_proxy.roc` | 28 | 63 |
| `codex_forewords@ai_hires_fix.roc` | 28 | 62 |
| `codex_forewords@ai_inpainting.roc` | 28 | 68 |
| `codex_forewords@ai_k_nearest_neighbor.roc` | 28 | 67 |
| `codex_forewords@ai_kv_cache.roc` | 28 | 69 |
| `codex_forewords@ai_lora_loader.roc` | 28 | 71 |
| `codex_forewords@ai_loss.roc` | 28 | 73 |
| `codex_forewords@ai_neural_net.roc` | 28 | 61 |
| `codex_forewords@ai_normalization.roc` | 100 | 160 |
| `codex_forewords@ai_optimizer.roc` | 28 | 71 |
| `codex_forewords@ai_png_metadata.roc` | 28 | 74 |
| `codex_forewords@ai_prompt_parser.roc` | 28 | 77 |
| `codex_forewords@ai_reservoir.roc` | 28 | 64 |
| `codex_forewords@ai_sampling.roc` | 28 | 63 |
| `codex_forewords@ai_sparse_lattice.roc` | 28 | 67 |
| `codex_forewords@ai_tensor.roc` | 28 | 68 |
| `codex_forewords@ai_text_encoder.roc` | 28 | 71 |
| `codex_forewords@ai_text_encoder_xl.roc` | 28 | 68 |
| `codex_forewords@ai_tokenizer.roc` | 28 | 72 |
| `codex_forewords@ai_transformer.roc` | 28 | 69 |
| `codex_forewords@ai_unet_xl.roc` | 28 | 76 |
| `codex_forewords@ai_upscaler.roc` | 28 | 86 |
| `codex_forewords@compress_brotli.roc` | 28 | 79 |
| `codex_forewords@compress_deflate.roc` | 28 | 68 |
| `codex_forewords@compress_huffman.roc` | 28 | 74 |
| `codex_forewords@compress_lz4.roc` | 28 | 62 |
| `codex_forewords@compress_lz77.roc` | 28 | 64 |
| `codex_forewords@compress_rle.roc` | 28 | 63 |
| `codex_forewords@core_bigint.roc` | 75 | 125 |
| `codex_forewords@encode_avi.roc` | 28 | 67 |
| `codex_forewords@encode_base64.roc` | 28 | 72 |
| `codex_forewords@encode_bencode.roc` | 28 | 70 |
| `codex_forewords@encode_bmp.roc` | 28 | 66 |
| `codex_forewords@encode_cbor.roc` | 28 | 66 |
| `codex_forewords@encode_crc32.roc` | 28 | 75 |
| `codex_forewords@encode_csv.roc` | 28 | 70 |
| `codex_forewords@encode_flac.roc` | 995 | 102 |
| `codex_forewords@encode_gif.roc` | 28 | 64 |
| `codex_forewords@encode_gray_code.roc` | 28 | 68 |
| `codex_forewords@encode_hex.roc` | 28 | 67 |
| `codex_forewords@encode_ini.roc` | 28 | 68 |
| `codex_forewords@encode_jpeg.roc` | 28 | 66 |
| `codex_forewords@encode_json.roc` | 28 | 71 |
| `codex_forewords@encode_lwm2m.roc` | 28 | 66 |
| `codex_forewords@encode_markdown.roc` | 28 | 67 |
| `codex_forewords@encode_message_pack.roc` | 28 | 64 |
| `codex_forewords@encode_midi.roc` | 995 | 83 |
| `codex_forewords@encode_mp3.roc` | 995 | 81 |
| `codex_forewords@encode_mp4.roc` | 28 | 59 |
| `codex_forewords@encode_ogg.roc` | 28 | 61 |
| `codex_forewords@encode_png.roc` | 28 | 63 |
| `codex_forewords@encode_protobuf.roc` | 28 | 65 |
| `codex_forewords@encode_qoi.roc` | 28 | 72 |
| `codex_forewords@encode_smtp.roc` | 28 | 74 |
| `codex_forewords@encode_tiff.roc` | 28 | 79 |
| `codex_forewords@encode_toml.roc` | 28 | 75 |
| `codex_forewords@encode_uri.roc` | 28 | 77 |
| `codex_forewords@encode_uuid.roc` | 28 | 74 |
| `codex_forewords@encode_video_codec.roc` | 28 | 77 |
| `codex_forewords@encode_wav.roc` | 995 | 85 |
| `codex_forewords@encode_web_socket.roc` | 28 | 72 |
| `codex_forewords@encode_yaml.roc` | 28 | 69 |
| `codex_forewords@engine_ability_system.roc` | 28 | 75 |
| `codex_forewords@engine_anim_blend.roc` | 28 | 74 |
| `codex_forewords@engine_asset_table.roc` | 28 | 78 |
| `codex_forewords@engine_audio_bus.roc` | 28 | 77 |
| `codex_forewords@engine_audio3d.roc` | 28 | 68 |
| `codex_forewords@engine_biome.roc` | 28 | 71 |
| `codex_forewords@engine_cloth_sim.roc` | 995 | 81 |
| `codex_forewords@engine_collision3d.roc` | 28 | 69 |
| `codex_forewords@engine_culling.roc` | 28 | 64 |
| `codex_forewords@engine_cutscene.roc` | 28 | 69 |
| `codex_forewords@engine_damage_system.roc` | 28 | 63 |
| `codex_forewords@engine_debug_draw.roc` | 28 | 63 |
| `codex_forewords@engine_edge_mesh.roc` | 28 | 74 |
| `codex_forewords@engine_facial_anim.roc` | 28 | 65 |
| `codex_forewords@engine_fog.roc` | 28 | 62 |
| `codex_forewords@engine_fractal_plant.roc` | 28 | 71 |
| `codex_forewords@engine_game_loop.roc` | 28 | 62 |
| `codex_forewords@engine_gameplay_tags.roc` | 28 | 67 |
| `codex_forewords@engine_hair_sim.roc` | 995 | 88 |
| `codex_forewords@engine_helm_bridge.roc` | 28 | 71 |
| `codex_forewords@engine_input.roc` | 28 | 74 |
| `codex_forewords@engine_lod.roc` | 28 | 74 |
| `codex_forewords@engine_material.roc` | 28 | 73 |
| `codex_forewords@engine_mesh.roc` | 28 | 79 |
| `codex_forewords@engine_musculature.roc` | 995 | 106 |
| `codex_forewords@engine_nav_mesh.roc` | 28 | 81 |
| `codex_forewords@engine_particle_renderer.roc` | 28 | 72 |
| `codex_forewords@engine_physics_joint.roc` | 995 | 95 |
| `codex_forewords@engine_post_process.roc` | 28 | 71 |
| `codex_forewords@engine_renderer3d.roc` | 28 | 78 |
| `codex_forewords@engine_scene3d.roc` | 28 | 71 |
| `codex_forewords@engine_signal.roc` | 28 | 68 |
| `codex_forewords@engine_skin_shader.roc` | 28 | 68 |
| `codex_forewords@engine_skinning.roc` | 28 | 70 |
| `codex_forewords@engine_soft_body.roc` | 995 | 85 |
| `codex_forewords@engine_spline_path.roc` | 28 | 66 |
| `codex_forewords@engine_terrain.roc` | 28 | 75 |
| `codex_forewords@engine_texture.roc` | 28 | 76 |
| `codex_forewords@engine_time_of_day.roc` | 28 | 69 |
| `codex_forewords@engine_water.roc` | 28 | 66 |
| `codex_forewords@engine_world_gen.roc` | 28 | 72 |
| `codex_forewords@engine_world_hud.roc` | 28 | 74 |
| `codex_forewords@foreword_aes.roc` | 28 | 68 |
| `codex_forewords@foreword_aes_gcm.roc` | 28 | 67 |
| `codex_forewords@foreword_aes256.roc` | 28 | 71 |
| `codex_forewords@foreword_apprunner.roc` | 28 | 78 |
| `codex_forewords@foreword_b_plus_tree.roc` | 28 | 69 |
| `codex_forewords@foreword_bit_set.roc` | 28 | 74 |
| `codex_forewords@foreword_bloom_filter.roc` | 28 | 73 |
| `codex_forewords@foreword_c_c_e.roc` | 28 | 72 |
| `codex_forewords@foreword_camera.roc` | 28 | 73 |
| `codex_forewords@foreword_cha_cha20.roc` | 28 | 81 |
| `codex_forewords@foreword_channel.roc` | 28 | 95 |
| `codex_forewords@foreword_circular_buffer.roc` | 28 | 87 |
| `codex_forewords@foreword_concurrent.roc` | 28 | 77 |
| `codex_forewords@foreword_consistent_hash.roc` | 28 | 72 |
| `codex_forewords@foreword_console.roc` | 28 | 65 |
| `codex_forewords@foreword_count_min_sketch.roc` | 28 | 71 |
| `codex_forewords@foreword_date_time.roc` | 77 | 108 |
| `codex_forewords@foreword_decimal.roc` | 28 | 70 |
| `codex_forewords@foreword_deque.roc` | 28 | 70 |
| `codex_forewords@foreword_diffie_hellman.roc` | 28 | 77 |
| `codex_forewords@foreword_display.roc` | 28 | 70 |
| `codex_forewords@foreword_ed25519.roc` | 28 | 72 |
| `codex_forewords@foreword_edit_distance.roc` | 28 | 64 |
| `codex_forewords@foreword_either.roc` | 28 | 69 |
| `codex_forewords@foreword_elastic_bloom.roc` | 28 | 69 |
| `codex_forewords@foreword_elastic_hash.roc` | 28 | 68 |
| `codex_forewords@foreword_event_bus.roc` | 28 | 71 |
| `codex_forewords@foreword_fact_store.roc` | 28 | 76 |
| `codex_forewords@foreword_fat16.roc` | 28 | 81 |
| `codex_forewords@foreword_fat32.roc` | 28 | 81 |
| `codex_forewords@foreword_file_system.roc` | 28 | 67 |
| `codex_forewords@foreword_format.roc` | 28 | 67 |
| `codex_forewords@foreword_fuel.roc` | 28 | 67 |
| `codex_forewords@foreword_funnel_hash.roc` | 28 | 71 |
| `codex_forewords@foreword_gpt.roc` | 28 | 66 |
| `codex_forewords@foreword_graph.roc` | 28 | 67 |
| `codex_forewords@foreword_hamt.roc` | 28 | 73 |
| `codex_forewords@foreword_history.roc` | 28 | 78 |
| `codex_forewords@foreword_hkdf.roc` | 28 | 66 |
| `codex_forewords@foreword_hmac.roc` | 28 | 80 |
| `codex_forewords@foreword_identity.roc` | 28 | 67 |
| `codex_forewords@foreword_interval_tree.roc` | 28 | 86 |
| `codex_forewords@foreword_kv_store.roc` | 28 | 73 |
| `codex_forewords@foreword_list.roc` | 28 | 88 |
| `codex_forewords@foreword_list_utils.roc` | 28 | 85 |
| `codex_forewords@foreword_load_test.roc` | 28 | 82 |
| `codex_forewords@foreword_locale.roc` | 28 | 77 |
| `codex_forewords@foreword_location.roc` | 28 | 76 |
| `codex_forewords@foreword_logger.roc` | 28 | 62 |
| `codex_forewords@foreword_lru_cache.roc` | 28 | 67 |
| `codex_forewords@foreword_math_lib.roc` | 28 | 73 |
| `codex_forewords@foreword_maybe.roc` | 28 | 64 |
| `codex_forewords@foreword_microphone.roc` | 28 | 65 |
| `codex_forewords@foreword_network.roc` | 28 | 69 |
| `codex_forewords@foreword_number_theory.roc` | 28 | 84 |
| `codex_forewords@foreword_pair.roc` | 28 | 90 |
| `codex_forewords@foreword_path.roc` | 28 | 76 |
| `codex_forewords@foreword_pattern.roc` | 28 | 76 |
| `codex_forewords@foreword_pbkdf.roc` | 28 | 72 |
| `codex_forewords@foreword_pipeline.roc` | 28 | 61 |
| `codex_forewords@foreword_priority_queue.roc` | 28 | 65 |
| `codex_forewords@foreword_probability.roc` | 28 | 61 |
| `codex_forewords@foreword_proof_of_work.roc` | 28 | 72 |
| `codex_forewords@foreword_queue.roc` | 28 | 65 |
| `codex_forewords@foreword_random.roc` | 28 | 65 |
| `codex_forewords@foreword_rate_limiter.roc` | 77 | 69 |
| `codex_forewords@foreword_regex.roc` | 28 | 70 |
| `codex_forewords@foreword_result.roc` | 28 | 75 |
| `codex_forewords@foreword_ring_buffer.roc` | 28 | 69 |
| `codex_forewords@foreword_rope.roc` | 28 | 63 |
| `codex_forewords@foreword_schedule.roc` | 28 | 67 |
| `codex_forewords@foreword_scheduler.roc` | 995 | 97 |
| `codex_forewords@foreword_sensors.roc` | 28 | 70 |
| `codex_forewords@foreword_set.roc` | 28 | 65 |
| `codex_forewords@foreword_sha1.roc` | 28 | 64 |
| `codex_forewords@foreword_sha256.roc` | 28 | 66 |
| `codex_forewords@foreword_sha512.roc` | 28 | 62 |
| `codex_forewords@foreword_sort.roc` | 28 | 62 |
| `codex_forewords@foreword_state.roc` | 28 | 67 |
| `codex_forewords@foreword_statistics.roc` | 28 | 64 |
| `codex_forewords@foreword_string_builder.roc` | 28 | 63 |
| `codex_forewords@foreword_string_utils.roc` | 28 | 65 |
| `codex_forewords@foreword_tab_complete.roc` | 28 | 65 |
| `codex_forewords@foreword_text_wrap.roc` | 28 | 80 |
| `codex_forewords@foreword_time.roc` | 28 | 73 |
| `codex_forewords@foreword_timing_wheel.roc` | 995 | 102 |
| `codex_forewords@foreword_tls.roc` | 28 | 67 |
| `codex_forewords@foreword_trie.roc` | 28 | 66 |
| `codex_forewords@foreword_tuple.roc` | 28 | 77 |
| `codex_forewords@foreword_unicode.roc` | 28 | 78 |
| `codex_forewords@foreword_union_find.roc` | 28 | 71 |
| `codex_forewords@game_a_star.roc` | 28 | 68 |
| `codex_forewords@game_bresenham.roc` | 28 | 66 |
| `codex_forewords@game_card_deck.roc` | 28 | 66 |
| `codex_forewords@game_cellular_automata.roc` | 28 | 71 |
| `codex_forewords@game_color.roc` | 28 | 68 |
| `codex_forewords@game_diamond_square.roc` | 28 | 72 |
| `codex_forewords@game_e_c_s.roc` | 28 | 68 |
| `codex_forewords@game_easing.roc` | 28 | 68 |
| `codex_forewords@game_flood_fill.roc` | 28 | 68 |
| `codex_forewords@game_game_camera.roc` | 28 | 64 |
| `codex_forewords@game_hex_map.roc` | 28 | 62 |
| `codex_forewords@game_inventory.roc` | 28 | 63 |
| `codex_forewords@game_klondike.roc` | 28 | 81 |
| `codex_forewords@game_netcode.roc` | 28 | 66 |
| `codex_forewords@game_octree.roc` | 28 | 64 |
| `codex_forewords@game_pathfinding.roc` | 28 | 66 |
| `codex_forewords@game_quadtree.roc` | 28 | 65 |
| `codex_forewords@game_rasterizer.roc` | 28 | 67 |
| `codex_forewords@game_raytracer.roc` | 28 | 63 |
| `codex_forewords@game_save_slot.roc` | 28 | 63 |
| `codex_forewords@game_scene2_d.roc` | 28 | 64 |
| `codex_forewords@game_sprite.roc` | 28 | 63 |
| `codex_forewords@game_state_machine.roc` | 28 | 68 |
| `codex_forewords@game_tile_map.roc` | 28 | 62 |
| `codex_forewords@game_tween.roc` | 28 | 65 |
| `codex_forewords@game_voronoi.roc` | 28 | 64 |
| `codex_forewords@gpu_atomic.roc` | 31 | 62 |
| `codex_forewords@gpu_barrier.roc` | 32 | 59 |
| `codex_forewords@gpu_device_buffer.roc` | 28 | 62 |
| `codex_forewords@gpu_device_effect.roc` | 28 | 60 |
| `codex_forewords@gpu_devicemath_atan.roc` | 136 | 303 |
| `codex_forewords@gpu_disjoint_slice.roc` | 32 | 65 |
| `codex_forewords@gpu_effect.roc` | 28 | 66 |
| `codex_forewords@gpu_launch_config.roc` | 32 | 66 |
| `codex_forewords@gpu_shared.roc` | 32 | 71 |
| `codex_forewords@gpu_thread.roc` | 32 | 79 |
| `codex_forewords@gpu_warp.roc` | 32 | 60 |
| `codex_forewords@math_bezier.roc` | 28 | 62 |
| `codex_forewords@math_complex.roc` | 28 | 66 |
| `codex_forewords@math_cordic.roc` | 28 | 65 |
| `codex_forewords@math_cordic_accuracy.roc` | 125 | 133 |
| `codex_forewords@math_cordic_quadrants.roc` | 116 | 143 |
| `codex_forewords@math_geodesic.roc` | 995 | 96 |
| `codex_forewords@math_geometry.roc` | 28 | 64 |
| `codex_forewords@math_linear_algebra.roc` | 28 | 79 |
| `codex_forewords@math_matrix3.roc` | 28 | 86 |
| `codex_forewords@math_matrix4.roc` | 28 | 78 |
| `codex_forewords@math_numeric.roc` | 28 | 64 |
| `codex_forewords@math_optimize.roc` | 28 | 64 |
| `codex_forewords@math_quaternion.roc` | 28 | 63 |
| `codex_forewords@math_spline.roc` | 28 | 68 |
| `codex_forewords@signal_audio_analysis.roc` | 995 | 106 |
| `codex_forewords@signal_audio_effect.roc` | 28 | 81 |
| `codex_forewords@signal_convolution.roc` | 28 | 69 |
| `codex_forewords@signal_envelope.roc` | 28 | 69 |
| `codex_forewords@signal_f_f_t.roc` | 28 | 88 |
| `codex_forewords@signal_filter.roc` | 995 | 85 |
| `codex_forewords@signal_music_theory.roc` | 28 | 67 |
| `codex_forewords@signal_noise.roc` | 28 | 63 |
| `codex_forewords@signal_oscillator.roc` | 995 | 98 |
| `codex_forewords@signal_perlin.roc` | 28 | 67 |
| `codex_forewords@signal_pitch.roc` | 995 | 88 |
| `codex_forewords@signal_resample.roc` | 995 | 118 |
| `codex_forewords@signal_synth.roc` | 995 | 95 |
| `codex_forewords@sim_collision.roc` | 28 | 74 |
| `codex_forewords@sim_constraint.roc` | 28 | 76 |
| `codex_forewords@sim_kinematics.roc` | 995 | 97 |
| `codex_forewords@sim_particle_system.roc` | 28 | 81 |
| `codex_forewords@sim_physics.roc` | 995 | 94 |
| `codex_forewords@sim_spatial_hash.roc` | 28 | 68 |
| `codex_forewords@sim_steering.roc` | 995 | 84 |
| `codex_forewords@ui_accessibility.roc` | 90 | 211 |
| `codex_forewords@ui_animation.roc` | 28 | 88 |
| `codex_forewords@ui_binding.roc` | 28 | 88 |
| `codex_forewords@ui_box_model.roc` | 28 | 65 |
| `codex_forewords@ui_charts.roc` | 28 | 68 |
| `codex_forewords@ui_clipboard.roc` | 28 | 65 |
| `codex_forewords@ui_cursor.roc` | 28 | 73 |
| `codex_forewords@ui_dialog.roc` | 28 | 70 |
| `codex_forewords@ui_drag.roc` | 28 | 67 |
| `codex_forewords@ui_event.roc` | 28 | 65 |
| `codex_forewords@ui_focus.roc` | 28 | 73 |
| `codex_forewords@ui_font.roc` | 28 | 72 |
| `codex_forewords@ui_icon.roc` | 28 | 79 |
| `codex_forewords@ui_layout.roc` | 28 | 68 |
| `codex_forewords@ui_orchestrator.roc` | 28 | 63 |
| `codex_forewords@ui_overlay.roc` | 28 | 62 |
| `codex_forewords@ui_render.roc` | 28 | 65 |
| `codex_forewords@ui_rich_text.roc` | 28 | 69 |
| `codex_forewords@ui_scroll.roc` | 28 | 69 |
| `codex_forewords@ui_selection.roc` | 28 | 67 |
| `codex_forewords@ui_sound.roc` | 28 | 68 |
| `codex_forewords@ui_surface.roc` | 28 | 69 |
| `codex_forewords@ui_text_field.roc` | 28 | 81 |
| `codex_forewords@ui_theme.roc` | 28 | 72 |
| `codex_forewords@ui_touch.roc` | 28 | 66 |
| `codex_forewords@ui_vector.roc` | 28 | 86 |
| `codex_forewords@ui_widget.roc` | 28 | 69 |
| `codex_frameless_leaf_probe.roc` | 62 | 105 |
| `codex_hamt_test.roc` | 121 | 286 |
| `codex_hart_encode.roc` | 61 | 540 |
| `codex_heap_advance_odd.roc` | 63 | 112 |
| `codex_hid_decode.roc` | 94 | 157 |
| `codex_iec104_encode.roc` | 90 | 445 |
| `codex_ieee802154_encode.roc` | 53 | 155 |
| `codex_if_in_arith.roc` | 35 | 67 |
| `codex_if_let_join.roc` | 72 | 74 |
| `codex_implicit_convert.roc` | 1004 | 96 |
| `codex_inductive_list.roc` | 34 | 89 |
| `codex_inline_cost_based.roc` | 71 | 100 |
| `codex_inline_single_caller.roc` | 52 | 81 |
| `codex_int_literal_underscore.roc` | 36 | 84 |
| `codex_ip_checksum_odd.roc` | 82 | 139 |
| `codex_ir_check_clean.roc` | 114 | 97 |
| `codex_iterate_test.roc` | 69 | 187 |
| `codex_iterate_zip_test.roc` | 67 | 108 |
| `codex_j1939_encode.roc` | 51 | 45 |
| `codex_klondike_test.roc` | 93 | 223 |
| `codex_knx_encode.roc` | 53 | 35 |
| `codex_lang_smoke.roc` | 244 | 118 |
| `codex_leaf_let_if.roc` | 39 | 75 |
| `codex_leaf_mispredict.roc` | 36 | 66 |
| `codex_let_else_scope.roc` | 49 | 69 |
| `codex_let_shadow_scope.roc` | 41 | 67 |
| `codex_lib@bencode_guard.roc` | 93 | 225 |
| `codex_lib@canvas_viewport.roc` | 81 | 136 |
| `codex_lib@decimal_test.roc` | 64 | 124 |
| `codex_lib@device_math.roc` | 167 | 169 |
| `codex_lib@format_test.roc` | 55 | 115 |
| `codex_lib@linalg_test.roc` | 64 | 127 |
| `codex_lib@locale_test.roc` | 57 | 148 |
| `codex_lib@loss_test.roc` | 56 | 244 |
| `codex_lib@lz4_test.roc` | 52 | 122 |
| `codex_lib@number_theory_test.roc` | 58 | 107 |
| `codex_lib@numeric_test.roc` | 94 | 127 |
| `codex_lib@path_test.roc` | 55 | 111 |
| `codex_lib@pixel_buf.roc` | 261 | 159 |
| `codex_lib@probability_test.roc` | 81 | 134 |
| `codex_lib@text_overflow.roc` | 103 | 128 |
| `codex_lib@toml_test.roc` | 50 | 222 |
| `codex_lib@yaml_test.roc` | 67 | 274 |
| `codex_linear_branch.roc` | 46 | 93 |
| `codex_linear_capture_once.roc` | 53 | 89 |
| `codex_linear_mint_container.roc` | 38 | 74 |
| `codex_linear_poly_freeze.roc` | 29 | 88 |
| `codex_linear_smoke.roc` | 47 | 85 |
| `codex_lir_binop_cross.roc` | 78 | 116 |
| `codex_lir_branch_cross.roc` | 119 | 134 |
| `codex_lir_call_cross.roc` | 79 | 79 |
| `codex_lir_check.roc` | 188 | 83 |
| `codex_lir_frame_cross.roc` | 60 | 87 |
| `codex_lir_join_cross.roc` | 75 | 72 |
| `codex_lir_load_cross.roc` | 130 | 89 |
| `codex_lir_nullary_cross.roc` | 71 | 99 |
| `codex_lir_selector_smoke.roc` | 78 | 68 |
| `codex_lir_test_cross.roc` | 75 | 68 |
| `codex_list_comprehension_copy.roc` | 45 | 89 |
| `codex_list_induction.roc` | 28 | 63 |
| `codex_list_literal_o1.roc` | 48 | 108 |
| `codex_list_pattern.roc` | 64 | 81 |
| `codex_list_tail_empty.roc` | 50 | 81 |
| `codex_list_test.roc` | 131 | 357 |
| `codex_literal_match_covered.roc` | 60 | 86 |
| `codex_literal_subpattern.roc` | 135 | 130 |
| `codex_lwm2m_encode.roc` | 109 | 117 |
| `codex_match_arms_per_line.roc` | 61 | 90 |
| `codex_match_in_record_field.roc` | 43 | 98 |
| `codex_mbus_encode.roc` | 53 | 172 |
| `codex_melsec_encode.roc` | 57 | 195 |
| `codex_method_template_contract_bounds_large.roc` | 34 | 74 |
| `codex_method_template_contract_bounds_small.roc` | 34 | 63 |
| `codex_method_template_contract_demands.roc` | 50 | 75 |
| `codex_method_template_contract_lookalike.roc` | 38 | 66 |
| `codex_method_template_contract_mono.roc` | 48 | 56 |
| `codex_method_template_contract_runtime.roc` | 34 | 80 |
| `codex_method_template_contract_unicode.roc` | 34 | 70 |
| `codex_method_template_contract_zero.roc` | 34 | 64 |
| `codex_mini_bootstrap.roc` | 69 | 79 |
| `codex_mix_bits.roc` | 74 | 101 |
| `codex_mod_bound_return.roc` | 42 | 70 |
| `codex_modbus_encode.roc` | 105 | 261 |
| `codex_modprobe.roc` | 46 | 106 |
| `codex_mut_borrow_transitive.roc` | 59 | 66 |
| `codex_neg_int_parse.roc` | 28 | 61 |
| `codex_negation_abutment.roc` | 65 | 91 |
| `codex_noise_test.roc` | 117 | 274 |
| `codex_normalize_eq.roc` | 50 | 61 |
| `codex_ops@bounded_modes_smoke.roc` | 137 | 101 |
| `codex_ops@builtin_name_shadow.roc` | 36 | 73 |
| `codex_ops@cap_word_64.roc` | 65 | 98 |
| `codex_ops@cce_builtin_bounds.roc` | 37 | 74 |
| `codex_ops@char_at_bounds.roc` | 43 | 81 |
| `codex_ops@char_code_at_high.roc` | 41 | 79 |
| `codex_ops@closure_under_apply.roc` | 89 | 85 |
| `codex_ops@div_negative_pow2.roc` | 72 | 84 |
| `codex_ops@int_add_wrapping.roc` | 71 | 86 |
| `codex_ops@int_min_literal.roc` | 55 | 92 |
| `codex_ops@int_mul_wrapping.roc` | 44 | 80 |
| `codex_ops@int_pow.roc` | 56 | 98 |
| `codex_ops@int_rem.roc` | 87 | 135 |
| `codex_ops@int_wrapping_spelling.roc` | 58 | 84 |
| `codex_ops@list_index_bounds.roc` | 55 | 91 |
| `codex_ops@list_view_bounds.roc` | 42 | 78 |
| `codex_ops@match_shadowed_arm.roc` | 64 | 82 |
| `codex_ops@native_nested_pattern.roc` | 140 | 94 |
| `codex_ops@native_nested_tags.roc` | 63 | 61 |
| `codex_ops@real_approx.roc` | 51 | 81 |
| `codex_ops@real_approx_equality.roc` | 55 | 83 |
| `codex_ops@real_approx_modes.roc` | 50 | 97 |
| `codex_ops@real_approx_negate.roc` | 52 | 81 |
| `codex_ops@real_bitcast.roc` | 49 | 85 |
| `codex_ops@real_bitcast_f64.roc` | 50 | 91 |
| `codex_ops@real_compare_negative.roc` | 110 | 105 |
| `codex_ops@real_mode_compare.roc` | 79 | 107 |
| `codex_ops@real_mode_show.roc` | 39 | 102 |
| `codex_ops@real_neg_neg.roc` | 36 | 102 |
| `codex_ops@real_negate.roc` | 66 | 77 |
| `codex_ops@real_saturating.roc` | 66 | 83 |
| `codex_ops@real_saturating_finite.roc` | 60 | 85 |
| `codex_ops@real_to_int_wide.roc` | 45 | 103 |
| `codex_ops@real_trapping.roc` | 62 | 85 |
| `codex_ops@record_closure_field_poly.roc` | 69 | 96 |
| `codex_ops@record_equality.roc` | 108 | 105 |
| `codex_ops@record_generic_eq.roc` | 62 | 136 |
| `codex_ops@runtime_bytes_unsigned.roc` | 49 | 97 |
| `codex_ops@saturated_call_returning_function.roc` | 211 | 102 |
| `codex_ops@section_title_keywords.roc` | 44 | 76 |
| `codex_ops@substring_bounds.roc` | 48 | 83 |
| `codex_ops@text_order_allowed.roc` | 48 | 97 |
| `codex_ops@tier0_cyrillic_print.roc` | 36 | 82 |
| `codex_ops@tier1_latin_print.roc` | 34 | 71 |
| `codex_ops@tier2_print.roc` | 34 | 73 |
| `codex_ops@unit_pattern_lit.roc` | 52 | 75 |
| `codex_ops@unit_real_arith.roc` | 77 | 81 |
| `codex_ops@unit_real_compare.roc` | 113 | 114 |
| `codex_ops@unit_show.roc` | 71 | 106 |
| `codex_ops@unused_let_alias_discard.roc` | 56 | 102 |
| `codex_osc_noise.roc` | 1039 | 140 |
| `codex_particle_spread.roc` | 55 | 110 |
| `codex_path_real.roc` | 35 | 88 |
| `codex_peek32_sign.roc` | 51 | 96 |
| `codex_pipe_unique_test.roc` | 45 | 153 |
| `codex_pit_rate.roc` | 41 | 83 |
| `codex_poke16_width.roc` | 59 | 99 |
| `codex_prop_arith.roc` | 28 | 85 |
| `codex_prose_binary_control.roc` | 32 | 39 |
| `codex_prose_consistency.roc` | 80 | 89 |
| `codex_prose_smoke.roc` | 74 | 95 |
| `codex_punctual_fastmath.roc` | 35 | 257 |
| `codex_punctual_iot.roc` | 139 | 99 |
| `codex_punctual_quire.roc` | 102 | 274 |
| `codex_punctual_smoke.roc` | 46 | 69 |
| `codex_queue_test.roc` | 44 | 139 |
| `codex_real_literal_boundary.roc` | 36 | 78 |
| `codex_real_show_wide.roc` | 57 | 117 |
| `codex_record_smoke.roc` | 232 | 119 |
| `codex_recursive_eq.roc` | 80 | 99 |
| `codex_reservoir_uniform.roc` | 105 | 129 |
| `codex_revised_narrow.roc` | 69 | 97 |
| `codex_riscv_encoder.roc` | 121 | 161 |
| `codex_riscv32c_encoder.roc` | 109 | 269 |
| `codex_roc_closure_captures_list.roc` | 41 | 63 |
| `codex_roc_early_return_predicate.roc` | 31 | 65 |
| `codex_roc_fold_count.roc` | 41 | 64 |
| `codex_roc_fold_empty.roc` | 41 | 73 |
| `codex_roc_fold_product.roc` | 41 | 64 |
| `codex_roc_fold_sum.roc` | 41 | 66 |
| `codex_roc_iter_drop_if.roc` | 62 | 57 |
| `codex_roc_iter_keep_if.roc` | 62 | 56 |
| `codex_roc_iter_map.roc` | 65 | 56 |
| `codex_roc_recursive_var.roc` | 39 | 61 |
| `codex_roc_returned_closure.roc` | 44 | 53 |
| `codex_rv_arg_order.roc` | 48 | 84 |
| `codex_rv_big_literal.roc` | 46 | 101 |
| `codex_rv_far_stack_param.roc` | 633 | 103 |
| `codex_rv_frameless_imm.roc` | 87 | 72 |
| `codex_rv_frameless_temp.roc` | 51 | 80 |
| `codex_rv_param_bind.roc` | 51 | 98 |
| `codex_rv_param_order.roc` | 61 | 88 |
| `codex_s7comm_encode.roc` | 85 | 194 |
| `codex_scope_console.roc` | 36 | 70 |
| `codex_scope_let_arm_global.roc` | 41 | 65 |
| `codex_sensor_data.roc` | 52 | 105 |
| `codex_simplify_check.roc` | 114 | 89 |
| `codex_sixlowpan_encode.roc` | 53 | 45 |
| `codex_sntp_encode.roc` | 69 | 94 |
| `codex_sort_test.roc` | 78 | 103 |
| `codex_sound_test.roc` | 1098 | 183 |
| `codex_stack_args_spill_overlap.roc` | 31 | 65 |
| `codex_stats_wrap_test.roc` | 96 | 433 |
| `codex_string_escape_quote.roc` | 31 | 63 |
| `codex_sum_field_eq.roc` | 66 | 88 |
| `codex_synth_test.roc` | 1091 | 154 |
| `codex_tail_call_spilled_arg.roc` | 43 | 69 |
| `codex_tco_bitop_loop.roc` | 87 | 89 |
| `codex_tco_direct_arg_reads.roc` | 44 | 79 |
| `codex_tco_framed_append.roc` | 54 | 89 |
| `codex_tco_global_bound.roc` | 48 | 78 |
| `codex_tco_nested_if.roc` | 38 | 77 |
| `codex_tco_shuffle_spill.roc` | 64 | 76 |
| `codex_text_accum_owner.roc` | 56 | 114 |
| `codex_text_eq_branches.roc` | 92 | 90 |
| `codex_text_fold_indexed.roc` | 63 | 88 |
| `codex_text_helper_native.roc` | 57 | 218 |
| `codex_thumb2_encoder.roc` | 129 | 365 |
| `codex_tuple_syntax.roc` | 73 | 76 |
| `codex_tvar_in_declared_type.roc` | 35 | 191 |
| `codex_type_checker_test.roc` | 43 | 51 |
| `codex_typeclass_compound_head.roc` | 60 | 92 |
| `codex_typeclass_instance_nested.roc` | 54 | 67 |
| `codex_typeclass_instance_types.roc` | 77 | 94 |
| `codex_typeclass_method_local_independent.roc` | 44 | 79 |
| `codex_typeclass_method_local_two_types.roc` | 44 | 71 |
| `codex_typeclass_poly.roc` | 77 | 77 |
| `codex_typeclass_smoke.roc` | 339 | 138 |
| `codex_typeclass_superclass_types.roc` | 86 | 77 |
| `codex_ui_sound_test.roc` | 103 | 123 |
| `codex_unconstrained_empty_list.roc` | 52 | 81 |
| `codex_unconstrained_nullary_sum.roc` | 60 | 78 |
| `codex_unit_bounded.roc` | 52 | 67 |
| `codex_unit_family.roc` | 75 | 64 |
| `codex_unit_family_mixed.roc` | 108 | 81 |
| `codex_unit_smoke.roc` | 69 | 77 |
| `codex_units_foreword.roc` | 1059 | 119 |
| `codex_value_eq.roc` | 31 | 62 |
| `codex_wavelet_sort_aliasing.roc` | 46 | 85 |
| `codex_when_arm_nontail.roc` | 83 | 88 |
| `codex_when_arm_tail_call.roc` | 72 | 80 |
| `codex_when_bool_cross.roc` | 69 | 73 |
| `codex_when_bool_pattern.roc` | 80 | 91 |
| `codex_when_generic_field.roc` | 72 | 204 |
| `codex_zigbee_encode.roc` | 53 | 169 |
