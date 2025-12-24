note
	description: "[
		KB_DATABASE - Knowledge Base Database Manager

		Manages SQLite database with FTS5 full-text search for the Eiffel
		knowledge base. Handles schema creation, content storage, and search.

		Schema:
			- classes: Indexed class metadata from source files
			- features: Feature signatures and contracts
			- examples: Code examples from Rosetta and manual sources
			- errors: Compiler error codes with explanations
			- patterns: Design patterns with Eiffel idioms
			- translations: Language translation mappings
			- kb_search: FTS5 virtual table for full-text search

		Usage:
			db: KB_DATABASE
			create db.make ("kb.db")
			db.ensure_schema
			results := db.search ("json parsing", 10)
	]"
	author: "Simple Eiffel"
	date: "$Date$"
	revision: "$Revision$"

class
	KB_DATABASE

inherit
	ANY
		redefine
			default_create
		end

create
	make,
	make_in_memory,
	default_create

feature {NONE} -- Initialization

	default_create
			-- Create with default database path
		do
			make (default_db_path)
		end

	make (a_path: READABLE_STRING_GENERAL)
			-- Create database at path
		require
			path_not_empty: not a_path.is_empty
		do
			db_path := a_path.to_string_32
			create db.make (db_path)
			if db.is_open then
				ensure_schema
			end
		ensure
			path_set: db_path.same_string_general (a_path)
		end

	make_in_memory
			-- Create in-memory database (for testing)
		do
			db_path := ":memory:"
			create db.make_memory
			if db.is_open then
				ensure_schema
			end
		ensure
			in_memory: db_path ~ ":memory:"
		end

feature -- Access

	db_path: STRING_32
			-- Path to database file

	db: SIMPLE_SQL_DATABASE
			-- Underlying database connection

	default_db_path: STRING_32
			-- Default database location
		once
			Result := "kb.db"
		end

feature -- Status

	is_open: BOOLEAN
			-- Is database connection open?
		do
			Result := db.is_open
		end

	has_error: BOOLEAN
			-- Did last operation fail?
		do
			Result := db.has_error
		end

	last_error: detachable STRING_32
			-- Last error message
		do
			Result := db.last_error_message
		end

	fts5_available: BOOLEAN
			-- Is FTS5 extension available?
		require
			is_open: is_open
		local
			l_result: SIMPLE_SQL_RESULT
			l_str: STRING_32
		do
			l_result := db.query ("PRAGMA compile_options")
			across l_result.rows as row loop
				if attached row.item (1) as val then
					l_str := val.out.to_string_32
					l_str.to_upper
					if l_str.has_substring ("FTS5") then
						Result := True
					end
				end
			end
		end

feature -- Schema

	ensure_schema
			-- Create schema if not exists
		require
			is_open: is_open
		do
			create_classes_table
			create_features_table
			create_examples_table
			create_errors_table
			create_patterns_table
			create_translations_table
			create_fts5_index
		end

feature {NONE} -- Schema Creation

	create_classes_table
			-- Create classes table
		do
			db.execute ("[
				CREATE TABLE IF NOT EXISTS classes (
					id INTEGER PRIMARY KEY,
					library TEXT NOT NULL,
					name TEXT NOT NULL,
					description TEXT,
					file_path TEXT,
					created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
					UNIQUE(library, name)
				)
			]")
		end

	create_features_table
			-- Create features table
		do
			db.execute ("[
				CREATE TABLE IF NOT EXISTS features (
					id INTEGER PRIMARY KEY,
					class_id INTEGER REFERENCES classes(id),
					name TEXT NOT NULL,
					signature TEXT,
					description TEXT,
					kind TEXT,
					preconditions TEXT,
					postconditions TEXT,
					UNIQUE(class_id, name)
				)
			]")
		end

	create_examples_table
			-- Create examples table
		do
			db.execute ("[
				CREATE TABLE IF NOT EXISTS examples (
					id INTEGER PRIMARY KEY,
					title TEXT NOT NULL,
					source TEXT,
					code TEXT NOT NULL,
					tags TEXT,
					tier TEXT,
					created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
				)
			]")
		end

	create_errors_table
			-- Create errors table
		do
			db.execute ("[
				CREATE TABLE IF NOT EXISTS errors (
					id INTEGER PRIMARY KEY,
					code TEXT UNIQUE NOT NULL,
					meaning TEXT NOT NULL,
					explanation TEXT,
					common_causes TEXT,
					fixes TEXT,
					examples TEXT,
					ecma_section TEXT
				)
			]")
		end

	create_patterns_table
			-- Create patterns table
		do
			db.execute ("[
				CREATE TABLE IF NOT EXISTS patterns (
					id INTEGER PRIMARY KEY,
					name TEXT NOT NULL,
					description TEXT,
					code TEXT NOT NULL,
					when_to_use TEXT,
					eiffel_idioms TEXT
				)
			]")
		end

	create_translations_table
			-- Create translations table
		do
			db.execute ("[
				CREATE TABLE IF NOT EXISTS translations (
					id INTEGER PRIMARY KEY,
					source_lang TEXT NOT NULL,
					source_pattern TEXT NOT NULL,
					eiffel_pattern TEXT NOT NULL,
					notes TEXT
				)
			]")
		end

	create_fts5_index
			-- Create FTS5 full-text search virtual table
		do
			db.execute ("[
				CREATE VIRTUAL TABLE IF NOT EXISTS kb_search USING fts5(
					content_type,
					content_id,
					title,
					body,
					tags,
					tokenize='porter unicode61'
				)
			]")
		end

