# Codex tests, ported to Roc

526 programs from [Cobblestone](https://github.com/damiant3/Cobblestone)'s own test suite, machine-translated
from Codex to Roc and checked against the output Cobblestone records for
each one.

526 of the 792 the emitter runs to their verdict are here. Two kinds
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
emitted from (569 KB), and each test is a short app over it
(1539 KB for all 526):

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

52 seconds for all 526 on one core, median 88 ms. Every one of
them RUNS in about 3 ms; the rest is the compiler. The slowest:

| test | ms |
|---|---|
| `hamt-test` | 326 |
| `dtls-handshake` | 287 |
| `list-test` | 264 |
| `text-helper-native` | 259 |
| `lib@cbor-test` | 239 |

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
| `codex_act_let_scope.roc` | 76 | 100 |
| `codex_act_unused_bind.roc` | 36 | 87 |
| `codex_amp_after_call.roc` | 31 | 92 |
| `codex_approx_eq.roc` | 44 | 97 |
| `codex_arith_operand_order.roc` | 37 | 75 |
| `codex_arithmetic.roc` | 87 | 131 |
| `codex_arm64_boot_test.roc` | 30 | 89 |
| `codex_asn1_der_write.roc` | 181 | 200 |
| `codex_audio_diffusion_test.roc` | 1058 | 193 |
| `codex_bezier_identity.roc` | 65 | 116 |
| `codex_bitop_if_cond.roc` | 38 | 102 |
| `codex_ble_att_encode.roc` | 57 | 34 |
| `codex_bounded_integer_ops.roc` | 69 | 92 |
| `codex_bounded_sig_runtime.roc` | 36 | 78 |
| `codex_bounds_proof.roc` | 124 | 95 |
| `codex_bounds_prover.roc` | 91 | 82 |
| `codex_bs3_smoke.roc` | 81 | 86 |
| `codex_call_clobber.roc` | 41 | 96 |
| `codex_canopen_encode.roc` | 53 | 54 |
| `codex_cap_heap_poke_pure.roc` | 37 | 83 |
| `codex_cap_manifest_derived.roc` | 28 | 81 |
| `codex_capability_doors.roc` | 152 | 175 |
| `codex_carddeck_shuffle.roc` | 94 | 146 |
| `codex_chapter_pages.roc` | 34 | 75 |
| `codex_circbuf_test.roc` | 84 | 127 |
| `codex_cite_override_quire.roc` | 29 | 88 |
| `codex_cms_spread.roc` | 81 | 161 |
| `codex_color_test.roc` | 92 | 132 |
| `codex_consistent_hash_balance.roc` | 63 | 125 |
| `codex_convolution_identity.roc` | 51 | 109 |
| `codex_ctor_narrow_warn.roc` | 45 | 73 |
| `codex_deriving_eq_recursive.roc` | 66 | 100 |
| `codex_dnp3_encode.roc` | 69 | 33 |
| `codex_dtls_handshake.roc` | 167 | 287 |
| `codex_edit_distance_test.roc` | 83 | 201 |
| `codex_effect_dotted_allow.roc` | 34 | 90 |
| `codex_effect_positive.roc` | 51 | 97 |
| `codex_effect_row_var_syntax.roc` | 47 | 102 |
| `codex_effect_widen_arg.roc` | 34 | 86 |
| `codex_effect_widen_scope.roc` | 38 | 79 |
| `codex_enip_encode.roc` | 60 | 35 |
| `codex_eq_generic_fields.roc` | 76 | 130 |
| `codex_eq_generic_recursive.roc` | 88 | 124 |
| `codex_eq_plain_sum.roc` | 68 | 109 |
| `codex_eventbus_test.roc` | 76 | 139 |
| `codex_examples@eight_queens.roc` | 96 | 136 |
| `codex_examples@missile_warning.roc` | 144 | 111 |
| `codex_expr_calculator.roc` | 182 | 206 |
| `codex_factlog_layout.roc` | 226 | 208 |
| `codex_factorial.roc` | 144 | 193 |
| `codex_field_cache_text_lit.roc` | 41 | 109 |
| `codex_fins_encode.roc` | 56 | 34 |
| `codex_forewords@ai_activation.roc` | 28 | 74 |
| `codex_forewords@ai_activation_range.roc` | 108 | 190 |
| `codex_forewords@ai_attention.roc` | 28 | 84 |
| `codex_forewords@ai_clip_interrogator.roc` | 28 | 78 |
| `codex_forewords@ai_control_net.roc` | 28 | 78 |
| `codex_forewords@ai_decision_tree.roc` | 28 | 77 |
| `codex_forewords@ai_diffusion_pipeline.roc` | 28 | 86 |
| `codex_forewords@ai_diffusion_scheduler.roc` | 28 | 85 |
| `codex_forewords@ai_embedding.roc` | 28 | 102 |
| `codex_forewords@ai_flux_pipeline.roc` | 28 | 75 |
| `codex_forewords@ai_genetic_algorithm.roc` | 64 | 171 |
| `codex_forewords@ai_gguf.roc` | 28 | 78 |
| `codex_forewords@ai_gpu_proxy.roc` | 28 | 91 |
| `codex_forewords@ai_hires_fix.roc` | 28 | 79 |
| `codex_forewords@ai_inpainting.roc` | 28 | 81 |
| `codex_forewords@ai_k_nearest_neighbor.roc` | 28 | 76 |
| `codex_forewords@ai_kv_cache.roc` | 28 | 81 |
| `codex_forewords@ai_lora_loader.roc` | 28 | 78 |
| `codex_forewords@ai_loss.roc` | 28 | 79 |
| `codex_forewords@ai_neural_net.roc` | 28 | 81 |
| `codex_forewords@ai_normalization.roc` | 100 | 216 |
| `codex_forewords@ai_optimizer.roc` | 28 | 76 |
| `codex_forewords@ai_png_metadata.roc` | 28 | 89 |
| `codex_forewords@ai_prompt_parser.roc` | 28 | 92 |
| `codex_forewords@ai_reservoir.roc` | 28 | 80 |
| `codex_forewords@ai_sampling.roc` | 28 | 76 |
| `codex_forewords@ai_sparse_lattice.roc` | 28 | 74 |
| `codex_forewords@ai_tensor.roc` | 28 | 77 |
| `codex_forewords@ai_text_encoder.roc` | 28 | 79 |
| `codex_forewords@ai_text_encoder_xl.roc` | 28 | 74 |
| `codex_forewords@ai_tokenizer.roc` | 28 | 74 |
| `codex_forewords@ai_transformer.roc` | 28 | 73 |
| `codex_forewords@ai_unet_xl.roc` | 28 | 71 |
| `codex_forewords@ai_upscaler.roc` | 28 | 87 |
| `codex_forewords@compress_huffman.roc` | 28 | 78 |
| `codex_forewords@compress_lz4.roc` | 28 | 80 |
| `codex_forewords@compress_rle.roc` | 28 | 81 |
| `codex_forewords@core_bigint.roc` | 75 | 117 |
| `codex_forewords@encode_avi.roc` | 28 | 75 |
| `codex_forewords@encode_base64.roc` | 28 | 77 |
| `codex_forewords@encode_bencode.roc` | 28 | 75 |
| `codex_forewords@encode_bmp.roc` | 28 | 76 |
| `codex_forewords@encode_cbor.roc` | 28 | 83 |
| `codex_forewords@encode_crc32.roc` | 28 | 79 |
| `codex_forewords@encode_csv.roc` | 28 | 74 |
| `codex_forewords@encode_flac.roc` | 995 | 100 |
| `codex_forewords@encode_gif.roc` | 28 | 77 |
| `codex_forewords@encode_gray_code.roc` | 28 | 75 |
| `codex_forewords@encode_hex.roc` | 28 | 78 |
| `codex_forewords@encode_ini.roc` | 28 | 77 |
| `codex_forewords@encode_jpeg.roc` | 28 | 77 |
| `codex_forewords@encode_json.roc` | 28 | 75 |
| `codex_forewords@encode_lwm2m.roc` | 28 | 77 |
| `codex_forewords@encode_markdown.roc` | 28 | 77 |
| `codex_forewords@encode_message_pack.roc` | 28 | 76 |
| `codex_forewords@encode_midi.roc` | 995 | 102 |
| `codex_forewords@encode_mp3.roc` | 995 | 94 |
| `codex_forewords@encode_mp4.roc` | 28 | 75 |
| `codex_forewords@encode_ogg.roc` | 28 | 72 |
| `codex_forewords@encode_png.roc` | 28 | 84 |
| `codex_forewords@encode_protobuf.roc` | 28 | 84 |
| `codex_forewords@encode_qoi.roc` | 28 | 79 |
| `codex_forewords@encode_smtp.roc` | 28 | 76 |
| `codex_forewords@encode_tiff.roc` | 28 | 77 |
| `codex_forewords@encode_toml.roc` | 28 | 92 |
| `codex_forewords@encode_uri.roc` | 28 | 79 |
| `codex_forewords@encode_uuid.roc` | 28 | 103 |
| `codex_forewords@encode_video_codec.roc` | 28 | 103 |
| `codex_forewords@encode_wav.roc` | 995 | 125 |
| `codex_forewords@encode_web_socket.roc` | 28 | 80 |
| `codex_forewords@encode_yaml.roc` | 28 | 85 |
| `codex_forewords@engine_ability_system.roc` | 28 | 86 |
| `codex_forewords@engine_anim_blend.roc` | 28 | 101 |
| `codex_forewords@engine_asset_table.roc` | 28 | 96 |
| `codex_forewords@engine_audio_bus.roc` | 28 | 76 |
| `codex_forewords@engine_audio3d.roc` | 28 | 76 |
| `codex_forewords@engine_biome.roc` | 28 | 78 |
| `codex_forewords@engine_cloth_sim.roc` | 995 | 101 |
| `codex_forewords@engine_collision3d.roc` | 28 | 90 |
| `codex_forewords@engine_culling.roc` | 28 | 81 |
| `codex_forewords@engine_cutscene.roc` | 28 | 76 |
| `codex_forewords@engine_damage_system.roc` | 28 | 74 |
| `codex_forewords@engine_debug_draw.roc` | 28 | 76 |
| `codex_forewords@engine_facial_anim.roc` | 28 | 75 |
| `codex_forewords@engine_fog.roc` | 28 | 102 |
| `codex_forewords@engine_fractal_plant.roc` | 28 | 80 |
| `codex_forewords@engine_game_loop.roc` | 28 | 88 |
| `codex_forewords@engine_gameplay_tags.roc` | 28 | 82 |
| `codex_forewords@engine_hair_sim.roc` | 995 | 95 |
| `codex_forewords@engine_helm_bridge.roc` | 28 | 81 |
| `codex_forewords@engine_input.roc` | 28 | 76 |
| `codex_forewords@engine_lod.roc` | 28 | 99 |
| `codex_forewords@engine_material.roc` | 28 | 82 |
| `codex_forewords@engine_mesh.roc` | 28 | 82 |
| `codex_forewords@engine_musculature.roc` | 995 | 96 |
| `codex_forewords@engine_particle_renderer.roc` | 28 | 78 |
| `codex_forewords@engine_physics_joint.roc` | 995 | 104 |
| `codex_forewords@engine_post_process.roc` | 28 | 78 |
| `codex_forewords@engine_renderer3d.roc` | 28 | 76 |
| `codex_forewords@engine_scene3d.roc` | 28 | 77 |
| `codex_forewords@engine_signal.roc` | 28 | 75 |
| `codex_forewords@engine_skin_shader.roc` | 28 | 83 |
| `codex_forewords@engine_skinning.roc` | 28 | 75 |
| `codex_forewords@engine_soft_body.roc` | 995 | 96 |
| `codex_forewords@engine_spline_path.roc` | 28 | 75 |
| `codex_forewords@engine_terrain.roc` | 28 | 75 |
| `codex_forewords@engine_texture.roc` | 28 | 90 |
| `codex_forewords@engine_time_of_day.roc` | 28 | 80 |
| `codex_forewords@engine_water.roc` | 28 | 77 |
| `codex_forewords@engine_world_gen.roc` | 28 | 75 |
| `codex_forewords@engine_world_hud.roc` | 28 | 75 |
| `codex_forewords@foreword_aes.roc` | 28 | 82 |
| `codex_forewords@foreword_aes_gcm.roc` | 28 | 95 |
| `codex_forewords@foreword_aes256.roc` | 28 | 94 |
| `codex_forewords@foreword_apprunner.roc` | 28 | 79 |
| `codex_forewords@foreword_b_plus_tree.roc` | 28 | 78 |
| `codex_forewords@foreword_bit_set.roc` | 28 | 74 |
| `codex_forewords@foreword_bloom_filter.roc` | 28 | 74 |
| `codex_forewords@foreword_c_c_e.roc` | 28 | 82 |
| `codex_forewords@foreword_camera.roc` | 28 | 77 |
| `codex_forewords@foreword_cha_cha20.roc` | 28 | 81 |
| `codex_forewords@foreword_channel.roc` | 28 | 80 |
| `codex_forewords@foreword_circular_buffer.roc` | 28 | 87 |
| `codex_forewords@foreword_consistent_hash.roc` | 28 | 88 |
| `codex_forewords@foreword_console.roc` | 28 | 84 |
| `codex_forewords@foreword_count_min_sketch.roc` | 28 | 78 |
| `codex_forewords@foreword_date_time.roc` | 77 | 96 |
| `codex_forewords@foreword_decimal.roc` | 28 | 74 |
| `codex_forewords@foreword_deque.roc` | 28 | 76 |
| `codex_forewords@foreword_display.roc` | 28 | 89 |
| `codex_forewords@foreword_edit_distance.roc` | 28 | 83 |
| `codex_forewords@foreword_either.roc` | 28 | 84 |
| `codex_forewords@foreword_elastic_bloom.roc` | 28 | 97 |
| `codex_forewords@foreword_elastic_hash.roc` | 28 | 72 |
| `codex_forewords@foreword_event_bus.roc` | 28 | 74 |
| `codex_forewords@foreword_fact_store.roc` | 28 | 73 |
| `codex_forewords@foreword_fat16.roc` | 28 | 76 |
| `codex_forewords@foreword_fat32.roc` | 28 | 79 |
| `codex_forewords@foreword_format.roc` | 28 | 91 |
| `codex_forewords@foreword_fuel.roc` | 28 | 95 |
| `codex_forewords@foreword_funnel_hash.roc` | 28 | 91 |
| `codex_forewords@foreword_gpt.roc` | 28 | 75 |
| `codex_forewords@foreword_hamt.roc` | 28 | 78 |
| `codex_forewords@foreword_history.roc` | 28 | 92 |
| `codex_forewords@foreword_hkdf.roc` | 28 | 99 |
| `codex_forewords@foreword_hmac.roc` | 28 | 85 |
| `codex_forewords@foreword_interval_tree.roc` | 28 | 91 |
| `codex_forewords@foreword_kv_store.roc` | 28 | 82 |
| `codex_forewords@foreword_list.roc` | 28 | 80 |
| `codex_forewords@foreword_list_utils.roc` | 28 | 81 |
| `codex_forewords@foreword_locale.roc` | 28 | 94 |
| `codex_forewords@foreword_location.roc` | 28 | 79 |
| `codex_forewords@foreword_logger.roc` | 28 | 78 |
| `codex_forewords@foreword_lru_cache.roc` | 28 | 76 |
| `codex_forewords@foreword_math_lib.roc` | 28 | 75 |
| `codex_forewords@foreword_maybe.roc` | 28 | 77 |
| `codex_forewords@foreword_microphone.roc` | 28 | 79 |
| `codex_forewords@foreword_network.roc` | 28 | 84 |
| `codex_forewords@foreword_number_theory.roc` | 28 | 76 |
| `codex_forewords@foreword_pair.roc` | 28 | 76 |
| `codex_forewords@foreword_path.roc` | 28 | 74 |
| `codex_forewords@foreword_pattern.roc` | 28 | 74 |
| `codex_forewords@foreword_pbkdf.roc` | 28 | 85 |
| `codex_forewords@foreword_pipeline.roc` | 28 | 83 |
| `codex_forewords@foreword_priority_queue.roc` | 28 | 78 |
| `codex_forewords@foreword_probability.roc` | 28 | 74 |
| `codex_forewords@foreword_proof_of_work.roc` | 28 | 78 |
| `codex_forewords@foreword_queue.roc` | 28 | 94 |
| `codex_forewords@foreword_random.roc` | 28 | 79 |
| `codex_forewords@foreword_rate_limiter.roc` | 77 | 82 |
| `codex_forewords@foreword_regex.roc` | 28 | 93 |
| `codex_forewords@foreword_result.roc` | 28 | 106 |
| `codex_forewords@foreword_ring_buffer.roc` | 28 | 79 |
| `codex_forewords@foreword_rope.roc` | 28 | 104 |
| `codex_forewords@foreword_schedule.roc` | 28 | 88 |
| `codex_forewords@foreword_scheduler.roc` | 995 | 135 |
| `codex_forewords@foreword_sensors.roc` | 28 | 87 |
| `codex_forewords@foreword_set.roc` | 28 | 82 |
| `codex_forewords@foreword_sha1.roc` | 28 | 81 |
| `codex_forewords@foreword_sha256.roc` | 28 | 78 |
| `codex_forewords@foreword_sha512.roc` | 28 | 73 |
| `codex_forewords@foreword_sort.roc` | 28 | 74 |
| `codex_forewords@foreword_state.roc` | 28 | 76 |
| `codex_forewords@foreword_statistics.roc` | 28 | 76 |
| `codex_forewords@foreword_string_utils.roc` | 28 | 80 |
| `codex_forewords@foreword_tab_complete.roc` | 28 | 82 |
| `codex_forewords@foreword_text_wrap.roc` | 28 | 77 |
| `codex_forewords@foreword_time.roc` | 28 | 78 |
| `codex_forewords@foreword_timing_wheel.roc` | 995 | 108 |
| `codex_forewords@foreword_trie.roc` | 28 | 80 |
| `codex_forewords@foreword_tuple.roc` | 28 | 81 |
| `codex_forewords@foreword_unicode.roc` | 28 | 79 |
| `codex_forewords@foreword_union_find.roc` | 28 | 76 |
| `codex_forewords@game_bresenham.roc` | 28 | 77 |
| `codex_forewords@game_card_deck.roc` | 28 | 76 |
| `codex_forewords@game_cellular_automata.roc` | 28 | 78 |
| `codex_forewords@game_color.roc` | 28 | 77 |
| `codex_forewords@game_diamond_square.roc` | 28 | 77 |
| `codex_forewords@game_e_c_s.roc` | 28 | 71 |
| `codex_forewords@game_easing.roc` | 28 | 94 |
| `codex_forewords@game_flood_fill.roc` | 28 | 75 |
| `codex_forewords@game_game_camera.roc` | 28 | 73 |
| `codex_forewords@game_hex_map.roc` | 28 | 76 |
| `codex_forewords@game_inventory.roc` | 28 | 80 |
| `codex_forewords@game_klondike.roc` | 28 | 91 |
| `codex_forewords@game_octree.roc` | 28 | 74 |
| `codex_forewords@game_quadtree.roc` | 28 | 75 |
| `codex_forewords@game_rasterizer.roc` | 28 | 77 |
| `codex_forewords@game_raytracer.roc` | 28 | 77 |
| `codex_forewords@game_save_slot.roc` | 28 | 78 |
| `codex_forewords@game_scene2_d.roc` | 28 | 84 |
| `codex_forewords@game_sprite.roc` | 28 | 78 |
| `codex_forewords@game_state_machine.roc` | 28 | 93 |
| `codex_forewords@game_tile_map.roc` | 28 | 106 |
| `codex_forewords@game_tween.roc` | 28 | 105 |
| `codex_forewords@game_voronoi.roc` | 28 | 86 |
| `codex_forewords@gpu_atomic.roc` | 31 | 84 |
| `codex_forewords@gpu_barrier.roc` | 31 | 63 |
| `codex_forewords@gpu_device_buffer.roc` | 28 | 83 |
| `codex_forewords@gpu_device_effect.roc` | 28 | 81 |
| `codex_forewords@gpu_devicemath_atan.roc` | 131 | 212 |
| `codex_forewords@gpu_disjoint_slice.roc` | 32 | 71 |
| `codex_forewords@gpu_effect.roc` | 28 | 74 |
| `codex_forewords@gpu_launch_config.roc` | 32 | 79 |
| `codex_forewords@gpu_shared.roc` | 32 | 71 |
| `codex_forewords@gpu_thread.roc` | 32 | 72 |
| `codex_forewords@gpu_warp.roc` | 32 | 75 |
| `codex_forewords@math_bezier.roc` | 28 | 82 |
| `codex_forewords@math_complex.roc` | 28 | 73 |
| `codex_forewords@math_cordic.roc` | 28 | 77 |
| `codex_forewords@math_cordic_accuracy.roc` | 118 | 168 |
| `codex_forewords@math_cordic_quadrants.roc` | 112 | 175 |
| `codex_forewords@math_geodesic.roc` | 995 | 97 |
| `codex_forewords@math_geometry.roc` | 28 | 75 |
| `codex_forewords@math_linear_algebra.roc` | 28 | 78 |
| `codex_forewords@math_matrix3.roc` | 28 | 77 |
| `codex_forewords@math_matrix4.roc` | 28 | 79 |
| `codex_forewords@math_numeric.roc` | 28 | 75 |
| `codex_forewords@math_optimize.roc` | 28 | 77 |
| `codex_forewords@math_quaternion.roc` | 28 | 100 |
| `codex_forewords@math_spline.roc` | 28 | 80 |
| `codex_forewords@signal_audio_analysis.roc` | 995 | 111 |
| `codex_forewords@signal_audio_effect.roc` | 28 | 88 |
| `codex_forewords@signal_convolution.roc` | 28 | 87 |
| `codex_forewords@signal_envelope.roc` | 28 | 89 |
| `codex_forewords@signal_filter.roc` | 995 | 121 |
| `codex_forewords@signal_music_theory.roc` | 28 | 76 |
| `codex_forewords@signal_noise.roc` | 28 | 73 |
| `codex_forewords@signal_oscillator.roc` | 995 | 106 |
| `codex_forewords@signal_perlin.roc` | 28 | 78 |
| `codex_forewords@signal_pitch.roc` | 995 | 102 |
| `codex_forewords@signal_resample.roc` | 995 | 97 |
| `codex_forewords@signal_synth.roc` | 995 | 93 |
| `codex_forewords@sim_collision.roc` | 28 | 79 |
| `codex_forewords@sim_constraint.roc` | 28 | 77 |
| `codex_forewords@sim_kinematics.roc` | 995 | 100 |
| `codex_forewords@sim_particle_system.roc` | 28 | 75 |
| `codex_forewords@sim_physics.roc` | 995 | 92 |
| `codex_forewords@sim_steering.roc` | 995 | 97 |
| `codex_forewords@ui_accessibility.roc` | 90 | 175 |
| `codex_forewords@ui_animation.roc` | 28 | 78 |
| `codex_forewords@ui_binding.roc` | 28 | 77 |
| `codex_forewords@ui_box_model.roc` | 28 | 75 |
| `codex_forewords@ui_clipboard.roc` | 28 | 77 |
| `codex_forewords@ui_cursor.roc` | 28 | 81 |
| `codex_forewords@ui_dialog.roc` | 28 | 77 |
| `codex_forewords@ui_drag.roc` | 28 | 72 |
| `codex_forewords@ui_event.roc` | 28 | 76 |
| `codex_forewords@ui_focus.roc` | 28 | 76 |
| `codex_forewords@ui_font.roc` | 28 | 73 |
| `codex_forewords@ui_icon.roc` | 28 | 75 |
| `codex_forewords@ui_layout.roc` | 28 | 83 |
| `codex_forewords@ui_orchestrator.roc` | 28 | 97 |
| `codex_forewords@ui_overlay.roc` | 28 | 90 |
| `codex_forewords@ui_render.roc` | 28 | 88 |
| `codex_forewords@ui_rich_text.roc` | 28 | 94 |
| `codex_forewords@ui_scroll.roc` | 28 | 103 |
| `codex_forewords@ui_selection.roc` | 28 | 118 |
| `codex_forewords@ui_sound.roc` | 28 | 104 |
| `codex_forewords@ui_surface.roc` | 28 | 101 |
| `codex_forewords@ui_text_field.roc` | 28 | 90 |
| `codex_forewords@ui_theme.roc` | 28 | 83 |
| `codex_forewords@ui_touch.roc` | 28 | 91 |
| `codex_forewords@ui_vector.roc` | 28 | 81 |
| `codex_forewords@ui_widget.roc` | 28 | 80 |
| `codex_frame_short_buffer.roc` | 94 | 178 |
| `codex_frameless_leaf_probe.roc` | 60 | 112 |
| `codex_hamt_test.roc` | 112 | 326 |
| `codex_hart_encode.roc` | 61 | 39 |
| `codex_hid_decode.roc` | 91 | 162 |
| `codex_ieee802154_encode.roc` | 53 | 31 |
| `codex_if_in_arith.roc` | 35 | 86 |
| `codex_if_let_join.roc` | 72 | 90 |
| `codex_implicit_convert.roc` | 1004 | 138 |
| `codex_inline_cost_based.roc` | 57 | 112 |
| `codex_inline_single_caller.roc` | 52 | 103 |
| `codex_int_literal_underscore.roc` | 36 | 87 |
| `codex_ip_checksum_odd.roc` | 80 | 163 |
| `codex_ir_check_clean.roc` | 105 | 115 |
| `codex_iterate_test.roc` | 62 | 97 |
| `codex_iterate_zip_test.roc` | 61 | 123 |
| `codex_j1939_encode.roc` | 51 | 49 |
| `codex_klondike_test.roc` | 92 | 174 |
| `codex_knx_encode.roc` | 53 | 35 |
| `codex_lang_smoke.roc` | 238 | 173 |
| `codex_leaf_let_if.roc` | 38 | 88 |
| `codex_leaf_mispredict.roc` | 36 | 76 |
| `codex_let_else_scope.roc` | 44 | 80 |
| `codex_let_shadow_scope.roc` | 38 | 77 |
| `codex_lib@canvas_viewport.roc` | 79 | 186 |
| `codex_lib@cbor_test.roc` | 114 | 239 |
| `codex_lib@decimal_test.roc` | 64 | 149 |
| `codex_lib@device_math.roc` | 165 | 223 |
| `codex_lib@format_test.roc` | 55 | 149 |
| `codex_lib@linalg_test.roc` | 64 | 156 |
| `codex_lib@locale_test.roc` | 57 | 137 |
| `codex_lib@loss_test.roc` | 56 | 140 |
| `codex_lib@lz4_test.roc` | 49 | 137 |
| `codex_lib@number_theory_test.roc` | 58 | 149 |
| `codex_lib@numeric_test.roc` | 89 | 133 |
| `codex_lib@path_test.roc` | 55 | 169 |
| `codex_lib@pixel_buf.roc` | 257 | 219 |
| `codex_lib@probability_test.roc` | 81 | 148 |
| `codex_lib@text_overflow.roc` | 103 | 178 |
| `codex_lib@toml_test.roc` | 48 | 177 |
| `codex_lib@yaml_test.roc` | 64 | 202 |
| `codex_linear_branch.roc` | 45 | 101 |
| `codex_linear_capture_once.roc` | 53 | 95 |
| `codex_linear_mint_container.roc` | 37 | 81 |
| `codex_linear_poly_freeze.roc` | 29 | 92 |
| `codex_linear_smoke.roc` | 45 | 94 |
| `codex_lir_binop_cross.roc` | 78 | 108 |
| `codex_lir_branch_cross.roc` | 119 | 177 |
| `codex_lir_call_cross.roc` | 79 | 102 |
| `codex_lir_check.roc` | 185 | 118 |
| `codex_lir_frame_cross.roc` | 60 | 142 |
| `codex_lir_join_cross.roc` | 72 | 123 |
| `codex_lir_load_cross.roc` | 130 | 85 |
| `codex_lir_nullary_cross.roc` | 71 | 107 |
| `codex_lir_selector_smoke.roc` | 76 | 87 |
| `codex_lir_test_cross.roc` | 75 | 96 |
| `codex_list_comprehension_copy.roc` | 42 | 112 |
| `codex_list_literal_o1.roc` | 46 | 131 |
| `codex_list_pattern.roc` | 64 | 120 |
| `codex_list_tail_empty.roc` | 47 | 109 |
| `codex_list_test.roc` | 115 | 264 |
| `codex_literal_subpattern.roc` | 135 | 143 |
| `codex_lwm2m_encode.roc` | 99 | 100 |
| `codex_match_arms_per_line.roc` | 61 | 101 |
| `codex_mbus_encode.roc` | 53 | 32 |
| `codex_melsec_encode.roc` | 56 | 33 |
| `codex_mini_bootstrap.roc` | 63 | 94 |
| `codex_mix_bits.roc` | 70 | 117 |
| `codex_mod_bound_return.roc` | 42 | 81 |
| `codex_modbus_encode.roc` | 105 | 114 |
| `codex_modprobe.roc` | 46 | 104 |
| `codex_mut_borrow_transitive.roc` | 41 | 73 |
| `codex_neg_int_parse.roc` | 28 | 74 |
| `codex_negation_abutment.roc` | 65 | 100 |
| `codex_noise_test.roc` | 98 | 159 |
| `codex_ops@bounded_modes_smoke.roc` | 101 | 135 |
| `codex_ops@builtin_name_shadow.roc` | 36 | 89 |
| `codex_ops@cap_word_64.roc` | 65 | 112 |
| `codex_ops@cce_builtin_bounds.roc` | 37 | 88 |
| `codex_ops@char_at_bounds.roc` | 43 | 108 |
| `codex_ops@closure_under_apply.roc` | 89 | 92 |
| `codex_ops@div_negative_pow2.roc` | 72 | 111 |
| `codex_ops@int_add_wrapping.roc` | 71 | 110 |
| `codex_ops@int_min_literal.roc` | 55 | 121 |
| `codex_ops@int_mul_wrapping.roc` | 44 | 102 |
| `codex_ops@int_pow.roc` | 56 | 118 |
| `codex_ops@int_rem.roc` | 87 | 129 |
| `codex_ops@int_wrapping_spelling.roc` | 58 | 105 |
| `codex_ops@list_index_bounds.roc` | 47 | 115 |
| `codex_ops@list_view_bounds.roc` | 42 | 96 |
| `codex_ops@match_shadowed_arm.roc` | 64 | 97 |
| `codex_ops@native_nested_pattern.roc` | 138 | 109 |
| `codex_ops@native_nested_tags.roc` | 63 | 86 |
| `codex_ops@real_bitcast_f64.roc` | 50 | 109 |
| `codex_ops@real_compare_negative.roc` | 110 | 123 |
| `codex_ops@real_neg_neg.roc` | 36 | 88 |
| `codex_ops@real_negate.roc` | 63 | 101 |
| `codex_ops@record_closure_field_poly.roc` | 69 | 96 |
| `codex_ops@record_equality.roc` | 87 | 111 |
| `codex_ops@saturated_call_returning_function.roc` | 209 | 120 |
| `codex_ops@substring_bounds.roc` | 47 | 103 |
| `codex_ops@text_order_allowed.roc` | 48 | 104 |
| `codex_ops@tier0_cyrillic_print.roc` | 36 | 119 |
| `codex_ops@unit_pattern_lit.roc` | 52 | 111 |
| `codex_ops@unit_real_arith.roc` | 77 | 113 |
| `codex_ops@unit_real_compare.roc` | 113 | 152 |
| `codex_ops@unit_show.roc` | 71 | 161 |
| `codex_ops@unused_let_alias_discard.roc` | 53 | 120 |
| `codex_osc_noise.roc` | 1037 | 174 |
| `codex_particle_spread.roc` | 55 | 151 |
| `codex_path_real.roc` | 35 | 95 |
| `codex_peek32_sign.roc` | 51 | 128 |
| `codex_pipe_unique_test.roc` | 42 | 115 |
| `codex_poke16_width.roc` | 59 | 133 |
| `codex_prose_binary_control.roc` | 35 | 28 |
| `codex_prose_consistency.roc` | 74 | 97 |
| `codex_prose_smoke.roc` | 68 | 106 |
| `codex_punctual_fastmath.roc` | 35 | 91 |
| `codex_punctual_iot.roc` | 119 | 111 |
| `codex_punctual_quire.roc` | 102 | 221 |
| `codex_punctual_smoke.roc` | 46 | 83 |
| `codex_queue_test.roc` | 44 | 101 |
| `codex_real_literal_boundary.roc` | 36 | 87 |
| `codex_record_smoke.roc` | 196 | 134 |
| `codex_recursive_eq.roc` | 80 | 113 |
| `codex_reservoir_uniform.roc` | 95 | 154 |
| `codex_revised_narrow.roc` | 59 | 102 |
| `codex_riscv_encoder.roc` | 115 | 199 |
| `codex_riscv32c_encoder.roc` | 101 | 155 |
| `codex_roc_closure_captures_list.roc` | 39 | 65 |
| `codex_roc_early_return_predicate.roc` | 31 | 92 |
| `codex_roc_fold_count.roc` | 40 | 91 |
| `codex_roc_fold_empty.roc` | 40 | 92 |
| `codex_roc_fold_product.roc` | 40 | 80 |
| `codex_roc_fold_sum.roc` | 40 | 82 |
| `codex_roc_iter_drop_if.roc` | 62 | 72 |
| `codex_roc_iter_keep_if.roc` | 62 | 78 |
| `codex_roc_iter_map.roc` | 65 | 90 |
| `codex_roc_recursive_var.roc` | 37 | 99 |
| `codex_roc_returned_closure.roc` | 44 | 64 |
| `codex_rv_arg_order.roc` | 48 | 103 |
| `codex_rv_big_literal.roc` | 46 | 126 |
| `codex_rv_frameless_imm.roc` | 81 | 126 |
| `codex_rv_frameless_temp.roc` | 51 | 88 |
| `codex_rv_param_bind.roc` | 51 | 121 |
| `codex_rv_param_order.roc` | 61 | 103 |
| `codex_s7comm_encode.roc` | 84 | 34 |
| `codex_scope_console.roc` | 36 | 101 |
| `codex_scope_let_arm_global.roc` | 40 | 89 |
| `codex_sensor_data.roc` | 50 | 97 |
| `codex_simplify_check.roc` | 105 | 112 |
| `codex_sixlowpan_encode.roc` | 53 | 51 |
| `codex_sntp_encode.roc` | 66 | 66 |
| `codex_sort_test.roc` | 68 | 119 |
| `codex_sound_test.roc` | 1082 | 211 |
| `codex_stats_wrap_test.roc` | 88 | 166 |
| `codex_string_escape_quote.roc` | 31 | 87 |
| `codex_sum_field_eq.roc` | 66 | 119 |
| `codex_synth_test.roc` | 1069 | 178 |
| `codex_tco_bitop_loop.roc` | 87 | 114 |
| `codex_tco_direct_arg_reads.roc` | 38 | 101 |
| `codex_tco_framed_append.roc` | 54 | 102 |
| `codex_tco_nested_if.roc` | 38 | 89 |
| `codex_tco_shuffle_spill.roc` | 49 | 94 |
| `codex_text_append_alias.roc` | 40 | 165 |
| `codex_text_eq_branches.roc` | 92 | 111 |
| `codex_text_fold_indexed.roc` | 59 | 102 |
| `codex_text_helper_native.roc` | 57 | 259 |
| `codex_thumb2_encoder.roc` | 120 | 200 |
| `codex_tuple_syntax.roc` | 73 | 109 |
| `codex_tvar_in_declared_type.roc` | 35 | 92 |
| `codex_type_checker_test.roc` | 43 | 64 |
| `codex_ui_sound_test.roc` | 101 | 151 |
| `codex_ui@theme_ink_on.roc` | 77 | 150 |
| `codex_unconstrained_empty_list.roc` | 52 | 110 |
| `codex_unconstrained_nullary_sum.roc` | 60 | 98 |
| `codex_unit_family.roc` | 72 | 94 |
| `codex_unit_family_mixed.roc` | 104 | 108 |
| `codex_unit_smoke.roc` | 61 | 86 |
| `codex_units_foreword.roc` | 1040 | 153 |
| `codex_usb_desc_guard.roc` | 65 | 223 |
| `codex_usb_test.roc` | 72 | 122 |
| `codex_wavelet_sort_aliasing.roc` | 42 | 101 |
| `codex_when_arm_nontail.roc` | 83 | 93 |
| `codex_when_arm_tail_call.roc` | 72 | 96 |
| `codex_when_bool_cross.roc` | 61 | 89 |
| `codex_when_bool_pattern.roc` | 80 | 112 |
| `codex_when_generic_field.roc` | 72 | 92 |
| `codex_zigbee_encode.roc` | 53 | 35 |
