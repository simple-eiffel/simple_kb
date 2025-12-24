note
	description: "[
		KB_CLI_APP - Knowledge Base Command Line Interface

		Main CLI application for querying the Eiffel knowledge base.

		Commands:
			kb search <query>   - Full-text search across all content
			kb class <name>     - Show class details + features
			kb error <code>     - Look up error code (e.g., kb error VEVI)
			kb error list       - List all known error codes
			kb ingest <path>    - Index source files from path
			kb seed             - Populate database with known error codes
			kb stats            - Show database statistics
			kb help             - Show help

		Usage:
			> kb search json
			[CLASS] SIMPLE_JSON - Parse and generate JSON
			[ERROR] SEARCH1 - JSON parsing error
			...
	]"
	author: "Simple Eiffel"
	date: "$Date$"
	revision: "$Revision$"

class
	KB_CLI_APP

inherit
	SHARED_EXECUTION_ENVIRONMENT

create
	make

feature {NONE} -- Initialization

	make
			-- Run CLI
		local
			l_args: ARGUMENTS_32
		do
			create l_args
			create db.make (default_db_path)

			if l_args.argument_count = 0 then
				show_help
			else
				process_command (l_args)
			end

			db.close
		end

feature -- Commands

	process_command (a_args: ARGUMENTS_32)
			-- Process command from arguments
		local
			l_cmd: STRING_32
		do
			l_cmd := a_args.argument (1).as_lower

			if l_cmd.same_string ("search") then
				process_search_command (a_args)
			elseif l_cmd.same_string ("class") then
				process_class_command (a_args)
			elseif l_cmd.same_string ("error") then
				process_error_command (a_args)
			elseif l_cmd.same_string ("pattern") then
				process_pattern_command (a_args)
			elseif l_cmd.same_string ("ingest") then
				process_ingest_command (a_args)
			elseif l_cmd.same_string ("rosetta") then
				process_rosetta_command (a_args)
			elseif l_cmd.same_string ("seed") then
				cmd_seed
			elseif l_cmd.same_string ("stats") then
				cmd_stats
			elseif l_cmd.same_string ("help") or l_cmd.same_string ("--help") or l_cmd.same_string ("-h") then
				show_help
			else
				io.put_string ("Unknown command: " + l_cmd.out + "%N")
				io.put_string ("Use 'kb help' for usage information.%N")
			end
		end

	process_search_command (a_args: ARGUMENTS_32)
			-- Handle 'search' subcommand
		local
			l_query: STRING_32
		do
			if a_args.argument_count < 2 then
				io.put_string ("Usage: kb search <query>%N")
				io.put_string ("Example: kb search json%N")
			else
				l_query := a_args.argument (2)
				cmd_search (l_query)
			end
		end

	process_class_command (a_args: ARGUMENTS_32)
			-- Handle 'class' subcommand
		local
			l_name: STRING_32
		do
			if a_args.argument_count < 2 then
				io.put_string ("Usage: kb class <name>%N")
				io.put_string ("Example: kb class SIMPLE_JSON%N")
			else
				l_name := a_args.argument (2).as_upper
				cmd_class (l_name)
			end
		end

	process_error_command (a_args: ARGUMENTS_32)
			-- Handle 'error' subcommand
		local
			l_code: STRING_32
		do
			if a_args.argument_count < 2 then
				cmd_error_list
			else
				l_code := a_args.argument (2).as_upper
				if l_code.same_string ("LIST") then
					cmd_error_list
				else
					cmd_error_lookup (l_code)
				end
			end
		end

	process_ingest_command (a_args: ARGUMENTS_32)
			-- Handle 'ingest' subcommand
		local
			l_path: STRING_32
		do
			if a_args.argument_count < 2 then
				io.put_string ("Usage: kb ingest <path>%N")
				io.put_string ("Example: kb ingest /d/prod/simple_json%N")
				io.put_string ("         kb ingest /d/prod  (all simple_* libraries)%N")
			else
				l_path := a_args.argument (2)
				cmd_ingest (l_path)
			end
		end

	process_rosetta_command (a_args: ARGUMENTS_32)
			-- Handle 'rosetta' subcommand
		local
			l_path: STRING_32
		do
			if a_args.argument_count < 2 then
				io.put_string ("Usage: kb rosetta <path>%N")
				io.put_string ("Example: kb rosetta /d/prod/simple_rosetta%N")
			else
				l_path := a_args.argument (2)
				cmd_rosetta (l_path)
			end
		end

	cmd_rosetta (a_path: STRING_32)
			-- Import Rosetta Code examples
		local
			l_importer: KB_ROSETTA_IMPORTER
			l_stats: TUPLE [imported, errors: INTEGER]
			l_dir: DIRECTORY
		do
			create l_dir.make (a_path.out)
			if not l_dir.exists then
				io.put_string ("Path not found: " + a_path.out + "%N")
			else
				io.put_string ("Importing Rosetta Code solutions from: " + a_path.out + "%N")
				create l_importer.make (db)
				l_importer.import_all (a_path)

				l_stats := l_importer.stats
				io.put_string ("%NDone. Imported:%N")
				io.put_string ("  - " + l_stats.imported.out + " examples%N")
				if l_stats.errors > 0 then
					io.put_string ("  - " + l_stats.errors.out + " errors%N")
				end
			end
		end

