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

inherit
	SHARED_EXECUTION_ENVIRONMENT

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
			libraries_indexed := 0
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

	libraries_indexed: INTEGER
			-- Number of libraries indexed (ECF files)

	last_error: STRING_32
			-- Last error message

	verbose: BOOLEAN
			-- Report progress during ingestion?

feature -- Settings

	set_verbose (a_val: BOOLEAN)
			-- Enable/disable progress reporting
		do
			verbose := a_val
		ensure
			verbose_set: verbose = a_val
		end

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
				if verbose then
					io.put_string ("[LIBRARY] " + a_library.out + " (" + a_src_path.out + ")%N")
				end
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
							-- Report progress
							if verbose then
								io.put_string ("  [CLASS] " + cls.name.out + "%N")
							end
							
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
			l_lib_path: PATH
			l_src_path: PATH
		do
			create l_dir.make (a_base_path.out)
			if l_dir.exists then
				across l_dir.entries as entry loop
					l_lib_name := entry.name.out
					if l_lib_name.starts_with ("simple_") then
						-- Index ECF file
						create l_lib_path.make_from_string (a_base_path.out)
						l_lib_path := l_lib_path.extended (l_lib_name)
						ingest_ecf (l_lib_name, l_lib_path.out)
						
						-- Try src/ subdirectory for source files
						create l_src_path.make_from_string (a_base_path.out)
						l_src_path := l_src_path.extended (l_lib_name).extended ("src")
						if (create {DIRECTORY}.make_with_path (l_src_path)).exists then
							ingest_library (l_lib_name, l_src_path.out)
						end
					end
				end
			end
		end

	ingest_ecf (a_library: READABLE_STRING_GENERAL; a_lib_path: READABLE_STRING_GENERAL)
			-- Parse ECF file and extract library metadata
		require
			library_not_empty: not a_library.is_empty
			path_not_empty: not a_lib_path.is_empty
		local
			l_ecf_path: STRING
			l_file: RAW_FILE
			l_content: STRING
			l_lib: KB_LIBRARY_INFO
			l_rescued: BOOLEAN
		do
			if not l_rescued then
				-- Find ECF file (library_name.ecf)
				l_ecf_path := a_lib_path.out + "/" + a_library.out + ".ecf"
				create l_file.make_with_name (l_ecf_path)
				if l_file.exists then
					if verbose then
						io.put_string ("[ECF] " + l_ecf_path + "%N")
					end
					
					-- Read ECF content
					l_file.open_read
					l_file.read_stream (l_file.count.max (1))
					l_content := l_file.last_string.twin
					l_file.close
					
					-- Parse and store library info
					l_lib := parse_ecf_content (a_library.to_string_32, l_content, l_ecf_path)
					db.add_library (l_lib)
					libraries_indexed := libraries_indexed + 1
				end
			end
		rescue
			l_rescued := True
			errors_count := errors_count + 1
			last_error := "Exception parsing ECF for " + a_library.out
			retry
		end

	parse_ecf_content (a_name: STRING_32; a_content: STRING; a_path: STRING): KB_LIBRARY_INFO
			-- Parse ECF XML content into library info
		local
			l_xml: SIMPLE_XML
			l_xml_doc: SIMPLE_XML_DOCUMENT
			l_targets, l_clusters, l_libs: ARRAYED_LIST [SIMPLE_XML_ELEMENT]
			l_tgt, l_el: SIMPLE_XML_ELEMENT
			i, j: INTEGER
		do
			create Result.make (a_name)
			Result.set_file_path (a_path.to_string_32)
			
			-- Parse XML
			create l_xml.make
			l_xml_doc := l_xml.parse (a_content)
			
			if attached l_xml_doc.root as root then
				-- ECF root is <system>
				-- UUID
				if attached root.attr ("uuid") as uuid then
					Result.set_uuid (uuid)
				end
				
				-- Description
				if attached root.element ("description") as desc_el then
					if attached desc_el.text as txt then
						Result.set_description (txt)
					end
				end
				
				-- Find targets for clusters and dependencies
				l_targets := root.elements ("target")
				from i := 1 until i > l_targets.count loop
					l_tgt := l_targets [i]
					
					-- Clusters
					l_clusters := l_tgt.elements ("cluster")
					from j := 1 until j > l_clusters.count loop
						l_el := l_clusters [j]
						if attached l_el.attr ("name") as cl_name then
							Result.add_cluster (cl_name)
						end
						j := j + 1
					end
					
					-- Dependencies (library tags)
					l_libs := l_tgt.elements ("library")
					from j := 1 until j > l_libs.count loop
						l_el := l_libs [j]
						if attached l_el.attr ("name") as lib_name then
							Result.add_dependency (lib_name)
						end
						j := j + 1
					end
					
					i := i + 1
				end
			end
		end

feature -- Statistics

	stats: TUPLE [files, classes, features, errors, libraries: INTEGER]
			-- Ingestion statistics
		do
			Result := [files_processed, classes_indexed, features_indexed, errors_count, libraries_indexed]
		end

	reset_stats
			-- Reset statistics counters
		do
			files_processed := 0
			classes_indexed := 0
			features_indexed := 0
			errors_count := 0
			libraries_indexed := 0
			last_error.wipe_out
		ensure
			files_reset: files_processed = 0
			classes_reset: classes_indexed = 0
			features_reset: features_indexed = 0
			errors_reset: errors_count = 0
			libraries_reset: libraries_indexed = 0
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
