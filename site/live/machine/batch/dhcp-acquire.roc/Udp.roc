# Udp -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Ethernet

Udp :: [].{
	UdpDatagram : { src_port : I64, dst_port : I64, payload : List(I64) }
	UdpFrame : { src_ip : List(I64), dst_ip : List(I64), datagram : Udp.UdpDatagram, valid : Bool }

	udp_header_size : I64
	udp_header_size = 8

	udp_build : I64, I64, List(I64) -> List(I64)
	udp_build = |src_port, dst_port, payload| ({
		len = (udp_header_size + U64.to_i64_wrap(List.len(payload)))
		List.concat(List.concat(List.concat(List.concat(Ethernet.write_be16(src_port), Ethernet.write_be16(dst_port)), Ethernet.write_be16(len)), [0, 0]), payload)
	})

	udp_pseudo_header : List(I64), List(I64), I64 -> List(I64)
	udp_pseudo_header = |src_ip, dst_ip, udp_len| List.concat(List.concat(List.concat(src_ip, dst_ip), [0, Ethernet.ip_proto_udp]), Ethernet.write_be16(udp_len))

	udp_sum : List(I64), List(I64), List(I64) -> I64
	udp_sum = |udp_bytes, src_ip, dst_ip| ({
		udp_len = U64.to_i64_wrap(List.len(udp_bytes))
		pseudo = udp_pseudo_header(src_ip, dst_ip, udp_len)
		padded = (if (I64.bitwise_and(udp_len, 1) == 1) { List.concat(List.concat(pseudo, udp_bytes), [0]) } else { List.concat(pseudo, udp_bytes) })
		Ethernet.ip_checksum(padded, 0, U64.to_i64_wrap(List.len(padded)), 0)
	})

	udp_with_checksum : List(I64), List(I64), List(I64) -> List(I64)
	udp_with_checksum = |udp_bytes, src_ip, dst_ip| ({
		raw = udp_sum(udp_bytes, src_ip, dst_ip)
		cksum = (if (raw == 0) { 65535 } else { raw })
		(List.set((List.set(udp_bytes, I64.to_u64_wrap(6), I64.shr_zf_wrap(cksum, I64.to_u8_wrap(8))) ?? crash("list-set-at past the end")), I64.to_u64_wrap(7), I64.bitwise_and(cksum, 255)) ?? crash("list-set-at past the end"))
	})

	udp_checksum_valid : List(I64), List(I64), List(I64) -> Bool
	udp_checksum_valid = |udp_bytes, src_ip, dst_ip| (if (U64.to_i64_wrap(List.len(udp_bytes)) < udp_header_size) { False } else { (if (Ethernet.read_be16(udp_bytes, 4) != U64.to_i64_wrap(List.len(udp_bytes))) { False } else { (if (Ethernet.read_be16(udp_bytes, 6) == 0) { True } else { (udp_sum(udp_bytes, src_ip, dst_ip) == 0) }) }) })

	udp_parse : List(I64) -> Udp.UdpDatagram
	udp_parse = |data| ({
		plen = U64.to_i64_wrap(List.len(data))
		(if (plen < udp_header_size) { { src_port: 0, dst_port: 0, payload: [] } } else { ({
			payload_len = (Ethernet.read_be16(data, 4) - udp_header_size)
			{ src_port: Ethernet.read_be16(data, 0), dst_port: Ethernet.read_be16(data, 2), payload: udp_extract_payload(data, udp_header_size, (udp_header_size + payload_len), []) }
		}) })
	})

	udp_extract_payload : List(I64), I64, I64, List(I64) -> List(I64)
	udp_extract_payload = |data, i, stop, acc| (if (i >= stop) { acc } else { (if (i >= U64.to_i64_wrap(List.len(data))) { acc } else { udp_extract_payload(data, (i + 1), stop, List.append(acc, (List.get(data, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))) }) })

	udp_build_ip_packet : List(I64), List(I64), I64, I64, List(I64) -> List(I64)
	udp_build_ip_packet = |src_ip, dst_ip, src_port, dst_port, payload| ({
		udp_data = udp_with_checksum(udp_build(src_port, dst_port, payload), src_ip, dst_ip)
		Ethernet.ip_build_packet(src_ip, dst_ip, Ethernet.ip_proto_udp, udp_data)
	})

	udp_build_frame : List(I64), List(I64), List(I64), List(I64), I64, I64, List(I64) -> List(I64)
	udp_build_frame = |dst_mac, src_mac, src_ip, dst_ip, src_port, dst_port, payload| ({
		ip_pkt = udp_build_ip_packet(src_ip, dst_ip, src_port, dst_port, payload)
		Ethernet.eth_build_frame(dst_mac, src_mac, Ethernet.eth_type_ipv4, ip_pkt)
	})

	udp_parse_ip_payload : List(I64), List(I64), List(I64) -> Udp.UdpFrame
	udp_parse_ip_payload = |ip_payload, src_ip, dst_ip| (if (U64.to_i64_wrap(List.len(ip_payload)) < udp_header_size) { { src_ip: src_ip, dst_ip: dst_ip, datagram: { src_port: 0, dst_port: 0, payload: [] }, valid: False } } else { { src_ip: src_ip, dst_ip: dst_ip, datagram: udp_parse(ip_payload), valid: True } })

	udp_datagram_length : Udp.UdpDatagram -> I64
	udp_datagram_length = |d| U64.to_i64_wrap(List.len(d.payload))

	format_udp_datagram : Udp.UdpDatagram -> Str
	format_udp_datagram = |d| Str.concat(Str.concat(Str.concat(Str.concat(I64.to_str(d.src_port), "->"), I64.to_str(d.dst_port)), " len="), I64.to_str(udp_datagram_length(d)))

	format_udp_frame : Udp.UdpFrame -> Str
	format_udp_frame = |f| Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(udp_format_ip(f.src_ip), ":"), I64.to_str(f.datagram.src_port)), " -> "), udp_format_ip(f.dst_ip)), ":"), I64.to_str(f.datagram.dst_port)), " len="), I64.to_str(udp_datagram_length(f.datagram)))

	udp_format_ip : List(I64) -> Str
	udp_format_ip = |ip| Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(I64.to_str((List.get(ip, I64.to_u64_wrap(0)) ?? crash("list-at out of range"))), "."), I64.to_str((List.get(ip, I64.to_u64_wrap(1)) ?? crash("list-at out of range")))), "."), I64.to_str((List.get(ip, I64.to_u64_wrap(2)) ?? crash("list-at out of range")))), "."), I64.to_str((List.get(ip, I64.to_u64_wrap(3)) ?? crash("list-at out of range"))))
}