feature -- Error Commands

	cmd_error_lookup (a_code: STRING_32)
			-- Look up specific error code
		local
			l_error: detachable KB_ERROR_INFO
		do
			l_error := db.get_error (a_code)
			if attached l_error as err then
				io.put_string (err.formatted.out)
				io.put_string ("%N")
			else
				io.put_string ("Error code not found: " + a_code.out + "%N%N")
				io.put_string ("Use 'kb error list' to see all known error codes.%N")
				io.put_string ("Or use 'kb seed' to populate the database first.%N")
			end
		end

	cmd_error_list
			-- List all error codes
		local
			l_errors: ARRAYED_LIST [KB_ERROR_INFO]
		do
			l_errors := db.all_errors
			if l_errors.is_empty then
				io.put_string ("No error codes in database.%N")
				io.put_string ("Run 'kb seed' to populate with known error codes.%N")
			else
				io.put_string ("Known Error Codes (" + l_errors.count.out + "):%N")
				io.put_string ("================================%N%N")
				across l_errors as err loop
					io.put_string (err.code.out)
					io.put_string (": ")
					io.put_string (err.meaning.out)
					io.put_string ("%N")
				end
			end
		end

feature -- Pattern Commands

	process_pattern_command (a_args: ARGUMENTS_32)
			-- Handle 'pattern' subcommand
		local
			l_name: STRING_32
		do
			if a_args.argument_count < 2 then
				cmd_pattern_list
			else
				l_name := a_args.argument (2).as_lower
				if l_name.same_string ("list") then
					cmd_pattern_list
				else
					cmd_pattern_lookup (l_name)
				end
			end
		end

	cmd_pattern_lookup (a_name: STRING_32)
			-- Look up specific pattern
		local
			l_pattern: detachable KB_PATTERN
		do
			l_pattern := db.get_pattern (a_name)
			if attached l_pattern as pat then
				io.put_string (pat.formatted.out)
				io.put_string ("%N")
			else
				io.put_string ("Pattern not found: " + a_name.out + "%N%N")
				io.put_string ("Use 'kb pattern list' to see all patterns.%N")
				io.put_string ("Or run 'kb seed' to populate patterns first.%N")
			end
		end

	cmd_pattern_list
			-- List all patterns
		local
			l_patterns: ARRAYED_LIST [KB_PATTERN]
		do
			l_patterns := db.all_patterns
			if l_patterns.is_empty then
				io.put_string ("No patterns in database.%N")
				io.put_string ("Run 'kb seed' to populate with Eiffel patterns.%N")
			else
				io.put_string ("Eiffel Patterns (" + l_patterns.count.out + "):%N")
				io.put_string ("========================%N%N")
				across l_patterns as pat loop
					io.put_string (pat.brief.out)
					io.put_string ("%N")
				end
			end
		end

