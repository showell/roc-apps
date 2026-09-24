# Capability -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import CceText

Capability :: [].{
	CapSpec : { cs_name : CceText, cs_id : I64, cs_base_bit : I64, cs_read_bit : I64, cs_write_bit : I64, cs_extra_bits : List(I64) }

	cap_console : I64
	cap_console = 0

	cap_concurrent : I64
	cap_concurrent = 3

	cap_console_read : I64
	cap_console_read = 4

	cap_console_write : I64
	cap_console_write = 5

	cap_filesystem_read : I64
	cap_filesystem_read = 6

	cap_filesystem_write : I64
	cap_filesystem_write = 7

	cap_network_read : I64
	cap_network_read = 8

	cap_network_write : I64
	cap_network_write = 9

	cap_block_device : I64
	cap_block_device = 10

	cap_ipc : I64
	cap_ipc = 11

	cap_process_create : I64
	cap_process_create = 12

	cap_capability_admin : I64
	cap_capability_admin = 14

	cap_identity : I64
	cap_identity = 15

	cap_device : I64
	cap_device = 16

	cap_gpu_compute : I64
	cap_gpu_compute = 17

	cap_gpu_memory : I64
	cap_gpu_memory = 18

	cap_camera : I64
	cap_camera = 19

	cap_microphone : I64
	cap_microphone = 20

	cap_location : I64
	cap_location = 21

	cap_sensors : I64
	cap_sensors = 22

	cap_display : I64
	cap_display = 23

	cap_flash : I64
	cap_flash = 24

	cap_audio : I64
	cap_audio = 25

	cap_process : I64
	cap_process = 26

	cap_gpio : I64
	cap_gpio = 27

	cap_uart : I64
	cap_uart = 28

	cap_spi : I64
	cap_spi = 29

	cap_i2c : I64
	cap_i2c = 1

	cap_adc : I64
	cap_adc = 2

	cap_power : I64
	cap_power = 13

	cap_rng : I64
	cap_rng = 30

	cap_dir_read : I64
	cap_dir_read = 0

	cap_dir_write : I64
	cap_dir_write = 1

	cap_dir_readwrite : I64
	cap_dir_readwrite = 2

	capability_table : List(Capability.CapSpec)
	capability_table = [{ cs_name: "Console", cs_id: 0, cs_base_bit: cap_console, cs_read_bit: cap_console_read, cs_write_bit: cap_console_write, cs_extra_bits: [] }, { cs_name: "FileSystem", cs_id: 1, cs_base_bit: (0 - 1), cs_read_bit: cap_filesystem_read, cs_write_bit: cap_filesystem_write, cs_extra_bits: [] }, { cs_name: "Network", cs_id: 2, cs_base_bit: (0 - 1), cs_read_bit: cap_network_read, cs_write_bit: cap_network_write, cs_extra_bits: [] }, { cs_name: "Concurrent", cs_id: 3, cs_base_bit: cap_concurrent, cs_read_bit: (0 - 1), cs_write_bit: (0 - 1), cs_extra_bits: [cap_ipc, cap_process_create] }, { cs_name: "Device", cs_id: 4, cs_base_bit: cap_block_device, cs_read_bit: (0 - 1), cs_write_bit: (0 - 1), cs_extra_bits: [cap_device] }, { cs_name: "Gpu.Compute", cs_id: 5, cs_base_bit: cap_gpu_compute, cs_read_bit: (0 - 1), cs_write_bit: (0 - 1), cs_extra_bits: [] }, { cs_name: "Gpu.Memory", cs_id: 6, cs_base_bit: cap_gpu_memory, cs_read_bit: (0 - 1), cs_write_bit: (0 - 1), cs_extra_bits: [] }, { cs_name: "Identity", cs_id: 7, cs_base_bit: cap_identity, cs_read_bit: (0 - 1), cs_write_bit: (0 - 1), cs_extra_bits: [] }, { cs_name: "Capability", cs_id: 8, cs_base_bit: cap_capability_admin, cs_read_bit: (0 - 1), cs_write_bit: (0 - 1), cs_extra_bits: [] }, { cs_name: "Gpu", cs_id: 9, cs_base_bit: (0 - 1), cs_read_bit: (0 - 1), cs_write_bit: (0 - 1), cs_extra_bits: [cap_gpu_compute, cap_gpu_memory] }, { cs_name: "Camera", cs_id: 10, cs_base_bit: cap_camera, cs_read_bit: (0 - 1), cs_write_bit: (0 - 1), cs_extra_bits: [] }, { cs_name: "Microphone", cs_id: 11, cs_base_bit: cap_microphone, cs_read_bit: (0 - 1), cs_write_bit: (0 - 1), cs_extra_bits: [] }, { cs_name: "Location", cs_id: 12, cs_base_bit: cap_location, cs_read_bit: (0 - 1), cs_write_bit: (0 - 1), cs_extra_bits: [] }, { cs_name: "Sensors", cs_id: 13, cs_base_bit: cap_sensors, cs_read_bit: (0 - 1), cs_write_bit: (0 - 1), cs_extra_bits: [] }, { cs_name: "Display", cs_id: 14, cs_base_bit: cap_display, cs_read_bit: (0 - 1), cs_write_bit: (0 - 1), cs_extra_bits: [] }, { cs_name: "Flash", cs_id: 15, cs_base_bit: cap_flash, cs_read_bit: (0 - 1), cs_write_bit: (0 - 1), cs_extra_bits: [] }, { cs_name: "Audio", cs_id: 16, cs_base_bit: cap_audio, cs_read_bit: (0 - 1), cs_write_bit: (0 - 1), cs_extra_bits: [] }, { cs_name: "Process", cs_id: 17, cs_base_bit: cap_process, cs_read_bit: (0 - 1), cs_write_bit: (0 - 1), cs_extra_bits: [] }, { cs_name: "Gpio", cs_id: 18, cs_base_bit: cap_gpio, cs_read_bit: (0 - 1), cs_write_bit: (0 - 1), cs_extra_bits: [] }, { cs_name: "Uart", cs_id: 19, cs_base_bit: cap_uart, cs_read_bit: (0 - 1), cs_write_bit: (0 - 1), cs_extra_bits: [] }, { cs_name: "Spi", cs_id: 20, cs_base_bit: cap_spi, cs_read_bit: (0 - 1), cs_write_bit: (0 - 1), cs_extra_bits: [] }, { cs_name: "I2c", cs_id: 21, cs_base_bit: cap_i2c, cs_read_bit: (0 - 1), cs_write_bit: (0 - 1), cs_extra_bits: [] }, { cs_name: "Adc", cs_id: 22, cs_base_bit: cap_adc, cs_read_bit: (0 - 1), cs_write_bit: (0 - 1), cs_extra_bits: [] }, { cs_name: "Power", cs_id: 23, cs_base_bit: cap_power, cs_read_bit: (0 - 1), cs_write_bit: (0 - 1), cs_extra_bits: [] }, { cs_name: "Rng", cs_id: 24, cs_base_bit: cap_rng, cs_read_bit: (0 - 1), cs_write_bit: (0 - 1), cs_extra_bits: [] }]

	cap_or_bits : List(I64), I64, I64, I64 -> I64
	cap_or_bits = |bs, i, len, acc| (if (i >= len) { acc } else { cap_or_bits(bs, (i + 1), len, I64.bitwise_or(acc, I64.shl_wrap(1, I64.to_u8_wrap((List.get(bs, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))))) })

	cap_dir_bits : I64, I64, I64 -> I64
	cap_dir_bits = |dir, read_bit, write_bit| (if (dir == cap_dir_read) { I64.shl_wrap(1, I64.to_u8_wrap(read_bit)) } else { (if (dir == cap_dir_write) { I64.shl_wrap(1, I64.to_u8_wrap(write_bit)) } else { I64.bitwise_or(I64.shl_wrap(1, I64.to_u8_wrap(read_bit)), I64.shl_wrap(1, I64.to_u8_wrap(write_bit))) }) })

	cap_bits_for_spec : Capability.CapSpec, I64 -> I64
	cap_bits_for_spec = |spec, dir| ({
		base = (if (spec.cs_base_bit >= 0) { I64.shl_wrap(1, I64.to_u8_wrap(spec.cs_base_bit)) } else { 0 })
		dirb = (if (spec.cs_read_bit >= 0) { cap_dir_bits(dir, spec.cs_read_bit, spec.cs_write_bit) } else { 0 })
		extra = cap_or_bits(spec.cs_extra_bits, 0, U64.to_i64_wrap(List.len(spec.cs_extra_bits)), 0)
		I64.bitwise_or(base, I64.bitwise_or(dirb, extra))
	})

	cap_find_by_name : List(Capability.CapSpec), CceText, I64, I64 -> I64
	cap_find_by_name = |ts, n, i, len| (if (i >= len) { (0 - 1) } else { (if ((List.get(ts, I64.to_u64_wrap(i)) ?? crash("list-at out of range")).cs_name == n) { i } else { cap_find_by_name(ts, n, (i + 1), len) }) })

	cap_find_by_id : List(Capability.CapSpec), I64, I64, I64 -> I64
	cap_find_by_id = |ts, id, i, len| (if (i >= len) { (0 - 1) } else { (if ((List.get(ts, I64.to_u64_wrap(i)) ?? crash("list-at out of range")).cs_id == id) { i } else { cap_find_by_id(ts, id, (i + 1), len) }) })

	cap_id_for_name : CceText -> I64
	cap_id_for_name = |n| ({
		ts = capability_table
		i = cap_find_by_name(ts, n, 0, U64.to_i64_wrap(List.len(ts)))
		(if (i < 0) { (0 - 1) } else { (List.get(ts, I64.to_u64_wrap(i)) ?? crash("list-at out of range")).cs_id })
	})

	cap_bits_for_name : CceText, I64 -> I64
	cap_bits_for_name = |n, dir| ({
		ts = capability_table
		i = cap_find_by_name(ts, n, 0, U64.to_i64_wrap(List.len(ts)))
		(if (i < 0) { 0 } else { cap_bits_for_spec((List.get(ts, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), dir) })
	})

	cap_bits_for_id : I64, I64 -> I64
	cap_bits_for_id = |id, dir| ({
		ts = capability_table
		i = cap_find_by_id(ts, id, 0, U64.to_i64_wrap(List.len(ts)))
		(if (i < 0) { 0 } else { cap_bits_for_spec((List.get(ts, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), dir) })
	})

	cap_names_from : List(Capability.CapSpec), I64, I64, List(CceText) -> List(CceText)
	cap_names_from = |ts, i, len, acc| (if (i >= len) { acc } else { ({
		s = (List.get(ts, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		a1 = List.append(acc, s.cs_name)
		(if (s.cs_read_bit >= 0) { cap_names_from(ts, (i + 1), len, List.append(List.append(a1, CceText.concat(s.cs_name, ".Read")), CceText.concat(s.cs_name, ".Write"))) } else { cap_names_from(ts, (i + 1), len, a1) })
	}) })

	capability_names : List(CceText)
	capability_names = ({
		ts = capability_table
		cap_names_from(ts, 0, U64.to_i64_wrap(List.len(ts)), [])
	})
}
