note
	description: "[
		The calculator on the phone: a display and twenty keys. CALC_ENGINE does the
		work; this class only turns taps into key presses and shows the display.
	]"
	author: "Larry Rix"

class
	CALC_APP

create
	make

feature {NONE} -- Initialization

	make
			-- Build the screen, then hand over to the phone until it ends the app.
		local
			l_screen: PHONE_COLUMN
		do
			create phone.make
			controls := phone.controls
			create engine.make
			create display.make (controls, engine.display)
			create l_screen.make (controls)
			l_screen.set_surface (Background, 0)
			l_screen.set_spacing (Gap, Gap)
			build_display (l_screen)
			build_keys (l_screen)
			controls.show (l_screen)
			phone.run_controls
		end

feature {NONE} -- Building the screen

	build_display (a_screen: PHONE_COLUMN)
			-- The number, at the right, taking all the room the keys leave.
		do
			display.call_integer ("setGravity", Right_and_bottom)
			display.call_integer ("setMaxLines", 1)
			display.set_padding (8, 8)
			display.set_color (On_background)
			show_display
			a_screen.extend_growing (display, 1)
		end

	build_keys (a_screen: PHONE_COLUMN)
			-- Five rows of keys, at the bottom of the screen.
		local
			l_row: PHONE_ROW
		do
			l_row := new_row (a_screen)
			add_key (l_row, {STRING_32} "C", Quiet_key, agent on_clear, 1)
			add_key (l_row, Delete_sign, Quiet_key, agent on_delete, 1)
			add_key (l_row, Sign_sign, Quiet_key, agent on_sign, 1)
			add_key (l_row, Divide_sign, Loud_key, agent on_operator (engine.Op_divide), 1)

			l_row := new_row (a_screen)
			add_digit (l_row, 7)
			add_digit (l_row, 8)
			add_digit (l_row, 9)
			add_key (l_row, Times_sign, Loud_key, agent on_operator (engine.Op_multiply), 1)

			l_row := new_row (a_screen)
			add_digit (l_row, 4)
			add_digit (l_row, 5)
			add_digit (l_row, 6)
			add_key (l_row, Minus_sign, Loud_key, agent on_operator (engine.Op_subtract), 1)

			l_row := new_row (a_screen)
			add_digit (l_row, 1)
			add_digit (l_row, 2)
			add_digit (l_row, 3)
			add_key (l_row, {STRING_32} "+", Loud_key, agent on_operator (engine.Op_add), 1)

			l_row := new_row (a_screen)
			add_key (l_row, {STRING_32} "0", Plain_key, agent on_digit (0), 2)
			add_key (l_row, {STRING_32} ".", Plain_key, agent on_point, 1)
			add_key (l_row, {STRING_32} "=", Loud_key, agent on_equals, 1)
		end

	new_row (a_screen: PHONE_COLUMN): PHONE_ROW
			-- A row of keys at the bottom of `a_screen'.
		do
			create Result.make (controls)
			Result.set_spacing (Gap, 0)
			a_screen.extend (Result)
		end

	add_digit (a_row: PHONE_ROW; a_digit: INTEGER)
			-- The key for `a_digit'.
		do
			add_key (a_row, a_digit.out.to_string_32, Plain_key, agent on_digit (a_digit), 1)
		end

	add_key (a_row: PHONE_ROW; a_text: READABLE_STRING_32; a_color: NATURAL_32; a_action: PROCEDURE [TUPLE]; a_share: INTEGER)
			-- A key showing `a_text' that runs `a_action' when tapped.
			-- The on-the-key color decides the color of the text.
		local
			l_key: PHONE_LABEL
		do
			create l_key.make (controls, a_text)
			l_key.set_style (Key_size, False)
			l_key.call_integer ("setGravity", Center)
			l_key.set_color (if a_color = Loud_key then On_loud_key else On_background end)
			l_key.set_least_height (Key_height)
			l_key.set_surface (a_color, Key_corner)
			l_key.set_on_tap (a_action)
			a_row.extend_growing (l_key, a_share)
		end

feature {NONE} -- Taps

	on_digit (a_digit: INTEGER)
		do
			leave_error
			engine.press_digit (a_digit)
			show_display
		end

	on_point
		do
			leave_error
			engine.press_point
			show_display
		end

	on_delete
		do
			leave_error
			engine.press_delete
			show_display
		end

	on_sign
		do
			leave_error
			engine.press_sign
			show_display
		end

	on_operator (a_operator: INTEGER)
		do
			leave_error
			engine.press_operator (a_operator)
			show_display
		end

	on_equals
		do
			leave_error
			engine.press_equals
			show_display
		end

	on_clear
		do
			engine.press_clear
			show_display
		end

	leave_error
			-- The engine takes no key but clear after an error, as its contracts say.
			-- For the person tapping, any key starts over.
		do
			if engine.is_in_error then
				engine.press_clear
			end
		ensure
			ready: not engine.is_in_error
		end

	show_display
			-- Show what the engine says, smaller when it is long.
		do
			display.set_text (engine.display)
			display.set_style (if engine.display.count > 10 then Small_display_size else Display_size end, False)
			display.set_color (if engine.is_in_error then Error_text else On_background end)
		end

feature {NONE} -- Implementation

	phone: SIMPLE_EIF_PHONE

	controls: PHONE_CONTROLS

	engine: CALC_ENGINE

	display: PHONE_LABEL

feature {NONE} -- Sizes

	Gap: INTEGER = 8
			-- Between keys, in density-independent pixels.

	Key_height: INTEGER = 84

	Key_corner: INTEGER = 20

	Key_size: INTEGER = 28
			-- Key text, in scale-independent pixels, which follow the phone's font setting.

	Display_size: INTEGER = 56

	Small_display_size: INTEGER = 34

feature {NONE} -- Android's gravity numbers

	Center: INTEGER = 17

	Right_and_bottom: INTEGER = 85

feature {NONE} -- Colors, as 0xAARRGGBB

	Background: NATURAL_32 = 0xFF14161C

	On_background: NATURAL_32 = 0xFFECE7DA

	Plain_key: NATURAL_32 = 0xFF2A2E38

	Quiet_key: NATURAL_32 = 0xFF454A58

	Loud_key: NATURAL_32 = 0xFFE8C36A

	On_loud_key: NATURAL_32 = 0xFF2A2110

	Error_text: NATURAL_32 = 0xFFF2B8B5

feature {NONE} -- Signs that are not on a PC keyboard

	Delete_sign: STRING_32 = "%/9003/"

	Sign_sign: STRING_32 = "%/177/"

	Divide_sign: STRING_32 = "%/247/"

	Times_sign: STRING_32 = "%/215/"

	Minus_sign: STRING_32 = "%/8722/"

end
