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
			elseif l_cmd.same_string ("example") then
				process_example_command (a_args)
			elseif l_cmd.same_string ("feature") then
				process_feature_command (a_args)
			elseif l_cmd.same_string ("library") or l_cmd.same_string ("lib") then
				process_library_command (a_args)
			elseif l_cmd.same_string ("ingest") then
				process_ingest_command (a_args)
			elseif l_cmd.same_string ("rosetta") then
				process_rosetta_command (a_args)
			elseif l_cmd.same_string ("seed") then
				cmd_seed
			elseif l_cmd.same_string ("stats") then
				cmd_stats
			elseif l_cmd.same_string ("clear") then
				process_clear_command (a_args)
			elseif l_cmd.same_string ("ai") then
				process_ai_command (a_args)
			elseif l_cmd.same_string ("ask") then
				process_ask_command (a_args)
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

feature -- AI Commands

	process_ai_command (a_args: ARGUMENTS_32)
			-- Handle 'ai' subcommand
		local
			l_subcmd: STRING_32
		do
			if a_args.argument_count < 2 then
				cmd_ai_status
			else
				l_subcmd := a_args.argument (2).as_lower
				if l_subcmd.same_string ("status") then
					cmd_ai_status
				elseif l_subcmd.same_string ("setup") then
					cmd_ai_setup
				elseif l_subcmd.same_string ("on") then
					cmd_ai_on
				elseif l_subcmd.same_string ("off") then
					cmd_ai_off
				elseif l_subcmd.same_string ("provider") then
					if a_args.argument_count >= 3 then
						cmd_ai_provider (a_args.argument (3))
					else
						io.put_string ("Usage: kb ai provider <name>%N")
						io.put_string ("Available: claude, openai, gemini, grok, ollama%N")
					end
				elseif l_subcmd.same_string ("prompt") then
					if a_args.argument_count >= 3 then
						cmd_ai_prompt (a_args.argument (3))
					else
						io.put_string ("Usage: kb ai prompt <query>%N")
					end
				else
					io.put_string ("Unknown AI command: " + l_subcmd.out + "%N")
					io.put_string ("Available: status, setup, on, off, provider, prompt%N")
				end
			end
		end

	cmd_ai_status
			-- Show AI configuration status
		do
			ensure_ai_config
			if attached ai_config as cfg then
				io.put_string (cfg.status_report)
			end
		end

	cmd_ai_setup
			-- Show setup instructions for AI providers
		do
			io.put_string ("SETTING UP AI ACCESS FOR SIMPLE_KB%N")
			io.put_string ("==================================%N%N")
			io.put_string ("simple_kb works great without AI (FTS5 search).%N")
			io.put_string ("Adding AI enables natural language queries and%N")
			io.put_string ("intelligent answer synthesis.%N%N")
			io.put_string ("OPTION 1: Local AI (Free, Private)%N")
			io.put_string ("---------------------------------%N")
			io.put_string ("Install Ollama: https://ollama.com/download%N%N")
			io.put_string ("Then run:%N")
			io.put_string ("  ollama pull llama3%N")
			io.put_string ("  ollama serve%N%N")
			io.put_string ("simple_kb will auto-detect Ollama at localhost:11434.%N%N")
			io.put_string ("OPTION 2: Claude API (Best Quality)%N")
			io.put_string ("-----------------------------------%N")
			io.put_string ("1. Get API key: https://console.anthropic.com/%N")
			io.put_string ("2. Set environment variable:%N")
			io.put_string ("   Windows: setx ANTHROPIC_API_KEY %"sk-ant-...%"%N")
			io.put_string ("   Linux:   export ANTHROPIC_API_KEY=%"sk-ant-...%"%N")
			io.put_string ("3. Restart terminal%N%N")
			io.put_string ("OPTION 3: OpenAI API%N")
			io.put_string ("--------------------%N")
			io.put_string ("1. Get API key: https://platform.openai.com/%N")
			io.put_string ("2. Set OPENAI_API_KEY environment variable%N%N")
			io.put_string ("OPTION 4: Google Gemini API%N")
			io.put_string ("---------------------------%N")
			io.put_string ("1. Get API key: https://aistudio.google.com/%N")
			io.put_string ("2. Set GOOGLE_AI_KEY environment variable%N%N")
			io.put_string ("OPTION 5: xAI Grok API%N")
			io.put_string ("----------------------%N")
			io.put_string ("1. Get API key: https://console.x.ai/%N")
			io.put_string ("2. Set XAI_API_KEY (or GROK_API_KEY) environment variable%N%N")
			io.put_string ("VERIFY SETUP%N")
			io.put_string ("------------%N")
			io.put_string ("Run: kb ai status%N")
		end

	cmd_ai_on
			-- Enable AI-assisted mode
		do
			ensure_ai_config
			if attached ai_config as cfg then
				if cfg.has_ai_configured then
					cfg.enable_ai
					io.put_string ("AI mode ENABLED%N")
					if attached cfg.active_provider as prov then
						io.put_string ("Using provider: " + prov.out + "%N")
					end
				else
					io.put_string ("No AI providers configured.%N")
					io.put_string ("Run 'kb ai setup' for instructions.%N")
				end
			end
		end

	cmd_ai_off
			-- Disable AI mode
		do
			ensure_ai_config
			if attached ai_config as cfg then
				cfg.disable_ai
			end
			io.put_string ("AI mode DISABLED (using FTS5 only)%N")
		end

	cmd_ai_provider (a_name: STRING_32)
			-- Switch active AI provider
		do
			ensure_ai_config
			if attached ai_config as cfg then
				if cfg.has_provider (a_name) then
					cfg.set_provider (a_name)
					io.put_string ("Switched to provider: " + a_name.out + "%N")
				else
					io.put_string ("Provider not available: " + a_name.out + "%N")
					io.put_string ("Configured providers: ")
					across cfg.available_providers as prov loop
						io.put_string (prov.out + " ")
					end
					io.put_string ("%N")
				end
			end
		end

	cmd_ai_prompt (a_query: STRING_32)
			-- Generate a prompt for manual AI use
		do
			io.put_string ("=== EIFFEL KNOWLEDGE BASE QUERY ===%N%N")
			io.put_string ("Copy this prompt to your AI:%N%N")
			io.put_string ("---%N")
			io.put_string ("I am working with Eiffel programming language.%N")
			io.put_string ("I need help with: " + a_query + "%N%N")
			io.put_string ("Context about Eiffel:%N")
			io.put_string ("- Uses Design by Contract (require/ensure/invariant)%N")
			io.put_string ("- Void-safe (detachable/attached types)%N")
			io.put_string ("- SCOOP for concurrency%N")
			io.put_string ("- Libraries use simple_* naming convention%N%N")
			io.put_string ("Please provide:%N")
			io.put_string ("1. Direct answer with Eiffel code examples%N")
			io.put_string ("2. Relevant class/feature names to look up%N")
			io.put_string ("3. Any library dependencies needed%N")
			io.put_string ("---%N")
		end

	ensure_ai_config
			-- Ensure AI config is initialized
		do
			if ai_config = Void then
				create ai_config.make
			end
		end

	process_ask_command (a_args: ARGUMENTS_32)
			-- Handle 'ask' subcommand for AI-powered queries
		local
			l_query: STRING_32
			i: INTEGER
		do
			if a_args.argument_count < 2 then
				io.put_string ("Usage: kb ask <natural language question>%N")
				io.put_string ("Example: kb ask What is the best library for JSON?%N")
			else
				-- Build query from all remaining args
				create l_query.make (100)
				from i := 2 until i > a_args.argument_count loop
					if i > 2 then
						l_query.append_character (' ')
					end
					l_query.append (a_args.argument (i))
					i := i + 1
				end
				cmd_ask (l_query)
			end
		end

	cmd_ask (a_query: STRING_32)
			-- Process AI-powered natural language query
		local
			l_router: KB_AI_ROUTER
			l_result: KB_QUERY_RESULT
		do
			ensure_ai_config
			if attached ai_config as cfg then
				create l_router.make (db, cfg)
				
				if l_router.is_ai_available then
					io.put_string ("Querying with AI (")
					if attached cfg.active_provider as prov then
						io.put_string (prov.out)
					end
					io.put_string (")...%N%N")
				else
					io.put_string ("AI not available, using keyword search...%N%N")
				end
				
				l_result := l_router.process_query (a_query)
				io.put_string (l_result.formatted)
			else
				io.put_string ("Could not initialize AI configuration.%N")
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
			-- List all error codes with interactive selection
		local
			l_errors: ARRAYED_LIST [KB_ERROR_INFO]
			i: INTEGER
			l_input: STRING
			l_choice: INTEGER
		do
			l_errors := db.all_errors
			if l_errors.is_empty then
				io.put_string ("No error codes in database.%N")
				io.put_string ("Run 'kb seed' to populate with known error codes.%N")
			else
				io.put_string ("Known Error Codes (" + l_errors.count.out + "):%N")
				io.put_string ("================================%N%N")
				from i := 1 until i > l_errors.count loop
					io.put_string ("#" + i.out + " " + l_errors[i].code.out + ": " + l_errors[i].meaning.out + "%N")
					i := i + 1
				end
				
				io.put_string ("%NSelect (1-" + l_errors.count.out + ") or Enter to skip: ")
				io.read_line
				l_input := io.last_string.twin
				l_input.left_adjust
				l_input.right_adjust
				
				if not l_input.is_empty and then l_input.is_integer then
					l_choice := l_input.to_integer
					if l_choice >= 1 and l_choice <= l_errors.count then
						io.put_string ("%N")
						io.put_string (l_errors[l_choice].formatted.out)
						io.put_string ("%N")
					end
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
			-- List all patterns with interactive selection
		local
			l_patterns: ARRAYED_LIST [KB_PATTERN]
			i: INTEGER
			l_input: STRING
			l_choice: INTEGER
		do
			l_patterns := db.all_patterns
			if l_patterns.is_empty then
				io.put_string ("No patterns in database.%N")
				io.put_string ("Run 'kb seed' to populate with Eiffel patterns.%N")
			else
				io.put_string ("Eiffel Patterns (" + l_patterns.count.out + "):%N")
				io.put_string ("========================%N%N")
				from i := 1 until i > l_patterns.count loop
					io.put_string ("#" + i.out + " " + l_patterns[i].brief.out + "%N")
					i := i + 1
				end
				
				io.put_string ("%NSelect (1-" + l_patterns.count.out + ") or Enter to skip: ")
				io.read_line
				l_input := io.last_string.twin
				l_input.left_adjust
				l_input.right_adjust
				
				if not l_input.is_empty and then l_input.is_integer then
					l_choice := l_input.to_integer
					if l_choice >= 1 and l_choice <= l_patterns.count then
						io.put_string ("%N")
						io.put_string (l_patterns[l_choice].formatted.out)
						io.put_string ("%N")
					end
				end
			end
		end

