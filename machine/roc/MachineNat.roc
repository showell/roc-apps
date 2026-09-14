# The NAT behind the wire, as codex-vm answers a frame the guest transmits
# (tools/codex-vm.c, nat_handle_tx). An ARP request answers from the gateway.
# A DHCP DISCOVER or REQUEST answers an offer or an ack of 10.0.2.15 for the
# lease, naming 10.0.2.2 as server and router and 10.0.2.3 for DNS.
#
# A DNS query reaches the host's resolver, a UDP datagram to any other port
# reaches a socket on the host, and a TCP SYN opens a connection to the host.
# This machine has none of those, so they stop the run by name. codex-vm
# drops every other frame, and so does this.

MachineNat :: [].{
	gateway_mac : List(U8)
	gateway_mac = [0x52, 0x55, 0x0A, 0x00, 0x02, 0x02]

	gateway : List(U8)
	gateway = [10, 0, 2, 2]

	guest : List(U8)
	guest = [10, 0, 2, 15]

	# The frames the NAT answers with, or what on the host the frame reaches.
	tx : List(U8), U64 -> [Replies(List(List(U8))), Host(Str)]
	tx = |f, lease| {
		len = List.len(f)
		ethertype = MachineNat.be16(f, 12)
		if len < 14 {
			Replies([])
		} else if ethertype == 0x0806 {
			Replies(if len < 42 { [] } else { [MachineNat.arp_reply(f)] })
		} else if ethertype != 0x0800 or len < 34 {
			Replies([])
		} else {
			ihl = U64.bitwise_and(MachineNat.byte(f, 14), 15) * 4
			proto = MachineNat.byte(f, 23)
			if proto == 6 and len >= 14 + ihl + 20 {
				flags = MachineNat.byte(f, 14 + ihl + 13)
				if U64.bitwise_and(flags, 0x12) == 0x02 { Host("a TCP connection to the host") } else { Replies([]) }
			} else if proto == 17 and len >= 14 + ihl + 8 {
				udp = 14 + ihl
				dport = MachineNat.be16(f, udp + 2)
				udp_len = MachineNat.be16(f, udp + 4)
				avail = len - udp - 8
				payload = if udp_len < 8 { 0 } else if udp_len - 8 > avail { avail } else { udp_len - 8 }
				if dport == 67 and payload > 0 {
					Replies(MachineNat.dhcp(f, List.sublist(f, { start: udp + 8, len: payload }), lease))
				} else if dport == 53 and payload > 0 {
					Host("the host's DNS resolver")
				} else {
					Host("a UDP socket on the host")
				}
			} else {
				Replies([])
			}
		}
	}

	arp_reply : List(U8) -> List(U8)
	arp_reply = |req|
		List.join(
			[
				List.sublist(req, { start: 6, len: 6 }),
				MachineNat.gateway_mac,
				[0x08, 0x06, 0, 1, 0x08, 0, 6, 4, 0, 2],
				MachineNat.gateway_mac,
				List.sublist(req, { start: 38, len: 4 }),
				List.sublist(req, { start: 6, len: 6 }),
				List.sublist(req, { start: 28, len: 4 }),
			],
		)

	# DHCP's answer to a DISCOVER (an offer) or a REQUEST (an ack), broadcast
	# from the server's port to the client's.
	dhcp : List(U8), List(U8), U64 -> List(List(U8))
	dhcp = |frame, msg, lease| {
		kind = MachineNat.dhcp_type(msg, 240, 0)
		if List.len(msg) < 240 or MachineNat.byte(msg, 0) != 1 or (kind != 1 and kind != 3) {
			[]
		} else {
			client = List.sublist(frame, { start: 6, len: 6 })
			bootp = List.join([[2, 1, 6, 0], List.sublist(msg, { start: 4, len: 4 }), List.repeat(0.U8, 8), MachineNat.guest, MachineNat.gateway, List.repeat(0.U8, 4), client, List.repeat(0.U8, 202)])
			options = List.join([[99, 130, 83, 99, 53, 1, if kind == 1 { 2 } else { 5 }, 54, 4], MachineNat.gateway, [1, 4, 255, 255, 255, 0, 3, 4], MachineNat.gateway, [6, 4, 10, 0, 2, 3, 51, 4], MachineNat.be32(lease), [255]])
			match MachineNat.udp_frame(client, MachineNat.gateway, [255, 255, 255, 255], 67, 68, List.concat(bootp, options)) {
				Ok(reply) => [reply]
				Err(_) => []
			}
		}
	}

	# Option 53, the message type, from the options after the magic cookie.
	dhcp_type : List(U8), U64, U64 -> U64
	dhcp_type = |msg, i, found| {
		len = List.len(msg)
		if i + 1 >= len {
			found
		} else {
			opt = MachineNat.byte(msg, i)
			if opt == 255 {
				found
			} else if opt == 0 {
				MachineNat.dhcp_type(msg, i + 1, found)
			} else {
				olen = MachineNat.byte(msg, i + 1)
				if i + 2 + olen > len {
					found
				} else {
					MachineNat.dhcp_type(msg, i + 2 + olen, if opt == 53 and olen >= 1 { MachineNat.byte(msg, i + 2) } else { found })
				}
			}
		}
	}

	# An Ethernet frame from the gateway around a UDP datagram, with both
	# checksums; a zero UDP checksum goes on the wire as 0xFFFF.
	udp_frame : List(U8), List(U8), List(U8), U64, U64, List(U8) -> Try(List(U8), [TooLong])
	udp_frame = |dst_mac, src_ip, dst_ip, sport, dport, payload| {
		udp_len = 8 + List.len(payload)
		ip_len = 20 + udp_len
		if 14 + ip_len > 1536 {
			Err(TooLong)
		} else {
			bare = List.join([[0x45, 0], MachineNat.be16_bytes(ip_len), [0, 0, 0x40, 0, 64, 17, 0, 0], src_ip, dst_ip])
			ip = List.join([List.sublist(bare, { start: 0, len: 10 }), MachineNat.be16_bytes(MachineNat.checksum(bare, 0, 0)), List.sublist(bare, { start: 12, len: 8 })])
			udp_bare = List.join([MachineNat.be16_bytes(sport), MachineNat.be16_bytes(dport), MachineNat.be16_bytes(udp_len), [0, 0], payload])
			pseudo = List.join([src_ip, dst_ip, [0, 17], MachineNat.be16_bytes(udp_len)])
			sum = MachineNat.checksum(List.concat(pseudo, udp_bare), 0, 0)
			udp = List.join([List.sublist(udp_bare, { start: 0, len: 6 }), MachineNat.be16_bytes(if sum == 0 { 0xFFFF } else { sum }), payload])
			Ok(List.join([dst_mac, MachineNat.gateway_mac, [0x08, 0x00], ip, udp]))
		}
	}

	# The Internet checksum: the ones' complement of the ones' complement sum
	# of the bytes two at a time, an odd last byte padded with zero.
	checksum : List(U8), U64, U64 -> U64
	checksum = |bytes, i, sum|
		if i >= List.len(bytes) {
			U64.bitwise_xor(MachineNat.fold(sum), 0xFFFF)
		} else {
			MachineNat.checksum(bytes, i + 2, sum + MachineNat.byte(bytes, i) * 256 + MachineNat.byte(bytes, i + 1))
		}

	fold : U64 -> U64
	fold = |s| if s > 0xFFFF { MachineNat.fold(U64.bitwise_and(s, 0xFFFF) + U64.div_trunc_by(s, 0x10000)) } else { s }

	byte : List(U8), U64 -> U64
	byte = |bytes, i| U8.to_u64(List.get(bytes, i) ?? 0)

	be16 : List(U8), U64 -> U64
	be16 = |bytes, i| MachineNat.byte(bytes, i) * 256 + MachineNat.byte(bytes, i + 1)

	be16_bytes : U64 -> List(U8)
	be16_bytes = |v| [U64.to_u8_wrap(U64.div_trunc_by(v, 256)), U64.to_u8_wrap(v)]

	be32 : U64 -> List(U8)
	be32 = |v| List.concat(MachineNat.be16_bytes(U64.div_trunc_by(v, 0x10000)), MachineNat.be16_bytes(v))
}
