note
	description: "[
		A four-function calculator with no screen. It knows what the keys do and
		what the display should say, and nothing about phones, so it can be tested
		on a PC. CALC_APP puts it on the phone.
	]"
	author: "Larry Rix"

class
	CALC_ENGINE

create
	make

feature {NONE} -- Initialization

	make
			-- Start at zero.
		do
			create display.make_from_string (Zero)
			create entry.make_empty
		ensure
			shows_zero: display.same_string (Zero)
			nothing_pending: pending_operator = Op_none
			no_error: not is_in_error
		end

feature -- Operators

	Op_none: INTEGER = 0

	Op_add: INTEGER = 1

	Op_subtract: INTEGER = 2

	Op_multiply: INTEGER = 3

	Op_divide: INTEGER = 4

feature -- Access

	display: STRING_32
			-- What the calculator shows.

	pending_operator: INTEGER
			-- The operator waiting for its second number.

	is_in_error: BOOLEAN
			-- Is the calculator showing an error? Only `press_clear' may follow.

feature -- Queries

	is_operator (a_operator: INTEGER): BOOLEAN
			-- Is `a_operator' one of the four?
		do
			Result := a_operator >= Op_add and a_operator <= Op_divide
		ensure
			definition: Result = (a_operator >= Op_add and a_operator <= Op_divide)
		end

feature -- Keys

	press_digit (a_digit: INTEGER)
			-- Add `a_digit' to the number being typed, or start a new one.
		require
			a_digit_valid: a_digit >= 0 and a_digit <= 9
			not_in_error: not is_in_error
		do
			if not is_typing then
				start_typing
			end
			if entry.same_string (Zero_8) then
				entry.wipe_out
			end
			if digit_count (entry) < Most_digits then
				entry.append_integer (a_digit)
			end
			show_entry
		ensure
			typing: is_typing
			operator_unchanged: pending_operator = old pending_operator
		end

	press_point
			-- Start the fraction of the number being typed.
		require
			not_in_error: not is_in_error
		do
			if not is_typing then
				start_typing
			end
			if entry.is_empty then
				entry.append (Zero_8)
			end
			if not entry.has ('.') then
				entry.append_character ('.')
			end
			show_entry
		ensure
			typing: is_typing
			one_point: entry.occurrences ('.') = 1
		end

	press_delete
			-- Take the last character off the number being typed.
		require
			not_in_error: not is_in_error
		do
			if is_typing then
				entry.remove_tail (1)
				if entry.is_empty or entry.same_string ("-") then
					entry.wipe_out
					entry.append (Zero_8)
				end
				show_entry
			end
		ensure
			never_empty: not display.is_empty
		end

	press_sign
			-- Change the sign of what is showing.
		require
			not_in_error: not is_in_error
		do
			if is_typing then
				if entry.starts_with ("-") then
					entry.remove_head (1)
				elseif not entry.same_string (Zero_8) then
					entry.prepend_character ('-')
				end
				show_entry
			else
				accumulator := -accumulator
				show_value (accumulator)
			end
		ensure
			operator_unchanged: pending_operator = old pending_operator
		end

	press_operator (a_operator: INTEGER)
			-- Finish any sum waiting, and wait for the next number.
		require
			known: is_operator (a_operator)
			not_in_error: not is_in_error
		do
			if is_typing then
				finish_sum
			end
			if not is_in_error then
				pending_operator := a_operator
			end
		ensure
			not_typing: not is_typing
			waiting: not is_in_error implies pending_operator = a_operator
		end

	press_equals
			-- Finish any sum waiting.
		require
			not_in_error: not is_in_error
		do
			if is_typing then
				finish_sum
			end
			pending_operator := Op_none
		ensure
			nothing_pending: pending_operator = Op_none
			not_typing: not is_typing
		end

	press_clear
			-- Back to zero, from anything.
		do
			accumulator := 0.0
			pending_operator := Op_none
			is_in_error := False
			is_typing := False
			entry.wipe_out
			display.wipe_out
			display.append (Zero)
		ensure
			shows_zero: display.same_string (Zero)
			nothing_pending: pending_operator = Op_none
			no_error: not is_in_error
		end

feature {NONE} -- The sum

	finish_sum
			-- Apply `pending_operator' to `accumulator' and the number typed.
		require
			typing: is_typing
		local
			l_typed: REAL_64
		do
			l_typed := typed_value
			is_typing := False
			inspect pending_operator
			when Op_add then
				show_value (accumulator + l_typed)
			when Op_subtract then
				show_value (accumulator - l_typed)
			when Op_multiply then
				show_value (accumulator * l_typed)
			when Op_divide then
				if l_typed = 0.0 then
					show_error (Divide_by_zero)
				else
					show_value (accumulator / l_typed)
				end
			else
				show_value (l_typed)
			end
		ensure
			not_typing: not is_typing
		end

	typed_value: REAL_64
			-- The number being typed.
		do
			if entry.is_double then
				Result := entry.to_double
			end
		end

