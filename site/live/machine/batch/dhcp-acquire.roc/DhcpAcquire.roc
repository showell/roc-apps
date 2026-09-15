app [main!] { pf: platform "../../../../../showell_repos/roc-apps/machine/batch/platform/main.roc" }

import pf.Echo

echo! = |msg| Echo.line!(msg)

# DhcpAcquire -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import DhcpIO
import Machine
import NetDriver
import NetworkConfig

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

# --- Entry ---

main! = |args| {
	machine = Machine.boot!(args, ["Console", "Network.Read", "Network.Write"])
	(machine1, machine__106) = NetDriver.net_driver_bring_up!(machine)
	card = machine__106
	(machine4, machine__107) = ({
		(machine2, mac) = NetDriver.net_driver_mac!(machine1)
		({
			(machine3, cfg) = DhcpIO.dhcp_io_configure!(machine2, mac, "codex", 305419896, 200000, 0)
			_ = line!(Str.concat("card   : ", NetDriver.net_driver_card_name(card)))
			_ = line!(Str.concat("config : ", NetworkConfig.format_net_config(cfg)))
			(machine3, line!(Str.concat("leased : ", (if NetworkConfig.net_is_configured(cfg) { "yes" } else { "no" }))))
		})
	})
	machine__107
	Machine.halt!(machine4)
	Ok({})
}
