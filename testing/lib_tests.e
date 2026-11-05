note
	description: "The calculator's tests. They press keys and read the display, as a person would."
	author: "Larry Rix"
	testing: "covers"

class
	LIB_TESTS

inherit
	TEST_SET_BASE

feature -- The list

	all_cases: ARRAYED_LIST [TUPLE [name: STRING_8; test: PROCEDURE]]
			-- Every test, by name.
		do
			create Result.make (24)
			Result.extend (["starts at zero", agent test_starts_at_zero])
			Result.extend (["digits build a number", agent test_digits_build_a_number])
			Result.extend (["leading zeros collapse", agent test_leading_zeros_collapse])
			Result.extend (["typing stops at twelve digits", agent test_twelve_digits])
			Result.extend (["point starts a fraction", agent test_point])
			Result.extend (["a second point is ignored", agent test_second_point])
			Result.extend (["addition", agent test_addition])
			Result.extend (["subtraction goes negative", agent test_subtraction])
			Result.extend (["multiplication", agent test_multiplication])
			Result.extend (["division", agent test_division])
			Result.extend (["sums chain left to right", agent test_chain])
			Result.extend (["a second operator replaces the first", agent test_operator_replaced])
			Result.extend (["0.1 + 0.2 shows 0.3", agent test_point_one_plus_point_two])
			Result.extend (["one third is rounded", agent test_one_third])
			Result.extend (["equals alone changes nothing", agent test_equals_alone])
			Result.extend (["a digit after equals starts over", agent test_digit_after_equals])
			Result.extend (["an operator after equals carries on", agent test_operator_after_equals])
			Result.extend (["delete takes the last digit", agent test_delete])
			Result.extend (["delete stops at zero", agent test_delete_to_zero])
			Result.extend (["sign changes while typing", agent test_sign_typing])
			Result.extend (["sign changes a result", agent test_sign_result])
			Result.extend (["zero has no sign", agent test_zero_no_sign])
			Result.extend (["dividing by zero is an error", agent test_divide_by_zero])
			Result.extend (["too large is an error", agent test_too_large])
			Result.extend (["clear ends an error", agent test_clear_ends_error])
			Result.extend (["a key in error breaks a contract", agent test_contract_guards_error])
		end