feature {NONE} -- What the display says

	start_typing
			-- A new number starts empty.
		do
			entry.wipe_out
			is_typing := True
		ensure
			typing: is_typing
			empty: entry.is_empty
		end

	show_entry
			-- Show the number as typed, with any point it ends in.
		do
			display.wipe_out
			display.append_string_general (entry)
		end

	show_value (a_value: REAL_64)
			-- Remember `a_value' and show it, or say it is too large.
		do
			if a_value.abs >= Largest then
				show_error (Too_large)
			else
				accumulator := a_value
				display.wipe_out
				display.append (text_of (a_value))
			end
		end

	show_error (a_message: READABLE_STRING_32)
			-- Show `a_message' until `press_clear'.
		do
			is_in_error := True
			pending_operator := Op_none
			display.wipe_out
			display.append (a_message)
		ensure
			in_error: is_in_error
		end

	text_of (a_value: REAL_64): STRING_32
			-- `a_value' to `Most_digits' significant digits, with no trailing zeros.
			-- A REAL_64 cannot hold 0.1 exactly, so 0.1 + 0.2 has noise in its last
			-- digits. Rounding here is what makes it show as 0.3.
		require
			fits: a_value.abs < Largest
		local
			l_size: REAL_64
			l_places, l_scale, l_scaled, l_whole, l_fraction: INTEGER_64
			l_digits: STRING_8
			i: INTEGER
		do
			l_places := Most_digits - 1
			from
				l_size := a_value.abs
			until
				l_size < 10.0 or l_places = 0
			loop
				l_size := l_size / 10.0
				l_places := l_places - 1
			end
			l_scale := 1
			from i := 1 until i > l_places loop
				l_scale := l_scale * 10
				i := i + 1
			end
			l_scaled := (a_value.abs * l_scale.to_double + 0.5).truncated_to_integer_64
			l_whole := l_scaled // l_scale
			l_fraction := l_scaled \\ l_scale
			create Result.make (Most_digits + 2)
			if a_value < 0.0 and l_scaled /= 0 then
				Result.append_character ('-')
			end
			Result.append_string_general (l_whole.out)
			if l_fraction /= 0 then
				l_digits := l_fraction.out
				from until l_digits.count >= l_places loop
					l_digits.prepend_character ('0')
				end
				from until l_digits [l_digits.count] /= '0' loop
					l_digits.remove_tail (1)
				end
				Result.append_character ('.')
				Result.append_string_general (l_digits)
			end
		ensure
			not_empty: not Result.is_empty
		end

	digit_count (a_text: READABLE_STRING_8): INTEGER
			-- How many digits `a_text' holds.
		do
			across a_text as ic loop
				if ic.is_digit then
					Result := Result + 1
				end
			end
		ensure
			not_negative: Result >= 0
		end

feature {NONE} -- Implementation

	accumulator: REAL_64
			-- The running total.

	entry: STRING_8
			-- The number being typed, as typed.

	is_typing: BOOLEAN
			-- Is a number being typed?

	Most_digits: INTEGER = 12
			-- How many digits a number may have.

	Largest: REAL_64 = 1.0e12
			-- The first number too large to show.

	Zero: STRING_32 = "0"

	Zero_8: STRING_8 = "0"

	Divide_by_zero: STRING_32 = "Cannot divide by zero"

	Too_large: STRING_32 = "Too large"

invariant
	display_exists: not display.is_empty
	operator_known: pending_operator = Op_none or is_operator (pending_operator)
	error_ends_the_sum: is_in_error implies pending_operator = Op_none

end
