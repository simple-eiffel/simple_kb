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
			-- Default database location (colocated with executable)
		local
			l_env: EXECUTION_ENVIRONMENT
			l_path: PATH
		once
			create l_env
			-- Get executable directory
			create l_path.make_from_string (l_env.current_working_path.out)
			if attached {ARGUMENTS_32}.command_name as al_cmd then
				create l_path.make_from_string (cmd)
				if attached l_path.parent as al_parent_dir then
					l_path := parent_dir.extended ("kb.db")
					Result := l_path.out
				else
					Result := "kb.db"
				end
			else
				Result := "kb.db"
			end
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
				if attached row.item (1) as al_val then
					l_str := al_val.out.to_string_32
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
			create_class_parents_table
			create_libraries_table
			create_examples_table
			create_errors_table
			create_patterns_table
			create_translations_table
			create_fts5_index
			create_faq_tables
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
					is_deferred INTEGER DEFAULT 0,
					is_expanded INTEGER DEFAULT 0,
					is_frozen INTEGER DEFAULT 0,
					generics TEXT,
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
					is_deferred INTEGER DEFAULT 0,
					is_frozen INTEGER DEFAULT 0,
					is_once INTEGER DEFAULT 0,
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

	create_class_parents_table
			-- Create class_parents table for inheritance tracking
		do
			db.execute ("[
				CREATE TABLE IF NOT EXISTS class_parents (
					id INTEGER PRIMARY KEY,
					class_id INTEGER REFERENCES classes(id),
					parent_name TEXT NOT NULL,
					conforming INTEGER DEFAULT 1,
					UNIQUE(class_id, parent_name)
				)
			]")
		end

	create_libraries_table
			-- Create libraries table for ECF metadata
		do
			db.execute ("[
				CREATE TABLE IF NOT EXISTS libraries (
					id INTEGER PRIMARY KEY,
					name TEXT UNIQUE NOT NULL,
					description TEXT,
					uuid TEXT,
					file_path TEXT,
					clusters TEXT,
					dependencies TEXT,
					created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
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

	create_faq_tables
			-- Create FAQ cache tables for emergent Q&A system
		do
			-- Main FAQ table
			db.execute ("[
				CREATE TABLE IF NOT EXISTS faqs (
					id INTEGER PRIMARY KEY,
					question TEXT NOT NULL,
					keywords TEXT,
					answer TEXT NOT NULL,
					sources TEXT,
					tags TEXT,
					hit_count INTEGER DEFAULT 0,
					helpful_count INTEGER DEFAULT 0,
					created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
					kb_version INTEGER DEFAULT 1
				)
			]")
			
			-- Normalized tags for efficient queries
			db.execute ("[
				CREATE TABLE IF NOT EXISTS faq_tags (
					faq_id INTEGER REFERENCES faqs(id) ON DELETE CASCADE,
					tag TEXT NOT NULL,
					PRIMARY KEY (faq_id, tag)
				)
			]")
			db.execute ("CREATE INDEX IF NOT EXISTS idx_faq_tag ON faq_tags(tag)")
			
			-- FTS5 index for FAQ search
			db.execute ("[
				CREATE VIRTUAL TABLE IF NOT EXISTS faq_search USING fts5(
					faq_id,
					question,
					answer,
					keywords,
					tags,
					tokenize='porter unicode61'
				)
			]")
		end

feature -- Search

	search (a_query: READABLE_STRING_GENERAL; a_limit: INTEGER): ARRAYED_LIST [KB_RESULT]
			-- Search knowledge base with FTS5
			-- Multi-word queries use AND logic (all words must appear)
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

			-- Format query for FTS5
			-- Multi-word: join with AND for "all words must match"
			l_fts_query := format_fts5_query (a_query)

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
				load_class_parents (Result)
			end
		end

	search_classes (a_query: READABLE_STRING_GENERAL; a_limit: INTEGER): ARRAYED_LIST [KB_CLASS_INFO]
			-- Search for classes by partial name match
		require
			is_open: is_open
			positive_limit: a_limit > 0
		local
			l_result: SIMPLE_SQL_RESULT
			l_class: KB_CLASS_INFO
			l_pattern: STRING
		do
			create Result.make (a_limit)
			l_pattern := "%%" + a_query.out.as_upper + "%%"
			l_result := db.query_with_args (
				"SELECT * FROM classes WHERE UPPER(name) LIKE ? ORDER BY name LIMIT " + a_limit.out,
				<<l_pattern>>
			)
			across l_result.rows as row loop
				create l_class.make_from_row (row)
				load_class_features (l_class)
				Result.extend (l_class)
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
				(library, name, description, file_path, is_deferred, is_expanded, is_frozen, generics)
				VALUES (?, ?, ?, ?, ?, ?, ?, ?)
			]", <<
				a_class.library,
				a_class.name,
				a_class.description,
				a_class.file_path,
				bool_to_int (a_class.is_deferred),
				bool_to_int (a_class.is_expanded),
				bool_to_int (a_class.is_frozen),
				a_class.generics
			>>)

			-- Get the ID for FTS5 update
			a_class.set_id (db.last_insert_rowid.to_integer_32)

			-- Store parents
			store_class_parents (a_class)

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

	find_feature (a_class_name, a_feature_name: READABLE_STRING_GENERAL): detachable KB_FEATURE_INFO
			-- Find feature by class name and feature name
		require
			is_open: is_open
		local
			l_result: SIMPLE_SQL_RESULT
			l_class_id: INTEGER
		do
			-- First find the class ID
			l_result := db.query_with_args (
				"SELECT id FROM classes WHERE name = ? COLLATE NOCASE LIMIT 1",
				<<a_class_name.to_string_32>>
			)
			if not l_result.is_empty then
				if attached l_result.rows.first.item (1) as al_val then
					l_class_id := al_val.out.to_integer
				end
				-- Now find the feature
				l_result := db.query_with_args (
					"SELECT * FROM features WHERE class_id = ? AND name = ? COLLATE NOCASE LIMIT 1",
					<<l_class_id, a_feature_name.to_string_32>>
				)
				if not l_result.is_empty then
					create Result.make_from_row (l_result.rows.first)
				end
			end
		end

	search_features (a_class_name, a_query: READABLE_STRING_GENERAL; a_limit: INTEGER): ARRAYED_LIST [KB_FEATURE_INFO]
			-- Search features in a class by partial name match
		require
			is_open: is_open
			positive_limit: a_limit > 0
		local
			l_result: SIMPLE_SQL_RESULT
			l_feature: KB_FEATURE_INFO
			l_class_id: INTEGER
			l_pattern: STRING
		do
			create Result.make (a_limit)
			-- First find the class ID
			l_result := db.query_with_args (
				"SELECT id FROM classes WHERE name = ? COLLATE NOCASE LIMIT 1",
				<<a_class_name.to_string_32>>
			)
			if not l_result.is_empty then
				if attached l_result.rows.first.item (1) as al_val then
					l_class_id := al_val.out.to_integer
				end
				l_pattern := "%%" + a_query.out.as_lower + "%%"
				l_result := db.query_with_args (
					"SELECT * FROM features WHERE class_id = ? AND LOWER(name) LIKE ? ORDER BY name LIMIT " + a_limit.out,
					<<l_class_id, l_pattern>>
				)
				across l_result.rows as row loop
					create l_feature.make_from_row (row)
					Result.extend (l_feature)
				end
			end
		end

	add_feature (a_feature: KB_FEATURE_INFO)
			-- Add or update feature entry
		require
			is_open: is_open
			feature_valid: a_feature.is_valid
		do
			db.execute_with_args ("[
				INSERT OR REPLACE INTO features
				(class_id, name, signature, description, kind, is_deferred, is_frozen, is_once, preconditions, postconditions)
				VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
			]", <<
				a_feature.class_id,
				a_feature.name,
				a_feature.signature,
				a_feature.description,
				a_feature.kind,
				bool_to_int (a_feature.is_deferred),
				bool_to_int (a_feature.is_frozen),
				bool_to_int (a_feature.is_once),
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

	find_example_like (a_title: READABLE_STRING_GENERAL): detachable KB_EXAMPLE
			-- Find example with title containing search term
		require
			is_open: is_open
		local
			l_result: SIMPLE_SQL_RESULT
			l_pattern: STRING
		do
			l_pattern := "%%" + a_title.out + "%%"
			l_result := db.query_with_args (
				"SELECT * FROM examples WHERE title LIKE ? COLLATE NOCASE LIMIT 1",
				<<l_pattern>>
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

feature -- Library Operations

	get_library (a_name: READABLE_STRING_GENERAL): detachable KB_LIBRARY_INFO
			-- Get library by name
		require
			is_open: is_open
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := db.query_with_args (
				"SELECT * FROM libraries WHERE name = ? COLLATE NOCASE LIMIT 1",
				<<a_name.to_string_32>>
			)
			if not l_result.is_empty then
				create Result.make_from_row (l_result.rows.first)
			end
		end

	add_library (a_library: KB_LIBRARY_INFO)
			-- Add or update library
		require
			is_open: is_open
		do
			db.execute_with_args ("[
				INSERT OR REPLACE INTO libraries
				(name, description, uuid, file_path, clusters, dependencies)
				VALUES (?, ?, ?, ?, ?, ?)
			]", <<
				a_library.name,
				a_library.description,
				a_library.uuid,
				a_library.file_path,
				a_library.clusters_json,
				a_library.dependencies_json
			>>)

			a_library.set_id (db.last_insert_rowid.to_integer_32)
		end

	all_libraries: ARRAYED_LIST [KB_LIBRARY_INFO]
			-- Get all libraries
		require
			is_open: is_open
		local
			l_result: SIMPLE_SQL_RESULT
			l_lib: KB_LIBRARY_INFO
		do
			create Result.make (50)
			l_result := db.query ("SELECT * FROM libraries ORDER BY name")
			across l_result.rows as row loop
				create l_lib.make_from_row (row)
				Result.extend (l_lib)
			end
		end

	search_libraries (a_query: READABLE_STRING_GENERAL; a_limit: INTEGER): ARRAYED_LIST [KB_LIBRARY_INFO]
			-- Search libraries by name
		require
			is_open: is_open
		local
			l_result: SIMPLE_SQL_RESULT
			l_lib: KB_LIBRARY_INFO
		do
			create Result.make (a_limit)
			l_result := db.query_with_args (
				"SELECT * FROM libraries WHERE name LIKE ? ORDER BY name LIMIT ?",
				<<"%%" + a_query.to_string_32 + "%%", a_limit>>
			)
			across l_result.rows as row loop
				create l_lib.make_from_row (row)
				Result.extend (l_lib)
			end
		end

	library_count: INTEGER
			-- Total number of libraries
		require
			is_open: is_open
		do
			Result := safe_count ("SELECT COUNT(*) FROM libraries")
		end

