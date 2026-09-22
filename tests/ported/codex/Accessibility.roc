# Accessibility -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import Maybe
import Text

Accessibility :: [].{
	A11yRole : [RoleButton, RoleTextbox, RoleCheckbox, RoleRadio, RoleSlider, RoleMenu, RoleMenuItem, RoleDialog, RoleAlert, RoleStatus, RoleHeading(I64), RoleList, RoleListItem, RoleLink, RoleImage, RoleNone]
	A11yLive : [LiveOff, LivePolite, LiveAssertive]
	A11yInfo : { ai_role : Accessibility.A11yRole, ai_label : List(U8), ai_description : List(U8), ai_live : Accessibility.A11yLive, ai_tab_index : I64, ai_hidden : Bool, ai_expanded : Maybe.Maybe(Bool), ai_checked : Maybe.Maybe(Bool), ai_value_now : I64, ai_value_min : I64, ai_value_max : I64 }

	a11y_empty : Accessibility.A11yInfo
	a11y_empty = { ai_role: RoleNone, ai_label: [], ai_description: [], ai_live: LiveOff, ai_tab_index: 0, ai_hidden: False, ai_expanded: None, ai_checked: None, ai_value_now: 0, ai_value_min: 0, ai_value_max: 100 }

	a11y_role : Accessibility.A11yInfo, Accessibility.A11yRole -> Accessibility.A11yInfo
	a11y_role = |info, role| { ..info, ai_role: role }

	a11y_label : Accessibility.A11yInfo, List(U8) -> Accessibility.A11yInfo
	a11y_label = |info, label| { ..info, ai_label: label }

	a11y_description : Accessibility.A11yInfo, List(U8) -> Accessibility.A11yInfo
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

	a11y_button : List(U8) -> Accessibility.A11yInfo
	a11y_button = |label| a11y_label(a11y_role(a11y_empty, RoleButton), label)

	a11y_textbox : List(U8) -> Accessibility.A11yInfo
	a11y_textbox = |label| a11y_label(a11y_role(a11y_empty, RoleTextbox), label)

	a11y_checkbox : List(U8), Bool -> Accessibility.A11yInfo
	a11y_checkbox = |label, checked| a11y_checked(a11y_label(a11y_role(a11y_empty, RoleCheckbox), label), checked)

	a11y_slider : List(U8), I64, I64, I64 -> Accessibility.A11yInfo
	a11y_slider = |label, now, lo, hi| a11y_value(a11y_label(a11y_role(a11y_empty, RoleSlider), label), now, lo, hi)

	a11y_heading : List(U8), I64 -> Accessibility.A11yInfo
	a11y_heading = |label, level| a11y_label(a11y_role(a11y_empty, RoleHeading(level)), label)

	a11y_alert : List(U8) -> Accessibility.A11yInfo
	a11y_alert = |msg| a11y_label(a11y_live(a11y_role(a11y_empty, RoleAlert), LiveAssertive), msg)

	a11y_status : List(U8) -> Accessibility.A11yInfo
	a11y_status = |msg| a11y_label(a11y_live(a11y_role(a11y_empty, RoleStatus), LivePolite), msg)

	a11y_role_name : Accessibility.A11yRole -> List(U8)
	a11y_role_name = |r| (match r {
		RoleButton => [32, 25, 14, 14, 16, 18]
		RoleTextbox => [14, 13, 36, 14, 32, 16, 36]
		RoleCheckbox => [24, 20, 13, 24, 34, 32, 16, 36]
		RoleRadio => [21, 15, 22, 17, 16]
		RoleSlider => [19, 23, 17, 22, 13, 21]
		RoleMenu => [26, 13, 18, 25]
		RoleMenuItem => [26, 13, 18, 25, 17, 14, 13, 26]
		RoleDialog => [22, 17, 15, 23, 16, 29]
		RoleAlert => [15, 23, 13, 21, 14]
		RoleStatus => [19, 14, 15, 14, 25, 19]
		RoleHeading(_n) => [20, 13, 15, 22, 17, 18, 29]
		RoleList => [23, 17, 19, 14]
		RoleListItem => [23, 17, 19, 14, 17, 14, 13, 26]
		RoleLink => [23, 17, 18, 34]
		RoleImage => [17, 26, 15, 29, 13]
		RoleNone => [18, 16, 18, 13]
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

	a11y_announce : Accessibility.A11yInfo -> List(U8)
	a11y_announce = |info| ({
		role = a11y_role_name(info.ai_role)
		label = info.ai_label
		(if (Text.len(label) > 0) { List.concat(List.concat(label, [66, 2]), role) } else { role })
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
