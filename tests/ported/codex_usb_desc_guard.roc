# usb-desc-guard
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/usb-desc-guard.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     device vendor=4660 product=22136 class=9 configs=1
#     device-short vendor=0 class=0 configs=0
#     endpoint addr=1 dir=128 type=3 maxpkt=8 interval=10
#     endpoint-past addr=0 maxpkt=0
#     interface num=0 class=3 sub=1 proto=1 eps=1
#     interface-past num=0 class=0
#     le16 in=25 at-end=0 past=0
#     scan honest total=25 ifaces=1
#     scan lying total=200 ifaces=1
#     scan huge total=65535 ifaces=1
#     scan empty ifaces=0

app [main!] { cdx: "./codex/main.roc" }

import cdx.Text
import cdx.Usb
import cdx.UsbHid

# UsbDescGuardTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

cfg_bytes : List(I64)
cfg_bytes = List.concat(List.concat([9, 2, 25, 0, 1, 1, 0, 128, 50], [9, 4, 0, 0, 1, 3, 1, 1, 0]), [7, 5, 129, 3, 8, 0, 10])

dev_bytes : List(I64)
dev_bytes = [18, 1, 0, 2, 9, 0, 0, 64, 52, 18, 120, 86, 0, 1, 1, 2, 3, 1]

ifc_count : List(UsbHid.HidInterface) -> I64
ifc_count = |xs| U64.to_i64_wrap(List.len(xs))

# --- Entry ---

main! = |_args| {
	d = Usb.usb_parse_device_desc(dev_bytes)
	dshort = Usb.usb_parse_device_desc([18, 1, 0, 2, 9])
	e = Usb.usb_parse_endpoint(cfg_bytes, 18)
	epast = Usb.usb_parse_endpoint(cfg_bytes, 22)
	i = Usb.usb_parse_interface(cfg_bytes, 9)
	ipast = Usb.usb_parse_interface(cfg_bytes, 20)
	line!(Text.printed(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat([22, 13, 33, 17, 24, 13, 2, 33, 13, 18, 22, 16, 21, 77], Text.show_int(d.usb_vendor)), [2, 31, 21, 16, 22, 25, 24, 14, 77]), Text.show_int(d.usb_product)), [2, 24, 23, 15, 19, 19, 77]), Text.show_int(d.usb_class)), [2, 24, 16, 18, 28, 17, 29, 19, 77]), Text.show_int(d.usb_num_configs))))
	line!(Text.printed(List.concat(List.concat(List.concat(List.concat(List.concat([22, 13, 33, 17, 24, 13, 73, 19, 20, 16, 21, 14, 2, 33, 13, 18, 22, 16, 21, 77], Text.show_int(dshort.usb_vendor)), [2, 24, 23, 15, 19, 19, 77]), Text.show_int(dshort.usb_class)), [2, 24, 16, 18, 28, 17, 29, 19, 77]), Text.show_int(dshort.usb_num_configs))))
	line!(Text.printed(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat([13, 18, 22, 31, 16, 17, 18, 14, 2, 15, 22, 22, 21, 77], Text.show_int(e.ep_address)), [2, 22, 17, 21, 77]), Text.show_int(e.ep_direction)), [2, 14, 30, 31, 13, 77]), Text.show_int(e.ep_type)), [2, 26, 15, 36, 31, 34, 14, 77]), Text.show_int(e.ep_max_packet)), [2, 17, 18, 14, 13, 21, 33, 15, 23, 77]), Text.show_int(e.ep_interval))))
	line!(Text.printed(List.concat(List.concat(List.concat([13, 18, 22, 31, 16, 17, 18, 14, 73, 31, 15, 19, 14, 2, 15, 22, 22, 21, 77], Text.show_int(epast.ep_address)), [2, 26, 15, 36, 31, 34, 14, 77]), Text.show_int(epast.ep_max_packet))))
	line!(Text.printed(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat([17, 18, 14, 13, 21, 28, 15, 24, 13, 2, 18, 25, 26, 77], Text.show_int(i.if_number)), [2, 24, 23, 15, 19, 19, 77]), Text.show_int(i.if_class)), [2, 19, 25, 32, 77]), Text.show_int(i.if_subclass)), [2, 31, 21, 16, 14, 16, 77]), Text.show_int(i.if_protocol)), [2, 13, 31, 19, 77]), Text.show_int(i.if_num_endpoints))))
	line!(Text.printed(List.concat(List.concat(List.concat([17, 18, 14, 13, 21, 28, 15, 24, 13, 73, 31, 15, 19, 14, 2, 18, 25, 26, 77], Text.show_int(ipast.if_number)), [2, 24, 23, 15, 19, 19, 77]), Text.show_int(ipast.if_class))))
	line!(Text.printed(List.concat(List.concat(List.concat(List.concat(List.concat([23, 13, 4, 9, 2, 17, 18, 77], Text.show_int(Usb.usb_le16(cfg_bytes, 2))), [2, 15, 14, 73, 13, 18, 22, 77]), Text.show_int(Usb.usb_le16(cfg_bytes, 24))), [2, 31, 15, 19, 14, 77]), Text.show_int(Usb.usb_le16(cfg_bytes, 99)))))
	line!(Text.printed(List.concat([19, 24, 15, 18, 2, 20, 16, 18, 13, 19, 14, 2, 14, 16, 14, 15, 23, 77, 5, 8, 2, 17, 28, 15, 24, 13, 19, 77], Text.show_int(ifc_count(UsbHid.hid_scan_interfaces(cfg_bytes, 25))))))
	line!(Text.printed(List.concat([19, 24, 15, 18, 2, 23, 30, 17, 18, 29, 2, 14, 16, 14, 15, 23, 77, 5, 3, 3, 2, 17, 28, 15, 24, 13, 19, 77], Text.show_int(ifc_count(UsbHid.hid_scan_interfaces(cfg_bytes, 200))))))
	line!(Text.printed(List.concat([19, 24, 15, 18, 2, 20, 25, 29, 13, 2, 14, 16, 14, 15, 23, 77, 9, 8, 8, 6, 8, 2, 17, 28, 15, 24, 13, 19, 77], Text.show_int(ifc_count(UsbHid.hid_scan_interfaces(cfg_bytes, 65535))))))
	line!(Text.printed(List.concat([19, 24, 15, 18, 2, 13, 26, 31, 14, 30, 2, 17, 28, 15, 24, 13, 19, 77], Text.show_int(ifc_count(UsbHid.hid_scan_interfaces([], 25))))))
	Ok({})
}
