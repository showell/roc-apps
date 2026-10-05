# UdpIO -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Ethernet
import Machine
import NetDriver
import Udp

UdpIO :: [].{
	UdpSocket := { us_local_mac : List(I64), us_local_ip : List(I64), us_local_port : I64, us_peer_ip : List(I64), us_peer_port : I64 }.{
		is_eq : UdpIO.UdpSocket, UdpIO.UdpSocket -> Bool
		is_eq = |a, b| eq_UdpSocket(a, b)
	}
	UdpRecv := { ur_data : List(I64), ur_got : Bool, ur_src_port : I64 }.{
		is_eq : UdpIO.UdpRecv, UdpIO.UdpRecv -> Bool
		is_eq = |a, b| eq_UdpRecv(a, b)
	}

	udp_io_open : List(I64), List(I64), I64, List(I64), I64 -> UdpIO.UdpSocket
	udp_io_open = |local_mac, local_ip, local_port, peer_ip, peer_port| UdpIO.UdpSocket.{ us_local_mac: local_mac, us_local_ip: local_ip, us_local_port: local_port, us_peer_ip: peer_ip, us_peer_port: peer_port }

	udp_io_send! : Machine.Machine, UdpIO.UdpSocket, List(I64) => (Machine.Machine, I64)
	udp_io_send! = |machine, sk, payload| ({
		frame : List(I64)
		frame = Udp.udp_build_frame(Ethernet.mac_broadcast, sk.us_local_mac, sk.us_local_ip, sk.us_peer_ip, sk.us_local_port, sk.us_peer_port, payload)
		NetDriver.net_driver_send_frame!(machine, frame)
	})

	udp_io_recv! : Machine.Machine, UdpIO.UdpSocket, I64 => (Machine.Machine, UdpIO.UdpRecv)
	udp_io_recv! = |machine, sk, fuel| (if (fuel <= 0) { (machine, UdpIO.UdpRecv.{ ur_data: [], ur_got: False, ur_src_port: 0 }) } else { ({
		(machine1, hp) = Machine.mark(machine)
		({
			(machine2, frame) = NetDriver.net_driver_recv_frame!(machine1)
			(if (U64.to_i64_wrap(List.len(frame)) == 0) { ({
				(machine3, _restored) = Machine.release(machine2, hp)
				udp_io_recv!(machine3, sk, (fuel - 1))
			}) } else { (if udp_io_mine(sk, frame) { (machine2, UdpIO.UdpRecv.{ ur_data: udp_io_payload(frame), ur_got: True, ur_src_port: udp_io_src_port(frame) }) } else { ({
				(machine4, _restored2) = Machine.release(machine2, hp)
				udp_io_recv!(machine4, sk, (fuel - 1))
			}) }) })
		})
	}) })

	udp_io_mine : UdpIO.UdpSocket, List(I64) -> Bool
	udp_io_mine = |sk, frame| (if (Ethernet.eth_ethertype(frame) != Ethernet.eth_type_ipv4) { False } else { ({
		ip : List(I64)
		ip = Ethernet.eth_payload(frame)
		(if (Ethernet.ip_length_valid(ip) == False) { False } else { (if (Ethernet.ip_header_valid(ip) == False) { False } else { (if (Ethernet.ip_proto(ip) != Ethernet.ip_proto_udp) { False } else { (if (Udp.udp_checksum_valid(Ethernet.ip_payload(ip), Ethernet.ip_src(ip), Ethernet.ip_dst(ip)) == False) { False } else { ({
			dg = Udp.udp_parse(Ethernet.ip_payload(ip))
			(dg.dst_port == sk.us_local_port)
		}) }) }) }) })
	}) })

	udp_io_payload : List(I64) -> List(I64)
	udp_io_payload = |frame| ({
		dg = Udp.udp_parse(Ethernet.ip_payload(Ethernet.eth_payload(frame)))
		dg.payload
	})

	udp_io_src_port : List(I64) -> I64
	udp_io_src_port = |frame| ({
		dg = Udp.udp_parse(Ethernet.ip_payload(Ethernet.eth_payload(frame)))
		dg.src_port
	})

	eq_UdpSocket : UdpIO.UdpSocket, UdpIO.UdpSocket -> Bool
	eq_UdpSocket = |ex, ey| (((((ex.us_local_mac == ey.us_local_mac) and (ex.us_local_ip == ey.us_local_ip)) and (ex.us_local_port == ey.us_local_port)) and (ex.us_peer_ip == ey.us_peer_ip)) and (ex.us_peer_port == ey.us_peer_port))

	eq_UdpRecv : UdpIO.UdpRecv, UdpIO.UdpRecv -> Bool
	eq_UdpRecv = |ex, ey| (((ex.ur_data == ey.ur_data) and (ex.ur_got == ey.ur_got)) and (ex.ur_src_port == ey.ur_src_port))
}