feature -- Search Commands

	cmd_search (a_query: STRING_32)
			-- Full-text search
		local
			l_results: ARRAYED_LIST [KB_RESULT]
		do
			l_results := db.search (a_query, 20)
			if l_results.is_empty then
				io.put_string ("No results found for: " + a_query.out + "%N%N")
				io.put_string ("Try different keywords or run 'kb seed' and 'kb ingest' first.%N")
			else
				io.put_string ("Search Results for '" + a_query.out + "' (" + l_results.count.out + "):%N")
				io.put_string ("============================================%N%N")
				across l_results as r loop
					io.put_string (r.type_label.out + " " + r.title.out + "%N")
					if not r.snippet.is_empty then
						io.put_string ("   " + truncate (r.snippet, 80).out + "%N")
					end
					io.put_string ("%N")
				end
			end
		end

	cmd_class (a_name: STRING_32)
			-- Show class details
		local
			l_class: detachable KB_CLASS_INFO
		do
			l_class := db.find_class (a_name)
			if attached l_class as cls then
				io.put_string ("CLASS: " + cls.name.out + "%N")
				io.put_string ("========================================%N%N")
				io.put_string ("Library:  " + cls.library.out + "%N")
				if not cls.description.is_empty then
					io.put_string ("Description:%N  " + cls.description.out + "%N")
				end
				if not cls.file_path.is_empty then
					io.put_string ("File: " + cls.file_path.out + "%N")
				end
				if not cls.features.is_empty then
					io.put_string ("%NFEATURES (" + cls.features.count.out + "):%N")
					across cls.features as f loop
						io.put_string ("  " + f.kind.out + " " + f.signature.out + "%N")
						if not f.description.is_empty then
							io.put_string ("    -- " + truncate (f.description, 60).out + "%N")
						end
					end
				end
			else
				io.put_string ("Class not found: " + a_name.out + "%N%N")
				io.put_string ("Run 'kb ingest <path>' to index source files first.%N")
			end
		end