feature -- Search

	search (a_query: READABLE_STRING_GENERAL; a_limit: INTEGER): ARRAYED_LIST [KB_RESULT]
			-- Search knowledge base with FTS5
		require
			is_open: is_open
			query_not_empty: not a_query.is_empty
			positive_limit: a_limit > 0
		local
			l_result: SIMPLE_SQL_RESULT
			l_item: KB_RESULT
			l_sql: STRING
			l_fts_query: STRING_32
		do
			create Result.make (a_limit)

			-- Format query for FTS5 (quote the term)
			create l_fts_query.make (a_query.count + 4)
			l_fts_query.append_character ('"')
			l_fts_query.append_string_general (a_query)
			l_fts_query.append_character ('"')

			-- FTS5 search with BM25 ranking
			l_sql := "SELECT content_type, content_id, title, body, bm25(kb_search) as rank FROM kb_search WHERE kb_search MATCH ? ORDER BY rank LIMIT " + a_limit.out

			l_result := db.query_with_args (l_sql, <<l_fts_query>>)

			across l_result.rows as row loop
				create l_item.make_from_row (row)
				Result.extend (l_item)
			end
		ensure
			result_not_void: Result /= Void
			within_limit: Result.count <= a_limit
		end

feature -- Error Operations

	get_error (a_code: READABLE_STRING_GENERAL): detachable KB_ERROR_INFO
			-- Get error info by code
		require
			is_open: is_open
			code_not_empty: not a_code.is_empty
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := db.query_with_args (
				"SELECT * FROM errors WHERE code = ? COLLATE NOCASE",
				<<a_code.to_string_32>>
			)
			if not l_result.is_empty then
				create Result.make_from_row (l_result.rows.first)
			end
		end

	add_error (a_error: KB_ERROR_INFO)
			-- Add or update error entry
		require
			is_open: is_open
			error_valid: a_error.is_valid
		do
			db.execute_with_args ("[
				INSERT OR REPLACE INTO errors
				(code, meaning, explanation, common_causes, fixes, examples, ecma_section)
				VALUES (?, ?, ?, ?, ?, ?, ?)
			]", <<
				a_error.code,
				a_error.meaning,
				a_error.explanation,
				a_error.common_causes_json,
				a_error.fixes_json,
				a_error.examples_json,
				a_error.ecma_section
			>>)

			-- Update FTS5 index
			update_fts5_error (a_error)
		end

	all_errors: ARRAYED_LIST [KB_ERROR_INFO]
			-- Get all error codes
		require
			is_open: is_open
		local
			l_result: SIMPLE_SQL_RESULT
			l_error: KB_ERROR_INFO
		do
			create Result.make (50)
			l_result := db.query ("SELECT * FROM errors ORDER BY code")
			across l_result.rows as row loop
				create l_error.make_from_row (row)
				Result.extend (l_error)
			end
		end

feature -- Class Operations

	get_class (a_library, a_name: READABLE_STRING_GENERAL): detachable KB_CLASS_INFO
			-- Get class info by library and name
		require
			is_open: is_open
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := db.query_with_args (
				"SELECT * FROM classes WHERE library = ? AND name = ? COLLATE NOCASE",
				<<a_library.to_string_32, a_name.to_string_32>>
			)
			if not l_result.is_empty then
				create Result.make_from_row (l_result.rows.first)
				load_class_features (Result)
			end
		end

	find_class (a_name: READABLE_STRING_GENERAL): detachable KB_CLASS_INFO
			-- Find class by name (any library)
		require
			is_open: is_open
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := db.query_with_args (
				"SELECT * FROM classes WHERE name = ? COLLATE NOCASE LIMIT 1",
				<<a_name.to_string_32>>
			)
			if not l_result.is_empty then
				create Result.make_from_row (l_result.rows.first)
				load_class_features (Result)
			end
		end

	add_class (a_class: KB_CLASS_INFO)
			-- Add or update class entry
		require
			is_open: is_open
			class_valid: a_class.is_valid
		do
			db.execute_with_args ("[
				INSERT OR REPLACE INTO classes
				(library, name, description, file_path)
				VALUES (?, ?, ?, ?)
			]", <<
				a_class.library,
				a_class.name,
				a_class.description,
				a_class.file_path
			>>)

			-- Get the ID for FTS5 update
			a_class.set_id (db.last_insert_rowid.to_integer_32)

			-- Update FTS5 index
			update_fts5_class (a_class)
		end

