# NetworkConfig -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Dhcp
import DnsResolver
import Maybe

NetworkConfig :: [].{
	NetState : [NetUnconfigured, NetDhcpPending, NetConfigured, NetFailed]
	NetworkConfig : { state : NetworkConfig.NetState, local_ip : List(I64), subnet_mask : List(I64), gateway : List(I64), dns_server : List(I64), local_mac : List(I64), hostname : Str, resolver : DnsResolver.DnsResolver, ntp_offset : I64, lease_time : I64, lease_start : I64 }

	net_config_empty : List(I64), Str -> NetworkConfig.NetworkConfig
	net_config_empty = |mac, hostname| { state: NetUnconfigured, local_ip: [0, 0, 0, 0], subnet_mask: [0, 0, 0, 0], gateway: [0, 0, 0, 0], dns_server: [0, 0, 0, 0], local_mac: mac, hostname: hostname, resolver: DnsResolver.resolver_new(DnsResolver.host_table_add(DnsResolver.host_table_empty, "localhost", [127, 0, 0, 1])), ntp_offset: 0, lease_time: 0, lease_start: 0 }

	net_config_static : List(I64), List(I64), List(I64), List(I64), List(I64), Str -> NetworkConfig.NetworkConfig
	net_config_static = |mac, ip, mask, gw, dns, hostname| { state: NetConfigured, local_ip: ip, subnet_mask: mask, gateway: gw, dns_server: dns, local_mac: mac, hostname: hostname, resolver: DnsResolver.resolver_new(DnsResolver.host_table_add(DnsResolver.host_table_add(DnsResolver.host_table_empty, "localhost", [127, 0, 0, 1]), hostname, ip)), ntp_offset: 0, lease_time: 0, lease_start: 0 }

	net_apply_dhcp_lease : NetworkConfig.NetworkConfig, Dhcp.DhcpLease, I64 -> NetworkConfig.NetworkConfig
	net_apply_dhcp_lease = |cfg, lease, now| (if Dhcp.dhcp_is_offer(lease) { net_apply_dhcp_offer(cfg, lease) } else { (if Dhcp.dhcp_is_ack(lease) { net_apply_dhcp_ack(cfg, lease, now) } else { cfg }) })

	net_apply_dhcp_offer : NetworkConfig.NetworkConfig, Dhcp.DhcpLease -> NetworkConfig.NetworkConfig
	net_apply_dhcp_offer = |cfg, lease| { state: NetDhcpPending, local_ip: lease.client_ip, subnet_mask: lease.subnet_mask, gateway: lease.gateway, dns_server: lease.dns_server, local_mac: cfg.local_mac, hostname: cfg.hostname, resolver: cfg.resolver, ntp_offset: cfg.ntp_offset, lease_time: lease.lease_time, lease_start: 0 }

	net_apply_dhcp_ack : NetworkConfig.NetworkConfig, Dhcp.DhcpLease, I64 -> NetworkConfig.NetworkConfig
	net_apply_dhcp_ack = |cfg, lease, now| ({
		ht = DnsResolver.host_table_add(DnsResolver.host_table_add(DnsResolver.host_table_empty, "localhost", [127, 0, 0, 1]), cfg.hostname, lease.client_ip)
		{ state: NetConfigured, local_ip: lease.client_ip, subnet_mask: lease.subnet_mask, gateway: lease.gateway, dns_server: lease.dns_server, local_mac: cfg.local_mac, hostname: cfg.hostname, resolver: DnsResolver.resolver_new(ht), ntp_offset: cfg.ntp_offset, lease_time: lease.lease_time, lease_start: now }
	})

	net_resolve : NetworkConfig.NetworkConfig, Str, I64 -> Maybe.Maybe(List(I64))
	net_resolve = |cfg, name, now| DnsResolver.resolve(cfg.resolver, name, now)

	net_cache_dns : NetworkConfig.NetworkConfig, Str, List(I64), I64, I64 -> NetworkConfig.NetworkConfig
	net_cache_dns = |cfg, name, ip, ttl, now| { state: cfg.state, local_ip: cfg.local_ip, subnet_mask: cfg.subnet_mask, gateway: cfg.gateway, dns_server: cfg.dns_server, local_mac: cfg.local_mac, hostname: cfg.hostname, resolver: DnsResolver.resolver_cache_result(cfg.resolver, name, ip, ttl, now), ntp_offset: cfg.ntp_offset, lease_time: cfg.lease_time, lease_start: cfg.lease_start }

	net_apply_ntp : NetworkConfig.NetworkConfig, I64 -> NetworkConfig.NetworkConfig
	net_apply_ntp = |cfg, offset| { state: cfg.state, local_ip: cfg.local_ip, subnet_mask: cfg.subnet_mask, gateway: cfg.gateway, dns_server: cfg.dns_server, local_mac: cfg.local_mac, hostname: cfg.hostname, resolver: cfg.resolver, ntp_offset: offset, lease_time: cfg.lease_time, lease_start: cfg.lease_start }

	net_is_configured : NetworkConfig.NetworkConfig -> Bool
	net_is_configured = |cfg| (match cfg.state {
		NetConfigured => True
		_ => False
	})

	net_lease_due : NetworkConfig.NetworkConfig, I64 -> Bool
	net_lease_due = |cfg, now| (if (net_is_configured(cfg) == False) { False } else { (if (cfg.lease_time <= 0) { False } else { ((now - cfg.lease_start) >= I64.div_trunc_by(cfg.lease_time, 2)) }) })

	net_lease_remaining : NetworkConfig.NetworkConfig, I64 -> I64
	net_lease_remaining = |cfg, now| (if (cfg.lease_time == 0) { 0 } else { ({
		elapsed = (now - cfg.lease_start)
		(if (elapsed >= cfg.lease_time) { 0 } else { (cfg.lease_time - elapsed) })
	}) })

	format_net_config : NetworkConfig.NetworkConfig -> Str
	format_net_config = |cfg| Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(format_net_state(cfg.state), " ip="), format_net_ip(cfg.local_ip)), " gw="), format_net_ip(cfg.gateway)), " dns="), format_net_ip(cfg.dns_server)), " lease="), I64.to_str(cfg.lease_time))

	format_net_state : NetworkConfig.NetState -> Str
	format_net_state = |s| (match s {
		NetUnconfigured => "UNCONFIGURED"
		NetDhcpPending => "DHCP_PENDING"
		NetConfigured => "CONFIGURED"
		NetFailed => "FAILED"
	})

	format_net_ip : List(I64) -> Str
	format_net_ip = |ip| Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(I64.to_str((List.get(ip, I64.to_u64_wrap(0)) ?? crash("list-at out of range"))), "."), I64.to_str((List.get(ip, I64.to_u64_wrap(1)) ?? crash("list-at out of range")))), "."), I64.to_str((List.get(ip, I64.to_u64_wrap(2)) ?? crash("list-at out of range")))), "."), I64.to_str((List.get(ip, I64.to_u64_wrap(3)) ?? crash("list-at out of range"))))

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
}
