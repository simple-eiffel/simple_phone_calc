note
	description: "Runs the calculator's tests on the PC."
	author: "Larry Rix"

class
	TEST_APP

create
	make

feature {NONE} -- Initialization

	make
			-- Run every test and say how it went.
		local
			l_tests: LIB_TESTS
		do
			print ("Running simple_phone_calc tests...%N%N")
			create l_tests
			across l_tests.all_cases as ic loop
				run_test (ic.test, ic.name)
			end
			print ("%N========================%N")
			print ("Results: " + passed.out + " passed, " + failed.out + " failed%N")
			if failed > 0 then
				print ("TESTS FAILED%N")
				(create {EXCEPTIONS}).die (1)
			else
				print ("ALL TESTS PASSED%N")
			end
		end

feature {NONE} -- Test Runners

	run_test (a_test: PROCEDURE; a_name: STRING_8)
			-- Run a single test and update counters.
		local
			l_retried: BOOLEAN
		do
			if not l_retried then
				a_test.call (Void)
				print ("  PASS: " + a_name + "%N")
				passed := passed + 1
			end
		rescue
			print ("  FAIL: " + a_name + "%N")
			if attached (create {EXCEPTION_MANAGER}).last_exception as al_ex and then attached al_ex.description as al_d then
				print ("    " + al_d.to_string_8 + "%N")
			end
			failed := failed + 1
			l_retried := True
			retry
		end

feature {NONE} -- Access

	passed, failed: INTEGER
			-- The counts.

end
