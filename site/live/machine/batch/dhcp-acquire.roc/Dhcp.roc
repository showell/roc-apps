# Dhcp -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Ethernet
import Udp

Dhcp :: [].{
	DhcpLease : { client_ip : List(I64), subnet_mask : List(I64), gateway : List(I64), dns_server : List(I64), server_id : List(I64), lease_time : I64, msg_type : I64, valid : Bool }

	dhcp_server_port : I64
	dhcp_server_port = 67

	dhcp_client_port : I64
	dhcp_client_port = 68

	dhcp_op_request : I64
	dhcp_op_request = 1

	dhcp_op_reply : I64
	dhcp_op_reply = 2

	dhcp_htype_ethernet : I64
	dhcp_htype_ethernet = 1

	dhcp_hlen_ethernet : I64
	dhcp_hlen_ethernet = 6

	dhcp_magic_cookie : List(I64)
	dhcp_magic_cookie = [99, 130, 83, 99]

	dhcp_header_size : I64
	dhcp_header_size = 236

	dhcp_msg_discover : I64
	dhcp_msg_discover = 1

	dhcp_msg_offer : I64
	dhcp_msg_offer = 2

	dhcp_msg_request : I64
	dhcp_msg_request = 3

	dhcp_msg_ack : I64
	dhcp_msg_ack = 5

	dhcp_msg_nak : I64
	dhcp_msg_nak = 6

	dhcp_opt_subnet : I64
	dhcp_opt_subnet = 1

	dhcp_opt_router : I64
	dhcp_opt_router = 3

	dhcp_opt_dns : I64
	dhcp_opt_dns = 6

	dhcp_opt_hostname : I64
	dhcp_opt_hostname = 12

	dhcp_opt_requested_ip : I64
	dhcp_opt_requested_ip = 50

	dhcp_opt_lease_time : I64
	dhcp_opt_lease_time = 51

	dhcp_opt_msg_type : I64
	dhcp_opt_msg_type = 53

	dhcp_opt_server_id : I64
	dhcp_opt_server_id = 54

	dhcp_opt_end : I64
	dhcp_opt_end = 255

	dhcp_lease_empty : Dhcp.DhcpLease
	dhcp_lease_empty = { client_ip: [0, 0, 0, 0], subnet_mask: [0, 0, 0, 0], gateway: [0, 0, 0, 0], dns_server: [0, 0, 0, 0], server_id: [0, 0, 0, 0], lease_time: 0, msg_type: 0, valid: False }

	dhcp_build_discover : I64, List(I64) -> List(I64)
	dhcp_build_discover = |xid, client_mac| dhcp_build_msg(xid, client_mac, [0, 0, 0, 0], dhcp_msg_discover, [])

	dhcp_build_request : I64, List(I64), List(I64), List(I64) -> List(I64)
	dhcp_build_request = |xid, client_mac, requested_ip, server_ip| ({
		opts = List.concat(List.concat(List.concat([dhcp_opt_requested_ip, 4], requested_ip), [dhcp_opt_server_id, 4]), server_ip)
		dhcp_build_msg(xid, client_mac, [0, 0, 0, 0], dhcp_msg_request, opts)
	})

	dhcp_build_renew : I64, List(I64), List(I64) -> List(I64)
	dhcp_build_renew = |xid, client_mac, client_ip| dhcp_build_msg(xid, client_mac, client_ip, dhcp_msg_request, [])

	dhcp_build_msg : I64, List(I64), List(I64), I64, List(I64) -> List(I64)
	dhcp_build_msg = |xid, client_mac, ci_addr, msg_type, extra_opts| ({
		header = [dhcp_op_request, dhcp_htype_ethernet, dhcp_hlen_ethernet, 0]
		xid_bytes = dhcp_write_be32(xid)
		secs_flags = [0, 0, 0, 0]
		ci = ci_addr
		yi = [0, 0, 0, 0]
		si = [0, 0, 0, 0]
		gi = [0, 0, 0, 0]
		chaddr = dhcp_pad_mac(client_mac)
		sname = dhcp_zeros(64)
		file = dhcp_zeros(128)
		options = List.concat(List.concat(List.concat(dhcp_magic_cookie, [dhcp_opt_msg_type, 1, msg_type]), extra_opts), [dhcp_opt_end])
		List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(header, xid_bytes), secs_flags), ci), yi), si), gi), chaddr), sname), file), options)
	})

	dhcp_pad_mac : List(I64) -> List(I64)
	dhcp_pad_mac = |mac| List.concat(mac, dhcp_zeros((16 - U64.to_i64_wrap(List.len(mac)))))

	dhcp_zeros : I64 -> List(I64)
	dhcp_zeros = |n| dhcp_zeros_loop(n, [])

	dhcp_zeros_loop : I64, List(I64) -> List(I64)
	dhcp_zeros_loop = |n, acc| (if (n <= 0) { acc } else { dhcp_zeros_loop((n - 1), List.append(acc, 0)) })

	dhcp_write_be32 : I64 -> List(I64)
	dhcp_write_be32 = |v| [I64.bitwise_and(I64.shr_zf_wrap(v, I64.to_u8_wrap(24)), 255), I64.bitwise_and(I64.shr_zf_wrap(v, I64.to_u8_wrap(16)), 255), I64.bitwise_and(I64.shr_zf_wrap(v, I64.to_u8_wrap(8)), 255), I64.bitwise_and(v, 255)]

	dhcp_parse_response : List(I64) -> Dhcp.DhcpLease
	dhcp_parse_response = |data| ({
		dlen = U64.to_i64_wrap(List.len(data))
		(if (dlen < (dhcp_header_size + 4)) { dhcp_lease_empty } else { ({
			op = (List.get(data, I64.to_u64_wrap(0)) ?? crash("list-at out of range"))
			(if (op != dhcp_op_reply) { dhcp_lease_empty } else { ({
				yi = [(List.get(data, I64.to_u64_wrap(16)) ?? crash("list-at out of range")), (List.get(data, I64.to_u64_wrap(17)) ?? crash("list-at out of range")), (List.get(data, I64.to_u64_wrap(18)) ?? crash("list-at out of range")), (List.get(data, I64.to_u64_wrap(19)) ?? crash("list-at out of range"))]
				opts_start = (dhcp_header_size + 4)
				dhcp_parse_options(data, opts_start, dlen, { client_ip: yi, subnet_mask: [0, 0, 0, 0], gateway: [0, 0, 0, 0], dns_server: [0, 0, 0, 0], server_id: [0, 0, 0, 0], lease_time: 0, msg_type: 0, valid: True })
			}) })
		}) })
	})

	dhcp_parse_options : List(I64), I64, I64, Dhcp.DhcpLease -> Dhcp.DhcpLease
	dhcp_parse_options = |data, i, dlen, lease| (if (i >= dlen) { lease } else { ({
		opt = (List.get(data, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if (opt == dhcp_opt_end) { lease } else { (if (opt == 0) { dhcp_parse_options(data, (i + 1), dlen, lease) } else { (if ((i + 1) >= dlen) { lease } else { ({
			olen = (List.get(data, I64.to_u64_wrap((i + 1))) ?? crash("list-at out of range"))
			val_start = (i + 2)
			next = (val_start + olen)
			updated = dhcp_apply_option(lease, opt, data, val_start, olen)
			dhcp_parse_options(data, next, dlen, updated)
		}) }) }) })
	}) })

	dhcp_apply_option : Dhcp.DhcpLease, I64, List(I64), I64, I64 -> Dhcp.DhcpLease
	dhcp_apply_option = |lease, opt, data, off, olen| (if (opt == dhcp_opt_msg_type) { (if (olen >= 1) { { client_ip: lease.client_ip, subnet_mask: lease.subnet_mask, gateway: lease.gateway, dns_server: lease.dns_server, server_id: lease.server_id, lease_time: lease.lease_time, msg_type: (List.get(data, I64.to_u64_wrap(off)) ?? crash("list-at out of range")), valid: lease.valid } } else { lease }) } else { (if (opt == dhcp_opt_subnet) { (if (olen >= 4) { { client_ip: lease.client_ip, subnet_mask: dhcp_read_ip(data, off), gateway: lease.gateway, dns_server: lease.dns_server, server_id: lease.server_id, lease_time: lease.lease_time, msg_type: lease.msg_type, valid: lease.valid } } else { lease }) } else { (if (opt == dhcp_opt_router) { (if (olen >= 4) { { client_ip: lease.client_ip, subnet_mask: lease.subnet_mask, gateway: dhcp_read_ip(data, off), dns_server: lease.dns_server, server_id: lease.server_id, lease_time: lease.lease_time, msg_type: lease.msg_type, valid: lease.valid } } else { lease }) } else { (if (opt == dhcp_opt_dns) { (if (olen >= 4) { { client_ip: lease.client_ip, subnet_mask: lease.subnet_mask, gateway: lease.gateway, dns_server: dhcp_read_ip(data, off), server_id: lease.server_id, lease_time: lease.lease_time, msg_type: lease.msg_type, valid: lease.valid } } else { lease }) } else { (if (opt == dhcp_opt_server_id) { (if (olen >= 4) { { client_ip: lease.client_ip, subnet_mask: lease.subnet_mask, gateway: lease.gateway, dns_server: lease.dns_server, server_id: dhcp_read_ip(data, off), lease_time: lease.lease_time, msg_type: lease.msg_type, valid: lease.valid } } else { lease }) } else { (if (opt == dhcp_opt_lease_time) { (if (olen >= 4) { { client_ip: lease.client_ip, subnet_mask: lease.subnet_mask, gateway: lease.gateway, dns_server: lease.dns_server, server_id: lease.server_id, lease_time: dhcp_read_be32(data, off), msg_type: lease.msg_type, valid: lease.valid } } else { lease }) } else { lease }) }) }) }) }) })

	dhcp_read_ip : List(I64), I64 -> List(I64)
	dhcp_read_ip = |data, off| (if ((off + 4) > U64.to_i64_wrap(List.len(data))) { [0, 0, 0, 0] } else { [(List.get(data, I64.to_u64_wrap(off)) ?? crash("list-at out of range")), (List.get(data, I64.to_u64_wrap((off + 1))) ?? crash("list-at out of range")), (List.get(data, I64.to_u64_wrap((off + 2))) ?? crash("list-at out of range")), (List.get(data, I64.to_u64_wrap((off + 3))) ?? crash("list-at out of range"))] })

	dhcp_read_be32 : List(I64), I64 -> I64
	dhcp_read_be32 = |data, off| (if ((off + 4) > U64.to_i64_wrap(List.len(data))) { 0 } else { ({
		b0 = I64.shl_wrap((List.get(data, I64.to_u64_wrap(off)) ?? crash("list-at out of range")), I64.to_u8_wrap(24))
		b1 = I64.shl_wrap((List.get(data, I64.to_u64_wrap((off + 1))) ?? crash("list-at out of range")), I64.to_u8_wrap(16))
		b2 = I64.shl_wrap((List.get(data, I64.to_u64_wrap((off + 2))) ?? crash("list-at out of range")), I64.to_u8_wrap(8))
		b3 = (List.get(data, I64.to_u64_wrap((off + 3))) ?? crash("list-at out of range"))
		I64.bitwise_or(b0, I64.bitwise_or(b1, I64.bitwise_or(b2, b3)))
	}) })

	dhcp_discover_udp : List(I64), I64 -> List(I64)
	dhcp_discover_udp = |client_mac, xid| ({
		payload = dhcp_build_discover(xid, client_mac)
		Udp.udp_build(dhcp_client_port, dhcp_server_port, payload)
	})

	dhcp_discover_frame : List(I64), I64 -> List(I64)
	dhcp_discover_frame = |client_mac, xid| ({
		ip_pkt = Udp.udp_build_ip_packet([0, 0, 0, 0], [255, 255, 255, 255], dhcp_client_port, dhcp_server_port, dhcp_build_discover(xid, client_mac))
		Ethernet.eth_build_frame(Ethernet.mac_broadcast, client_mac, Ethernet.eth_type_ipv4, ip_pkt)
	})

	dhcp_is_offer : Dhcp.DhcpLease -> Bool
	dhcp_is_offer = |l| (l.valid and (l.msg_type == dhcp_msg_offer))

	dhcp_is_ack : Dhcp.DhcpLease -> Bool
	dhcp_is_ack = |l| (l.valid and (l.msg_type == dhcp_msg_ack))

	format_dhcp_lease : Dhcp.DhcpLease -> Str
	format_dhcp_lease = |l| Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat("ip=", format_dhcp_ip(l.client_ip)), " mask="), format_dhcp_ip(l.subnet_mask)), " gw="), format_dhcp_ip(l.gateway)), " dns="), format_dhcp_ip(l.dns_server)), " lease="), I64.to_str(l.lease_time))

	format_dhcp_ip : List(I64) -> Str
	format_dhcp_ip = |ip| Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(I64.to_str((List.get(ip, I64.to_u64_wrap(0)) ?? crash("list-at out of range"))), "."), I64.to_str((List.get(ip, I64.to_u64_wrap(1)) ?? crash("list-at out of range")))), "."), I64.to_str((List.get(ip, I64.to_u64_wrap(2)) ?? crash("list-at out of range")))), "."), I64.to_str((List.get(ip, I64.to_u64_wrap(3)) ?? crash("list-at out of range"))))
}
