# NetworkConfig -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import CceText
import Dhcp
import DnsResolver

NetworkConfig :: [].{
	NetState : [NetUnconfigured, NetDhcpPending, NetConfigured, NetFailed]
	NetworkConfig := { state : NetworkConfig.NetState, local_ip : List(I64), subnet_mask : List(I64), gateway : List(I64), dns_server : List(I64), local_mac : List(I64), hostname : CceText, resolver : DnsResolver.DnsResolver, ntp_offset : I64, lease_time : I64, lease_start : I64 }.{
		is_eq : NetworkConfig.NetworkConfig, NetworkConfig.NetworkConfig -> Bool
		is_eq = |a, b| eq_NetworkConfig(a, b)
	}

	net_config_empty : List(I64), CceText -> NetworkConfig.NetworkConfig
	net_config_empty = |mac, hostname| NetworkConfig.NetworkConfig.{ state: NetUnconfigured, local_ip: [0, 0, 0, 0], subnet_mask: [0, 0, 0, 0], gateway: [0, 0, 0, 0], dns_server: [0, 0, 0, 0], local_mac: mac, hostname: hostname, resolver: DnsResolver.resolver_new(DnsResolver.host_table_add(DnsResolver.host_table_empty, "localhost", [127, 0, 0, 1])), ntp_offset: 0, lease_time: 0, lease_start: 0 }

	net_apply_dhcp_ack : NetworkConfig.NetworkConfig, Dhcp.DhcpLease, I64 -> NetworkConfig.NetworkConfig
	net_apply_dhcp_ack = |cfg, lease, now| ({
		ht = DnsResolver.host_table_add(DnsResolver.host_table_add(DnsResolver.host_table_empty, "localhost", [127, 0, 0, 1]), cfg.hostname, lease.client_ip)
		NetworkConfig.NetworkConfig.{ state: NetConfigured, local_ip: lease.client_ip, subnet_mask: lease.subnet_mask, gateway: lease.gateway, dns_server: lease.dns_server, local_mac: cfg.local_mac, hostname: cfg.hostname, resolver: DnsResolver.resolver_new(ht), ntp_offset: cfg.ntp_offset, lease_time: lease.lease_time, lease_start: now }
	})

	net_is_configured : NetworkConfig.NetworkConfig -> Bool
	net_is_configured = |cfg| (match cfg.state {
		NetConfigured => True
		_ => False
	})

	format_net_config : NetworkConfig.NetworkConfig -> CceText
	format_net_config = |cfg| CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(format_net_state(cfg.state), " ip="), format_net_ip(cfg.local_ip)), " gw="), format_net_ip(cfg.gateway)), " dns="), format_net_ip(cfg.dns_server)), " lease="), CceText.show_int(cfg.lease_time))

	format_net_state : NetworkConfig.NetState -> CceText
	format_net_state = |s| (match s {
		NetUnconfigured => "UNCONFIGURED"
		NetDhcpPending => "DHCP_PENDING"
		NetConfigured => "CONFIGURED"
		NetFailed => "FAILED"
	})

	format_net_ip : List(I64) -> CceText
	format_net_ip = |ip| CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.show_int((List.get(ip, I64.to_u64_wrap(0)) ?? crash("list-at out of range"))), "."), CceText.show_int((List.get(ip, I64.to_u64_wrap(1)) ?? crash("list-at out of range")))), "."), CceText.show_int((List.get(ip, I64.to_u64_wrap(2)) ?? crash("list-at out of range")))), "."), CceText.show_int((List.get(ip, I64.to_u64_wrap(3)) ?? crash("list-at out of range"))))

	eq_NetState : NetworkConfig.NetState, NetworkConfig.NetState -> Bool
	eq_NetState = |ex, ey| (match ex {
		NetUnconfigured => (match ey {
			NetUnconfigured => True
			_ => False
		})
		NetDhcpPending => (match ey {
			NetDhcpPending => True
			_ => False
		})
		NetConfigured => (match ey {
			NetConfigured => True
			_ => False
		})
		NetFailed => (match ey {
			NetFailed => True
			_ => False
		})
	})

	eq_NetworkConfig : NetworkConfig.NetworkConfig, NetworkConfig.NetworkConfig -> Bool
	eq_NetworkConfig = |ex, ey| ((((((((((eq_NetState(ex.state, ey.state) and (ex.local_ip == ey.local_ip)) and (ex.subnet_mask == ey.subnet_mask)) and (ex.gateway == ey.gateway)) and (ex.dns_server == ey.dns_server)) and (ex.local_mac == ey.local_mac)) and (ex.hostname == ey.hostname)) and DnsResolver.eq_DnsResolver(ex.resolver, ey.resolver)) and (ex.ntp_offset == ey.ntp_offset)) and (ex.lease_time == ey.lease_time)) and (ex.lease_start == ey.lease_start))
}
