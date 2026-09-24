# Codex tests, ported to Roc

525 programs from [Cobblestone](https://github.com/damiant3/Cobblestone)'s own test suite, machine-translated
from Codex to Roc and checked against the output Cobblestone records for
each one.

525 of the 792 the emitter runs to their verdict are here. Two kinds
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

`codex/` is a package of the 120 Codex chapters the tests are
emitted from (577 KB), and each test is a short app over it
(1541 KB for all 525):

    app [main!] { cdx: "./codex/main.roc" }
    import cdx.ListUtils

A Codex program carries every chapter it cites, so the 792 units carried
792 copies of the same chapters. A chapter's emitted text depends only on
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

39 seconds for all 525 on one core, median 59 ms. Every one of
them RUNS in about 3 ms; the rest is the compiler. The slowest:

| test | ms |
|---|---|
| `hamt-test` | 372 |
| `dtls-handshake` | 264 |
| `sound-test` | 245 |
| `lib@pixel-buf` | 238 |
| `list-test` | 232 |

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
| `codex_act_let_scope.roc` | 76 | 91 |
| `codex_act_unused_bind.roc` | 36 | 60 |
| `codex_amp_after_call.roc` | 31 | 50 |
| `codex_approx_eq.roc` | 44 | 93 |
| `codex_arith_operand_order.roc` | 40 | 109 |
| `codex_arithmetic.roc` | 90 | 140 |
| `codex_arm64_boot_test.roc` | 30 | 56 |
| `codex_asn1_der_write.roc` | 181 | 181 |
| `codex_audio_diffusion_test.roc` | 1058 | 177 |
| `codex_bezier_identity.roc` | 65 | 118 |
| `codex_bitop_if_cond.roc` | 38 | 57 |
| `codex_ble_att_encode.roc` | 57 | 29 |
| `codex_bounded_integer_ops.roc` | 78 | 87 |
| `codex_bounded_sig_runtime.roc` | 36 | 56 |
| `codex_bounds_proof.roc` | 130 | 86 |
| `codex_bounds_prover.roc` | 100 | 81 |
| `codex_bs3_smoke.roc` | 87 | 89 |
| `codex_call_clobber.roc` | 41 | 89 |
| `codex_canopen_encode.roc` | 53 | 55 |
| `codex_cap_heap_poke_pure.roc` | 37 | 86 |
| `codex_cap_manifest_derived.roc` | 28 | 50 |
| `codex_capability_doors.roc` | 152 | 177 |
| `codex_carddeck_shuffle.roc` | 94 | 155 |
| `codex_chapter_pages.roc` | 34 | 51 |
| `codex_circbuf_test.roc` | 84 | 138 |
| `codex_cite_override_quire.roc` | 29 | 63 |
| `codex_cms_spread.roc` | 81 | 157 |
| `codex_color_test.roc` | 92 | 126 |
| `codex_consistent_hash_balance.roc` | 63 | 128 |
| `codex_convolution_identity.roc` | 51 | 67 |
| `codex_ctor_narrow_warn.roc` | 45 | 77 |
| `codex_deriving_eq_recursive.roc` | 66 | 101 |
| `codex_dnp3_encode.roc` | 69 | 35 |
| `codex_dtls_handshake.roc` | 167 | 264 |
| `codex_edit_distance_test.roc` | 83 | 153 |
| `codex_effect_dotted_allow.roc` | 34 | 59 |
| `codex_effect_positive.roc` | 51 | 63 |
| `codex_effect_row_var_syntax.roc` | 47 | 66 |
| `codex_effect_widen_arg.roc` | 34 | 46 |
| `codex_effect_widen_scope.roc` | 38 | 52 |
| `codex_enip_encode.roc` | 60 | 39 |
| `codex_eq_generic_fields.roc` | 76 | 150 |
| `codex_eq_generic_recursive.roc` | 88 | 126 |
| `codex_eq_plain_sum.roc` | 68 | 108 |
| `codex_eventbus_test.roc` | 76 | 155 |
| `codex_examples@eight_queens.roc` | 96 | 57 |
| `codex_examples@missile_warning.roc` | 147 | 109 |
| `codex_expr_calculator.roc` | 185 | 192 |
| `codex_factlog_layout.roc` | 226 | 140 |
| `codex_factorial.roc` | 150 | 164 |
| `codex_field_cache_text_lit.roc` | 44 | 93 |
| `codex_fins_encode.roc` | 56 | 34 |
| `codex_forewords@ai_activation.roc` | 28 | 53 |
| `codex_forewords@ai_activation_range.roc` | 108 | 212 |
| `codex_forewords@ai_attention.roc` | 28 | 49 |
| `codex_forewords@ai_clip_interrogator.roc` | 28 | 52 |
| `codex_forewords@ai_control_net.roc` | 28 | 50 |
| `codex_forewords@ai_decision_tree.roc` | 28 | 59 |
| `codex_forewords@ai_diffusion_pipeline.roc` | 28 | 61 |
| `codex_forewords@ai_diffusion_scheduler.roc` | 28 | 51 |
| `codex_forewords@ai_embedding.roc` | 28 | 68 |
| `codex_forewords@ai_flux_pipeline.roc` | 28 | 69 |
| `codex_forewords@ai_genetic_algorithm.roc` | 64 | 164 |
| `codex_forewords@ai_gguf.roc` | 28 | 49 |
| `codex_forewords@ai_gpu_proxy.roc` | 28 | 67 |
| `codex_forewords@ai_hires_fix.roc` | 28 | 68 |
| `codex_forewords@ai_inpainting.roc` | 28 | 48 |
| `codex_forewords@ai_k_nearest_neighbor.roc` | 28 | 49 |
| `codex_forewords@ai_kv_cache.roc` | 28 | 49 |
| `codex_forewords@ai_lora_loader.roc` | 28 | 49 |
| `codex_forewords@ai_loss.roc` | 28 | 48 |
| `codex_forewords@ai_neural_net.roc` | 28 | 47 |
| `codex_forewords@ai_normalization.roc` | 100 | 187 |
| `codex_forewords@ai_optimizer.roc` | 28 | 49 |
| `codex_forewords@ai_png_metadata.roc` | 28 | 47 |
| `codex_forewords@ai_prompt_parser.roc` | 28 | 46 |
| `codex_forewords@ai_reservoir.roc` | 28 | 45 |
| `codex_forewords@ai_sampling.roc` | 28 | 48 |
| `codex_forewords@ai_sparse_lattice.roc` | 28 | 45 |
| `codex_forewords@ai_tensor.roc` | 28 | 49 |
| `codex_forewords@ai_text_encoder.roc` | 28 | 47 |
| `codex_forewords@ai_text_encoder_xl.roc` | 28 | 45 |
| `codex_forewords@ai_tokenizer.roc` | 28 | 48 |
| `codex_forewords@ai_transformer.roc` | 28 | 54 |
| `codex_forewords@ai_unet_xl.roc` | 28 | 51 |
| `codex_forewords@ai_upscaler.roc` | 28 | 48 |
| `codex_forewords@compress_huffman.roc` | 28 | 54 |
| `codex_forewords@compress_lz4.roc` | 28 | 50 |
| `codex_forewords@compress_rle.roc` | 28 | 52 |
| `codex_forewords@core_bigint.roc` | 75 | 126 |
| `codex_forewords@encode_avi.roc` | 28 | 88 |
| `codex_forewords@encode_base64.roc` | 28 | 66 |
| `codex_forewords@encode_bencode.roc` | 28 | 51 |
| `codex_forewords@encode_bmp.roc` | 28 | 47 |
| `codex_forewords@encode_cbor.roc` | 28 | 52 |
| `codex_forewords@encode_crc32.roc` | 28 | 47 |
| `codex_forewords@encode_csv.roc` | 28 | 46 |
| `codex_forewords@encode_flac.roc` | 995 | 55 |
| `codex_forewords@encode_gif.roc` | 28 | 46 |
| `codex_forewords@encode_gray_code.roc` | 28 | 48 |
| `codex_forewords@encode_hex.roc` | 28 | 55 |
| `codex_forewords@encode_ini.roc` | 28 | 53 |
| `codex_forewords@encode_jpeg.roc` | 28 | 47 |
| `codex_forewords@encode_json.roc` | 28 | 48 |
| `codex_forewords@encode_lwm2m.roc` | 28 | 52 |
| `codex_forewords@encode_markdown.roc` | 28 | 52 |
| `codex_forewords@encode_message_pack.roc` | 28 | 53 |
| `codex_forewords@encode_midi.roc` | 995 | 60 |
| `codex_forewords@encode_mp3.roc` | 995 | 61 |
| `codex_forewords@encode_mp4.roc` | 28 | 50 |
| `codex_forewords@encode_ogg.roc` | 28 | 50 |
| `codex_forewords@encode_png.roc` | 28 | 52 |
| `codex_forewords@encode_protobuf.roc` | 28 | 53 |
| `codex_forewords@encode_qoi.roc` | 28 | 47 |
| `codex_forewords@encode_smtp.roc` | 28 | 58 |
| `codex_forewords@encode_tiff.roc` | 28 | 52 |
| `codex_forewords@encode_toml.roc` | 28 | 48 |
| `codex_forewords@encode_uri.roc` | 28 | 47 |
| `codex_forewords@encode_uuid.roc` | 28 | 56 |
| `codex_forewords@encode_video_codec.roc` | 28 | 52 |
| `codex_forewords@encode_wav.roc` | 995 | 67 |
| `codex_forewords@encode_web_socket.roc` | 28 | 51 |
| `codex_forewords@encode_yaml.roc` | 28 | 49 |
| `codex_forewords@engine_ability_system.roc` | 28 | 47 |
| `codex_forewords@engine_anim_blend.roc` | 28 | 48 |
| `codex_forewords@engine_asset_table.roc` | 28 | 48 |
| `codex_forewords@engine_audio_bus.roc` | 28 | 46 |
| `codex_forewords@engine_audio3d.roc` | 28 | 46 |
| `codex_forewords@engine_biome.roc` | 28 | 49 |
| `codex_forewords@engine_cloth_sim.roc` | 995 | 67 |
| `codex_forewords@engine_collision3d.roc` | 28 | 50 |
| `codex_forewords@engine_culling.roc` | 28 | 51 |
| `codex_forewords@engine_cutscene.roc` | 28 | 59 |
| `codex_forewords@engine_damage_system.roc` | 28 | 52 |
| `codex_forewords@engine_debug_draw.roc` | 28 | 50 |
| `codex_forewords@engine_facial_anim.roc` | 28 | 55 |
| `codex_forewords@engine_fog.roc` | 28 | 67 |
| `codex_forewords@engine_fractal_plant.roc` | 28 | 68 |
| `codex_forewords@engine_game_loop.roc` | 28 | 64 |
| `codex_forewords@engine_gameplay_tags.roc` | 28 | 50 |
| `codex_forewords@engine_hair_sim.roc` | 995 | 77 |
| `codex_forewords@engine_helm_bridge.roc` | 28 | 71 |
| `codex_forewords@engine_input.roc` | 28 | 71 |
| `codex_forewords@engine_lod.roc` | 28 | 63 |
| `codex_forewords@engine_material.roc` | 28 | 46 |
| `codex_forewords@engine_mesh.roc` | 28 | 75 |
| `codex_forewords@engine_musculature.roc` | 995 | 78 |
| `codex_forewords@engine_particle_renderer.roc` | 28 | 54 |
| `codex_forewords@engine_physics_joint.roc` | 995 | 63 |
| `codex_forewords@engine_post_process.roc` | 28 | 48 |
| `codex_forewords@engine_renderer3d.roc` | 28 | 49 |
| `codex_forewords@engine_scene3d.roc` | 28 | 48 |
| `codex_forewords@engine_signal.roc` | 28 | 46 |
| `codex_forewords@engine_skin_shader.roc` | 28 | 45 |
| `codex_forewords@engine_skinning.roc` | 28 | 51 |
| `codex_forewords@engine_soft_body.roc` | 995 | 71 |
| `codex_forewords@engine_spline_path.roc` | 28 | 50 |
| `codex_forewords@engine_terrain.roc` | 28 | 48 |
| `codex_forewords@engine_texture.roc` | 28 | 48 |
| `codex_forewords@engine_time_of_day.roc` | 28 | 46 |
| `codex_forewords@engine_water.roc` | 28 | 46 |
| `codex_forewords@engine_world_gen.roc` | 28 | 49 |
| `codex_forewords@engine_world_hud.roc` | 28 | 60 |
| `codex_forewords@foreword_aes.roc` | 28 | 50 |
| `codex_forewords@foreword_aes_gcm.roc` | 28 | 48 |
| `codex_forewords@foreword_aes256.roc` | 28 | 50 |
| `codex_forewords@foreword_apprunner.roc` | 28 | 47 |
| `codex_forewords@foreword_b_plus_tree.roc` | 28 | 49 |
| `codex_forewords@foreword_bit_set.roc` | 28 | 56 |
| `codex_forewords@foreword_bloom_filter.roc` | 28 | 63 |
| `codex_forewords@foreword_c_c_e.roc` | 28 | 49 |
| `codex_forewords@foreword_camera.roc` | 28 | 46 |
| `codex_forewords@foreword_cha_cha20.roc` | 28 | 47 |
| `codex_forewords@foreword_channel.roc` | 28 | 47 |
| `codex_forewords@foreword_circular_buffer.roc` | 28 | 52 |
| `codex_forewords@foreword_consistent_hash.roc` | 28 | 49 |
| `codex_forewords@foreword_console.roc` | 28 | 47 |
| `codex_forewords@foreword_count_min_sketch.roc` | 28 | 49 |
| `codex_forewords@foreword_date_time.roc` | 77 | 92 |
| `codex_forewords@foreword_decimal.roc` | 28 | 49 |
| `codex_forewords@foreword_deque.roc` | 28 | 58 |
| `codex_forewords@foreword_display.roc` | 28 | 56 |
| `codex_forewords@foreword_edit_distance.roc` | 28 | 58 |
| `codex_forewords@foreword_either.roc` | 28 | 49 |
| `codex_forewords@foreword_elastic_bloom.roc` | 28 | 57 |
| `codex_forewords@foreword_elastic_hash.roc` | 28 | 54 |
| `codex_forewords@foreword_event_bus.roc` | 28 | 51 |
| `codex_forewords@foreword_fact_store.roc` | 28 | 50 |
| `codex_forewords@foreword_fat16.roc` | 28 | 46 |
| `codex_forewords@foreword_fat32.roc` | 28 | 49 |
| `codex_forewords@foreword_format.roc` | 28 | 50 |
| `codex_forewords@foreword_fuel.roc` | 28 | 47 |
| `codex_forewords@foreword_funnel_hash.roc` | 28 | 47 |
| `codex_forewords@foreword_gpt.roc` | 28 | 50 |
| `codex_forewords@foreword_hamt.roc` | 28 | 49 |
| `codex_forewords@foreword_history.roc` | 28 | 46 |
| `codex_forewords@foreword_hkdf.roc` | 28 | 51 |
| `codex_forewords@foreword_hmac.roc` | 28 | 47 |
| `codex_forewords@foreword_interval_tree.roc` | 28 | 48 |
| `codex_forewords@foreword_kv_store.roc` | 28 | 47 |
| `codex_forewords@foreword_list.roc` | 28 | 46 |
| `codex_forewords@foreword_list_utils.roc` | 28 | 48 |
| `codex_forewords@foreword_locale.roc` | 28 | 45 |
| `codex_forewords@foreword_location.roc` | 28 | 46 |
| `codex_forewords@foreword_logger.roc` | 28 | 46 |
| `codex_forewords@foreword_lru_cache.roc` | 28 | 46 |
| `codex_forewords@foreword_math_lib.roc` | 28 | 51 |
| `codex_forewords@foreword_maybe.roc` | 28 | 52 |
| `codex_forewords@foreword_microphone.roc` | 28 | 49 |
| `codex_forewords@foreword_network.roc` | 28 | 57 |
| `codex_forewords@foreword_number_theory.roc` | 28 | 50 |
| `codex_forewords@foreword_pair.roc` | 28 | 46 |
| `codex_forewords@foreword_path.roc` | 28 | 47 |
| `codex_forewords@foreword_pattern.roc` | 28 | 51 |
| `codex_forewords@foreword_pbkdf.roc` | 28 | 49 |
| `codex_forewords@foreword_pipeline.roc` | 28 | 51 |
| `codex_forewords@foreword_priority_queue.roc` | 28 | 52 |
| `codex_forewords@foreword_probability.roc` | 28 | 61 |
| `codex_forewords@foreword_proof_of_work.roc` | 28 | 60 |
| `codex_forewords@foreword_queue.roc` | 28 | 49 |
| `codex_forewords@foreword_random.roc` | 28 | 48 |
| `codex_forewords@foreword_rate_limiter.roc` | 77 | 91 |
| `codex_forewords@foreword_regex.roc` | 28 | 48 |
| `codex_forewords@foreword_result.roc` | 28 | 50 |
| `codex_forewords@foreword_ring_buffer.roc` | 28 | 48 |
| `codex_forewords@foreword_rope.roc` | 28 | 48 |
| `codex_forewords@foreword_schedule.roc` | 28 | 52 |
| `codex_forewords@foreword_scheduler.roc` | 995 | 60 |
| `codex_forewords@foreword_sensors.roc` | 28 | 47 |
| `codex_forewords@foreword_set.roc` | 28 | 48 |
| `codex_forewords@foreword_sha1.roc` | 28 | 48 |
| `codex_forewords@foreword_sha256.roc` | 28 | 49 |
| `codex_forewords@foreword_sha512.roc` | 28 | 56 |
| `codex_forewords@foreword_sort.roc` | 28 | 52 |
| `codex_forewords@foreword_state.roc` | 28 | 52 |
| `codex_forewords@foreword_statistics.roc` | 28 | 56 |
| `codex_forewords@foreword_string_utils.roc` | 28 | 54 |
| `codex_forewords@foreword_tab_complete.roc` | 28 | 55 |
| `codex_forewords@foreword_text_wrap.roc` | 28 | 52 |
| `codex_forewords@foreword_time.roc` | 28 | 49 |
| `codex_forewords@foreword_timing_wheel.roc` | 995 | 75 |
| `codex_forewords@foreword_trie.roc` | 28 | 58 |
| `codex_forewords@foreword_tuple.roc` | 28 | 71 |
| `codex_forewords@foreword_unicode.roc` | 28 | 69 |
| `codex_forewords@foreword_union_find.roc` | 28 | 73 |
| `codex_forewords@game_bresenham.roc` | 28 | 71 |
| `codex_forewords@game_card_deck.roc` | 28 | 70 |
| `codex_forewords@game_cellular_automata.roc` | 28 | 64 |
| `codex_forewords@game_color.roc` | 28 | 62 |
| `codex_forewords@game_diamond_square.roc` | 28 | 55 |
| `codex_forewords@game_e_c_s.roc` | 28 | 53 |
| `codex_forewords@game_easing.roc` | 28 | 52 |
| `codex_forewords@game_flood_fill.roc` | 28 | 52 |
| `codex_forewords@game_game_camera.roc` | 28 | 47 |
| `codex_forewords@game_hex_map.roc` | 28 | 50 |
| `codex_forewords@game_inventory.roc` | 28 | 47 |
| `codex_forewords@game_klondike.roc` | 28 | 54 |
| `codex_forewords@game_octree.roc` | 28 | 78 |
| `codex_forewords@game_quadtree.roc` | 28 | 52 |
| `codex_forewords@game_rasterizer.roc` | 28 | 48 |
| `codex_forewords@game_raytracer.roc` | 28 | 53 |
| `codex_forewords@game_save_slot.roc` | 28 | 53 |
| `codex_forewords@game_scene2_d.roc` | 28 | 55 |
| `codex_forewords@game_sprite.roc` | 28 | 54 |
| `codex_forewords@game_state_machine.roc` | 28 | 69 |
| `codex_forewords@game_tile_map.roc` | 28 | 51 |
| `codex_forewords@game_tween.roc` | 28 | 58 |
| `codex_forewords@game_voronoi.roc` | 28 | 60 |
| `codex_forewords@gpu_atomic.roc` | 31 | 93 |
| `codex_forewords@gpu_barrier.roc` | 32 | 76 |
| `codex_forewords@gpu_device_buffer.roc` | 28 | 48 |
| `codex_forewords@gpu_device_effect.roc` | 28 | 51 |
| `codex_forewords@gpu_devicemath_atan.roc` | 131 | 105 |
| `codex_forewords@gpu_disjoint_slice.roc` | 32 | 102 |
| `codex_forewords@gpu_effect.roc` | 28 | 56 |
| `codex_forewords@gpu_launch_config.roc` | 32 | 86 |
| `codex_forewords@gpu_shared.roc` | 32 | 103 |
| `codex_forewords@gpu_thread.roc` | 32 | 86 |
| `codex_forewords@gpu_warp.roc` | 32 | 74 |
| `codex_forewords@math_bezier.roc` | 28 | 60 |
| `codex_forewords@math_complex.roc` | 28 | 48 |
| `codex_forewords@math_cordic.roc` | 28 | 50 |
| `codex_forewords@math_cordic_accuracy.roc` | 118 | 166 |
| `codex_forewords@math_cordic_quadrants.roc` | 112 | 182 |
| `codex_forewords@math_geodesic.roc` | 995 | 58 |
| `codex_forewords@math_geometry.roc` | 28 | 50 |
| `codex_forewords@math_linear_algebra.roc` | 28 | 50 |
| `codex_forewords@math_matrix3.roc` | 28 | 62 |
| `codex_forewords@math_matrix4.roc` | 28 | 63 |
| `codex_forewords@math_numeric.roc` | 28 | 61 |
| `codex_forewords@math_optimize.roc` | 28 | 53 |
| `codex_forewords@math_quaternion.roc` | 28 | 53 |
| `codex_forewords@math_spline.roc` | 28 | 52 |
| `codex_forewords@signal_audio_analysis.roc` | 995 | 70 |
| `codex_forewords@signal_audio_effect.roc` | 28 | 54 |
| `codex_forewords@signal_convolution.roc` | 28 | 58 |
| `codex_forewords@signal_envelope.roc` | 28 | 53 |
| `codex_forewords@signal_filter.roc` | 995 | 59 |
| `codex_forewords@signal_music_theory.roc` | 28 | 50 |
| `codex_forewords@signal_noise.roc` | 28 | 52 |
| `codex_forewords@signal_oscillator.roc` | 995 | 56 |
| `codex_forewords@signal_perlin.roc` | 28 | 72 |
| `codex_forewords@signal_pitch.roc` | 995 | 69 |
| `codex_forewords@signal_resample.roc` | 995 | 62 |
| `codex_forewords@signal_synth.roc` | 995 | 62 |
| `codex_forewords@sim_collision.roc` | 28 | 49 |
| `codex_forewords@sim_constraint.roc` | 28 | 59 |
| `codex_forewords@sim_kinematics.roc` | 995 | 69 |
| `codex_forewords@sim_particle_system.roc` | 28 | 54 |
| `codex_forewords@sim_physics.roc` | 995 | 66 |
| `codex_forewords@sim_steering.roc` | 995 | 84 |
| `codex_forewords@ui_accessibility.roc` | 90 | 196 |
| `codex_forewords@ui_animation.roc` | 28 | 53 |
| `codex_forewords@ui_binding.roc` | 28 | 52 |
| `codex_forewords@ui_box_model.roc` | 28 | 69 |
| `codex_forewords@ui_clipboard.roc` | 28 | 67 |
| `codex_forewords@ui_cursor.roc` | 28 | 49 |
| `codex_forewords@ui_dialog.roc` | 28 | 50 |
| `codex_forewords@ui_drag.roc` | 28 | 51 |
| `codex_forewords@ui_event.roc` | 28 | 48 |
| `codex_forewords@ui_focus.roc` | 28 | 48 |
| `codex_forewords@ui_font.roc` | 28 | 46 |
| `codex_forewords@ui_icon.roc` | 28 | 64 |
| `codex_forewords@ui_layout.roc` | 28 | 48 |
| `codex_forewords@ui_orchestrator.roc` | 28 | 47 |
| `codex_forewords@ui_overlay.roc` | 28 | 60 |
| `codex_forewords@ui_render.roc` | 28 | 48 |
| `codex_forewords@ui_rich_text.roc` | 28 | 50 |
| `codex_forewords@ui_scroll.roc` | 28 | 46 |
| `codex_forewords@ui_selection.roc` | 28 | 47 |
| `codex_forewords@ui_sound.roc` | 28 | 49 |
| `codex_forewords@ui_surface.roc` | 28 | 48 |
| `codex_forewords@ui_text_field.roc` | 28 | 57 |
| `codex_forewords@ui_theme.roc` | 28 | 55 |
| `codex_forewords@ui_touch.roc` | 28 | 55 |
| `codex_forewords@ui_vector.roc` | 28 | 51 |
| `codex_forewords@ui_widget.roc` | 28 | 47 |
| `codex_frame_short_buffer.roc` | 94 | 176 |
| `codex_frameless_leaf_probe.roc` | 60 | 68 |
| `codex_hamt_test.roc` | 112 | 372 |
| `codex_hart_encode.roc` | 61 | 45 |
| `codex_hid_decode.roc` | 91 | 133 |
| `codex_ieee802154_encode.roc` | 53 | 29 |
| `codex_if_in_arith.roc` | 35 | 57 |
| `codex_if_let_join.roc` | 72 | 68 |
| `codex_implicit_convert.roc` | 1004 | 58 |
| `codex_inline_cost_based.roc` | 60 | 96 |
| `codex_inline_single_caller.roc` | 52 | 64 |
| `codex_int_literal_underscore.roc` | 36 | 64 |
| `codex_ip_checksum_odd.roc` | 80 | 143 |
| `codex_ir_check_clean.roc` | 108 | 122 |
| `codex_iterate_test.roc` | 62 | 63 |
| `codex_iterate_zip_test.roc` | 61 | 116 |
| `codex_j1939_encode.roc` | 51 | 44 |
| `codex_klondike_test.roc` | 92 | 174 |
| `codex_knx_encode.roc` | 53 | 31 |
| `codex_lang_smoke.roc` | 238 | 154 |
| `codex_leaf_let_if.roc` | 38 | 62 |
| `codex_leaf_mispredict.roc` | 36 | 58 |
| `codex_let_else_scope.roc` | 44 | 58 |
| `codex_let_shadow_scope.roc` | 38 | 49 |
| `codex_lib@canvas_viewport.roc` | 79 | 173 |
| `codex_lib@cbor_test.roc` | 114 | 218 |
| `codex_lib@decimal_test.roc` | 64 | 143 |
| `codex_lib@device_math.roc` | 165 | 141 |
| `codex_lib@format_test.roc` | 55 | 91 |
| `codex_lib@linalg_test.roc` | 64 | 137 |
| `codex_lib@locale_test.roc` | 57 | 132 |
| `codex_lib@loss_test.roc` | 56 | 155 |
| `codex_lib@lz4_test.roc` | 49 | 138 |
| `codex_lib@number_theory_test.roc` | 58 | 143 |
| `codex_lib@numeric_test.roc` | 89 | 128 |
| `codex_lib@path_test.roc` | 55 | 155 |
| `codex_lib@pixel_buf.roc` | 257 | 238 |
| `codex_lib@probability_test.roc` | 81 | 154 |
| `codex_lib@text_overflow.roc` | 103 | 127 |
| `codex_lib@toml_test.roc` | 48 | 157 |
| `codex_lib@yaml_test.roc` | 64 | 214 |
| `codex_linear_branch.roc` | 45 | 91 |
| `codex_linear_capture_once.roc` | 53 | 65 |
| `codex_linear_mint_container.roc` | 37 | 53 |
| `codex_linear_poly_freeze.roc` | 29 | 62 |
| `codex_linear_smoke.roc` | 45 | 60 |
| `codex_lir_binop_cross.roc` | 78 | 72 |
| `codex_lir_branch_cross.roc` | 119 | 76 |
| `codex_lir_call_cross.roc` | 79 | 68 |
| `codex_lir_check.roc` | 185 | 78 |
| `codex_lir_frame_cross.roc` | 60 | 62 |
| `codex_lir_join_cross.roc` | 72 | 63 |
| `codex_lir_load_cross.roc` | 130 | 65 |
| `codex_lir_nullary_cross.roc` | 71 | 90 |
| `codex_lir_selector_smoke.roc` | 76 | 85 |
| `codex_lir_test_cross.roc` | 75 | 80 |
| `codex_list_comprehension_copy.roc` | 42 | 78 |
| `codex_list_literal_o1.roc` | 46 | 87 |
| `codex_list_pattern.roc` | 64 | 62 |
| `codex_list_tail_empty.roc` | 47 | 65 |
| `codex_list_test.roc` | 118 | 232 |
| `codex_literal_subpattern.roc` | 135 | 80 |
| `codex_lwm2m_encode.roc` | 99 | 116 |
| `codex_match_arms_per_line.roc` | 61 | 74 |
| `codex_mbus_encode.roc` | 53 | 42 |
| `codex_melsec_encode.roc` | 56 | 43 |
| `codex_mini_bootstrap.roc` | 66 | 91 |
| `codex_mix_bits.roc` | 70 | 123 |
| `codex_mod_bound_return.roc` | 42 | 59 |
| `codex_modbus_encode.roc` | 105 | 103 |
| `codex_modprobe.roc` | 46 | 90 |
| `codex_mut_borrow_transitive.roc` | 50 | 88 |
| `codex_neg_int_parse.roc` | 28 | 43 |
| `codex_negation_abutment.roc` | 65 | 79 |
| `codex_noise_test.roc` | 98 | 188 |
| `codex_ops@bounded_modes_smoke.roc` | 119 | 185 |
| `codex_ops@builtin_name_shadow.roc` | 36 | 69 |
| `codex_ops@cap_word_64.roc` | 65 | 84 |
| `codex_ops@cce_builtin_bounds.roc` | 37 | 53 |
| `codex_ops@char_at_bounds.roc` | 43 | 73 |
| `codex_ops@closure_under_apply.roc` | 89 | 64 |
| `codex_ops@div_negative_pow2.roc` | 72 | 76 |
| `codex_ops@int_add_wrapping.roc` | 71 | 70 |
| `codex_ops@int_min_literal.roc` | 55 | 70 |
| `codex_ops@int_mul_wrapping.roc` | 44 | 65 |
| `codex_ops@int_pow.roc` | 56 | 77 |
| `codex_ops@int_rem.roc` | 87 | 76 |
| `codex_ops@int_wrapping_spelling.roc` | 58 | 67 |
| `codex_ops@list_index_bounds.roc` | 47 | 70 |
| `codex_ops@list_view_bounds.roc` | 42 | 67 |
| `codex_ops@match_shadowed_arm.roc` | 64 | 94 |
| `codex_ops@native_nested_pattern.roc` | 138 | 108 |
| `codex_ops@native_nested_tags.roc` | 63 | 76 |
| `codex_ops@real_bitcast_f64.roc` | 50 | 71 |
| `codex_ops@real_compare_negative.roc` | 110 | 76 |
| `codex_ops@real_neg_neg.roc` | 36 | 57 |
| `codex_ops@real_negate.roc` | 66 | 98 |
| `codex_ops@record_closure_field_poly.roc` | 69 | 69 |
| `codex_ops@record_equality.roc` | 99 | 113 |
| `codex_ops@saturated_call_returning_function.roc` | 209 | 76 |
| `codex_ops@substring_bounds.roc` | 47 | 75 |
| `codex_ops@text_order_allowed.roc` | 48 | 69 |
| `codex_ops@tier0_cyrillic_print.roc` | 36 | 56 |
| `codex_ops@unit_pattern_lit.roc` | 52 | 52 |
| `codex_ops@unit_real_arith.roc` | 77 | 74 |
| `codex_ops@unit_real_compare.roc` | 113 | 80 |
| `codex_ops@unit_show.roc` | 71 | 119 |
| `codex_ops@unused_let_alias_discard.roc` | 53 | 66 |
| `codex_osc_noise.roc` | 1037 | 155 |
| `codex_particle_spread.roc` | 55 | 126 |
| `codex_path_real.roc` | 35 | 77 |
| `codex_peek32_sign.roc` | 51 | 116 |
| `codex_pipe_unique_test.roc` | 42 | 128 |
| `codex_poke16_width.roc` | 59 | 98 |
| `codex_prose_binary_control.roc` | 35 | 28 |
| `codex_prose_consistency.roc` | 77 | 103 |
| `codex_prose_smoke.roc` | 71 | 119 |
| `codex_punctual_fastmath.roc` | 35 | 68 |
| `codex_punctual_iot.roc` | 122 | 105 |
| `codex_punctual_quire.roc` | 102 | 186 |
| `codex_punctual_smoke.roc` | 46 | 56 |
| `codex_queue_test.roc` | 44 | 95 |
| `codex_real_literal_boundary.roc` | 36 | 60 |
| `codex_record_smoke.roc` | 214 | 134 |
| `codex_recursive_eq.roc` | 80 | 106 |
| `codex_reservoir_uniform.roc` | 95 | 139 |
| `codex_revised_narrow.roc` | 62 | 105 |
| `codex_riscv_encoder.roc` | 115 | 185 |
| `codex_riscv32c_encoder.roc` | 101 | 93 |
| `codex_roc_closure_captures_list.roc` | 39 | 59 |
| `codex_roc_early_return_predicate.roc` | 31 | 94 |
| `codex_roc_fold_count.roc` | 40 | 51 |
| `codex_roc_fold_empty.roc` | 40 | 54 |
| `codex_roc_fold_product.roc` | 40 | 51 |
| `codex_roc_fold_sum.roc` | 40 | 53 |
| `codex_roc_iter_drop_if.roc` | 62 | 69 |
| `codex_roc_iter_keep_if.roc` | 62 | 69 |
| `codex_roc_iter_map.roc` | 65 | 71 |
| `codex_roc_recursive_var.roc` | 37 | 54 |
| `codex_roc_returned_closure.roc` | 44 | 72 |
| `codex_rv_arg_order.roc` | 48 | 59 |
| `codex_rv_big_literal.roc` | 46 | 68 |
| `codex_rv_frameless_imm.roc` | 81 | 67 |
| `codex_rv_frameless_temp.roc` | 51 | 66 |
| `codex_rv_param_bind.roc` | 51 | 59 |
| `codex_rv_param_order.roc` | 61 | 73 |
| `codex_s7comm_encode.roc` | 84 | 34 |
| `codex_scope_console.roc` | 36 | 57 |
| `codex_scope_let_arm_global.roc` | 40 | 51 |
| `codex_sensor_data.roc` | 50 | 108 |
| `codex_simplify_check.roc` | 105 | 97 |
| `codex_sixlowpan_encode.roc` | 53 | 60 |
| `codex_sntp_encode.roc` | 66 | 70 |
| `codex_sort_test.roc` | 68 | 94 |
| `codex_sound_test.roc` | 1082 | 245 |
| `codex_stats_wrap_test.roc` | 88 | 82 |
| `codex_string_escape_quote.roc` | 31 | 47 |
| `codex_sum_field_eq.roc` | 66 | 113 |
| `codex_synth_test.roc` | 1069 | 166 |
| `codex_tco_bitop_loop.roc` | 87 | 71 |
| `codex_tco_direct_arg_reads.roc` | 41 | 83 |
| `codex_tco_framed_append.roc` | 54 | 59 |
| `codex_tco_nested_if.roc` | 38 | 59 |
| `codex_tco_shuffle_spill.roc` | 55 | 102 |
| `codex_text_append_alias.roc` | 40 | 160 |
| `codex_text_eq_branches.roc` | 92 | 53 |
| `codex_text_fold_indexed.roc` | 59 | 68 |
| `codex_text_helper_native.roc` | 57 | 98 |
| `codex_thumb2_encoder.roc` | 120 | 109 |
| `codex_tuple_syntax.roc` | 73 | 107 |
| `codex_tvar_in_declared_type.roc` | 35 | 56 |
| `codex_type_checker_test.roc` | 43 | 40 |
| `codex_ui_sound_test.roc` | 101 | 155 |
| `codex_unconstrained_empty_list.roc` | 52 | 65 |
| `codex_unconstrained_nullary_sum.roc` | 60 | 72 |
| `codex_unit_family.roc` | 72 | 59 |
| `codex_unit_family_mixed.roc` | 104 | 62 |
| `codex_unit_smoke.roc` | 61 | 61 |
| `codex_units_foreword.roc` | 1040 | 78 |
| `codex_usb_desc_guard.roc` | 65 | 197 |
| `codex_usb_test.roc` | 72 | 129 |
| `codex_wavelet_sort_aliasing.roc` | 42 | 100 |
| `codex_when_arm_nontail.roc` | 83 | 93 |
| `codex_when_arm_tail_call.roc` | 72 | 67 |
| `codex_when_bool_cross.roc` | 61 | 69 |
| `codex_when_bool_pattern.roc` | 80 | 111 |
| `codex_when_generic_field.roc` | 72 | 97 |
| `codex_zigbee_encode.roc` | 53 | 38 |