feature -- Example Commands

	process_example_command (a_args: ARGUMENTS_32)
			-- Handle 'example' subcommand
		local
			l_title: STRING_32
			i: INTEGER
		do
			if a_args.argument_count < 2 then
				io.put_string ("Usage: kb example <title>%N")
				io.put_string ("Example: kb example %"Sieve of Eratosthenes%"%N")
			else
				-- Combine all args after 'example' as the title
				create l_title.make_empty
				from i := 2 until i > a_args.argument_count loop
					if i > 2 then l_title.append (" ") end
					l_title.append (a_args.argument (i))
					i := i + 1
				end
				cmd_example (l_title)
			end
		end

	cmd_example (a_title: STRING_32)
			-- Show full example code
		local
			l_example: detachable KB_EXAMPLE
		do
			l_example := db.get_example (a_title)
			if attached l_example as ex then
				io.put_string (ex.formatted.out)
				io.put_string ("%N")
			else
				-- Try partial match
				l_example := db.find_example_like (a_title)
				if attached l_example as ex then
					io.put_string (ex.formatted.out)
					io.put_string ("%N")
				else
					io.put_string ("Example not found: " + a_title.out + "%N%N")
					io.put_string ("Use 'kb search <keyword>' to find examples.%N")
				end
			end
		end

