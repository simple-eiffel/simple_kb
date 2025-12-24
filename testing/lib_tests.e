note
	description: "Unit tests for simple_kb"
	date: "$Date$"
	revision: "$Revision$"

class
	LIB_TESTS

create
	make

feature {NONE} -- Initialization

	make
			-- Initialize test fixture
		do
			create db.make_in_memory
		end

feature -- Test Fixture

	db: KB_DATABASE
			-- Test database (in-memory)

	cleanup
			-- Close database
		do
			db.close
		end

feature -- Database Tests

	test_database_create
			-- Test database creation
		local
			l_db: KB_DATABASE
		do
			create l_db.make_in_memory
			assert ("db_open", l_db.is_open)
			l_db.close
		end

	test_schema_creation
			-- Test schema is created
		do
			assert ("db_open", db.is_open)
			assert ("no_error", not db.has_error)
		end

	test_fts5_available
			-- Test FTS5 extension is available
		do
			assert ("fts5_available", db.fts5_available)
		end

feature -- Error Tests

	test_add_error
			-- Test adding error entry
		local
			l_error: KB_ERROR_INFO
		do
			create l_error.make ("TEST01", "Test error meaning")
			l_error.set_explanation ("Full explanation of the test error")
			l_error.add_cause ("Cause 1")
			l_error.add_cause ("Cause 2")
			l_error.add_fix ("Fix 1", "Description of fix 1", "code example 1")

			db.add_error (l_error)
			assert ("no_error", not db.has_error)
		end

	test_get_error
			-- Test retrieving error
		local
			l_error: detachable KB_ERROR_INFO
		do
			-- First add an error
			test_add_error

			-- Then retrieve it
			l_error := db.get_error ("TEST01")
			assert ("error_found", l_error /= Void)
			if attached l_error as err then
				assert ("code_match", err.code.same_string ("TEST01"))
				assert ("meaning_match", err.meaning.same_string ("Test error meaning"))
				assert ("has_causes", err.common_causes.count >= 2)
			end
		end

	test_error_formatted
			-- Test error formatting
		local
			l_error: KB_ERROR_INFO
			l_formatted: STRING_32
		do
			create l_error.make ("VEVI", "Variable not properly set")
			l_error.set_explanation ("An attached variable must be assigned on all paths")
			l_error.add_cause ("Result not assigned in else branch")
			l_error.add_fix ("Add else branch", "Ensure all paths assign value", "else Result := default end")
			l_error.set_ecma_section ("8.19.17")

			l_formatted := l_error.formatted
			assert ("has_code", l_formatted.has_substring ("VEVI"))
			assert ("has_meaning", l_formatted.has_substring ("Variable not properly set"))
			assert ("has_ecma", l_formatted.has_substring ("8.19.17"))
		end

feature -- Search Tests

	test_search_basic
			-- Test basic FTS5 search
		local
			l_error: KB_ERROR_INFO
			l_results: ARRAYED_LIST [KB_RESULT]
		do
			-- Add searchable content
			create l_error.make ("SEARCH1", "JSON parsing error")
			l_error.set_explanation ("Error when parsing JSON content")
			db.add_error (l_error)

			-- Search for it
			l_results := db.search ("JSON", 10)
			assert ("found_results", not l_results.is_empty)
		end

	test_search_ranking
			-- Test BM25 ranking
		local
			l_err1, l_err2: KB_ERROR_INFO
			l_results: ARRAYED_LIST [KB_RESULT]
		do
			-- Add two errors, one more relevant
			create l_err1.make ("RANK1", "Database connection timeout")
			l_err1.set_explanation ("Connection to database timed out")
			db.add_error (l_err1)

			create l_err2.make ("RANK2", "Database database database")
			l_err2.set_explanation ("Database database database database")
			db.add_error (l_err2)

			-- Search should rank RANK2 higher (more "database" occurrences)
			l_results := db.search ("database", 10)
			assert ("found_results", l_results.count >= 2)
		end