feature {NONE} -- Class Helpers

	load_class_features (a_class: KB_CLASS_INFO)
			-- Load features for class
		require
			class_has_id: a_class.id > 0
		local
			l_result: SIMPLE_SQL_RESULT
			l_feature: KB_FEATURE_INFO
		do
			l_result := db.query_with_args (
				"SELECT * FROM features WHERE class_id = ? ORDER BY kind, name",
				<<a_class.id>>
			)
			across l_result.rows as row loop
				create l_feature.make_from_row (row)
				a_class.add_feature (l_feature)
			end
		end

feature -- Feature Operations

	add_feature (a_feature: KB_FEATURE_INFO)
			-- Add or update feature entry
		require
			is_open: is_open
			feature_valid: a_feature.is_valid
		do
			db.execute_with_args ("[
				INSERT OR REPLACE INTO features
				(class_id, name, signature, description, kind, preconditions, postconditions)
				VALUES (?, ?, ?, ?, ?, ?, ?)
			]", <<
				a_feature.class_id,
				a_feature.name,
				a_feature.signature,
				a_feature.description,
				a_feature.kind,
				a_feature.preconditions_json,
				a_feature.postconditions_json
			>>)

			-- Update FTS5 index
			update_fts5_feature (a_feature)
		end

feature -- Example Operations

	get_example (a_title: READABLE_STRING_GENERAL): detachable KB_EXAMPLE
			-- Get example by title
		require
			is_open: is_open
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := db.query_with_args (
				"SELECT * FROM examples WHERE title = ? COLLATE NOCASE LIMIT 1",
				<<a_title.to_string_32>>
			)
			if not l_result.is_empty then
				create Result.make_from_row (l_result.rows.first)
			end
		end

	search_examples (a_query: READABLE_STRING_GENERAL; a_limit: INTEGER): ARRAYED_LIST [KB_EXAMPLE]
			-- Search examples
		require
			is_open: is_open
			positive_limit: a_limit > 0
		local
			l_result: SIMPLE_SQL_RESULT
			l_example: KB_EXAMPLE
			l_pattern: STRING
		do
			create Result.make (a_limit)
			l_pattern := "%%" + a_query.out + "%%"
			l_result := db.query_with_args ("SELECT * FROM examples WHERE title LIKE ? OR tags LIKE ? LIMIT " + a_limit.out, <<l_pattern, l_pattern>>)
			across l_result.rows as row loop
				create l_example.make_from_row (row)
				Result.extend (l_example)
			end
		end

	add_example (a_example: KB_EXAMPLE)
			-- Add example
		require
			is_open: is_open
			example_valid: a_example.is_valid
		do
			db.execute_with_args ("[
				INSERT INTO examples (title, source, code, tags, tier)
				VALUES (?, ?, ?, ?, ?)
			]", <<
				a_example.title,
				a_example.source,
				a_example.code,
				a_example.tags_json,
				a_example.tier
			>>)

			a_example.set_id (db.last_insert_rowid.to_integer_32)
			update_fts5_example (a_example)
		end

feature -- Pattern Operations

	get_pattern (a_name: READABLE_STRING_GENERAL): detachable KB_PATTERN
			-- Get pattern by name
		require
			is_open: is_open
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := db.query_with_args (
				"SELECT * FROM patterns WHERE name = ? COLLATE NOCASE LIMIT 1",
				<<a_name.to_string_32>>
			)
			if not l_result.is_empty then
				create Result.make_from_row (l_result.rows.first)
			end
		end

	add_pattern (a_pattern: KB_PATTERN)
			-- Add pattern
		require
			is_open: is_open
			pattern_valid: a_pattern.is_valid
		do
			db.execute_with_args ("[
				INSERT OR REPLACE INTO patterns
				(name, description, code, when_to_use, eiffel_idioms)
				VALUES (?, ?, ?, ?, ?)
			]", <<
				a_pattern.name,
				a_pattern.description,
				a_pattern.code,
				a_pattern.when_to_use,
				a_pattern.eiffel_idioms_json
			>>)

			a_pattern.set_id (db.last_insert_rowid.to_integer_32)
			update_fts5_pattern (a_pattern)
		end

	all_patterns: ARRAYED_LIST [KB_PATTERN]
			-- Get all patterns
		require
			is_open: is_open
		local
			l_result: SIMPLE_SQL_RESULT
			l_pattern: KB_PATTERN
		do
			create Result.make (20)
			l_result := db.query ("SELECT * FROM patterns ORDER BY name")
			across l_result.rows as row loop
				create l_pattern.make_from_row (row)
				Result.extend (l_pattern)
			end
		end