feature -- Feature Commands

	process_feature_command (a_args: ARGUMENTS_32)
			-- Handle 'feature' subcommand
			-- Syntax: kb feature CLASS.name or kb feature CLASS name
		local
			l_arg, l_class_name, l_feature_name: STRING_32
			l_dot_pos: INTEGER
		do
			if a_args.argument_count < 2 then
				io.put_string ("Usage: kb feature CLASS.feature_name%N")
				io.put_string ("       kb feature CLASS feature_name%N")
				io.put_string ("Example: kb feature SIMPLE_HTTP.get%N")
			else
				l_arg := a_args.argument (2)
				l_dot_pos := l_arg.index_of ('.', 1)
				if l_dot_pos > 0 then
					-- Format: CLASS.feature
					l_class_name := l_arg.head (l_dot_pos - 1).as_upper
					l_feature_name := l_arg.tail (l_arg.count - l_dot_pos)
					cmd_feature (l_class_name, l_feature_name)
				elseif a_args.argument_count >= 3 then
					-- Format: CLASS feature
					l_class_name := l_arg.as_upper
					l_feature_name := a_args.argument (3)
					cmd_feature (l_class_name, l_feature_name)
				else
					-- Just class name - show features interactively
					l_class_name := l_arg.as_upper
					cmd_class_features (l_class_name)
				end
			end
		end

	cmd_feature (a_class_name, a_feature_name: STRING_32)
			-- Show feature details with contracts
		local
			l_feature: detachable KB_FEATURE_INFO
			l_matches: ARRAYED_LIST [KB_FEATURE_INFO]
			i: INTEGER
			l_input: STRING
			l_choice: INTEGER
		do
			l_feature := db.find_feature (a_class_name, a_feature_name)
			if attached l_feature as feat then
				show_feature_details (a_class_name, feat)
			else
				-- Try partial match
				l_matches := db.search_features (a_class_name, a_feature_name, 20)
				if l_matches.is_empty then
					io.put_string ("Feature not found: " + a_class_name.out + "." + a_feature_name.out + "%N%N")
					io.put_string ("Try 'kb class " + a_class_name.out + "' to see all features.%N")
				else
					io.put_string ("Features matching '" + a_feature_name.out + "' in " + a_class_name.out + ":%N")
					io.put_string ("========================================%N%N")
					from i := 1 until i > l_matches.count loop
						io.put_string ("#" + i.out + " " + l_matches[i].name.out + " " + l_matches[i].signature.out + "%N")
						i := i + 1
					end
					
					io.put_string ("%NSelect (1-" + l_matches.count.out + ") or Enter to skip: ")
					io.read_line
					l_input := io.last_string.twin
					l_input.left_adjust
					l_input.right_adjust
					
					if not l_input.is_empty and then l_input.is_integer then
						l_choice := l_input.to_integer
						if l_choice >= 1 and l_choice <= l_matches.count then
							io.put_string ("%N")
							show_feature_details (a_class_name, l_matches[l_choice])
						end
					end
				end
			end
		end

	cmd_class_features (a_class_name: STRING_32)
			-- Show class features with interactive selection
		local
			l_class: detachable KB_CLASS_INFO
			i: INTEGER
			l_input: STRING
			l_choice: INTEGER
		do
			l_class := db.find_class (a_class_name)
			if attached l_class as cls then
				if cls.features.is_empty then
					io.put_string ("No features found for class: " + a_class_name.out + "%N")
				else
					io.put_string ("Features in " + cls.name.out + " (" + cls.features.count.out + "):%N")
					io.put_string ("========================================%N%N")
					from i := 1 until i > cls.features.count loop
						io.put_string ("#" + i.out + " " + cls.features[i].kind.out + " " + cls.features[i].name.out)
						if not cls.features[i].signature.is_empty then
							io.put_string (" " + cls.features[i].signature.out)
						end
						io.put_string ("%N")
						i := i + 1
					end
					
					io.put_string ("%NSelect (1-" + cls.features.count.out + ") or Enter to skip: ")
					io.read_line
					l_input := io.last_string.twin
					l_input.left_adjust
					l_input.right_adjust
					
					if not l_input.is_empty and then l_input.is_integer then
						l_choice := l_input.to_integer
						if l_choice >= 1 and l_choice <= cls.features.count then
							io.put_string ("%N")
							show_feature_details (cls.name, cls.features[l_choice])
						end
					end
				end
			else
				io.put_string ("Class not found: " + a_class_name.out + "%N")
			end
		end

	show_feature_details (a_class_name: STRING_32; a_feature: KB_FEATURE_INFO)
			-- Display full feature details with contracts
		local
			l_modifiers: STRING
		do
			-- Build modifier string
			create l_modifiers.make_empty
			if a_feature.is_frozen then l_modifiers.append ("frozen ") end
			if a_feature.is_deferred then l_modifiers.append ("deferred ") end
			if a_feature.is_once then l_modifiers.append ("once ") end

			io.put_string ("FEATURE: " + a_class_name.out + "." + a_feature.name.out + "%N")
			io.put_string ("========================================%N%N")
			io.put_string ("Kind: " + l_modifiers + a_feature.kind.out + "%N")
			io.put_string ("Signature: " + a_feature.name.out)
			if not a_feature.signature.is_empty then
				io.put_string (" " + a_feature.signature.out)
			end
			io.put_string ("%N")
			if not a_feature.description.is_empty then
				io.put_string ("%NDescription:%N  " + a_feature.description.out + "%N")
			end
			if not a_feature.preconditions.is_empty then
				io.put_string ("%NREQUIRE (Preconditions):%N")
				across a_feature.preconditions as pre loop
					io.put_string ("  " + pre.tag.out + ": " + pre.expression.out + "%N")
				end
			end
			if not a_feature.postconditions.is_empty then
				io.put_string ("%NENSURE (Postconditions):%N")
				across a_feature.postconditions as post loop
					io.put_string ("  " + post.tag.out + ": " + post.expression.out + "%N")
				end
			end
			io.put_string ("%N")
		end