feature -- Other Commands

	cmd_ingest (a_path: STRING_32)
			-- Index source files
		local
			l_ingester: KB_INGESTER
			l_stats: TUPLE [files, classes, features, errors: INTEGER]
			l_dir: DIRECTORY
			l_lib_name: STRING_32
			l_src_path: STRING
		do
			create l_dir.make (a_path.out)
			if not l_dir.exists then
				io.put_string ("Path not found: " + a_path.out + "%N")
			else
				io.put_string ("Ingesting source files from: " + a_path.out + "%N")
				create l_ingester.make (db)

				-- Check if it's the base path with simple_* libraries
				if has_simple_libraries (a_path) then
					l_ingester.ingest_all_simple_libraries (a_path)
				else
					-- Treat as single library - look for src subdirectory
					l_lib_name := extract_library_name (a_path)
					l_src_path := a_path.out + "/src"
					create l_dir.make (l_src_path)
					if l_dir.exists then
						l_ingester.ingest_library (l_lib_name, l_src_path)
					else
						-- Maybe src is the path itself
						l_ingester.ingest_library (l_lib_name, a_path.out)
					end
				end

				l_stats := l_ingester.stats
				io.put_string ("%NDone. Indexed:%N")
				io.put_string ("  - " + l_stats.files.out + " files%N")
				io.put_string ("  - " + l_stats.classes.out + " classes%N")
				io.put_string ("  - " + l_stats.features.out + " features%N")
				if l_stats.errors > 0 then
					io.put_string ("  - " + l_stats.errors.out + " parse errors%N")
				end
			end
		end

	cmd_seed
			-- Seed database with known error codes and patterns
		local
			l_error_seeder: KB_ERROR_SEEDER
			l_pattern_seeder: KB_PATTERN_SEEDER
			l_stats: TUPLE [classes, features, examples, errors, patterns: INTEGER]
		do
			io.put_string ("Seeding database...%N")
			io.put_string ("  - Adding error codes...%N")
			create l_error_seeder.make (db)
			io.put_string ("  - Adding Eiffel patterns...%N")
			create l_pattern_seeder.make (db)
			l_stats := db.stats
			io.put_string ("%NDone. Database now contains:%N")
			io.put_string ("  - " + l_stats.errors.out + " error codes%N")
			io.put_string ("  - " + l_stats.patterns.out + " patterns%N")
			io.put_string ("  - " + l_stats.classes.out + " classes%N")
			io.put_string ("  - " + l_stats.features.out + " features%N")
			io.put_string ("  - " + l_stats.examples.out + " examples%N")
		end

	cmd_stats
			-- Show database statistics
		local
			l_stats: TUPLE [classes, features, examples, errors, patterns: INTEGER]
		do
			l_stats := db.stats
			io.put_string ("Knowledge Base Statistics%N")
			io.put_string ("=========================%N%N")
			io.put_string ("Error codes:  " + l_stats.errors.out + "%N")
			io.put_string ("Classes:      " + l_stats.classes.out + "%N")
			io.put_string ("Features:     " + l_stats.features.out + "%N")
			io.put_string ("Examples:     " + l_stats.examples.out + "%N")
			io.put_string ("Patterns:     " + l_stats.patterns.out + "%N")
		end

	show_help
			-- Show help message
		do
			io.put_string ("[
Eiffel Knowledge Base CLI
=========================

USAGE:
    kb <command> [arguments]

SEARCH COMMANDS:
    search <query>     Full-text search across all content
    class <name>       Show class details and features
    error <code>       Look up compiler error code
    pattern <name>     Show Eiffel design pattern

ADMIN COMMANDS:
    ingest <path>      Index source files from path
    rosetta <path>     Import Rosetta Code examples
    seed               Populate error codes + patterns
    stats              Show database statistics
    help               Show this help message

EXAMPLES:
    kb search json                 # Search for 'json'
    kb class SIMPLE_HTTP           # Show class details
    kb error VEVI                  # Look up VEVI error
    kb pattern singleton           # Show singleton pattern
    kb pattern list                # List all patterns
    kb ingest /d/prod              # Index all simple_* libraries
    kb rosetta /d/prod/simple_rosetta  # Import Rosetta solutions
    kb seed                        # Initialize database

NOTES:
    - Run 'kb seed' to populate error codes and patterns
    - Run 'kb ingest <path>' to index source files
    - Run 'kb rosetta <path>' to import Rosetta examples
    - Database is stored in kb.db

]")
		end

feature {NONE} -- Implementation

	db: KB_DATABASE
			-- Database connection

	default_db_path: STRING_32
			-- Default database path
		once
			Result := "kb.db"
		end

	truncate (a_text: STRING_32; a_max: INTEGER): STRING_32
			-- Truncate text to max length
		do
			if a_text.count <= a_max then
				Result := a_text
			else
				Result := a_text.head (a_max - 3)
				Result.append ("...")
			end
		end

	has_simple_libraries (a_path: READABLE_STRING_GENERAL): BOOLEAN
			-- Does path contain simple_* subdirectories?
		local
			l_dir, l_subdir: DIRECTORY
			l_subpath: PATH
		do
			create l_dir.make (a_path.out)
			if l_dir.exists then
				across l_dir.entries as entry loop
					if entry.name.out.starts_with ("simple_") then
						-- Must be a directory, not just a file starting with "simple_"
						create l_subpath.make_from_string (a_path.out)
						l_subpath := l_subpath.extended (entry.name.out)
						create l_subdir.make_with_path (l_subpath)
						if l_subdir.exists then
							Result := True
						end
					end
				end
			end
		end

	extract_library_name (a_path: READABLE_STRING_GENERAL): STRING_32
			-- Extract library name from path
		local
			l_parts: LIST [STRING]
			l_path: STRING
		do
			l_path := a_path.out
			l_parts := l_path.split ('/')
			if l_parts.is_empty then
				l_parts := l_path.split ('\')
			end
			if l_parts.is_empty then
				Result := "unknown"
			else
				Result := l_parts.last.to_string_32
			end
		end

end
