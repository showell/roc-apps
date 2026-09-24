# forewords@ui-accessibility
#
# Ported from Cobblestone's Codex test suite, not written for Roc.
#
#   from      https://github.com/damiant3/Cobblestone/blob/master/codex/test/forewords@ui-accessibility.codex
#   emitted   by rocemit, https://github.com/showell/roc-apps (Codex -> Roc)
#
# The chapters it imports are in ./codex, a package of the Codex chapters
# these tests are emitted from. Written by tests/package.py. Do not edit.
#
# Expected stdout:
#     roles    : button/y textbox/y checkbox/y radio/y slider/y menu/n menuitem/y dialog/n alert/n status/n heading/n list/n listitem/n link/y image/n none/n
#     empty    : none off tab 0 hidden n None None 0 0 100
#     announce : Save, button | button
#     checkbox : Just True Sounds, checkbox
#     slider   : 40 of 0..100
#     heading  : heading level 2
#     alert    : assertive alert
#     status   : polite status
#     hidden   : y tab 7 Close, button

app [main!] { cdx: "./codex/main.roc" }

import cdx.Accessibility
import cdx.CceText
import cdx.Maybe

# FwdAccessibilityTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

yn : Bool -> CceText
yn = |b| (if b { "y" } else { "n" })

mb : Maybe.Maybe(Bool) -> CceText
mb = |m| (match m {
	Just(b) => (if b { "Just True" } else { "Just False" })
	None => "None"
})

live_name : Accessibility.A11yLive -> CceText
live_name = |l| (match l {
	LiveOff => "off"
	LivePolite => "polite"
	LiveAssertive => "assertive"
})

head_level : Accessibility.A11yRole -> I64
head_level = |r| (match r {
	RoleHeading(n) => n
	_ => (0 - 1)
})

cell : Accessibility.A11yRole -> CceText
cell = |r| CceText.concat(CceText.concat(Accessibility.a11y_role_name(r), "/"), yn(Accessibility.a11y_is_interactive(r)))

all_roles : List(Accessibility.A11yRole)
all_roles = [RoleButton, RoleTextbox, RoleCheckbox, RoleRadio, RoleSlider, RoleMenu, RoleMenuItem, RoleDialog, RoleAlert, RoleStatus, RoleHeading(2), RoleList, RoleListItem, RoleLink, RoleImage, RoleNone]

census : List(Accessibility.A11yRole), I64, CceText -> CceText
census = |rs, i, acc| (if (i >= U64.to_i64_wrap(List.len(rs))) { acc } else { census(rs, (i + 1), CceText.concat(CceText.concat(acc, " "), cell((List.get(rs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))))) })

# --- Entry ---

main! = |_args| {
	({
		e = Accessibility.a11y_empty
		btn = Accessibility.a11y_button("Save")
		bare = Accessibility.a11y_role(Accessibility.a11y_empty, RoleButton)
		chk = Accessibility.a11y_checkbox("Sounds", True)
		sld = Accessibility.a11y_slider("Volume", 40, 0, 100)
		hd = Accessibility.a11y_heading("Appearance", 2)
		al = Accessibility.a11y_alert("disk full")
		st = Accessibility.a11y_status("saved")
		hid = Accessibility.a11y_focus_order(Accessibility.a11y_hidden(Accessibility.a11y_button("Close")), 7)
		({
			line!(CceText.printed(CceText.concat("roles    :", census(all_roles, 0, ""))))
			line!(CceText.printed(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat("empty    : ", Accessibility.a11y_role_name(e.ai_role)), " "), live_name(e.ai_live)), " tab "), CceText.show_int(e.ai_tab_index)), " hidden "), yn(e.ai_hidden)), " "), mb(e.ai_expanded)), " "), mb(e.ai_checked)), " "), CceText.show_int(e.ai_value_now)), " "), CceText.show_int(e.ai_value_min)), " "), CceText.show_int(e.ai_value_max))))
			line!(CceText.printed(CceText.concat(CceText.concat(CceText.concat("announce : ", Accessibility.a11y_announce(btn)), " | "), Accessibility.a11y_announce(bare))))
			line!(CceText.printed(CceText.concat(CceText.concat(CceText.concat("checkbox : ", mb(chk.ai_checked)), " "), Accessibility.a11y_announce(chk))))
			line!(CceText.printed(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat("slider   : ", CceText.show_int(sld.ai_value_now)), " of "), CceText.show_int(sld.ai_value_min)), ".."), CceText.show_int(sld.ai_value_max))))
			line!(CceText.printed(CceText.concat(CceText.concat(CceText.concat("heading  : ", Accessibility.a11y_role_name(hd.ai_role)), " level "), CceText.show_int(head_level(hd.ai_role)))))
			line!(CceText.printed(CceText.concat(CceText.concat(CceText.concat("alert    : ", live_name(al.ai_live)), " "), Accessibility.a11y_role_name(al.ai_role))))
			line!(CceText.printed(CceText.concat(CceText.concat(CceText.concat("status   : ", live_name(st.ai_live)), " "), Accessibility.a11y_role_name(st.ai_role))))
			line!(CceText.printed(CceText.concat(CceText.concat(CceText.concat(CceText.concat(CceText.concat("hidden   : ", yn(hid.ai_hidden)), " tab "), CceText.show_int(hid.ai_tab_index)), " "), Accessibility.a11y_announce(hid))))
		})
	})
	Ok({})
}