feature -- Library Commands

	process_library_command (a_args: ARGUMENTS_32)
			-- Handle 'library' subcommand
		local
			l_name: STRING_32
		do
			if a_args.argument_count < 2 then
				cmd_library_list
			else
				l_name := a_args.argument (2).as_lower
				if l_name.same_string ("list") then
					cmd_library_list
				else
					cmd_library (l_name)
				end
			end
		end

	cmd_library (a_name: STRING_32)
			-- Show library details
		local
			l_lib: detachable KB_LIBRARY_INFO
			l_matches: ARRAYED_LIST [KB_LIBRARY_INFO]
			i: INTEGER
			l_input: STRING
			l_choice: INTEGER
		do
			l_lib := db.get_library (a_name)
			if attached l_lib as lib then
				io.put_string (lib.formatted.out)
				io.put_string ("%N")
			else
				-- Try partial match
				l_matches := db.search_libraries (a_name, 20)
				if l_matches.is_empty then
					io.put_string ("Library not found: " + a_name.out + "%N%N")
					io.put_string ("Run 'kb ingest <path>' to index libraries first.%N")
					io.put_string ("Or use 'kb library list' to see all libraries.%N")
				else
					io.put_string ("Libraries matching '" + a_name.out + "' (" + l_matches.count.out + "):%N")
					io.put_string ("========================================%N%N")
					from i := 1 until i > l_matches.count loop
						io.put_string ("#" + i.out + " " + l_matches[i].name.out)
						if not l_matches[i].description.is_empty then
							io.put_string (" - " + truncate (l_matches[i].description, 50).out)
						end
						io.put_string ("%N")
						i := i + 1
					end
					
					io.put_string ("%NSelect (1-" + l_matches.count.out + ") or Enter to skip: ")
					io.read_line
					l_input := io.last_string.twin
					l_input.left_adjust
					l_input.right_adjust
					
					if not l_input.is_empty and then l_input.is_integer then
						l_choice := l_input.to_integer
						if l_choice >= 1 and l_choice <= l_matches.count then
							io.put_string ("%N")
							io.put_string (l_matches[l_choice].formatted.out)
							io.put_string ("%N")
						end
					end
				end
			end
		end

	cmd_library_list
			-- List all libraries with interactive selection
		local
			l_libs: ARRAYED_LIST [KB_LIBRARY_INFO]
			i: INTEGER
			l_input: STRING
			l_choice: INTEGER
		do
			l_libs := db.all_libraries
			if l_libs.is_empty then
				io.put_string ("No libraries in database.%N")
				io.put_string ("Run 'kb ingest <path>' to index libraries.%N")
			else
				io.put_string ("Libraries (" + l_libs.count.out + "):%N")
				io.put_string ("========================%N%N")
				from i := 1 until i > l_libs.count loop
					io.put_string ("#" + i.out + " " + l_libs[i].name.out)
					if not l_libs[i].description.is_empty then
						io.put_string (" - " + truncate (l_libs[i].description, 50).out)
					end
					io.put_string ("%N")
					i := i + 1
				end
				
				io.put_string ("%NSelect (1-" + l_libs.count.out + ") or Enter to skip: ")
				io.read_line
				l_input := io.last_string.twin
				l_input.left_adjust
				l_input.right_adjust
				
				if not l_input.is_empty and then l_input.is_integer then
					l_choice := l_input.to_integer
					if l_choice >= 1 and l_choice <= l_libs.count then
						io.put_string ("%N")
						io.put_string (l_libs[l_choice].formatted.out)
						io.put_string ("%N")
					end
				end
			end
		end

