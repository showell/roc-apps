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
import cdx.Maybe
import cdx.Text

# FwdAccessibilityTest -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.

# The Echo platform's echo! writes no newline; a Codex line is one.
line! = |s| echo!(Str.concat(s, "\n"))

yn : Bool -> List(U8)
yn = |b| (if b { [30] } else { [18] })

mb : Maybe.Maybe(Bool) -> List(U8)
mb = |m| (match m {
	Just(b) => (if b { [61, 25, 19, 14, 2, 40, 21, 25, 13] } else { [61, 25, 19, 14, 2, 54, 15, 23, 19, 13] })
	None => [44, 16, 18, 13]
})

live_name : Accessibility.A11yLive -> List(U8)
live_name = |l| (match l {
	LiveOff => [16, 28, 28]
	LivePolite => [31, 16, 23, 17, 14, 13]
	LiveAssertive => [15, 19, 19, 13, 21, 14, 17, 33, 13]
})

head_level : Accessibility.A11yRole -> I64
head_level = |r| (match r {
	RoleHeading(n) => n
	_ => (0 - 1)
})

cell : Accessibility.A11yRole -> List(U8)
cell = |r| List.concat(List.concat(Accessibility.a11y_role_name(r), [81]), yn(Accessibility.a11y_is_interactive(r)))

all_roles : List(Accessibility.A11yRole)
all_roles = [RoleButton, RoleTextbox, RoleCheckbox, RoleRadio, RoleSlider, RoleMenu, RoleMenuItem, RoleDialog, RoleAlert, RoleStatus, RoleHeading(2), RoleList, RoleListItem, RoleLink, RoleImage, RoleNone]

census : List(Accessibility.A11yRole), I64, List(U8) -> List(U8)
census = |rs, i, acc| (if (i >= U64.to_i64_wrap(List.len(rs))) { acc } else { census(rs, (i + 1), List.concat(List.concat(acc, [2]), cell((List.get(rs, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))))) })

# --- Entry ---

main! = |_args| {
	({
		e = Accessibility.a11y_empty
		btn = Accessibility.a11y_button([45, 15, 33, 13])
		bare = Accessibility.a11y_role(Accessibility.a11y_empty, RoleButton)
		chk = Accessibility.a11y_checkbox([45, 16, 25, 18, 22, 19], True)
		sld = Accessibility.a11y_slider([59, 16, 23, 25, 26, 13], 40, 0, 100)
		hd = Accessibility.a11y_heading([41, 31, 31, 13, 15, 21, 15, 18, 24, 13], 2)
		al = Accessibility.a11y_alert([22, 17, 19, 34, 2, 28, 25, 23, 23])
		st = Accessibility.a11y_status([19, 15, 33, 13, 22])
		hid = Accessibility.a11y_focus_order(Accessibility.a11y_hidden(Accessibility.a11y_button([50, 23, 16, 19, 13])), 7)
		({
			line!(Text.printed(List.concat([21, 16, 23, 13, 19, 2, 2, 2, 2, 69], census(all_roles, 0, []))))
			line!(Text.printed(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat(List.concat([13, 26, 31, 14, 30, 2, 2, 2, 2, 69, 2], Accessibility.a11y_role_name(e.ai_role)), [2]), live_name(e.ai_live)), [2, 14, 15, 32, 2]), Text.show_int(e.ai_tab_index)), [2, 20, 17, 22, 22, 13, 18, 2]), yn(e.ai_hidden)), [2]), mb(e.ai_expanded)), [2]), mb(e.ai_checked)), [2]), Text.show_int(e.ai_value_now)), [2]), Text.show_int(e.ai_value_min)), [2]), Text.show_int(e.ai_value_max))))
			line!(Text.printed(List.concat(List.concat(List.concat([15, 18, 18, 16, 25, 18, 24, 13, 2, 69, 2], Accessibility.a11y_announce(btn)), [2, 87, 2]), Accessibility.a11y_announce(bare))))
			line!(Text.printed(List.concat(List.concat(List.concat([24, 20, 13, 24, 34, 32, 16, 36, 2, 69, 2], mb(chk.ai_checked)), [2]), Accessibility.a11y_announce(chk))))
			line!(Text.printed(List.concat(List.concat(List.concat(List.concat(List.concat([19, 23, 17, 22, 13, 21, 2, 2, 2, 69, 2], Text.show_int(sld.ai_value_now)), [2, 16, 28, 2]), Text.show_int(sld.ai_value_min)), [65, 65]), Text.show_int(sld.ai_value_max))))
			line!(Text.printed(List.concat(List.concat(List.concat([20, 13, 15, 22, 17, 18, 29, 2, 2, 69, 2], Accessibility.a11y_role_name(hd.ai_role)), [2, 23, 13, 33, 13, 23, 2]), Text.show_int(head_level(hd.ai_role)))))
			line!(Text.printed(List.concat(List.concat(List.concat([15, 23, 13, 21, 14, 2, 2, 2, 2, 69, 2], live_name(al.ai_live)), [2]), Accessibility.a11y_role_name(al.ai_role))))
			line!(Text.printed(List.concat(List.concat(List.concat([19, 14, 15, 14, 25, 19, 2, 2, 2, 69, 2], live_name(st.ai_live)), [2]), Accessibility.a11y_role_name(st.ai_role))))
			line!(Text.printed(List.concat(List.concat(List.concat(List.concat(List.concat([20, 17, 22, 22, 13, 18, 2, 2, 2, 69, 2], yn(hid.ai_hidden)), [2, 14, 15, 32, 2]), Text.show_int(hid.ai_tab_index)), [2]), Accessibility.a11y_announce(hid))))
		})
	})
	Ok({})
}
