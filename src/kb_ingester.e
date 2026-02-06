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

	show_spinner: BOOLEAN
			-- Show spinning progress indicator during batch ingestion?

	debug_mode: BOOLEAN
			-- Show extra debug output during ingestion?

feature -- Settings

	set_verbose (a_val: BOOLEAN)
			-- Enable/disable progress reporting
		do
			verbose := a_val
		ensure
			verbose_set: verbose = a_val
		end

	set_show_spinner (a_val: BOOLEAN)
			-- Enable/disable spinning progress indicator
		do
			show_spinner := a_val
		ensure
			spinner_set: show_spinner = a_val
		end

	set_debug_mode (a_val: BOOLEAN)
			-- Enable/disable extra debug output
		do
			debug_mode := a_val
		ensure
			debug_set: debug_mode = a_val
		end

feature -- Version

	Version: STRING = "1.0.5"
			-- KB Ingester version for tracking which binary is running
			-- 1.0.1: Added C3 fallback, basic logging
			-- 1.0.2: SIMPLE_LOGGER integration, version tracking
			-- 1.0.3: Added minimal class detection (sed_meta_model.e crash fix)
			-- 1.0.4: Added extremely long line detection (test_memory.e crash fix)
			-- 1.0.5: Added SCOOP inline syntax detection (separate x as y do)

feature -- Logging

	log_file_path: STRING = "kb_ingest.log"
			-- Path to log file

	logger: detachable SIMPLE_LOGGER
			-- Logger instance (created on first use)

	get_logger: SIMPLE_LOGGER
			-- Get or create logger
		do
			if attached logger as al_l then
				Result := al_l
			else
				create Result.make_to_file (log_file_path)
				Result.set_level (Result.Level_debug)
				logger := Result
			end
		ensure
			result_not_void: Result /= Void
		end

	log_to_file (a_message: STRING)
			-- Log message using SIMPLE_LOGGER (flushed immediately)
		do
			get_logger.info (a_message)
		rescue
			-- Ignore logging errors - don't let logging break ingestion
		end

	clear_log_file
			-- Clear the log file at start of ingestion and log version
		local
			l_file: RAW_FILE
		do
			-- Clear the file first
			create l_file.make_create_read_write (log_file_path)
			l_file.close
			-- Reset logger so it reopens the file
			logger := Void
			-- Log startup with version
			log_to_file ("========================================")
			log_to_file ("KB INGESTER VERSION " + Version)
			log_to_file ("========================================")
		rescue
			-- Ignore
		end