feature -- Search Commands

	cmd_search (a_query: STRING_32)
			-- Full-text search with interactive selection
		local
			l_results: ARRAYED_LIST [KB_RESULT]
			i: INTEGER
			l_input: STRING
			l_choice: INTEGER
			l_result: KB_RESULT
		do
			l_results := db.search (a_query, 20)
			if l_results.is_empty then
				io.put_string ("No results found for: " + a_query.out + "%N%N")
				io.put_string ("Try different keywords or run 'kb seed' and 'kb ingest' first.%N")
			else
				io.put_string ("Search Results for '" + a_query.out + "' (" + l_results.count.out + "):%N")
				io.put_string ("============================================%N%N")
				from i := 1 until i > l_results.count loop
					l_result := l_results [i]
					io.put_string ("#" + i.out + " " + l_result.type_label.out + " " + l_result.title.out + "%N")
					if not l_result.snippet.is_empty then
						io.put_string ("   " + truncate (l_result.snippet, 75).out + "%N")
					end
					io.put_string ("%N")
					i := i + 1
				end
				
				-- Prompt for selection
				io.put_string ("Select (1-" + l_results.count.out + ") or Enter to skip: ")
				io.read_line
				l_input := io.last_string.twin
				l_input.left_adjust
				l_input.right_adjust
				
				if not l_input.is_empty and then l_input.is_integer then
					l_choice := l_input.to_integer
					if l_choice >= 1 and l_choice <= l_results.count then
						l_result := l_results [l_choice]
						io.put_string ("%N")
						show_full_result (l_result)
					end
				end
			end
		end

	show_full_result (a_result: KB_RESULT)
			-- Show full content based on result type
		do
			if a_result.content_type.same_string ("example") then
				cmd_example (a_result.title)
			elseif a_result.content_type.same_string ("class") then
				cmd_class (a_result.title)
			elseif a_result.content_type.same_string ("pattern") then
				cmd_pattern_lookup (a_result.title)
			elseif a_result.content_type.same_string ("error") then
				cmd_error_lookup (a_result.title)
			else
				io.put_string ("Content type '" + a_result.content_type.out + "' not viewable.%N")
			end
		end

	cmd_class (a_name: STRING_32)
			-- Show class details, or search if not exact match
		local
			l_class: detachable KB_CLASS_INFO
			l_matches: ARRAYED_LIST [KB_CLASS_INFO]
			i: INTEGER
			l_input: STRING
			l_choice: INTEGER
		do
			l_class := db.find_class (a_name)
			if attached l_class as cls then
				show_class_details (cls)
			else
				-- Try partial match
				l_matches := db.search_classes (a_name, 20)
				if l_matches.is_empty then
					io.put_string ("Class not found: " + a_name.out + "%N%N")
					io.put_string ("Run 'kb ingest <path>' to index source files first.%N")
				else
					io.put_string ("Classes matching '" + a_name.out + "' (" + l_matches.count.out + "):%N")
					io.put_string ("========================================%N%N")
					from i := 1 until i > l_matches.count loop
						io.put_string ("#" + i.out + " " + l_matches[i].name.out + " (" + l_matches[i].library.out + ")%N")
						i := i + 1
					end
					
					io.put_string ("%NSelect (1-" + l_matches.count.out + ") or Enter to skip: ")
					io.read_line
					l_input := io.last_string.twin
					l_input.left_adjust
					l_input.right_adjust
					
					if not l_input.is_empty and then l_input.is_integer then
						l_choice := l_input.to_integer
						if l_choice >= 1 and l_choice <= l_matches.count then
							io.put_string ("%N")
							show_class_details (l_matches[l_choice])
						end
					end
				end
			end
		end

	show_class_details (a_class: KB_CLASS_INFO)
			-- Display full class details with interactive feature selection
		local
			i: INTEGER
			l_input: STRING
			l_choice: INTEGER
			l_modifiers: STRING
			l_ancestors, l_descendants: ARRAYED_LIST [STRING_32]
		do
			-- Build modifier string
			create l_modifiers.make_empty
			if a_class.is_deferred then l_modifiers.append ("deferred ") end
			if a_class.is_expanded then l_modifiers.append ("expanded ") end
			if a_class.is_frozen then l_modifiers.append ("frozen ") end

			io.put_string ("CLASS: " + l_modifiers + a_class.name.out + "%N")
			io.put_string ("========================================%N%N")
			io.put_string ("Library:  " + a_class.library.out + "%N")
			if not a_class.description.is_empty then
				io.put_string ("Description:%N  " + a_class.description.out + "%N")
			end
			if not a_class.file_path.is_empty then
				io.put_string ("File: " + a_class.file_path.out + "%N")
			end

			-- Show parents
			if not a_class.parents.is_empty then
				io.put_string ("%NPARENTS: ")
				from i := 1 until i > a_class.parents.count loop
					if i > 1 then io.put_string (", ") end
					io.put_string (a_class.parents[i].out)
					i := i + 1
				end
				io.put_string ("%N")
			end

			-- Show ancestors (full inheritance chain)
			l_ancestors := db.get_ancestors (a_class.name)
			if not l_ancestors.is_empty then
				io.put_string ("ANCESTORS: ")
				from i := 1 until i > l_ancestors.count loop
					if i > 1 then io.put_string (", ") end
					io.put_string (l_ancestors[i].out)
					i := i + 1
				end
				io.put_string ("%N")
			end

			-- Show descendants
			l_descendants := db.get_descendants (a_class.name)
			if not l_descendants.is_empty then
				io.put_string ("DESCENDANTS: ")
				from i := 1 until i > l_descendants.count.min (10) loop
					if i > 1 then io.put_string (", ") end
					io.put_string (l_descendants[i].out)
					i := i + 1
				end
				if l_descendants.count > 10 then
					io.put_string (" ... (+" + (l_descendants.count - 10).out + " more)")
				end
				io.put_string ("%N")
			end
			if not a_class.features.is_empty then
				io.put_string ("%NFEATURES (" + a_class.features.count.out + "):%N")
				from i := 1 until i > a_class.features.count loop
					io.put_string ("  #" + i.out + " " + a_class.features[i].kind.out + " " + a_class.features[i].name.out)
					if not a_class.features[i].signature.is_empty then
						io.put_string (" " + a_class.features[i].signature.out)
					end
					io.put_string ("%N")
					i := i + 1
				end
				
				io.put_string ("%NSelect feature (1-" + a_class.features.count.out + ") or Enter to skip: ")
				io.read_line
				l_input := io.last_string.twin
				l_input.left_adjust
				l_input.right_adjust
				
				if not l_input.is_empty and then l_input.is_integer then
					l_choice := l_input.to_integer
					if l_choice >= 1 and l_choice <= a_class.features.count then
						io.put_string ("%N")
						show_feature_details (a_class.name, a_class.features[l_choice])
					end
				end
			end
		end