feature -- Tests

	test_starts_at_zero
		do
			shows ("start", new_engine, "0")
		end

	test_digits_build_a_number
		local
			e: CALC_ENGINE
		do
			e := new_engine
			e.press_digit (1)
			e.press_digit (2)
			e.press_digit (3)
			shows ("123", e, "123")
		end

	test_leading_zeros_collapse
		local
			e: CALC_ENGINE
		do
			e := new_engine
			e.press_digit (0)
			e.press_digit (0)
			e.press_digit (7)
			shows ("7", e, "7")
		end

	test_twelve_digits
		local
			e: CALC_ENGINE
			i: INTEGER
		do
			e := new_engine
			from i := 1 until i > 15 loop
				e.press_digit (9)
				i := i + 1
			end
			shows ("twelve nines", e, "999999999999")
		end

	test_point
		local
			e: CALC_ENGINE
		do
			e := new_engine
			e.press_point
			shows ("zero point", e, "0.")
			e.press_digit (5)
			shows ("half", e, "0.5")
		end

	test_second_point
		local
			e: CALC_ENGINE
		do
			e := new_engine
			e.press_digit (1)
			e.press_point
			e.press_point
			e.press_digit (5)
			shows ("1.5", e, "1.5")
		end

	test_addition
		do
			shows ("2 + 3", sum (2, {CALC_ENGINE}.Op_add, 3), "5")
		end

	test_subtraction
		do
			shows ("2 - 3", sum (2, {CALC_ENGINE}.Op_subtract, 3), "-1")
		end

	test_multiplication
		do
			shows ("6 x 7", sum (6, {CALC_ENGINE}.Op_multiply, 7), "42")
		end

	test_division
		do
			shows ("9 / 2", sum (9, {CALC_ENGINE}.Op_divide, 2), "4.5")
		end

	test_chain
		local
			e: CALC_ENGINE
		do
			e := new_engine
			e.press_digit (2)
			e.press_operator (e.Op_add)
			e.press_digit (3)
			e.press_operator (e.Op_multiply)
			shows ("running total", e, "5")
			e.press_digit (4)
			e.press_equals
			shows ("(2 + 3) x 4", e, "20")
		end

	test_operator_replaced
		local
			e: CALC_ENGINE
		do
			e := new_engine
			e.press_digit (8)
			e.press_operator (e.Op_add)
			e.press_operator (e.Op_subtract)
			e.press_digit (3)
			e.press_equals
			shows ("8 - 3", e, "5")
		end

	test_point_one_plus_point_two
		local
			e: CALC_ENGINE
		do
			e := new_engine
			e.press_point
			e.press_digit (1)
			e.press_operator (e.Op_add)
			e.press_point
			e.press_digit (2)
			e.press_equals
			shows ("no noise", e, "0.3")
		end

	test_one_third
		do
			shows ("1 / 3", sum (1, {CALC_ENGINE}.Op_divide, 3), "0.33333333333")
		end

	test_equals_alone
		local
			e: CALC_ENGINE
		do
			e := new_engine
			e.press_digit (4)
			e.press_equals
			e.press_equals
			shows ("still 4", e, "4")
		end

	test_digit_after_equals
		local
			e: CALC_ENGINE
		do
			e := sum (2, {CALC_ENGINE}.Op_add, 3)
			e.press_digit (9)
			shows ("new number", e, "9")
		end

	test_operator_after_equals
		local
			e: CALC_ENGINE
		do
			e := sum (2, {CALC_ENGINE}.Op_add, 3)
			e.press_operator (e.Op_multiply)
			e.press_digit (2)
			e.press_equals
			shows ("5 x 2", e, "10")
		end

	test_delete
		local
			e: CALC_ENGINE
		do
			e := new_engine
			e.press_digit (1)
			e.press_digit (2)
			e.press_delete
			shows ("1", e, "1")
		end

	test_delete_to_zero
		local
			e: CALC_ENGINE
		do
			e := new_engine
			e.press_digit (1)
			e.press_delete
			shows ("0", e, "0")
			e.press_delete
			shows ("still 0", e, "0")
		end

	test_sign_typing
		local
			e: CALC_ENGINE
		do
			e := new_engine
			e.press_digit (5)
			e.press_sign
			shows ("-5", e, "-5")
			e.press_sign
			shows ("5", e, "5")
		end

	test_sign_result
		local
			e: CALC_ENGINE
		do
			e := sum (2, {CALC_ENGINE}.Op_add, 3)
			e.press_sign
			shows ("-5", e, "-5")
		end

	test_zero_no_sign
		local
			e: CALC_ENGINE
		do
			e := new_engine
			e.press_sign
			shows ("0 at the start", e, "0")
			e.press_digit (0)
			e.press_sign
			shows ("0 typed", e, "0")
		end

	test_divide_by_zero
		local
			e: CALC_ENGINE
		do
			e := sum (1, {CALC_ENGINE}.Op_divide, 0)
			assert_true ("in error", e.is_in_error)
			shows ("message", e, "Cannot divide by zero")
		end

	test_too_large
		local
			e: CALC_ENGINE
			i: INTEGER
		do
			e := new_engine
			from i := 1 until i > 12 loop
				e.press_digit (9)
				i := i + 1
			end
			e.press_operator (e.Op_multiply)
			e.press_digit (9)
			e.press_equals
			assert_true ("in error", e.is_in_error)
			shows ("message", e, "Too large")
		end

	test_clear_ends_error
		local
			e: CALC_ENGINE
		do
			e := sum (1, {CALC_ENGINE}.Op_divide, 0)
			e.press_clear
			assert_false ("no error", e.is_in_error)
			shows ("zero", e, "0")
		end

	test_contract_guards_error
			-- The contract is a test too: pressing a digit in error must be refused.
		local
			e: CALC_ENGINE
			l_refused, l_tried: BOOLEAN
		do
			if not l_tried then
				l_tried := True
				e := sum (1, {CALC_ENGINE}.Op_divide, 0)
				e.press_digit (1)
			else
				l_refused := True
			end
			assert_true ("refused", l_refused)
		rescue
			if not l_tried then
				l_tried := True
			end
			retry
		end

feature {NONE} -- Helpers

	new_engine: CALC_ENGINE
		do
			create Result.make
		end

	sum (a_left, a_operator, a_right: INTEGER): CALC_ENGINE
			-- A calculator that has just worked out `a_left' `a_operator' `a_right'.
		do
			create Result.make
			Result.press_digit (a_left)
			Result.press_operator (a_operator)
			Result.press_digit (a_right)
			Result.press_equals
		end

	shows (a_tag: STRING_8; a_engine: CALC_ENGINE; a_text: READABLE_STRING_32)
			-- Does `a_engine' show `a_text'?
		do
			assert (a_tag + ": shows " + a_engine.display.to_string_8, a_engine.display.same_string (a_text))
		end

end