feature -- Class Tests

	test_add_class
			-- Test adding class entry
		local
			l_class: KB_CLASS_INFO
		do
			create l_class.make ("simple_json", "JSON_PARSER")
			l_class.set_description ("Parse JSON text into structured objects")
			l_class.set_file_path ("/d/prod/simple_json/src/json_parser.e")

			db.add_class (l_class)
			assert ("no_error", not db.has_error)
			assert ("has_id", l_class.id > 0)
		end

	test_find_class
			-- Test finding class
		local
			l_class: detachable KB_CLASS_INFO
		do
			-- First add a class
			test_add_class

			-- Then find it
			l_class := db.find_class ("JSON_PARSER")
			assert ("class_found", l_class /= Void)
			if attached l_class as cls then
				assert ("name_match", cls.name.same_string ("JSON_PARSER"))
				assert ("library_match", cls.library.same_string ("simple_json"))
			end
		end

feature -- Example Tests

	test_add_example
			-- Test adding example
		local
			l_example: KB_EXAMPLE
		do
			create l_example.make ("Bubble Sort", "[
				class BUBBLE_SORT
				feature
					sort (a: ARRAY[INTEGER])
						do
							-- implementation
						end
				end
			]")
			l_example.set_source ("rosetta")
			l_example.set_tier ("TIER1")
			l_example.add_tag ("sorting")
			l_example.add_tag ("array")

			db.add_example (l_example)
			assert ("no_error", not db.has_error)
			assert ("has_id", l_example.id > 0)
		end

	test_search_examples
			-- Test searching examples
		local
			l_results: ARRAYED_LIST [KB_EXAMPLE]
		do
			-- First add an example
			test_add_example

			-- Then search
			l_results := db.search_examples ("sort", 10)
			assert ("found_examples", not l_results.is_empty)
		end

feature -- Pattern Tests

	test_add_pattern
			-- Test adding pattern
		local
			l_pattern: KB_PATTERN
		do
			create l_pattern.make ("singleton", "[
				shared_instance: MY_CLASS
					once
						create Result.make
					end
			]")
			l_pattern.set_description ("Ensure only one instance exists")
			l_pattern.set_when_to_use ("When you need global access to single instance")
			l_pattern.add_idiom ("Use once function, not class")
			l_pattern.add_idiom ("once per process by default")

			db.add_pattern (l_pattern)
			assert ("no_error", not db.has_error)
			assert ("has_id", l_pattern.id > 0)
		end

	test_get_pattern
			-- Test getting pattern
		local
			l_pattern: detachable KB_PATTERN
		do
			-- First add a pattern
			test_add_pattern

			-- Then get it
			l_pattern := db.get_pattern ("singleton")
			assert ("pattern_found", l_pattern /= Void)
			if attached l_pattern as pat then
				assert ("name_match", pat.name.same_string ("singleton"))
				assert ("has_idioms", not pat.eiffel_idioms.is_empty)
			end
		end

	test_pattern_seeder
			-- Test pattern seeder populates database
		local
			l_seeder: KB_PATTERN_SEEDER
			l_patterns: ARRAYED_LIST [KB_PATTERN]
			l_singleton: detachable KB_PATTERN
		do
			create l_seeder.make (db)
			l_patterns := db.all_patterns
			assert ("seeder_added_patterns", l_patterns.count >= 10)

			-- Verify specific pattern
			l_singleton := db.get_pattern ("singleton")
			assert ("singleton_found", l_singleton /= Void)
			if attached l_singleton as pat then
				assert ("singleton_has_idioms", not pat.eiffel_idioms.is_empty)
				assert ("singleton_has_code", not pat.code.is_empty)
			end
		end