feature -- Other Commands

	cmd_ingest (a_path: STRING_32)
			-- Index source files
		local
			l_ingester: KB_INGESTER
			l_stats: TUPLE [files, classes, features, errors, libraries: INTEGER]
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
					-- Use batch mode (progress format, no verbose)
					l_ingester.ingest_all_simple_libraries (a_path)
				elseif has_ecf_subdirectories (a_path) then
					-- Directory contains subdirectories with ECF files (e.g. EiffelStudio library)
					-- Use batch mode (progress format, no verbose)
					l_ingester.ingest_directory_recursive (a_path)
				else
					-- Single library - use verbose mode
					l_ingester.set_verbose (True)
					l_lib_name := extract_library_name (a_path)
					-- Index ECF file
					l_ingester.ingest_ecf (l_lib_name, a_path.out)
					-- Index source files
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
				io.put_string ("  - " + l_stats.libraries.out + " libraries%N")
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
			l_stats: TUPLE [classes, features, examples, errors, patterns, libraries: INTEGER]
		do
			l_stats := db.stats
			io.put_string ("Knowledge Base Statistics%N")
			io.put_string ("=========================%N%N")
			io.put_string ("Libraries:    " + l_stats.libraries.out + "%N")
			io.put_string ("Classes:      " + l_stats.classes.out + "%N")
			io.put_string ("Features:     " + l_stats.features.out + "%N")
			io.put_string ("Examples:     " + l_stats.examples.out + "%N")
			io.put_string ("Error codes:  " + l_stats.errors.out + "%N")
			io.put_string ("Patterns:     " + l_stats.patterns.out + "%N")
		end

feature -- Clear Commands

	process_clear_command (a_args: ARGUMENTS_32)
			-- Handle 'clear' subcommand
		local
			l_target: STRING_32
		do
			if a_args.argument_count < 2 then
				show_clear_help
			else
				l_target := a_args.argument (2).as_lower
				if l_target.same_string ("all") then
					cmd_clear_all
				elseif l_target.same_string ("classes") then
					cmd_clear_classes
				elseif l_target.same_string ("examples") then
					cmd_clear_examples
				elseif l_target.same_string ("errors") then
					cmd_clear_errors
				elseif l_target.same_string ("patterns") then
					cmd_clear_patterns
				elseif l_target.same_string ("library") then
					if a_args.argument_count >= 3 then
						cmd_clear_library (a_args.argument (3))
					else
						io.put_string ("Usage: kb clear library <name>%N")
						io.put_string ("Example: kb clear library simple_json%N")
					end
				elseif l_target.same_string ("faqs") or l_target.same_string ("faq") then
					cmd_clear_faqs
				elseif l_target.same_string ("help") then
					show_clear_help
				else
					io.put_string ("Unknown clear target: " + l_target.out + "%N")
					show_clear_help
				end
			end
		end

	show_clear_help
			-- Show clear command help
		do
			io.put_string ("[
Clear Commands:
    kb clear all            Clear ALL data
    kb clear classes        Clear all indexed classes and features
    kb clear library <name> Clear specific library (for re-ingesting)
    kb clear examples       Clear Rosetta Code examples
    kb clear errors         Clear error codes
    kb clear patterns       Clear design patterns
    kb clear help           Show this help
]")
		end

	cmd_clear_all
			-- Clear all data with confirmation
		do
			io.put_string ("WARNING: This will delete ALL data from the knowledge base:%N")
			io.put_string ("  - " + db.stats.classes.out + " classes%N")
			io.put_string ("  - " + db.stats.features.out + " features%N")
			io.put_string ("  - " + db.stats.examples.out + " examples%N")
			io.put_string ("  - " + db.stats.errors.out + " errors%N")
			io.put_string ("  - " + db.stats.patterns.out + " patterns%N%N")
			if confirm ("Are you sure you want to delete ALL data?") then
				db.clear_all
				io.put_string ("All data cleared.%N")
			else
				io.put_string ("Cancelled.%N")
			end
		end

	cmd_clear_classes
			-- Clear classes and features
		do
			io.put_string ("This will delete:%N")
			io.put_string ("  - " + db.stats.classes.out + " classes%N")
			io.put_string ("  - " + db.stats.features.out + " features%N%N")
			if confirm ("Are you sure?") then
				db.clear_classes
				io.put_string ("Classes and features cleared.%N")
			else
				io.put_string ("Cancelled.%N")
			end
		end

	cmd_clear_examples
			-- Clear examples
		do
			io.put_string ("This will delete " + db.stats.examples.out + " examples.%N%N")
			if confirm ("Are you sure?") then
				db.clear_examples
				io.put_string ("Examples cleared.%N")
			else
				io.put_string ("Cancelled.%N")
			end
		end

	cmd_clear_errors
			-- Clear error codes
		do
			io.put_string ("This will delete " + db.stats.errors.out + " error codes.%N%N")
			if confirm ("Are you sure?") then
				db.clear_errors
				io.put_string ("Error codes cleared.%N")
			else
				io.put_string ("Cancelled.%N")
			end
		end

	cmd_clear_patterns
			-- Clear patterns
		do
			io.put_string ("This will delete " + db.stats.patterns.out + " patterns.%N%N")
			if confirm ("Are you sure?") then
				db.clear_patterns
				io.put_string ("Patterns cleared.%N")
			else
				io.put_string ("Cancelled.%N")
			end
		end

	cmd_clear_faqs
			-- Clear FAQ cache
		do
			io.put_string ("Clearing FAQ cache...%N")
			db.db.execute ("DELETE FROM faq_search")
			db.db.execute ("DELETE FROM faq_tags")
			db.db.execute ("DELETE FROM faqs")
			io.put_string ("FAQ cache cleared. Fresh answers will be generated from KB.%N")
		end

	cmd_clear_library (a_name: STRING_32)
			-- Clear a specific library's classes and features
		local
			l_count: INTEGER
		do
			l_count := db.library_class_count (a_name)
			if l_count = 0 then
				io.put_string ("No classes found for library: " + a_name.out + "%N")
			else
				io.put_string ("This will delete " + l_count.out + " classes from library '" + a_name.out + "'.%N%N")
				if confirm ("Are you sure?") then
					db.clear_library (a_name)
					io.put_string ("Library '" + a_name.out + "' cleared.%N")
				else
					io.put_string ("Cancelled.%N")
				end
			end
		end

	confirm (a_prompt: STRING): BOOLEAN
			-- Ask user for confirmation, return True if 'y' or 'yes'
		local
			l_input: STRING
		do
			io.put_string (a_prompt + " (y/n): ")
			io.read_line
			l_input := io.last_string.twin
			l_input.left_adjust
			l_input.right_adjust
			l_input.to_lower
			Result := l_input.same_string ("y") or l_input.same_string ("yes")
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
    ask <question>     AI-powered natural language query
    search <query>     Full-text search across all content
    class <name>       Show class details and features
    feature <class>.<name>  Show feature with contracts
    error <code>       Look up compiler error code
    pattern <name>     Show Eiffel design pattern
    example <title>    Show full Rosetta Code example

