# Udp -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Ethernet

Udp :: [].{
	UdpDatagram := { src_port : I64, dst_port : I64, payload : List(I64) }.{
		is_eq : Udp.UdpDatagram, Udp.UdpDatagram -> Bool
		is_eq = |a, b| eq_UdpDatagram(a, b)
	}
	UdpFrame := { src_ip : List(I64), dst_ip : List(I64), datagram : Udp.UdpDatagram, valid : Bool }.{
		is_eq : Udp.UdpFrame, Udp.UdpFrame -> Bool
		is_eq = |a, b| eq_UdpFrame(a, b)
	}

	udp_header_size : I64
	udp_header_size = 8

	udp_build : I64, I64, List(I64) -> List(I64)
	udp_build = |src_port, dst_port, payload| ({
		len : I64
		len = (udp_header_size + U64.to_i64_wrap(List.len(payload)))
		List.concat(List.concat(List.concat(List.concat(Ethernet.write_be16(src_port), Ethernet.write_be16(dst_port)), Ethernet.write_be16(len)), [0, 0]), payload)
	})

	udp_pseudo_header : List(I64), List(I64), I64 -> List(I64)
	udp_pseudo_header = |src_ip, dst_ip, udp_len| List.concat(List.concat(List.concat(src_ip, dst_ip), [0, Ethernet.ip_proto_udp]), Ethernet.write_be16(udp_len))

	udp_sum : List(I64), List(I64), List(I64) -> I64
	udp_sum = |udp_bytes, src_ip, dst_ip| ({
		udp_len : I64
		udp_len = U64.to_i64_wrap(List.len(udp_bytes))
		pseudo : List(I64)
		pseudo = udp_pseudo_header(src_ip, dst_ip, udp_len)
		padded : List(I64)
		padded = (if (I64.bitwise_and(udp_len, 1) == 1) { List.concat(List.concat(pseudo, udp_bytes), [0]) } else { List.concat(pseudo, udp_bytes) })
		Ethernet.ip_checksum(padded, 0, U64.to_i64_wrap(List.len(padded)), 0)
	})

	udp_with_checksum : List(I64), List(I64), List(I64) -> List(I64)
	udp_with_checksum = |udp_bytes, src_ip, dst_ip| ({
		raw : I64
		raw = udp_sum(udp_bytes, src_ip, dst_ip)
		cksum : I64
		cksum = (if (raw == 0) { 65535 } else { raw })
		udp_bytes_v1 : List(I64)
		udp_bytes_v1 = (List.set(udp_bytes, I64.to_u64_wrap(6), I64.shr_zf_wrap(cksum, I64.to_u8_wrap(8))) ?? crash("list-set-at past the end"))
		(List.set(udp_bytes_v1, I64.to_u64_wrap(7), I64.bitwise_and(cksum, 255)) ?? crash("list-set-at past the end"))
	})

	udp_checksum_valid : List(I64), List(I64), List(I64) -> Bool
	udp_checksum_valid = |udp_bytes, src_ip, dst_ip| (if (U64.to_i64_wrap(List.len(udp_bytes)) < udp_header_size) { False } else { (if (Ethernet.read_be16(udp_bytes, 4) != U64.to_i64_wrap(List.len(udp_bytes))) { False } else { (if (Ethernet.read_be16(udp_bytes, 6) == 0) { True } else { (udp_sum(udp_bytes, src_ip, dst_ip) == 0) }) }) })

	udp_parse : List(I64) -> Udp.UdpDatagram
	udp_parse = |data| ({
		plen : I64
		plen = U64.to_i64_wrap(List.len(data))
		(if (plen < udp_header_size) { Udp.UdpDatagram.{ src_port: 0, dst_port: 0, payload: [] } } else { ({
			payload_len : I64
			payload_len = (Ethernet.read_be16(data, 4) - udp_header_size)
			Udp.UdpDatagram.{ src_port: Ethernet.read_be16(data, 0), dst_port: Ethernet.read_be16(data, 2), payload: udp_extract_payload(data, udp_header_size, (udp_header_size + payload_len), []) }
		}) })
	})

	udp_extract_payload : List(I64), I64, I64, List(I64) -> List(I64)
	udp_extract_payload = |data, i, stop, acc| (if (i >= stop) { acc } else { (if (i >= U64.to_i64_wrap(List.len(data))) { acc } else { udp_extract_payload(data, (i + 1), stop, List.append(acc, (List.get(data, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))) }) })

	udp_build_ip_packet : List(I64), List(I64), I64, I64, List(I64) -> List(I64)
	udp_build_ip_packet = |src_ip, dst_ip, src_port, dst_port, payload| ({
		udp_with_checksum_v1 : List(I64)
		udp_with_checksum_v1 = udp_with_checksum(udp_build(src_port, dst_port, payload), src_ip, dst_ip)
		udp_data : List(I64)
		udp_data = udp_with_checksum_v1
		Ethernet.ip_build_packet(src_ip, dst_ip, Ethernet.ip_proto_udp, udp_data)
	})

	udp_build_frame : List(I64), List(I64), List(I64), List(I64), I64, I64, List(I64) -> List(I64)
	udp_build_frame = |dst_mac, src_mac, src_ip, dst_ip, src_port, dst_port, payload| ({
		ip_pkt : List(I64)
		ip_pkt = udp_build_ip_packet(src_ip, dst_ip, src_port, dst_port, payload)
		Ethernet.eth_build_frame(dst_mac, src_mac, Ethernet.eth_type_ipv4, ip_pkt)
	})

	eq_UdpDatagram : Udp.UdpDatagram, Udp.UdpDatagram -> Bool
	eq_UdpDatagram = |ex, ey| (((ex.src_port == ey.src_port) and (ex.dst_port == ey.dst_port)) and (ex.payload == ey.payload))

	eq_UdpFrame : Udp.UdpFrame, Udp.UdpFrame -> Bool
	eq_UdpFrame = |ex, ey| ((((ex.src_ip == ey.src_ip) and (ex.dst_ip == ey.dst_ip)) and eq_UdpDatagram(ex.datagram, ey.datagram)) and (ex.valid == ey.valid))
}