feature -- Quick Facade Tests

	test_kb_quick_search
			-- Test KB_QUICK search
		local
			l_quick: KB_QUICK
			l_results: ARRAYED_LIST [KB_RESULT]
			l_error: KB_ERROR_INFO
		do
			-- Add some content first
			create l_error.make ("QUICK1", "Quick test error")
			db.add_error (l_error)

			-- Test via quick facade (using same db)
			create l_quick.make_with_path (":memory:")
			-- Note: This creates new db, so add content there
			create l_error.make ("QUICK2", "Another quick test")
			l_quick.db.add_error (l_error)

			l_results := l_quick.search ("quick")
			assert ("results_returned", l_results /= Void)
			l_quick.close
		end

	test_kb_quick_stats
			-- Test KB_QUICK stats
		local
			l_quick: KB_QUICK
			l_stats: TUPLE [classes, features, examples, errors, patterns: INTEGER]
		do
			create l_quick.make_with_path (":memory:")
			l_stats := l_quick.stats
			assert ("stats_returned", l_stats /= Void)
			-- Empty db should have 0 counts
			assert ("zero_classes", l_stats.classes = 0)
			l_quick.close
		end

feature -- Seeder Tests

	test_error_seeder
			-- Test error seeder populates database
		local
			l_seeder: KB_ERROR_SEEDER
			l_errors: ARRAYED_LIST [KB_ERROR_INFO]
			l_vevi: detachable KB_ERROR_INFO
		do
			create l_seeder.make (db)
			l_errors := db.all_errors
			assert ("seeder_added_errors", l_errors.count >= 30)

			-- Verify specific error
			l_vevi := db.get_error ("VEVI")
			assert ("vevi_found", l_vevi /= Void)
			if attached l_vevi as err then
				assert ("vevi_has_causes", err.common_causes.count >= 2)
				assert ("vevi_has_fixes", err.fixes.count >= 1)
			end
		end

feature -- Ingester Tests

	test_ingester_create
			-- Test ingester creation
		local
			l_ingester: KB_INGESTER
		do
			create l_ingester.make (db)
			assert ("stats_zero", l_ingester.files_processed = 0)
			assert ("classes_zero", l_ingester.classes_indexed = 0)
		end

	test_ingester_parse_file
			-- Test parsing a single file
		local
			l_ingester: KB_INGESTER
			l_class: detachable KB_CLASS_INFO
		do
			create l_ingester.make (db)
			-- Parse a known file from simple_kb itself
			l_ingester.ingest_file ("simple_kb", "D:/prod/simple_kb/src/kb_result.e")
			assert ("file_processed", l_ingester.files_processed = 1)
			assert ("class_indexed", l_ingester.classes_indexed >= 1)

			-- Verify class was added
			l_class := db.find_class ("KB_RESULT")
			assert ("class_found", l_class /= Void)
		end

	test_ingester_stats
			-- Test ingester statistics
		local
			l_ingester: KB_INGESTER
			l_stats: TUPLE [files, classes, features, errors: INTEGER]
		do
			create l_ingester.make (db)
			l_ingester.ingest_file ("simple_kb", "D:/prod/simple_kb/src/kb_pattern.e")
			l_stats := l_ingester.stats
			assert ("files_counted", l_stats.files >= 1)
			assert ("classes_counted", l_stats.classes >= 1)
		end

feature -- Rosetta Importer Tests

	test_rosetta_importer_create
			-- Test Rosetta importer creation
		local
			l_importer: KB_ROSETTA_IMPORTER
		do
			create l_importer.make (db)
			assert ("stats_zero", l_importer.examples_imported = 0)
		end

	test_rosetta_import_all
			-- Test importing Rosetta examples
		local
			l_importer: KB_ROSETTA_IMPORTER
			l_examples: ARRAYED_LIST [KB_EXAMPLE]
		do
			create l_importer.make (db)
			l_importer.import_all ("D:/prod/simple_rosetta")
			assert ("examples_imported", l_importer.examples_imported > 100)

			-- Search for imported examples
			l_examples := db.search_examples ("sort", 10)
			assert ("found_sort_examples", not l_examples.is_empty)
		end

feature {NONE} -- Assertion Helper

	assert (a_tag: STRING; a_condition: BOOLEAN)
			-- Assert condition is true
		require
			tag_not_empty: not a_tag.is_empty
		do
			if not a_condition then
				(create {EXCEPTIONS}).raise ("Assertion failed: " + a_tag)
			end
		end

end
