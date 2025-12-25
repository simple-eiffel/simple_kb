note
	description: "Test runner for simple_kb"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_APP

inherit
	SHARED_EXECUTION_ENVIRONMENT

create
	make

feature {NONE} -- Initialization

	make
			-- Run tests
		do
			io.put_string ("simple_kb Test Suite%N")
			io.put_string ("===================%N%N")

			create lib_tests.make
			run_all_tests
			print_summary
			lib_tests.cleanup
		end

feature -- Tests

	lib_tests: LIB_TESTS
			-- Test class instance

	passed: INTEGER
	failed: INTEGER
	total: INTEGER

	run_all_tests
			-- Run all test methods
		do
			io.put_string ("Database Tests:%N")
			run_test (agent lib_tests.test_database_create, "test_database_create")
			run_test (agent lib_tests.test_schema_creation, "test_schema_creation")
			run_test (agent lib_tests.test_fts5_available, "test_fts5_available")

			io.put_string ("%NError Tests:%N")
			run_test (agent lib_tests.test_add_error, "test_add_error")
			run_test (agent lib_tests.test_get_error, "test_get_error")
			run_test (agent lib_tests.test_error_formatted, "test_error_formatted")

			io.put_string ("%NSearch Tests:%N")
			run_test (agent lib_tests.test_search_basic, "test_search_basic")
			run_test (agent lib_tests.test_search_ranking, "test_search_ranking")

			io.put_string ("%NClass Tests:%N")
			run_test (agent lib_tests.test_add_class, "test_add_class")
			run_test (agent lib_tests.test_find_class, "test_find_class")

			io.put_string ("%NExample Tests:%N")
			run_test (agent lib_tests.test_add_example, "test_add_example")
			run_test (agent lib_tests.test_search_examples, "test_search_examples")

			io.put_string ("%NPattern Tests:%N")
			run_test (agent lib_tests.test_add_pattern, "test_add_pattern")
			run_test (agent lib_tests.test_get_pattern, "test_get_pattern")
			run_test (agent lib_tests.test_pattern_seeder, "test_pattern_seeder")

			io.put_string ("%NQuick Facade Tests:%N")
			run_test (agent lib_tests.test_kb_quick_search, "test_kb_quick_search")
			run_test (agent lib_tests.test_kb_quick_stats, "test_kb_quick_stats")

			io.put_string ("%NSeeder Tests:%N")
			run_test (agent lib_tests.test_error_seeder, "test_error_seeder")

			io.put_string ("%NIngester Tests:%N")
			run_test (agent lib_tests.test_ingester_create, "test_ingester_create")
			run_test (agent lib_tests.test_ingester_parse_file, "test_ingester_parse_file")
			run_test (agent lib_tests.test_ingester_stats, "test_ingester_stats")

			io.put_string ("%NIngester Regression Tests (Parser Issues):%N")
			run_test (agent lib_tests.test_ingester_feature_count_not_one, "test_ingester_feature_count_not_one")
			run_test (agent lib_tests.test_ingester_average_features_per_class, "test_ingester_average_features_per_class")
			run_test (agent lib_tests.test_stdlib_parsing_not_all_errors, "test_stdlib_parsing_not_all_errors")
			run_test (agent lib_tests.test_parser_exception_handling, "test_parser_exception_handling")
			run_test (agent lib_tests.test_minimal_class_parsing, "test_minimal_class_parsing")
			run_test (agent lib_tests.test_sed_meta_model_file, "test_sed_meta_model_file")
			run_test (agent lib_tests.test_long_lines_file, "test_long_lines_file")

			io.put_string ("%NRosetta Importer Tests:%N")
			run_test (agent lib_tests.test_rosetta_importer_create, "test_rosetta_importer_create")
			run_test (agent lib_tests.test_rosetta_import_all, "test_rosetta_import_all")

			io.put_string ("%NClass Metadata Tests:%N")
			run_test (agent lib_tests.test_class_deferred, "test_class_deferred")
			run_test (agent lib_tests.test_class_parents, "test_class_parents")

			io.put_string ("%NAncestry Tests:%N")
			run_test (agent lib_tests.test_ancestry_simple, "test_ancestry_simple")
			run_test (agent lib_tests.test_diamond_inheritance, "test_diamond_inheritance")

			io.put_string ("%NFeature Metadata Tests:%N")
			run_test (agent lib_tests.test_feature_deferred, "test_feature_deferred")
			run_test (agent lib_tests.test_feature_once, "test_feature_once")

			io.put_string ("%NEdge Case Tests:%N")
			run_test (agent lib_tests.test_class_no_parents, "test_class_no_parents")
			run_test (agent lib_tests.test_unknown_class_ancestry, "test_unknown_class_ancestry")
		end

	run_test (a_test: PROCEDURE; a_name: STRING)
			-- Run single test with error handling
		local
			l_rescued: BOOLEAN
		do
			if not l_rescued then
				total := total + 1
				a_test.call (Void)
				passed := passed + 1
				io.put_string ("  [PASS] " + a_name + "%N")
			end
		rescue
			failed := failed + 1
			io.put_string ("  [FAIL] " + a_name + "%N")
			l_rescued := True
			retry
		end

	print_summary
			-- Print test summary
		do
			io.put_string ("%N===================%N")
			io.put_string ("Tests: " + total.out + " | ")
			io.put_string ("Passed: " + passed.out + " | ")
			io.put_string ("Failed: " + failed.out + "%N")

			if failed = 0 then
				io.put_string ("%NAll tests passed!%N")
			else
				io.put_string ("%NSOME TESTS FAILED%N")
			end
		end

end
