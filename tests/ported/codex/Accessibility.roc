# Accessibility -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import CceText
import Maybe

Accessibility :: [].{
	A11yRole : [RoleButton, RoleTextbox, RoleCheckbox, RoleRadio, RoleSlider, RoleMenu, RoleMenuItem, RoleDialog, RoleAlert, RoleStatus, RoleHeading(I64), RoleList, RoleListItem, RoleLink, RoleImage, RoleNone]
	A11yLive : [LiveOff, LivePolite, LiveAssertive]
	A11yInfo := { ai_role : Accessibility.A11yRole, ai_label : CceText, ai_description : CceText, ai_live : Accessibility.A11yLive, ai_tab_index : I64, ai_hidden : Bool, ai_expanded : Maybe.Maybe(Bool), ai_checked : Maybe.Maybe(Bool), ai_value_now : I64, ai_value_min : I64, ai_value_max : I64 }.{
		is_eq : Accessibility.A11yInfo, Accessibility.A11yInfo -> Bool
		is_eq = |a, b| a.ai_role == b.ai_role and a.ai_label == b.ai_label and a.ai_description == b.ai_description and a.ai_live == b.ai_live and a.ai_tab_index == b.ai_tab_index and a.ai_hidden == b.ai_hidden and a.ai_expanded == b.ai_expanded and a.ai_checked == b.ai_checked and a.ai_value_now == b.ai_value_now and a.ai_value_min == b.ai_value_min and a.ai_value_max == b.ai_value_max
	}

	a11y_empty : Accessibility.A11yInfo
	a11y_empty = Accessibility.A11yInfo.{ ai_role: RoleNone, ai_label: "", ai_description: "", ai_live: LiveOff, ai_tab_index: 0, ai_hidden: False, ai_expanded: None, ai_checked: None, ai_value_now: 0, ai_value_min: 0, ai_value_max: 100 }

	a11y_role : Accessibility.A11yInfo, Accessibility.A11yRole -> Accessibility.A11yInfo
	a11y_role = |info, role| { ..info, ai_role: role }

	a11y_label : Accessibility.A11yInfo, CceText -> Accessibility.A11yInfo
	a11y_label = |info, label| { ..info, ai_label: label }

	a11y_description : Accessibility.A11yInfo, CceText -> Accessibility.A11yInfo
	a11y_description = |info, desc| { ..info, ai_description: desc }

	a11y_live : Accessibility.A11yInfo, Accessibility.A11yLive -> Accessibility.A11yInfo
	a11y_live = |info, mode| { ..info, ai_live: mode }

	a11y_focus_order : Accessibility.A11yInfo, I64 -> Accessibility.A11yInfo
	a11y_focus_order = |info, idx| { ..info, ai_tab_index: idx }

	a11y_hidden : Accessibility.A11yInfo -> Accessibility.A11yInfo
	a11y_hidden = |info| { ..info, ai_hidden: True }

	a11y_expanded : Accessibility.A11yInfo, Bool -> Accessibility.A11yInfo
	a11y_expanded = |info, state| { ..info, ai_expanded: Just(state) }

	a11y_checked : Accessibility.A11yInfo, Bool -> Accessibility.A11yInfo
	a11y_checked = |info, state| { ..info, ai_checked: Just(state) }

	a11y_value : Accessibility.A11yInfo, I64, I64, I64 -> Accessibility.A11yInfo
	a11y_value = |info, now, min_val, max_val| { ..{ ..{ ..info, ai_value_now: now }, ai_value_min: min_val }, ai_value_max: max_val }

	a11y_button : CceText -> Accessibility.A11yInfo
	a11y_button = |label| a11y_label(a11y_role(a11y_empty, RoleButton), label)

	a11y_textbox : CceText -> Accessibility.A11yInfo
	a11y_textbox = |label| a11y_label(a11y_role(a11y_empty, RoleTextbox), label)

	a11y_checkbox : CceText, Bool -> Accessibility.A11yInfo
	a11y_checkbox = |label, checked| a11y_checked(a11y_label(a11y_role(a11y_empty, RoleCheckbox), label), checked)

	a11y_slider : CceText, I64, I64, I64 -> Accessibility.A11yInfo
	a11y_slider = |label, now, lo, hi| a11y_value(a11y_label(a11y_role(a11y_empty, RoleSlider), label), now, lo, hi)

	a11y_heading : CceText, I64 -> Accessibility.A11yInfo
	a11y_heading = |label, level| a11y_label(a11y_role(a11y_empty, RoleHeading(level)), label)

	a11y_alert : CceText -> Accessibility.A11yInfo
	a11y_alert = |msg| a11y_label(a11y_live(a11y_role(a11y_empty, RoleAlert), LiveAssertive), msg)

	a11y_status : CceText -> Accessibility.A11yInfo
	a11y_status = |msg| a11y_label(a11y_live(a11y_role(a11y_empty, RoleStatus), LivePolite), msg)

	a11y_role_name : Accessibility.A11yRole -> CceText
	a11y_role_name = |r| (match r {
		RoleButton => "button"
		RoleTextbox => "textbox"
		RoleCheckbox => "checkbox"
		RoleRadio => "radio"
		RoleSlider => "slider"
		RoleMenu => "menu"
		RoleMenuItem => "menuitem"
		RoleDialog => "dialog"
		RoleAlert => "alert"
		RoleStatus => "status"
		RoleHeading(_n) => "heading"
		RoleList => "list"
		RoleListItem => "listitem"
		RoleLink => "link"
		RoleImage => "image"
		RoleNone => "none"
	})

	a11y_is_interactive : Accessibility.A11yRole -> Bool
	a11y_is_interactive = |r| (match r {
		RoleButton => True
		RoleTextbox => True
		RoleCheckbox => True
		RoleRadio => True
		RoleSlider => True
		RoleLink => True
		RoleMenuItem => True
		_ => False
	})

	a11y_announce : Accessibility.A11yInfo -> CceText
	a11y_announce = |info| ({
		role = a11y_role_name(info.ai_role)
		label = info.ai_label
		(if (CceText.len(label) > 0) { CceText.concat(CceText.concat(label, ", "), role) } else { role })
	})

	eq_A11yRole : Accessibility.A11yRole, Accessibility.A11yRole -> Bool
	eq_A11yRole = |ex, ey| (match ex {
		RoleButton => (match ey {
			RoleButton => True
			_ => False
		})
		RoleTextbox => (match ey {
			RoleTextbox => True
			_ => False
		})
		RoleCheckbox => (match ey {
			RoleCheckbox => True
			_ => False
		})
		RoleRadio => (match ey {
			RoleRadio => True
			_ => False
		})
		RoleSlider => (match ey {
			RoleSlider => True
			_ => False
		})
		RoleMenu => (match ey {
			RoleMenu => True
			_ => False
		})
		RoleMenuItem => (match ey {
			RoleMenuItem => True
			_ => False
		})
		RoleDialog => (match ey {
			RoleDialog => True
			_ => False
		})
		RoleAlert => (match ey {
			RoleAlert => True
			_ => False
		})
		RoleStatus => (match ey {
			RoleStatus => True
			_ => False
		})
		RoleHeading(exf0) => (match ey {
			RoleHeading(eyf0) => (exf0 == eyf0)
			_ => False
		})
		RoleList => (match ey {
			RoleList => True
			_ => False
		})
		RoleListItem => (match ey {
			RoleListItem => True
			_ => False
		})
		RoleLink => (match ey {
			RoleLink => True
			_ => False
		})
		RoleImage => (match ey {
			RoleImage => True
			_ => False
		})
		RoleNone => (match ey {
			RoleNone => True
			_ => False
		})
	})

	eq_A11yLive : Accessibility.A11yLive, Accessibility.A11yLive -> Bool
	eq_A11yLive = |ex, ey| (match ex {
		LiveOff => (match ey {
			LiveOff => True
			_ => False
		})
		LivePolite => (match ey {
			LivePolite => True
			_ => False
		})
		LiveAssertive => (match ey {
			LiveAssertive => True
			_ => False
		})
	})
}