feature -- Statistics

	stats: TUPLE [classes, features, examples, errors, patterns: INTEGER]
			-- Database statistics
		require
			is_open: is_open
		local
			l_classes, l_features, l_examples, l_errors, l_patterns: INTEGER
		do
			l_classes := safe_count ("SELECT COUNT(*) FROM classes")
			l_features := safe_count ("SELECT COUNT(*) FROM features")
			l_examples := safe_count ("SELECT COUNT(*) FROM examples")
			l_errors := safe_count ("SELECT COUNT(*) FROM errors")
			l_patterns := safe_count ("SELECT COUNT(*) FROM patterns")
			Result := [l_classes, l_features, l_examples, l_errors, l_patterns]
		end

	safe_count (a_sql: STRING): INTEGER
			-- Execute count query safely
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := db.query (a_sql)
			if not l_result.is_empty then
				if attached l_result.rows.first as first_row then
					if attached first_row.item (1) as val then
						Result := val.out.to_integer
					end
				end
			end
		end

feature {NONE} -- FTS5 Index Updates

	update_fts5_error (a_error: KB_ERROR_INFO)
			-- Add error to FTS5 index
		do
			-- Delete existing entry
			db.execute_with_args (
				"DELETE FROM kb_search WHERE content_type = 'error' AND title = ?",
				<<a_error.code>>
			)
			-- Insert new entry
			db.execute_with_args ("[
				INSERT INTO kb_search (content_type, content_id, title, body, tags)
				VALUES ('error', ?, ?, ?, ?)
			]", <<
				a_error.code,
				a_error.code,
				a_error.meaning + " " + a_error.explanation,
				"error compiler"
			>>)
		end

	update_fts5_class (a_class: KB_CLASS_INFO)
			-- Add class to FTS5 index
		do
			db.execute_with_args (
				"DELETE FROM kb_search WHERE content_type = 'class' AND content_id = ?",
				<<a_class.id.out>>
			)
			db.execute_with_args ("[
				INSERT INTO kb_search (content_type, content_id, title, body, tags)
				VALUES ('class', ?, ?, ?, ?)
			]", <<
				a_class.id.out,
				a_class.name,
				a_class.description,
				a_class.library
			>>)
		end

	update_fts5_feature (a_feature: KB_FEATURE_INFO)
			-- Add feature to FTS5 index
		do
			db.execute_with_args (
				"DELETE FROM kb_search WHERE content_type = 'feature' AND content_id = ?",
				<<a_feature.id.out>>
			)
			db.execute_with_args ("[
				INSERT INTO kb_search (content_type, content_id, title, body, tags)
				VALUES ('feature', ?, ?, ?, ?)
			]", <<
				a_feature.id.out,
				a_feature.name,
				a_feature.signature + " " + a_feature.description,
				a_feature.kind
			>>)
		end

	update_fts5_example (a_example: KB_EXAMPLE)
			-- Add example to FTS5 index
		do
			db.execute_with_args (
				"DELETE FROM kb_search WHERE content_type = 'example' AND content_id = ?",
				<<a_example.id.out>>
			)
			db.execute_with_args ("[
				INSERT INTO kb_search (content_type, content_id, title, body, tags)
				VALUES ('example', ?, ?, ?, ?)
			]", <<
				a_example.id.out,
				a_example.title,
				a_example.code,
				a_example.tags_json
			>>)
		end

	update_fts5_pattern (a_pattern: KB_PATTERN)
			-- Add pattern to FTS5 index
		do
			db.execute_with_args (
				"DELETE FROM kb_search WHERE content_type = 'pattern' AND content_id = ?",
				<<a_pattern.id.out>>
			)
			db.execute_with_args ("[
				INSERT INTO kb_search (content_type, content_id, title, body, tags)
				VALUES ('pattern', ?, ?, ?, ?)
			]", <<
				a_pattern.id.out,
				a_pattern.name,
				a_pattern.description + " " + a_pattern.code,
				"pattern design"
			>>)
		end

feature -- Cleanup

	close
			-- Close database connection
		do
			if db.is_open then
				db.close
			end
		end

invariant
	db_not_void: db /= Void
	path_not_empty: not db_path.is_empty

end