feature -- Progress Display

	show_file_progress (a_filename: READABLE_STRING_GENERAL)
			-- Display spinning progress indicator with current filename.
			-- Overwrites current line using carriage return.
		local
			l_basename: STRING
			l_display: STRING
			l_max_len: INTEGER
		do
			-- Extract basename from path
			l_basename := a_filename.out
			if l_basename.has ('/') then
				l_basename := l_basename.substring (l_basename.last_index_of ('/', l_basename.count) + 1, l_basename.count)
			elseif l_basename.has ('\') then
				l_basename := l_basename.substring (l_basename.last_index_of ('\', l_basename.count) + 1, l_basename.count)
			end

			-- Limit display length to avoid line wrapping
			l_max_len := 60
			if l_basename.count > l_max_len then
				l_basename := l_basename.substring (1, l_max_len - 3) + "..."
			end

			-- Build display: "  | filename.e" (with padding to clear previous)
			create l_display.make (80)
			l_display.append ("  ")
			l_display.append_character (spinner_char)
			l_display.append (" ")
			l_display.append (l_basename)

			-- Pad with spaces to clear any longer previous filename
			from until l_display.count >= 75 loop
				l_display.append_character (' ')
			end

			-- Carriage return to start of line (no newline)
			io.put_character ('%R')
			io.put_string (l_display)

			-- Advance spinner
			advance_spinner
		end

	clear_progress_line
			-- Clear the progress line and return cursor to start
		local
			l_blanks: STRING
		do
			create l_blanks.make_filled (' ', 80)
			io.put_character ('%R')
			io.put_string (l_blanks)
			io.put_character ('%R')
		end

feature {NONE} -- Spinner Implementation

	spinner_chars: STRING = "|/-\"
			-- Characters for spinning animation

	spinner_index: INTEGER
			-- Current position in spinner_chars (1-4)

	spinner_char: CHARACTER
			-- Current spinner character
		do
			if spinner_index < 1 or spinner_index > 4 then
				spinner_index := 1
			end
			Result := spinner_chars [spinner_index]
		end

	advance_spinner
			-- Move to next spinner character
		do
			spinner_index := spinner_index + 1
			if spinner_index > 4 then
				spinner_index := 1
			end
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
			l_file: RAW_FILE
			l_rescued: BOOLEAN
			l_file_size: INTEGER
			l_content: STRING
			l_use_fallback: BOOLEAN
		do
			if not l_rescued then
				files_processed := files_processed + 1

				-- AGGRESSIVE LOGGING: Log every file BEFORE parsing
				log_to_file (">>> START " + a_file_path.out)

				-- Show spinning progress indicator with filename
				if show_spinner then
					show_file_progress (a_file_path)
				end

				-- Verbose mode: detailed tracing
				if verbose then
					io.put_string ("  [TRACE] file=" + a_file_path.out + "%N")
				end

				-- Check file exists
				create l_file.make_with_name (a_file_path.out)
				if not l_file.exists then
					errors_count := errors_count + 1
					log_to_file ("    ERR:notfound")
					if verbose then io.put_string ("    [ERR:notfound] " + a_file_path.out + "%N") end
					last_error := "File not found: " + a_file_path.out
				else
					-- Skip very large files (likely generated or test data)
					l_file_size := l_file.count
					log_to_file ("    size=" + l_file_size.out)
					if l_file_size > 500_000 then
						-- Skip files larger than 500KB
						errors_count := errors_count + 1
						log_to_file ("    ERR:toolarge")
						if verbose then io.put_string ("    [ERR:toolarge] " + a_file_path.out + "%N") end
						last_error := "File too large, skipped: " + a_file_path.out
					else
						-- Read file content to check for C3 constants
						log_to_file ("    reading content...")
						l_file.open_read
						l_file.read_stream (l_file_size.max (1))
						l_content := l_file.last_string.twin
						l_file.close
						log_to_file ("    content read, len=" + l_content.count.out)

						-- Check for patterns that crash/fail the Gobo parser:
						-- 1. C3 character constants (%/code/)
						-- 2. Minimal classes (no feature keyword)
						-- 3. Extremely long lines (> 5000 chars, e.g., test data)
						-- 4. SCOOP inline syntax - NOW HANDLED BY GOBO (no fallback needed)
						l_use_fallback := has_c3_character_constants (l_content)
						if not l_use_fallback then
							l_use_fallback := is_minimal_class (l_content)
							if l_use_fallback then
								log_to_file ("    minimal_class=True (using fallback)")
							end
						end
						if not l_use_fallback then
							l_use_fallback := has_extremely_long_lines (l_content)
							if l_use_fallback then
								log_to_file ("    long_lines=True (using fallback)")
							end
						end
						log_to_file ("    c3=" + has_c3_character_constants (l_content).out + " minimal=" + is_minimal_class (l_content).out + " longlines=" + has_extremely_long_lines (l_content).out)

						if l_use_fallback then
							-- Use simple regex-based fallback for problematic files
							log_to_file ("    using FALLBACK parser")
							if verbose then
								io.put_string ("    [FALLBACK:C3] " + a_file_path.out + "%N")
							end
							if not simple_extract_class (a_library, a_file_path, l_content) then
								errors_count := errors_count + 1
								log_to_file ("    fallback FAILED")
								last_error := "Fallback parse failed: " + a_file_path.out
							else
								log_to_file ("    fallback OK")
							end
						else
							-- Use full Gobo parser
							log_to_file ("    calling parser.parse_file...")
							l_ast := parser.parse_file (a_file_path.out)
							log_to_file ("    parser returned, has_errors=" + l_ast.has_errors.out + " classes=" + l_ast.classes.count.out)

							if l_ast.has_errors and l_ast.classes.is_empty then
								-- Parse failed completely
								errors_count := errors_count + 1
								log_to_file ("    ERR:parseerr")
								if verbose then io.put_string ("    [ERR:parseerr] " + a_file_path.out + "%N") end
								last_error := "Parse error in " + a_file_path.out
							elseif l_ast.classes.is_empty then
								-- No classes found (possibly not an Eiffel class file)
								errors_count := errors_count + 1
								log_to_file ("    ERR:noclass")
								if verbose then io.put_string ("    [ERR:noclass] " + a_file_path.out + "%N") end
								last_error := "No classes found in " + a_file_path.out
							else
								-- Note: has_errors may be True but we still got classes (partial parse)
								-- We count this as success since we can extract information
								log_to_file ("    processing " + l_ast.classes.count.out + " classes")
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
									across cls.parents as ic_p loop
										l_class.add_parent (ic_p.parent_name.to_string_32)
									end

									-- Add to database
									db.add_class (l_class)
									classes_indexed := classes_indexed + 1

									-- Index features (with per-feature exception protection)
									index_class_features (l_class, cls)
									log_to_file ("      class " + cls.name.out + " indexed")
								end
							end
						end
					end
				end
				log_to_file ("<<< END " + a_file_path.out)
			end
		rescue
			l_rescued := True
			errors_count := errors_count + 1
			log_to_file ("!!! EXCEPTION in " + a_file_path.out)
			if verbose then io.put_string ("    [ERR:exception] " + a_file_path.out + "%N") end
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
			l_libs: ARRAYED_LIST [STRING]
			l_total, l_current, l_lib_errors: INTEGER
			l_classes_before, l_features_before: INTEGER
			l_classes_added, l_features_added: INTEGER
		do
			-- Batch mode: enable spinner, disable verbose
			verbose := False
			show_spinner := True

			create l_libs.make (60)
			create l_dir.make (a_base_path.out)

			-- First pass: collect all simple_* directories
			if l_dir.exists then
				across l_dir.entries as entry loop
					l_lib_name := entry.name.out
					if l_lib_name.starts_with ("simple_") then
						l_libs.extend (l_lib_name)
					end
				end
			end

			l_total := l_libs.count
			io.put_string ("Found " + l_total.out + " simple_* libraries to process%N%N")

			-- Second pass: index each library
			across l_libs as l_lib loop
				l_current := l_current + 1
				l_lib_name := l_lib

				-- Track counts before processing
				l_classes_before := classes_indexed
				l_features_before := features_indexed

				-- Build paths
				create l_lib_path.make_from_string (a_base_path.out)
				l_lib_path := l_lib_path.extended (l_lib_name)
				create l_src_path.make_from_string (a_base_path.out)
				l_src_path := l_src_path.extended (l_lib_name).extended ("src")

				-- Index ECF and source files (with error recovery)
				if ingest_simple_library (l_lib_name, l_lib_path.out, l_src_path.out) then
					l_classes_added := classes_indexed - l_classes_before
					l_features_added := features_indexed - l_features_before
					clear_progress_line
					io.put_string ("[" + l_current.out + "/" + l_total.out + "] " + l_lib_name + ": " + l_classes_added.out + " classes, " + l_features_added.out + " features%N")
				else
					l_lib_errors := l_lib_errors + 1
					clear_progress_line
					io.put_string ("[" + l_current.out + "/" + l_total.out + "] " + l_lib_name + ": ERROR (skipped)%N")
				end
			end

			-- Final summary
			io.put_string ("%NIngestion complete: " + (l_total - l_lib_errors).out + "/" + l_total.out + " libraries%N")
			io.put_string ("  Classes: " + classes_indexed.out + " | Features: " + features_indexed.out)
			if l_lib_errors > 0 then
				io.put_string (" | Errors: " + l_lib_errors.out)
			end
			io.put_string ("%N")
		end

	ingest_simple_library (a_lib_name: STRING; a_lib_path: READABLE_STRING_GENERAL; a_src_path: READABLE_STRING_GENERAL): BOOLEAN
			-- Index a simple_* library (ECF + src/). Returns True if successful.
		local
			l_rescued: BOOLEAN
		do
			if not l_rescued then
				ingest_ecf (a_lib_name, a_lib_path.out)
				if (create {DIRECTORY}.make (a_src_path.out)).exists then
					ingest_library (a_lib_name, a_src_path.out)
				end
				Result := True
			end
		rescue
			l_rescued := True
			errors_count := errors_count + 1
			Result := False
			retry
		end


	ingest_directory_recursive (a_base_path: READABLE_STRING_GENERAL)
			-- Recursively scan directory for ECF files and index each library.
			-- Works with any directory structure (not just simple_* directories).
			-- Suitable for EiffelStudio standard library layout.
		require
			path_not_empty: not a_base_path.is_empty
		local
			l_ecf_files: ARRAYED_LIST [PATH]
			l_lib_name: STRING_32
			l_lib_dir: PATH
			l_total, l_current, l_lib_errors: INTEGER
			l_classes_before, l_features_before: INTEGER
			l_classes_added, l_features_added: INTEGER
		do
			-- Clear log file and start fresh
			clear_log_file
			log_to_file ("Starting ingest_directory_recursive: " + a_base_path.out)

			-- Batch mode: enable spinner, disable verbose
			verbose := False
			show_spinner := True
			debug_mode := False

			io.put_string ("Scanning for ECF files in: " + a_base_path.out + "%N")

			-- Find all ECF files recursively
			l_ecf_files := scan_for_ecf_files (create {PATH}.make_from_string (a_base_path.out))
			l_total := l_ecf_files.count

			io.put_string ("Found " + l_total.out + " libraries to process%N%N")

			-- Process each ECF file
			across l_ecf_files as ecf loop
				l_current := l_current + 1

				-- Extract library name from ECF filename (without .ecf extension)
				l_lib_name := ecf.name.out
				if l_lib_name.ends_with (".ecf") then
					l_lib_name := l_lib_name.substring (1, l_lib_name.count - 4)
				end

				-- Get library directory (parent of ECF file)
				if attached ecf.parent as al_parent_path then
					l_lib_dir := al_parent_path
				else
					create l_lib_dir.make_from_string (a_base_path.out)
				end

				-- Track counts before processing
				l_classes_before := classes_indexed
				l_features_before := features_indexed

				-- LOGGING: Log library start
				log_to_file ("=== LIBRARY [" + l_current.out + "/" + l_total.out + "] " + l_lib_name + " ===")
				log_to_file ("    ecf=" + ecf.out)
				log_to_file ("    dir=" + l_lib_dir.out)

				-- Index the ECF file and source files (with error recovery)
				if ingest_library_with_ecf (l_lib_name, ecf.out, l_lib_dir.out) then
					l_classes_added := classes_indexed - l_classes_before
					l_features_added := features_indexed - l_features_before
					log_to_file ("    DONE: +" + l_classes_added.out + " classes, +" + l_features_added.out + " features")
					clear_progress_line
					io.put_string ("[" + l_current.out + "/" + l_total.out + "] " + l_lib_name + ": " + l_classes_added.out + " classes, " + l_features_added.out + " features%N")
				else
					l_lib_errors := l_lib_errors + 1
					log_to_file ("    LIBRARY ERROR - skipped")
					clear_progress_line
					io.put_string ("[" + l_current.out + "/" + l_total.out + "] " + l_lib_name + ": ERROR (skipped)%N")
				end
			end

			-- Final summary
			io.put_string ("%NIngestion complete: " + (l_total - l_lib_errors).out + "/" + l_total.out + " libraries%N")
			io.put_string ("  Classes: " + classes_indexed.out + " | Features: " + features_indexed.out)
			if l_lib_errors > 0 then
				io.put_string (" | Errors: " + l_lib_errors.out)
			end
			io.put_string ("%N")
		end

	ingest_library_with_ecf (a_library: READABLE_STRING_GENERAL; a_ecf_path: READABLE_STRING_GENERAL; a_lib_dir: READABLE_STRING_GENERAL): BOOLEAN
			-- Index ECF and library source files. Returns True if successful.
		local
			l_rescued: BOOLEAN
		do
			if not l_rescued then
				ingest_ecf_file (a_library, a_ecf_path)
				ingest_library (a_library, a_lib_dir)
				Result := True
			end
		rescue
			l_rescued := True
			errors_count := errors_count + 1
			Result := False
			retry
		end

	ingest_ecf_file (a_library: READABLE_STRING_GENERAL; a_ecf_path: READABLE_STRING_GENERAL)
			-- Parse ECF file at exact path and extract library metadata
		require
			library_not_empty: not a_library.is_empty
			path_not_empty: not a_ecf_path.is_empty
		local
			l_file: RAW_FILE
			l_content: STRING
			l_lib: KB_LIBRARY_INFO
			l_rescued: BOOLEAN
		do
			if not l_rescued then
				create l_file.make_with_name (a_ecf_path.out)
				if l_file.exists then
					if verbose then
						io.put_string ("[ECF] " + a_ecf_path.out + "%N")
					end

					-- Read ECF content
					l_file.open_read
					l_file.read_stream (l_file.count.max (1))
					l_content := l_file.last_string.twin
					l_file.close

					-- Parse and store library info
					l_lib := parse_ecf_content (a_library.to_string_32, l_content, a_ecf_path.out)
					db.add_library (l_lib)
					libraries_indexed := libraries_indexed + 1
				end
			end
		rescue
			l_rescued := True
			errors_count := errors_count + 1
			last_error := "Exception parsing ECF: " + a_ecf_path.out
			retry
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
			
			if attached l_xml_doc.root as al_root then
				-- ECF root is <system>
				-- UUID
				if attached al_root.attr ("uuid") as al_uuid then
					Result.set_uuid (al_uuid)
				end
				
				-- Description
				if attached al_root.element ("description") as al_desc_el then
					if attached al_desc_el.text as al_txt then
						Result.set_description (al_txt)
					end
				end
				
				-- Find targets for clusters and dependencies
				l_targets := al_root.elements ("target")
				from i := 1 until i > l_targets.count loop
					l_tgt := l_targets [i]
					
					-- Clusters
					l_clusters := l_tgt.elements ("cluster")
					from j := 1 until j > l_clusters.count loop
						l_el := l_clusters [j]
						if attached l_el.attr ("name") as al_cl_name then
							Result.add_cluster (al_cl_name)
						end
						j := j + 1
					end
					
					-- Dependencies (library tags)
					l_libs := l_tgt.elements ("library")
					from j := 1 until j > l_libs.count loop
						l_el := l_libs [j]
						if attached l_el.attr ("name") as al_lib_name then
							Result.add_dependency (al_lib_name)
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

	has_c3_character_constants (a_content: STRING): BOOLEAN
			-- Does content contain C3 character constants (%/code/)?
			-- These cause segfaults in the Gobo parser.
		local
			i: INTEGER
		do
			-- Look for patterns like %/123/ or %/0x1F/
			from i := 1 until i > a_content.count - 3 or Result loop
				if a_content.item (i) = '%%' and then i + 1 <= a_content.count then
					if a_content.item (i + 1) = '/' then
						-- Found %/ - this is a C3 character constant start
						Result := True
					end
				end
				i := i + 1
			end
		end

	is_minimal_class (a_content: STRING): BOOLEAN
			-- Is this a minimal class that may crash the Gobo parser?
			-- Pattern: class with no feature keyword (just notes and class declaration)
			-- These cause segfaults in sed_meta_model.e and similar files.
		local
			l_upper: STRING
			l_has_class, l_has_feature, l_has_end: BOOLEAN
		do
			l_upper := a_content.as_upper
			l_has_class := l_upper.has_substring ("CLASS")
			l_has_feature := l_upper.has_substring ("FEATURE")
			l_has_end := l_upper.has_substring ("END")

			-- Minimal class = has class and end but no feature keyword
			Result := l_has_class and l_has_end and not l_has_feature
		end

	has_extremely_long_lines (a_content: STRING): BOOLEAN
			-- Does content have extremely long lines that may crash the Gobo parser?
			-- Pattern: lines > 5000 characters (e.g., test data with huge strings)
			-- These cause hangs in test_memory.e and similar files.
		local
			i, line_start, line_len: INTEGER
			Max_line_length: INTEGER
		do
			Max_line_length := 5000
			line_start := 1
			from i := 1 until i > a_content.count or Result loop
				if a_content.item (i) = '%N' then
					line_len := i - line_start
					if line_len > Max_line_length then
						Result := True
					end
					line_start := i + 1
				end
				i := i + 1
			end
			-- Check last line (may not have newline)
			if not Result then
				line_len := a_content.count - line_start + 1
				if line_len > Max_line_length then
					Result := True
				end
			end
		end

	simple_extract_class (a_library: READABLE_STRING_GENERAL; a_file_path: READABLE_STRING_GENERAL; a_content: STRING): BOOLEAN
			-- Extract class info using simple regex-based parsing.
			-- Fallback for files that crash the Gobo parser.
		local
			l_class: KB_CLASS_INFO
			l_class_name: STRING
			l_upper: STRING
			i, j, k: INTEGER
			l_in_feature: BOOLEAN
			l_feat_name: STRING
			l_feature: KB_FEATURE_INFO
		do
			-- Find class name
			l_upper := a_content.as_upper
			i := l_upper.substring_index ("CLASS", 1)
			if i > 0 then
				-- Skip "class" and whitespace
				from i := i + 5 until i > a_content.count or else not a_content.item (i).is_space loop
					i := i + 1
				end
				-- Find end of class name
				from j := i until j > a_content.count or else not (a_content.item (j).is_alpha or a_content.item (j).is_digit or a_content.item (j) = '_') loop
					j := j + 1
				end
				if j > i then
					l_class_name := a_content.substring (i, j - 1).as_upper

					-- Create class info
					create l_class.make (a_library.to_string_32, l_class_name.to_string_32)
					l_class.set_file_path (a_file_path.to_string_32)
					l_class.set_description ({STRING_32} "[Parsed with fallback - C3 constants]")

					-- Check for deferred
					if l_upper.has_substring ("DEFERRED CLASS") then
						l_class.set_deferred (True)
					end

					-- Check for expanded
					if l_upper.has_substring ("EXPANDED CLASS") then
						l_class.set_expanded (True)
					end

					db.add_class (l_class)
					classes_indexed := classes_indexed + 1

					-- Extract feature names using simple pattern matching
					-- Look for "feature" keyword sections
					i := 1
					from until i > l_upper.count loop
						-- Find next potential feature name (after tab at start of line)
						-- Pattern: newline + tab + identifier + space or (
						if i > 1 and then a_content.item (i - 1) = '%N' and then a_content.item (i) = '%T' then
							-- Skip the tab
							i := i + 1
							if i <= a_content.count and then a_content.item (i).is_alpha then
								-- Capture feature name
								from j := i until j > a_content.count or else not (a_content.item (j).is_alpha or a_content.item (j).is_digit or a_content.item (j) = '_') loop
									j := j + 1
								end
								l_feat_name := a_content.substring (i, j - 1)

								-- Check it's not a keyword
								if not is_eiffel_keyword (l_feat_name.as_lower) then
									-- Check next char is space, (, :, or newline
									if j <= a_content.count then
										inspect a_content.item (j)
										when ' ', '%T', '(', ':', '%N' then
											create l_feature.make (l_class.id, l_feat_name.as_lower.to_string_32)
											l_feature.set_kind ("query")
											db.add_feature (l_feature)
											features_indexed := features_indexed + 1
										else
											-- Not a feature
										end
									end
								end
								i := j
							end
						end
						i := i + 1
					end

					Result := True
				end
			end
		end

	is_eiffel_keyword (a_name: STRING): BOOLEAN
			-- Is this an Eiffel keyword?
		do
			Result := a_name.same_string ("do") or a_name.same_string ("end")
				or a_name.same_string ("if") or a_name.same_string ("then")
				or a_name.same_string ("else") or a_name.same_string ("elseif")
				or a_name.same_string ("from") or a_name.same_string ("until")
				or a_name.same_string ("loop") or a_name.same_string ("across")
				or a_name.same_string ("require") or a_name.same_string ("ensure")
				or a_name.same_string ("local") or a_name.same_string ("rescue")
				or a_name.same_string ("retry") or a_name.same_string ("create")
				or a_name.same_string ("inherit") or a_name.same_string ("feature")
				or a_name.same_string ("class") or a_name.same_string ("deferred")
				or a_name.same_string ("expanded") or a_name.same_string ("frozen")
				or a_name.same_string ("once") or a_name.same_string ("note")
				or a_name.same_string ("invariant") or a_name.same_string ("variant")
				or a_name.same_string ("check") or a_name.same_string ("debug")
				or a_name.same_string ("inspect") or a_name.same_string ("when")
				or a_name.same_string ("attribute") or a_name.same_string ("redefine")
				or a_name.same_string ("rename") or a_name.same_string ("export")
				or a_name.same_string ("undefine") or a_name.same_string ("select")
				or a_name.same_string ("obsolete") or a_name.same_string ("external")
				or a_name.same_string ("alias") or a_name.same_string ("convert")
				or a_name.same_string ("old") or a_name.same_string ("agent")
				or a_name.same_string ("attached") or a_name.same_string ("detachable")
				or a_name.same_string ("separate") or a_name.same_string ("result")
				or a_name.same_string ("current") or a_name.same_string ("precursor")
				or a_name.same_string ("true") or a_name.same_string ("false")
				or a_name.same_string ("void") or a_name.same_string ("like")
				or a_name.same_string ("and") or a_name.same_string ("or")
				or a_name.same_string ("xor") or a_name.same_string ("not")
				or a_name.same_string ("implies") or a_name.same_string ("as")
		end

	index_class_features (a_class: KB_CLASS_INFO; a_parsed_class: EIFFEL_CLASS_NODE)
			-- Safely index features from parsed class.
			-- Isolates exceptions to per-feature level.
		do
			across a_parsed_class.features as feat loop
				index_single_feature (a_class, feat)
			end
		end

	index_single_feature (a_class: KB_CLASS_INFO; a_feat: EIFFEL_FEATURE_NODE)
			-- Index a single feature with exception protection.
		local
			l_feature: KB_FEATURE_INFO
			l_rescued: BOOLEAN
			l_name, l_sig, l_desc, l_kind: STRING_32
		do
			if not l_rescued then
				-- Extract feature properties
				l_name := safe_string (a_feat.name)
				l_sig := safe_string (a_feat.signature)
				l_desc := safe_string (a_feat.header_comment)
				l_kind := map_parser_kind_to_kb_kind (safe_string (a_feat.kind_string))

				-- Create feature
				create l_feature.make (a_class.id, l_name)
				l_feature.set_signature (l_sig)
				l_feature.set_description (l_desc)
				l_feature.set_kind (l_kind)

				-- Set feature modifiers
				set_feature_modifiers (l_feature, a_feat)

				-- Add contracts
				add_feature_contracts (l_feature, a_feat)

				db.add_feature (l_feature)
				features_indexed := features_indexed + 1
			end
		rescue
			l_rescued := True
			-- Silently skip bad features - class was still successfully indexed
			if verbose then
				io.put_string ("      [WARN:feat] Exception extracting feature%N")
			end
			retry
		end

	safe_string (a_str: detachable READABLE_STRING_GENERAL): STRING_32
			-- Convert string safely, returning empty string for Void
		do
			if attached a_str as al_s then
				Result := al_s.to_string_32
			else
				create Result.make_empty
			end
		end

	map_parser_kind_to_kb_kind (a_parser_kind: STRING_32): STRING_32
			-- Map parser kind strings to KB kind strings.
			-- Parser returns: procedure, function, attribute, once, external, unknown
			-- KB expects: query, command, creation, attribute
		do
			if a_parser_kind.same_string ("procedure") then
				Result := "command"
			elseif a_parser_kind.same_string ("function") then
				Result := "query"
			elseif a_parser_kind.same_string ("once") then
				Result := "query"  -- once functions are queries
			elseif a_parser_kind.same_string ("external") then
				Result := "query"  -- externals could be either, default to query
			elseif a_parser_kind.same_string ("attribute") then
				Result := "attribute"
			else
				Result := "query"  -- default for unknown
			end
		ensure
			valid_result: Result.same_string ("query") or Result.same_string ("command")
				or Result.same_string ("creation") or Result.same_string ("attribute")
		end

	set_feature_modifiers (a_feature: KB_FEATURE_INFO; a_parsed: EIFFEL_FEATURE_NODE)
			-- Safely set feature modifiers
		local
			l_rescued: BOOLEAN
		do
			if not l_rescued then
				a_feature.set_deferred (a_parsed.is_deferred)
				a_feature.set_frozen (a_parsed.is_frozen)
				a_feature.set_once (a_parsed.is_once)
			end
		rescue
			l_rescued := True
			retry
		end

	add_feature_contracts (a_feature: KB_FEATURE_INFO; a_parsed: EIFFEL_FEATURE_NODE)
			-- Safely add feature contracts
		local
			l_rescued: BOOLEAN
		do
			if not l_rescued then
				if attached a_parsed.precondition as pre and then not pre.is_empty then
					a_feature.add_precondition ("require", pre.to_string_32)
				end
				if attached a_parsed.postcondition as post and then not post.is_empty then
					a_feature.add_postcondition ("ensure", post.to_string_32)
				end
			end
		rescue
			l_rescued := True
			retry
		end

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

	scan_for_ecf_files (a_path: PATH): ARRAYED_LIST [PATH]
			-- Recursively find all .ecf files in directory tree
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
							Result.append (scan_for_ecf_files (l_file_path))
						elseif entry.name.out.ends_with (".ecf") then
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
