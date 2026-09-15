# Ethernet -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

Ethernet :: [].{
	ArpPacket : { op : I64, sender_mac : List(I64), sender_ip : List(I64), target_mac : List(I64), target_ip : List(I64) }

	eth_type_ipv4 : I64
	eth_type_ipv4 = 2048

	eth_type_arp : I64
	eth_type_arp = 2054

	eth_header_size : I64
	eth_header_size = 14

	eth_max_frame : I64
	eth_max_frame = 1518

	arp_hw_ethernet : I64
	arp_hw_ethernet = 1

	arp_op_request : I64
	arp_op_request = 1

	arp_op_reply : I64
	arp_op_reply = 2

	arp_packet_size : I64
	arp_packet_size = 28

	ip_version_ihl : I64
	ip_version_ihl = 69

	ip_proto_icmp : I64
	ip_proto_icmp = 1

	ip_proto_tcp : I64
	ip_proto_tcp = 6

	ip_proto_udp : I64
	ip_proto_udp = 17

	ip_header_size : I64
	ip_header_size = 20

	mac_bytes : I64, I64, I64, I64, I64, I64 -> List(I64)
	mac_bytes = |a, b, c, d, e, f| [a, b, c, d, e, f]

	mac_broadcast : List(I64)
	mac_broadcast = [255, 255, 255, 255, 255, 255]

	mac_equal : List(I64), List(I64) -> Bool
	mac_equal = |a, b| (((((((List.get(a, I64.to_u64_wrap(0)) ?? crash("list-at out of range")) == (List.get(b, I64.to_u64_wrap(0)) ?? crash("list-at out of range"))) and ((List.get(a, I64.to_u64_wrap(1)) ?? crash("list-at out of range")) == (List.get(b, I64.to_u64_wrap(1)) ?? crash("list-at out of range")))) and ((List.get(a, I64.to_u64_wrap(2)) ?? crash("list-at out of range")) == (List.get(b, I64.to_u64_wrap(2)) ?? crash("list-at out of range")))) and ((List.get(a, I64.to_u64_wrap(3)) ?? crash("list-at out of range")) == (List.get(b, I64.to_u64_wrap(3)) ?? crash("list-at out of range")))) and ((List.get(a, I64.to_u64_wrap(4)) ?? crash("list-at out of range")) == (List.get(b, I64.to_u64_wrap(4)) ?? crash("list-at out of range")))) and ((List.get(a, I64.to_u64_wrap(5)) ?? crash("list-at out of range")) == (List.get(b, I64.to_u64_wrap(5)) ?? crash("list-at out of range"))))

	ip_bytes : I64, I64, I64, I64 -> List(I64)
	ip_bytes = |a, b, c, d| [a, b, c, d]

	ip_equal : List(I64), List(I64) -> Bool
	ip_equal = |a, b| (((((List.get(a, I64.to_u64_wrap(0)) ?? crash("list-at out of range")) == (List.get(b, I64.to_u64_wrap(0)) ?? crash("list-at out of range"))) and ((List.get(a, I64.to_u64_wrap(1)) ?? crash("list-at out of range")) == (List.get(b, I64.to_u64_wrap(1)) ?? crash("list-at out of range")))) and ((List.get(a, I64.to_u64_wrap(2)) ?? crash("list-at out of range")) == (List.get(b, I64.to_u64_wrap(2)) ?? crash("list-at out of range")))) and ((List.get(a, I64.to_u64_wrap(3)) ?? crash("list-at out of range")) == (List.get(b, I64.to_u64_wrap(3)) ?? crash("list-at out of range"))))

	write_be16 : I64 -> List(I64)
	write_be16 = |v| [I64.bitwise_and(I64.shr_wrap(v, I64.to_u8_wrap(8)), 255), I64.bitwise_and(v, 255)]

	read_be16 : List(I64), I64 -> I64
	read_be16 = |buf, off| (if ((off + 2) > U64.to_i64_wrap(List.len(buf))) { 0 } else { I64.bitwise_or(I64.shl_wrap((List.get(buf, I64.to_u64_wrap(off)) ?? crash("list-at out of range")), I64.to_u8_wrap(8)), (List.get(buf, I64.to_u64_wrap((off + 1))) ?? crash("list-at out of range"))) })

	eth_build_frame : List(I64), List(I64), I64, List(I64) -> List(I64)
	eth_build_frame = |dst_mac, src_mac, ethertype, payload| List.concat(List.concat(List.concat(dst_mac, src_mac), write_be16(ethertype)), payload)

	eth_dst_mac : List(I64) -> List(I64)
	eth_dst_mac = |frame| (if (U64.to_i64_wrap(List.len(frame)) < 6) { [0, 0, 0, 0, 0, 0] } else { [(List.get(frame, I64.to_u64_wrap(0)) ?? crash("list-at out of range")), (List.get(frame, I64.to_u64_wrap(1)) ?? crash("list-at out of range")), (List.get(frame, I64.to_u64_wrap(2)) ?? crash("list-at out of range")), (List.get(frame, I64.to_u64_wrap(3)) ?? crash("list-at out of range")), (List.get(frame, I64.to_u64_wrap(4)) ?? crash("list-at out of range")), (List.get(frame, I64.to_u64_wrap(5)) ?? crash("list-at out of range"))] })

	eth_src_mac : List(I64) -> List(I64)
	eth_src_mac = |frame| (if (U64.to_i64_wrap(List.len(frame)) < 12) { [0, 0, 0, 0, 0, 0] } else { [(List.get(frame, I64.to_u64_wrap(6)) ?? crash("list-at out of range")), (List.get(frame, I64.to_u64_wrap(7)) ?? crash("list-at out of range")), (List.get(frame, I64.to_u64_wrap(8)) ?? crash("list-at out of range")), (List.get(frame, I64.to_u64_wrap(9)) ?? crash("list-at out of range")), (List.get(frame, I64.to_u64_wrap(10)) ?? crash("list-at out of range")), (List.get(frame, I64.to_u64_wrap(11)) ?? crash("list-at out of range"))] })

	eth_ethertype : List(I64) -> I64
	eth_ethertype = |frame| (if (U64.to_i64_wrap(List.len(frame)) < 14) { 0 } else { read_be16(frame, 12) })

	eth_payload : List(I64) -> List(I64)
	eth_payload = |frame| eth_payload_loop(frame, eth_header_size, U64.to_i64_wrap(List.len(frame)), [])

	eth_payload_loop : List(I64), I64, I64, List(I64) -> List(I64)
	eth_payload_loop = |frame, i, len, acc| (if (i >= len) { acc } else { eth_payload_loop(frame, (i + 1), len, List.append(acc, (List.get(frame, I64.to_u64_wrap(i)) ?? crash("list-at out of range")))) })

	arp_build_request : List(I64), List(I64), List(I64) -> List(I64)
	arp_build_request = |src_mac, src_ip, target_ip| ({
		payload = List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(write_be16(arp_hw_ethernet), write_be16(eth_type_ipv4)), [6, 4]), write_be16(arp_op_request)), src_mac), src_ip), [0, 0, 0, 0, 0, 0]), target_ip)
		eth_build_frame(mac_broadcast, src_mac, eth_type_arp, payload)
	})

	arp_build_reply : List(I64), List(I64), List(I64), List(I64), List(I64) -> List(I64)
	arp_build_reply = |src_mac, src_ip, dst_mac, dst_ip, reply_mac| ({
		payload = List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(write_be16(arp_hw_ethernet), write_be16(eth_type_ipv4)), [6, 4]), write_be16(arp_op_reply)), reply_mac), src_ip), dst_mac), dst_ip)
		eth_build_frame(dst_mac, src_mac, eth_type_arp, payload)
	})

	arp_parse : List(I64) -> Ethernet.ArpPacket
	arp_parse = |payload| (if (U64.to_i64_wrap(List.len(payload)) < 28) { { op: 1, sender_mac: [0, 0, 0, 0, 0, 0], sender_ip: [0, 0, 0, 0], target_mac: [0, 0, 0, 0, 0, 0], target_ip: [0, 0, 0, 0] } } else { { op: read_be16(payload, 6), sender_mac: [(List.get(payload, I64.to_u64_wrap(8)) ?? crash("list-at out of range")), (List.get(payload, I64.to_u64_wrap(9)) ?? crash("list-at out of range")), (List.get(payload, I64.to_u64_wrap(10)) ?? crash("list-at out of range")), (List.get(payload, I64.to_u64_wrap(11)) ?? crash("list-at out of range")), (List.get(payload, I64.to_u64_wrap(12)) ?? crash("list-at out of range")), (List.get(payload, I64.to_u64_wrap(13)) ?? crash("list-at out of range"))], sender_ip: [(List.get(payload, I64.to_u64_wrap(14)) ?? crash("list-at out of range")), (List.get(payload, I64.to_u64_wrap(15)) ?? crash("list-at out of range")), (List.get(payload, I64.to_u64_wrap(16)) ?? crash("list-at out of range")), (List.get(payload, I64.to_u64_wrap(17)) ?? crash("list-at out of range"))], target_mac: [(List.get(payload, I64.to_u64_wrap(18)) ?? crash("list-at out of range")), (List.get(payload, I64.to_u64_wrap(19)) ?? crash("list-at out of range")), (List.get(payload, I64.to_u64_wrap(20)) ?? crash("list-at out of range")), (List.get(payload, I64.to_u64_wrap(21)) ?? crash("list-at out of range")), (List.get(payload, I64.to_u64_wrap(22)) ?? crash("list-at out of range")), (List.get(payload, I64.to_u64_wrap(23)) ?? crash("list-at out of range"))], target_ip: [(List.get(payload, I64.to_u64_wrap(24)) ?? crash("list-at out of range")), (List.get(payload, I64.to_u64_wrap(25)) ?? crash("list-at out of range")), (List.get(payload, I64.to_u64_wrap(26)) ?? crash("list-at out of range")), (List.get(payload, I64.to_u64_wrap(27)) ?? crash("list-at out of range"))] } })

	ip_sum : List(I64), I64, I64, I64 -> I64
	ip_sum = |buf, i, len, sum| (if (i >= len) { sum } else { (if ((i + 1) >= len) { (sum + I64.shl_wrap((List.get(buf, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), I64.to_u8_wrap(8))) } else { ip_sum(buf, (i + 2), len, (sum + read_be16(buf, i))) }) })

	ip_checksum : List(I64), I64, I64, I64 -> I64
	ip_checksum = |hdr, i, len, sum| ({
		total = ip_sum(hdr, i, len, sum)
		folded = (I64.bitwise_and(total, 65535) + I64.shr_zf_wrap(total, I64.to_u8_wrap(16)))
		folded2 = (I64.bitwise_and(folded, 65535) + I64.shr_zf_wrap(folded, I64.to_u8_wrap(16)))
		I64.bitwise_and(I64.bitwise_xor(folded2, 65535), 65535)
	})

	ip_length_valid_at : List(I64), I64 -> Bool
	ip_length_valid_at = |pkt, off| (if ((U64.to_i64_wrap(List.len(pkt)) - off) < ip_header_size) { False } else { (if (ip_total_length_at(pkt, off) < ip_header_size) { False } else { (ip_total_length_at(pkt, off) <= (U64.to_i64_wrap(List.len(pkt)) - off)) }) })

	ip_length_valid : List(I64) -> Bool
	ip_length_valid = |pkt| ip_length_valid_at(pkt, 0)

	ip_header_valid_at : List(I64), I64 -> Bool
	ip_header_valid_at = |pkt, off| (if ((U64.to_i64_wrap(List.len(pkt)) - off) < ip_header_size) { False } else { (ip_checksum(pkt, off, (off + ip_header_size), 0) == 0) })

	ip_header_valid : List(I64) -> Bool
	ip_header_valid = |pkt| ip_header_valid_at(pkt, 0)

	ip_build_packet : List(I64), List(I64), I64, List(I64) -> List(I64)
	ip_build_packet = |src_ip, dst_ip, proto, payload| ({
		total_len = (ip_header_size + U64.to_i64_wrap(List.len(payload)))
		hdr = List.concat(List.concat(List.concat(List.concat([ip_version_ihl, 0], write_be16(total_len)), [0, 0, 0, 0, 64, proto, 0, 0]), src_ip), dst_ip)
		cksum = ip_checksum(hdr, 0, ip_header_size, 0)
		hdr_final = List.concat(List.concat(List.concat(List.concat(List.concat([ip_version_ihl, 0], write_be16(total_len)), [0, 0, 0, 0, 64, proto]), write_be16(cksum)), src_ip), dst_ip)
		List.concat(hdr_final, payload)
	})

	ip_src_at : List(I64), I64 -> List(I64)
	ip_src_at = |pkt, off| [(List.get(pkt, I64.to_u64_wrap((off + 12))) ?? crash("list-at out of range")), (List.get(pkt, I64.to_u64_wrap((off + 13))) ?? crash("list-at out of range")), (List.get(pkt, I64.to_u64_wrap((off + 14))) ?? crash("list-at out of range")), (List.get(pkt, I64.to_u64_wrap((off + 15))) ?? crash("list-at out of range"))]

	ip_src : List(I64) -> List(I64)
	ip_src = |pkt| ip_src_at(pkt, 0)

	ip_dst_at : List(I64), I64 -> List(I64)
	ip_dst_at = |pkt, off| [(List.get(pkt, I64.to_u64_wrap((off + 16))) ?? crash("list-at out of range")), (List.get(pkt, I64.to_u64_wrap((off + 17))) ?? crash("list-at out of range")), (List.get(pkt, I64.to_u64_wrap((off + 18))) ?? crash("list-at out of range")), (List.get(pkt, I64.to_u64_wrap((off + 19))) ?? crash("list-at out of range"))]

	ip_dst : List(I64) -> List(I64)
	ip_dst = |pkt| ip_dst_at(pkt, 0)

	ip_proto_at : List(I64), I64 -> I64
	ip_proto_at = |pkt, off| (List.get(pkt, I64.to_u64_wrap((off + 9))) ?? crash("list-at out of range"))

	ip_proto : List(I64) -> I64
	ip_proto = |pkt| ip_proto_at(pkt, 0)

	ip_total_length_at : List(I64), I64 -> I64
	ip_total_length_at = |pkt, off| read_be16(pkt, (off + 2))

	ip_total_length : List(I64) -> I64
	ip_total_length = |pkt| ip_total_length_at(pkt, 0)

	ip_payload : List(I64) -> List(I64)
	ip_payload = |pkt| eth_payload_loop(pkt, ip_header_size, read_be16(pkt, 2), [])
}