AI COMMANDS:
    ai                 Show AI configuration status
    ai status          Show AI provider status
    ai setup           Show setup instructions
    ai on              Enable AI-assisted mode
    ai off             Disable AI (use direct search)
    ai provider <name> Switch AI provider

ADMIN COMMANDS:
    ingest <path>      Index source files from path
    rosetta <path>     Import Rosetta Code examples
    seed               Populate error codes + patterns
    stats              Show database statistics
    clear <target>     Clear data (all|classes|examples|errors|patterns)
    help               Show this help message

EXAMPLES:
    kb search json                 # Search for 'json'
    kb class SIMPLE_HTTP           # Show class details
    kb error VEVI                  # Look up VEVI error
    kb pattern singleton           # Show singleton pattern
    kb example "Sieve of Eratosthenes"  # Show full example
    kb feature SIMPLE_HTTP.get         # Show feature with contracts
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

feature -- Interactive Mode

	run_interactive_mode
			-- Run interactive REPL loop
		local
			l_input: STRING
			l_done: BOOLEAN
		do
			io.put_string ("Eiffel Knowledge Base - Interactive Mode%N")
			io.put_string ("========================================%N")
			io.put_string ("Type 'help' for commands, 'quit' to exit%N%N")
			
			from l_done := False until l_done loop
				io.put_string ("kb> ")
				io.read_line
				l_input := io.last_string.twin
				l_input.left_adjust
				l_input.right_adjust
				
				if l_input.is_empty then
					-- Skip empty input
				elseif is_quit_command (l_input) then
					l_done := True
					io.put_string ("Goodbye!%N")
				else
					dispatch_interactive_command (l_input)
				end
			end
		end

	dispatch_interactive_command (a_input: STRING)
			-- Parse and dispatch interactive command
		local
			l_parts: LIST [STRING]
			l_cmd, l_arg: STRING_32
		do
			l_parts := a_input.split (' ')
			if l_parts.is_empty then
				-- Nothing to do
			else
				l_cmd := l_parts.first.as_lower.to_string_32
				
				-- Get rest of input as argument (everything after first space)
				if a_input.has (' ') then
					l_arg := a_input.substring (a_input.index_of (' ', 1) + 1, a_input.count).to_string_32
					l_arg.left_adjust
				else
					create l_arg.make_empty
				end
				
				-- Command dispatch with shortcuts
				if l_cmd.same_string ("s") or l_cmd.same_string ("search") then
					if l_arg.is_empty then
						io.put_string ("Usage: search <query>%N")
					else
						cmd_search (l_arg)
					end
				elseif l_cmd.same_string ("c") or l_cmd.same_string ("class") then
					if l_arg.is_empty then
						io.put_string ("Usage: class <name>%N")
					else
						cmd_class (l_arg.as_upper)
					end
				elseif l_cmd.same_string ("f") or l_cmd.same_string ("feature") then
					if l_arg.is_empty then
						io.put_string ("Usage: feature CLASS.name%N")
					else
						process_feature_arg (l_arg)
					end
				elseif l_cmd.same_string ("e") or l_cmd.same_string ("error") then
					if l_arg.is_empty or l_arg.same_string ("list") then
						cmd_error_list
					else
						cmd_error_lookup (l_arg.as_upper)
					end
				elseif l_cmd.same_string ("p") or l_cmd.same_string ("pattern") then
					if l_arg.is_empty or l_arg.same_string ("list") then
						cmd_pattern_list
					else
						cmd_pattern_lookup (l_arg)
					end
				elseif l_cmd.same_string ("ex") or l_cmd.same_string ("example") then
					if l_arg.is_empty then
						io.put_string ("Usage: example <title>%N")
					else
						cmd_example (l_arg)
					end
				elseif l_cmd.same_string ("l") or l_cmd.same_string ("lib") or l_cmd.same_string ("library") then
					if l_arg.is_empty or l_arg.same_string ("list") then
						cmd_library_list
					else
						cmd_library (l_arg)
					end
				elseif l_cmd.same_string ("stats") then
					cmd_stats
				elseif l_cmd.same_string ("seed") then
					cmd_seed
				elseif l_cmd.same_string ("ingest") then
					if l_arg.is_empty then
						io.put_string ("Usage: ingest <path>%N")
					else
						cmd_ingest (l_arg)
					end
				elseif l_cmd.same_string ("rosetta") then
					if l_arg.is_empty then
						io.put_string ("Usage: rosetta <path>%N")
					else
						cmd_rosetta (l_arg)
					end
				elseif l_cmd.same_string ("clear") then
					if l_arg.is_empty then
						show_clear_help
					elseif l_arg.same_string ("all") then
						cmd_clear_all
					elseif l_arg.same_string ("classes") then
						cmd_clear_classes
					elseif l_arg.same_string ("examples") then
						cmd_clear_examples
					elseif l_arg.same_string ("errors") then
						cmd_clear_errors
					elseif l_arg.same_string ("patterns") then
						cmd_clear_patterns
					else
						show_clear_help
					end
				elseif l_cmd.same_string ("help") or l_cmd.same_string ("h") or l_cmd.same_string ("?") then
					show_interactive_help
				else
					io.put_string ("Unknown command: " + l_cmd.out + ". Type 'help' for commands.%N")
				end
			end
		end

	process_feature_arg (a_arg: STRING_32)
			-- Parse feature argument (CLASS.feature or CLASS feature)
		local
			l_dot_pos: INTEGER
			l_class_name, l_feature_name: STRING_32
		do
			l_dot_pos := a_arg.index_of ('.', 1)
			if l_dot_pos > 0 then
				l_class_name := a_arg.head (l_dot_pos - 1).as_upper
				l_feature_name := a_arg.tail (a_arg.count - l_dot_pos)
				cmd_feature (l_class_name, l_feature_name)
			elseif a_arg.has (' ') then
				l_class_name := a_arg.split (' ').first.as_upper.to_string_32
				l_feature_name := a_arg.substring (a_arg.index_of (' ', 1) + 1, a_arg.count).to_string_32
				cmd_feature (l_class_name, l_feature_name)
			else
				-- Just class name - show features
				cmd_class_features (a_arg.as_upper)
			end
		end

	is_quit_command (a_input: STRING): BOOLEAN
			-- Is this a quit command?
		local
			l_lower: STRING
		do
			l_lower := a_input.as_lower
			Result := l_lower.same_string ("quit") or l_lower.same_string ("exit")
				or l_lower.same_string ("bye") or l_lower.same_string ("q")
		end

	show_interactive_help
			-- Show interactive mode help with shortcuts
		do
			io.put_string ("[
Interactive Mode Commands
=========================

SHORTCUTS:
    s <query>      Search (alias: search)
    c <name>       Class details (alias: class)
    f <class.name> Feature details (alias: feature)
    l <name>       Library details (alias: lib, library)
    e <code>       Error lookup (alias: error)
    p <name>       Pattern lookup (alias: pattern)
    ex <title>     Example code (alias: example)
    h or ?         This help (alias: help)
    q              Quit (alias: quit, exit, bye)

ADMIN:
    stats          Show database statistics
    seed           Populate error codes + patterns
    ingest <path>  Index source files
    rosetta <path> Import Rosetta examples
    clear <target> Clear data

EXAMPLES:
    s json         # Search for 'json'
    c SIMPLE_HTTP  # Show class
    f SIMPLE_HTTP.get  # Show feature
    l simple_json  # Show library
    e VEVI         # Look up error
    p singleton    # Show pattern

]")
		end

