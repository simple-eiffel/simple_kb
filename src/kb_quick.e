note
	description: "[
		KB_QUICK - One-liner Facade for Knowledge Base

		Provides simple, convenient methods for common KB operations.
		Use this for quick lookups; use KB_DATABASE directly for full control.

		Usage:
			kb: KB_QUICK
			create kb.make

			-- Error lookup
			kb.print_error ("VEVI")

			-- Search
			results := kb.search ("json parsing")

			-- Class lookup
			kb.print_class ("JSON_PARSER")
	]"
	author: "Simple Eiffel"
	date: "$Date$"
	revision: "$Revision$"

class
	KB_QUICK

create
	make,
	make_with_path

feature {NONE} -- Initialization

	make
			-- Create with default database
		do
			create db.make (default_db_path)
		end

	make_with_path (a_path: READABLE_STRING_GENERAL)
			-- Create with specific database path
		require
			path_not_empty: not a_path.is_empty
		do
			create db.make (a_path)
		end

feature -- Access

	db: KB_DATABASE
			-- Underlying database

	default_db_path: STRING_32
			-- Default database location
		local
			l_env: EXECUTION_ENVIRONMENT
		once
			create l_env
			if attached l_env.item ("SIMPLE_EIFFEL") as al_path then
				Result := path + "/simple_kb/kb.db"
			else
				Result := "kb.db"
			end
		end

feature -- Search

	search (a_query: READABLE_STRING_GENERAL): ARRAYED_LIST [KB_RESULT]
			-- Search knowledge base (default 10 results)
		require
			db_open: db.is_open
		do
			Result := db.search (a_query, 10)
		end

	search_limit (a_query: READABLE_STRING_GENERAL; a_limit: INTEGER): ARRAYED_LIST [KB_RESULT]
			-- Search with custom limit
		require
			db_open: db.is_open
			positive_limit: a_limit > 0
		do
			Result := db.search (a_query, a_limit)
		end

feature -- Error Lookup

	error (a_code: READABLE_STRING_GENERAL): detachable KB_ERROR_INFO
			-- Get error info by code
		require
			db_open: db.is_open
		do
			Result := db.get_error (a_code)
		end

	print_error (a_code: READABLE_STRING_GENERAL)
			-- Print error info to stdout
		local
			l_error: detachable KB_ERROR_INFO
		do
			l_error := error (a_code)
			if attached l_error as al_err then
				io.put_string (al_err.formatted.to_string_8)
			else
				io.put_string ("Error code not found: ")
				io.put_string (a_code.to_string_8)
				io.put_new_line
			end
		end

feature -- Class Lookup

	class_info (a_name: READABLE_STRING_GENERAL): detachable KB_CLASS_INFO
			-- Get class info by name
		require
			db_open: db.is_open
		do
			Result := db.find_class (a_name)
		end

	print_class (a_name: READABLE_STRING_GENERAL)
			-- Print class info to stdout
		local
			l_class: detachable KB_CLASS_INFO
		do
			l_class := class_info (a_name)
			if attached l_class as al_cls then
				io.put_string (al_cls.formatted.to_string_8)
			else
				io.put_string ("Class not found: ")
				io.put_string (a_name.to_string_8)
				io.put_new_line
			end
		end

feature -- Example Lookup

	example (a_title: READABLE_STRING_GENERAL): detachable KB_EXAMPLE
			-- Get example by title
		require
			db_open: db.is_open
		do
			Result := db.get_example (a_title)
		end

	search_examples (a_query: READABLE_STRING_GENERAL): ARRAYED_LIST [KB_EXAMPLE]
			-- Search examples
		require
			db_open: db.is_open
		do
			Result := db.search_examples (a_query, 10)
		end

	print_example (a_title: READABLE_STRING_GENERAL)
			-- Print example to stdout
		local
			l_example: detachable KB_EXAMPLE
		do
			l_example := example (a_title)
			if attached l_example as al_ex then
				io.put_string (al_ex.formatted.to_string_8)
			else
				io.put_string ("Example not found: ")
				io.put_string (a_title.to_string_8)
				io.put_new_line
			end
		end

feature -- Pattern Lookup

	pattern (a_name: READABLE_STRING_GENERAL): detachable KB_PATTERN
			-- Get pattern by name
		require
			db_open: db.is_open
		do
			Result := db.get_pattern (a_name)
		end

	print_pattern (a_name: READABLE_STRING_GENERAL)
			-- Print pattern to stdout
		local
			l_pattern: detachable KB_PATTERN
		do
			l_pattern := pattern (a_name)
			if attached l_pattern as al_pat then
				io.put_string (al_pat.formatted.to_string_8)
			else
				io.put_string ("Pattern not found: ")
				io.put_string (a_name.to_string_8)
				io.put_new_line
			end
		end

feature -- Statistics

	stats: TUPLE [classes, features, examples, errors, patterns: INTEGER]
			-- Database statistics
		require
			db_open: db.is_open
		do
			Result := db.stats
		end

	print_stats
			-- Print statistics to stdout
		local
			l_s: like stats
		do
			s := stats
			io.put_string ("Knowledge Base Statistics%N")
			io.put_string ("=========================%N")
			io.put_string ("Classes:  " + s.classes.out + "%N")
			io.put_string ("Features: " + s.features.out + "%N")
			io.put_string ("Examples: " + s.examples.out + "%N")
			io.put_string ("Errors:   " + s.errors.out + "%N")
			io.put_string ("Patterns: " + s.patterns.out + "%N")
		end

feature -- Cleanup

	close
			-- Close database
		do
			db.close
		end

invariant
	db_not_void: db /= Void

end
