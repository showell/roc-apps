# DhcpIO -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Dhcp
import Machine
import NetworkConfig
import UdpIO

DhcpIO :: [].{

	dhcp_io_socket : List(I64), List(I64) -> UdpIO.UdpSocket
	dhcp_io_socket = |mac, from_ip| UdpIO.udp_io_open(mac, from_ip, Dhcp.dhcp_client_port, [255, 255, 255, 255], Dhcp.dhcp_server_port)

	dhcp_io_acquire! : Machine.Machine, List(I64), I64, I64 => (Machine.Machine, Dhcp.DhcpLease)
	dhcp_io_acquire! = |machine, mac, xid, fuel| ({
		sk = dhcp_io_socket(mac, [0, 0, 0, 0])
		({
			(machine1, _sent) = UdpIO.udp_io_send!(machine, sk, Dhcp.dhcp_build_discover(xid, mac))
			(machine2, offer) = dhcp_io_await!(machine1, sk, fuel, Dhcp.dhcp_msg_offer)
			dhcp_io_request!(machine2, sk, mac, xid, fuel, offer)
		})
	})

	dhcp_io_request! : Machine.Machine, UdpIO.UdpSocket, List(I64), I64, I64, Dhcp.DhcpLease => (Machine.Machine, Dhcp.DhcpLease)
	dhcp_io_request! = |machine, sk, mac, xid, fuel, offer| (if (Dhcp.dhcp_is_offer(offer) == False) { (machine, Dhcp.dhcp_lease_empty) } else { ({
		(machine1, _sent) = UdpIO.udp_io_send!(machine, sk, Dhcp.dhcp_build_request(xid, mac, offer.client_ip, offer.server_id))
		dhcp_io_await!(machine1, sk, fuel, Dhcp.dhcp_msg_ack)
	}) })

	dhcp_io_await! : Machine.Machine, UdpIO.UdpSocket, I64, I64 => (Machine.Machine, Dhcp.DhcpLease)
	dhcp_io_await! = |machine, sk, fuel, want| (if (fuel <= 0) { (machine, Dhcp.dhcp_lease_empty) } else { ({
		(machine1, hp) = Machine.mark(machine)
		({
			(machine2, got) = UdpIO.udp_io_recv!(machine1, sk, 1)
			(if (got.ur_got == False) { ({
				(machine3, _restored) = Machine.release(machine2, hp)
				dhcp_io_await!(machine3, sk, (fuel - 1), want)
			}) } else { ({
				lease = Dhcp.dhcp_parse_response(got.ur_data)
				(if (lease.valid and (lease.msg_type == want)) { (machine2, lease) } else { ({
					(machine4, _restored2) = Machine.release(machine2, hp)
					dhcp_io_await!(machine4, sk, (fuel - 1), want)
				}) })
			}) })
		})
	}) })

	dhcp_io_configure! : Machine.Machine, List(I64), Str, I64, I64, I64 => (Machine.Machine, NetworkConfig.NetworkConfig)
	dhcp_io_configure! = |machine, mac, hostname, xid, fuel, now| ({
		cfg = NetworkConfig.net_config_empty(mac, hostname)
		({
			(machine1, lease) = dhcp_io_acquire!(machine, mac, xid, fuel)
			(machine1, dhcp_io_apply(cfg, lease, now))
		})
	})

	dhcp_io_apply : NetworkConfig.NetworkConfig, Dhcp.DhcpLease, I64 -> NetworkConfig.NetworkConfig
	dhcp_io_apply = |cfg, lease, now| (if Dhcp.dhcp_is_ack(lease) { NetworkConfig.net_apply_dhcp_ack(cfg, lease, now) } else { cfg })

	dhcp_io_maybe_renew! : Machine.Machine, NetworkConfig.NetworkConfig, I64, I64, I64 => (Machine.Machine, NetworkConfig.NetworkConfig)
	dhcp_io_maybe_renew! = |machine, cfg, xid, fuel, now| (if (NetworkConfig.net_lease_due(cfg, now) == False) { (machine, cfg) } else { dhcp_io_renew!(machine, cfg, xid, fuel, now) })

	dhcp_io_renew! : Machine.Machine, NetworkConfig.NetworkConfig, I64, I64, I64 => (Machine.Machine, NetworkConfig.NetworkConfig)
	dhcp_io_renew! = |machine, cfg, xid, fuel, now| ({
		sk = dhcp_io_socket(cfg.local_mac, cfg.local_ip)
		({
			(machine1, _sent) = UdpIO.udp_io_send!(machine, sk, Dhcp.dhcp_build_renew(xid, cfg.local_mac, cfg.local_ip))
			(machine2, lease) = dhcp_io_await!(machine1, sk, fuel, Dhcp.dhcp_msg_ack)
			(machine2, dhcp_io_apply(cfg, lease, now))
		})
	})
}