feature {NONE} -- Implementation

	db: KB_DATABASE
			-- Database connection

	ai_config: detachable KB_AI_CONFIG
			-- AI provider configuration (lazy initialized)

	default_db_path: STRING_32
			-- Default database path (colocated with executable)
		local
			l_path: PATH
			l_args: ARGUMENTS_32
		once
			create l_args
			if attached l_args.command_name as cmd then
				create l_path.make_from_string (cmd)
				if attached l_path.parent as parent_dir then
					l_path := parent_dir.extended ("kb.db")
					Result := l_path.out
				else
					Result := "kb.db"
				end
			else
				Result := "kb.db"
			end
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
	has_ecf_subdirectories (a_path: READABLE_STRING_GENERAL): BOOLEAN
			-- Does path contain subdirectories that have ECF files?
			-- Used to detect general Eiffel library directories (like EiffelStudio library)
		local
			l_dir, l_subdir: DIRECTORY
			l_subpath: PATH
			l_ecf_path: PATH
		do
			create l_dir.make (a_path.out)
			if l_dir.exists then
				across l_dir.entries as entry loop
					if not entry.name.out.starts_with (".") then
						create l_subpath.make_from_string (a_path.out)
						l_subpath := l_subpath.extended (entry.name.out)
						create l_subdir.make_with_path (l_subpath)
						if l_subdir.exists then
							-- Check if subdirectory contains an ECF file with same name
							l_ecf_path := l_subpath.extended (entry.name.out + ".ecf")
							if (create {RAW_FILE}.make_with_path (l_ecf_path)).exists then
								Result := True
							end
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
