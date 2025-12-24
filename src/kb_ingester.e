note
	description: "[
		KB_INGESTER - Source Code Indexer

		Parses Eiffel source files and indexes classes/features into
		the knowledge base for full-text search.

		Usage:
			ingester: KB_INGESTER
			create ingester.make (db)
			ingester.ingest_library ("simple_json", "/d/prod/simple_json/src")
			ingester.ingest_all_simple_libraries ("/d/prod")
	]"
	author: "Simple Eiffel"
	date: "$Date$"
	revision: "$Revision$"

class
	KB_INGESTER

create
	make

feature {NONE} -- Initialization

	make (a_db: KB_DATABASE)
			-- Create ingester with database
		require
			db_not_void: a_db /= Void
			db_open: a_db.is_open
		do
			db := a_db
			create parser.make
			classes_indexed := 0
			features_indexed := 0
			files_processed := 0
			errors_count := 0
			create last_error.make_empty
		ensure
			db_set: db = a_db
		end

feature -- Access

	db: KB_DATABASE
			-- Target database

	classes_indexed: INTEGER
			-- Number of classes indexed

	features_indexed: INTEGER
			-- Number of features indexed

	files_processed: INTEGER
			-- Number of files processed

	errors_count: INTEGER
			-- Number of parse errors

	last_error: STRING_32
			-- Last error message

feature -- Ingestion

	ingest_library (a_library: READABLE_STRING_GENERAL; a_src_path: READABLE_STRING_GENERAL)
			-- Index all .e files in library source path
		require
			library_not_empty: not a_library.is_empty
			path_not_empty: not a_src_path.is_empty
		local
			l_dir: DIRECTORY
			l_entries: ARRAYED_LIST [PATH]
		do
			create l_dir.make (a_src_path.out)
			if l_dir.exists then
				l_entries := scan_directory (l_dir.path)
				across l_entries as entry loop
					ingest_file (a_library, entry.out)
				end
			end
		end

	ingest_file (a_library: READABLE_STRING_GENERAL; a_file_path: READABLE_STRING_GENERAL)
			-- Index single .e file
		require
			library_not_empty: not a_library.is_empty
			path_not_empty: not a_file_path.is_empty
		local
			l_ast: EIFFEL_AST
			l_class: KB_CLASS_INFO
			l_feature: KB_FEATURE_INFO
			l_file: RAW_FILE
			l_rescued: BOOLEAN
		do
			if not l_rescued then
				files_processed := files_processed + 1

				-- Check file exists
				create l_file.make_with_name (a_file_path.out)
				if not l_file.exists then
					errors_count := errors_count + 1
					last_error := "File not found: " + a_file_path.out
				else
					l_ast := parser.parse_file (a_file_path.out)

					if l_ast.has_errors then
						errors_count := errors_count + 1
						last_error := "Parse error in " + a_file_path.out
					elseif l_ast.classes.is_empty then
						errors_count := errors_count + 1
						last_error := "No classes found in " + a_file_path.out
					else
						across l_ast.classes as cls loop
							-- Create class info
							create l_class.make (a_library.to_string_32, cls.name.to_string_32)
							l_class.set_description (cls.header_comment.to_string_32)
							l_class.set_file_path (a_file_path.to_string_32)

							-- Set class modifiers
							l_class.set_deferred (cls.is_deferred)
							l_class.set_expanded (cls.is_expanded)
							l_class.set_frozen (cls.is_frozen)

							-- Extract parents
							across cls.parents as p loop
								l_class.add_parent (p.parent_name.to_string_32)
							end

							-- Add to database
							db.add_class (l_class)
							classes_indexed := classes_indexed + 1

							-- Index features
							across cls.features as feat loop
								create l_feature.make (l_class.id, feat.name.to_string_32)
								l_feature.set_signature (feat.signature.to_string_32)
								l_feature.set_description (feat.header_comment.to_string_32)
								l_feature.set_kind (feat.kind_string.to_string_32)

								-- Set feature modifiers
								l_feature.set_deferred (feat.is_deferred)
								l_feature.set_frozen (feat.is_frozen)
								l_feature.set_once (feat.is_once)

								-- Add contracts if present
								if not feat.precondition.is_empty then
									l_feature.add_precondition ("require", feat.precondition.to_string_32)
								end
								if not feat.postcondition.is_empty then
									l_feature.add_postcondition ("ensure", feat.postcondition.to_string_32)
								end

								db.add_feature (l_feature)
								features_indexed := features_indexed + 1
							end
						end
					end
				end
			end
		rescue
			l_rescued := True
			errors_count := errors_count + 1
			last_error := "Exception parsing " + a_file_path.out
			retry
		end

	ingest_all_simple_libraries (a_base_path: READABLE_STRING_GENERAL)
			-- Index all simple_* libraries from base path
		require
			path_not_empty: not a_base_path.is_empty
		local
			l_dir: DIRECTORY
			l_lib_name: STRING
			l_src_path: PATH
		do
			create l_dir.make (a_base_path.out)
			if l_dir.exists then
				across l_dir.entries as entry loop
					l_lib_name := entry.name.out
					if l_lib_name.starts_with ("simple_") then
						-- Try src/ subdirectory
						create l_src_path.make_from_string (a_base_path.out)
						l_src_path := l_src_path.extended (l_lib_name).extended ("src")
						if (create {DIRECTORY}.make_with_path (l_src_path)).exists then
							ingest_library (l_lib_name, l_src_path.out)
						end
					end
				end
			end
		end

feature -- Statistics

	stats: TUPLE [files, classes, features, errors: INTEGER]
			-- Ingestion statistics
		do
			Result := [files_processed, classes_indexed, features_indexed, errors_count]
		end

	reset_stats
			-- Reset statistics counters
		do
			files_processed := 0
			classes_indexed := 0
			features_indexed := 0
			errors_count := 0
			last_error.wipe_out
		ensure
			files_reset: files_processed = 0
			classes_reset: classes_indexed = 0
			features_reset: features_indexed = 0
			errors_reset: errors_count = 0
		end

feature {NONE} -- Implementation

	parser: SIMPLE_EIFFEL_PARSER
			-- Eiffel parser

	scan_directory (a_path: PATH): ARRAYED_LIST [PATH]
			-- Recursively find all .e files
		local
			l_dir: DIRECTORY
			l_file_path: PATH
		do
			create Result.make (50)
			create l_dir.make_with_path (a_path)

			if l_dir.exists and then l_dir.is_readable then
				across l_dir.entries as entry loop
					if not entry.name.out.starts_with (".") then
						l_file_path := a_path.extended (entry.name.out)
						if (create {DIRECTORY}.make_with_path (l_file_path)).exists then
							-- Recurse into subdirectory
							Result.append (scan_directory (l_file_path))
						elseif entry.name.out.ends_with (".e") then
							Result.extend (l_file_path)
						end
					end
				end
			end
		end

invariant
	db_not_void: db /= Void
	parser_not_void: parser /= Void

end
