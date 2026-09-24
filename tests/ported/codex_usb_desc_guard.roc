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

import cdx.CceText
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
	line!(CceText.printed(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat("device vendor=", CceText.show_int(d.usb_vendor)), " product="), CceText.show_int(d.usb_product)), " class="), CceText.show_int(d.usb_class)), " configs="), CceText.show_int(d.usb_num_configs))))
	line!(CceText.printed(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat("device-short vendor=", CceText.show_int(dshort.usb_vendor)), " class="), CceText.show_int(dshort.usb_class)), " configs="), CceText.show_int(dshort.usb_num_configs))))
	line!(CceText.printed(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat("endpoint addr=", CceText.show_int(e.ep_address)), " dir="), CceText.show_int(e.ep_direction)), " type="), CceText.show_int(e.ep_type)), " maxpkt="), CceText.show_int(e.ep_max_packet)), " interval="), CceText.show_int(e.ep_interval))))
	line!(CceText.printed(CceText.concat(CceText.concat(CceText.concat("endpoint-past addr=", CceText.show_int(epast.ep_address)), " maxpkt="), CceText.show_int(epast.ep_max_packet))))
	line!(CceText.printed(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat("interface num=", CceText.show_int(i.if_number)), " class="), CceText.show_int(i.if_class)), " sub="), CceText.show_int(i.if_subclass)), " proto="), CceText.show_int(i.if_protocol)), " eps="), CceText.show_int(i.if_num_endpoints))))
	line!(CceText.printed(CceText.concat(CceText.concat(CceText.concat("interface-past num=", CceText.show_int(ipast.if_number)), " class="), CceText.show_int(ipast.if_class))))
	line!(CceText.printed(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat("le16 in=", CceText.show_int(Usb.usb_le16(cfg_bytes, 2))), " at-end="), CceText.show_int(Usb.usb_le16(cfg_bytes, 24))), " past="), CceText.show_int(Usb.usb_le16(cfg_bytes, 99)))))
	line!(CceText.printed(CceText.concat("scan honest total=25 ifaces=", CceText.show_int(ifc_count(UsbHid.hid_scan_interfaces(cfg_bytes, 25))))))
	line!(CceText.printed(CceText.concat("scan lying total=200 ifaces=", CceText.show_int(ifc_count(UsbHid.hid_scan_interfaces(cfg_bytes, 200))))))
	line!(CceText.printed(CceText.concat("scan huge total=65535 ifaces=", CceText.show_int(ifc_count(UsbHid.hid_scan_interfaces(cfg_bytes, 65535))))))
	line!(CceText.printed(CceText.concat("scan empty ifaces=", CceText.show_int(ifc_count(UsbHid.hid_scan_interfaces([], 25))))))
	Ok({})
}