feature -- Statistics

	stats: TUPLE [classes, features, examples, errors, patterns, libraries: INTEGER]
			-- Database statistics
		require
			is_open: is_open
		local
			l_classes, l_features, l_examples, l_errors, l_patterns, l_libraries: INTEGER
		do
			l_classes := safe_count ("SELECT COUNT(*) FROM classes")
			l_features := safe_count ("SELECT COUNT(*) FROM features")
			l_examples := safe_count ("SELECT COUNT(*) FROM examples")
			l_errors := safe_count ("SELECT COUNT(*) FROM errors")
			l_patterns := safe_count ("SELECT COUNT(*) FROM patterns")
			l_libraries := safe_count ("SELECT COUNT(*) FROM libraries")
			Result := [l_classes, l_features, l_examples, l_errors, l_patterns, l_libraries]
		end

	safe_count (a_sql: STRING): INTEGER
			-- Execute count query safely
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := db.query (a_sql)
			if not l_result.is_empty then
				if attached l_result.rows.first as al_first_row then
					if attached al_first_row.item (1) as al_val then
						Result := val.out.to_integer
					end
				end
			end
		end

feature {NONE} -- FTS5 Query Formatting

	format_fts5_query (a_query: READABLE_STRING_GENERAL): STRING_32
			-- Format query for FTS5 search
			-- Preserves OR operator, joins other words with AND
		local
			l_words: LIST [STRING_32]
			l_word: STRING_32
			l_lower: STRING_32
			l_last_was_or: BOOLEAN
		do
			create Result.make (a_query.count + 20)
			l_words := a_query.to_string_32.split (' ')

			from l_words.start until l_words.after loop
				l_word := l_words.item
				l_word.left_adjust
				l_word.right_adjust
				if not l_word.is_empty then
					-- Check for FTS5 OR operator (preserve it)
					if l_word.same_string ("OR") then
						if Result.count > 0 then
							Result.append (" OR ")
							l_last_was_or := True
						end
					else
						-- Strip punctuation from word
						l_word := strip_punctuation (l_word)
						l_lower := l_word.as_lower
						if not l_word.is_empty and then not is_stop_word (l_lower) then
							if Result.count > 0 and then not l_last_was_or then
								Result.append (" AND ")
							end
							Result.append (l_word)
							Result.append_character ('*')
							l_last_was_or := False
						end
					end
				end
				l_words.forth
			end

			-- Fallback: if all words were stop words, use original query
			if Result.is_empty then
				Result.append_string_general (a_query)
				Result.append_character ('*')
			end
		ensure
			result_not_empty: not Result.is_empty
		end

	is_stop_word (a_word: STRING_32): BOOLEAN
			-- Is this a common stop word to filter out?
		do
			Result := stop_words.has (a_word)
		end

	stop_words: ARRAYED_SET [STRING_32]
			-- Common English stop words
		once
			create Result.make (50)
			Result.compare_objects
			-- Articles/determiners
			Result.extend ("a"); Result.extend ("an"); Result.extend ("the")
			-- Pronouns
			Result.extend ("i"); Result.extend ("me"); Result.extend ("my")
			Result.extend ("you"); Result.extend ("your"); Result.extend ("we")
			Result.extend ("it"); Result.extend ("its"); Result.extend ("this")
			Result.extend ("that"); Result.extend ("these"); Result.extend ("those")
			-- Prepositions
			Result.extend ("in"); Result.extend ("on"); Result.extend ("at")
			Result.extend ("to"); Result.extend ("for"); Result.extend ("of")
			Result.extend ("with"); Result.extend ("by"); Result.extend ("from")
			Result.extend ("about"); Result.extend ("into"); Result.extend ("through")
			-- Conjunctions (note: "or" excluded - it's an FTS5 operator)
			Result.extend ("and"); Result.extend ("but")
			Result.extend ("if"); Result.extend ("then"); Result.extend ("so")
			-- Verbs (common)
			Result.extend ("is"); Result.extend ("are"); Result.extend ("was")
			Result.extend ("be"); Result.extend ("been"); Result.extend ("being")
			Result.extend ("have"); Result.extend ("has"); Result.extend ("had")
			Result.extend ("do"); Result.extend ("does"); Result.extend ("did")
			Result.extend ("can"); Result.extend ("could"); Result.extend ("would")
			Result.extend ("should"); Result.extend ("will"); Result.extend ("shall")
			-- Question words
			Result.extend ("how"); Result.extend ("what"); Result.extend ("when")
			Result.extend ("where"); Result.extend ("why"); Result.extend ("which")
			Result.extend ("who"); Result.extend ("whom")
			-- Other common
			Result.extend ("use"); Result.extend ("using")
			Result.extend ("get"); Result.extend ("make"); Result.extend ("create")
		end

	strip_punctuation (a_word: STRING_32): STRING_32
			-- Remove leading/trailing punctuation from word
		local
			i, j: INTEGER
		do
			create Result.make_from_string (a_word)
			-- Strip trailing punctuation
			from i := Result.count until i < 1 or else Result.item (i).is_alpha_numeric loop
				i := i - 1
			end
			if i < Result.count then
				Result.keep_head (i)
			end
			-- Strip leading punctuation
			from j := 1 until j > Result.count or else Result.item (j).is_alpha_numeric loop
				j := j + 1
			end
			if j > 1 then
				Result.remove_head (j - 1)
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

feature -- Clear Operations

	library_class_count (a_library: READABLE_STRING_GENERAL): INTEGER
			-- Count of classes in library
		require
			is_open: is_open
		do
			Result := safe_count ("SELECT COUNT(*) FROM classes WHERE library = '" + a_library.out + "'")
		end

	clear_library (a_library: READABLE_STRING_GENERAL)
			-- Delete all classes and features for a specific library
		require
			is_open: is_open
		local
			l_class_ids: STRING
			l_result: SIMPLE_SQL_RESULT
		do
			-- Get class IDs for this library
			l_result := db.query_with_args (
				"SELECT id FROM classes WHERE library = ?",
				<<a_library.to_string_32>>
			)
			
			if not l_result.is_empty then
				-- Build comma-separated list of IDs
				create l_class_ids.make (100)
				across l_result.rows as row loop
					if not l_class_ids.is_empty then
						l_class_ids.append (",")
					end
					if attached row.item (1) as al_id then
						l_class_ids.append (al_id.out)
					end
				end
				
				-- Delete from FTS index
				db.execute ("DELETE FROM kb_search WHERE content_type = 'class' AND content_id IN (" + l_class_ids + ")")
				db.execute ("DELETE FROM kb_search WHERE content_type = 'feature' AND content_id IN (SELECT id FROM features WHERE class_id IN (" + l_class_ids + "))")
				
				-- Delete features then classes
				db.execute ("DELETE FROM features WHERE class_id IN (" + l_class_ids + ")")
				db.execute_with_args ("DELETE FROM classes WHERE library = ?", <<a_library.to_string_32>>)
			end
		end

	clear_all
			-- Delete all data from all tables
		require
			is_open: is_open
		do
			db.execute ("DELETE FROM kb_search")
			db.execute ("DELETE FROM faq_search")
			db.execute ("DELETE FROM faq_tags")
			db.execute ("DELETE FROM faqs")
			db.execute ("DELETE FROM features")
			db.execute ("DELETE FROM class_parents")
			db.execute ("DELETE FROM classes")
			db.execute ("DELETE FROM libraries")
			db.execute ("DELETE FROM examples")
			db.execute ("DELETE FROM errors")
			db.execute ("DELETE FROM patterns")
			db.execute ("DELETE FROM translations")
		end

	clear_classes
			-- Delete all classes and features
		require
			is_open: is_open
		do
			db.execute ("DELETE FROM kb_search WHERE content_type IN ('class', 'feature')")
			db.execute ("DELETE FROM features")
			db.execute ("DELETE FROM classes")
		end

	clear_examples
			-- Delete all examples
		require
			is_open: is_open
		do
			db.execute ("DELETE FROM kb_search WHERE content_type = 'example'")
			db.execute ("DELETE FROM examples")
		end

	clear_errors
			-- Delete all error codes
		require
			is_open: is_open
		do
			db.execute ("DELETE FROM kb_search WHERE content_type = 'error'")
			db.execute ("DELETE FROM errors")
		end

	clear_patterns
			-- Delete all patterns
		require
			is_open: is_open
		do
			db.execute ("DELETE FROM kb_search WHERE content_type = 'pattern'")
			db.execute ("DELETE FROM patterns")
		end

feature {NONE} -- Parent Operations

	store_class_parents (a_class: KB_CLASS_INFO)
			-- Store parent relationships for a class
		require
			class_has_id: a_class.id > 0
		do
			-- Delete existing parents for this class
			db.execute_with_args ("DELETE FROM class_parents WHERE class_id = ?", <<a_class.id>>)
			-- Insert new parents
			across a_class.parents as ic_p loop
				db.execute_with_args (
					"INSERT INTO class_parents (class_id, parent_name) VALUES (?, ?)",
					<<a_class.id, ic_p>>
				)
			end
		end

	load_class_parents (a_class: KB_CLASS_INFO)
			-- Load parent relationships for a class
		require
			class_has_id: a_class.id > 0
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := db.query_with_args (
				"SELECT parent_name FROM class_parents WHERE class_id = ? ORDER BY parent_name",
				<<a_class.id>>
			)
			across l_result.rows as row loop
				if attached row.item (1) as al_val then
					a_class.add_parent (al_val.out)
				end
			end
		end

feature -- Ancestry Queries

	get_ancestors (a_class_name: READABLE_STRING_GENERAL): ARRAYED_LIST [STRING_32]
			-- Get all ancestor class names (direct and indirect parents)
		require
			is_open: is_open
		local
			l_to_check: ARRAYED_LIST [STRING_32]
			l_parent: STRING_32
			l_result: SIMPLE_SQL_RESULT
		do
			create Result.make (10)
			Result.compare_objects
			create l_to_check.make (5)
			l_to_check.compare_objects
			l_to_check.extend (a_class_name.to_string_32.as_upper)

			from until l_to_check.is_empty loop
				l_parent := l_to_check.first
				l_to_check.start
				l_to_check.remove
				
				l_result := db.query_with_args ("[
					SELECT cp.parent_name FROM class_parents cp
					JOIN classes c ON c.id = cp.class_id
					WHERE UPPER(c.name) = ?
				]", <<l_parent>>)
				
				across l_result.rows as row loop
					if attached row.item (1) as al_val then
						l_parent := al_val.out.to_string_32.as_upper
						if not Result.has (l_parent) then
							Result.extend (l_parent)
							l_to_check.extend (l_parent)
						end
					end
				end
			end
		end

	get_descendants (a_class_name: READABLE_STRING_GENERAL): ARRAYED_LIST [STRING_32]
			-- Get all descendant class names (direct and indirect children)
		require
			is_open: is_open
		local
			l_to_check: ARRAYED_LIST [STRING_32]
			l_child: STRING_32
			l_result: SIMPLE_SQL_RESULT
		do
			create Result.make (10)
			Result.compare_objects
			create l_to_check.make (5)
			l_to_check.compare_objects
			l_to_check.extend (a_class_name.to_string_32.as_upper)

			from until l_to_check.is_empty loop
				l_child := l_to_check.first
				l_to_check.start
				l_to_check.remove
				
				l_result := db.query_with_args ("[
					SELECT c.name FROM classes c
					JOIN class_parents cp ON cp.class_id = c.id
					WHERE UPPER(cp.parent_name) = ?
				]", <<l_child>>)
				
				across l_result.rows as row loop
					if attached row.item (1) as al_val then
						l_child := al_val.out.to_string_32.as_upper
						if not Result.has (l_child) then
							Result.extend (l_child)
							l_to_check.extend (l_child)
						end
					end
				end
			end
		end

	get_direct_parents (a_class_name: READABLE_STRING_GENERAL): ARRAYED_LIST [STRING_32]
			-- Get direct parent class names only
		require
			is_open: is_open
		local
			l_result: SIMPLE_SQL_RESULT
		do
			create Result.make (5)
			l_result := db.query_with_args ("[
				SELECT cp.parent_name FROM class_parents cp
				JOIN classes c ON c.id = cp.class_id
				WHERE UPPER(c.name) = ?
			]", <<a_class_name.to_string_32.as_upper>>)
			
			across l_result.rows as row loop
				if attached row.item (1) as al_val then
					Result.extend (al_val.out.to_string_32)
				end
			end
		end

	get_direct_children (a_class_name: READABLE_STRING_GENERAL): ARRAYED_LIST [STRING_32]
			-- Get direct child class names only
		require
			is_open: is_open
		local
			l_result: SIMPLE_SQL_RESULT
		do
			create Result.make (10)
			l_result := db.query_with_args ("[
				SELECT c.name FROM classes c
				JOIN class_parents cp ON cp.class_id = c.id
				WHERE UPPER(cp.parent_name) = ?
			]", <<a_class_name.to_string_32.as_upper>>)
			
			across l_result.rows as row loop
				if attached row.item (1) as al_val then
					Result.extend (al_val.out.to_string_32)
				end
			end
		end

feature {NONE} -- Helpers

	bool_to_int (a_bool: BOOLEAN): INTEGER
			-- Convert boolean to integer for SQLite
		do
			if a_bool then
				Result := 1
			end
		end

feature -- Cleanup

	close
			-- Close database connection
		local
			l_rescued: BOOLEAN
		do
			if not l_rescued and then db.is_open then
				db.close
			end
		rescue
			l_rescued := True
			-- Ignore errors during close to prevent crash
			retry
		end

invariant
	db_not_void: db /= Void
	path_not_empty: not db_path.is_empty

end
