note
	description: "[
		KB_ROSETTA_IMPORTER - Import Rosetta Code solutions as examples

		Scans simple_rosetta/solutions/tier*/ directories and imports
		each .e file as a KB_EXAMPLE with proper tags and tiers.
	]"
	author: "Simple Eiffel"
	date: "$Date$"
	revision: "$Revision$"

class
	KB_ROSETTA_IMPORTER

create
	make

feature {NONE} -- Initialization

	make (a_db: KB_DATABASE)
			-- Create importer with database
		require
			db_not_void: a_db /= Void
			db_open: a_db.is_open
		do
			db := a_db
			examples_imported := 0
			errors_count := 0
			create last_error.make_empty
		ensure
			db_set: db = a_db
		end

feature -- Access

	db: KB_DATABASE
			-- Target database

	examples_imported: INTEGER
			-- Number of examples imported

	errors_count: INTEGER
			-- Number of import errors

	last_error: STRING_32
			-- Last error message

feature -- Import

	import_all (a_rosetta_path: READABLE_STRING_GENERAL)
			-- Import all solutions from Rosetta path
		require
			path_not_empty: not a_rosetta_path.is_empty
		local
			l_solutions_path: PATH
			l_dir: DIRECTORY
		do
			create l_solutions_path.make_from_string (a_rosetta_path.out)
			l_solutions_path := l_solutions_path.extended ("solutions")
			create l_dir.make_with_path (l_solutions_path)

			if l_dir.exists then
				import_tier (l_solutions_path.out, "tier1_trivial", "TIER1")
				import_tier (l_solutions_path.out, "tier2_easy", "TIER2")
				import_tier (l_solutions_path.out, "tier3_moderate", "TIER3")
				import_tier (l_solutions_path.out, "tier4_complex", "TIER4")
			else
				errors_count := errors_count + 1
				last_error := "Solutions path not found: " + l_solutions_path.out
			end
		end

	import_tier (a_solutions_path: READABLE_STRING_GENERAL; a_tier_dir: STRING; a_tier: STRING)
			-- Import all solutions from a tier directory
		local
			l_tier_path: PATH
			l_dir: DIRECTORY
			l_file_path: PATH
		do
			create l_tier_path.make_from_string (a_solutions_path.out)
			l_tier_path := l_tier_path.extended (a_tier_dir)
			create l_dir.make_with_path (l_tier_path)

			if l_dir.exists and then l_dir.is_readable then
				across l_dir.entries as entry loop
					if entry.name.out.ends_with (".e") and not entry.name.out.starts_with (".") then
						l_file_path := l_tier_path.extended (entry.name.out)
						import_solution (l_file_path.out, a_tier)
					end
				end
			end
		end

	import_solution (a_file_path: READABLE_STRING_GENERAL; a_tier: STRING)
			-- Import a single solution file
		local
			l_file: RAW_FILE
			l_content: STRING
			l_example: KB_EXAMPLE
			l_title, l_task: STRING
			l_rescued: BOOLEAN
		do
			if not l_rescued then
				create l_file.make (a_file_path.out)
				if l_file.exists and then l_file.is_readable then
					l_file.open_read
					l_file.read_stream (l_file.count)
					l_content := l_file.last_string.twin
					l_file.close

					-- Extract title from rosetta_task note or filename
					l_task := extract_rosetta_task (l_content)
					if l_task.is_empty then
						l_title := extract_filename (a_file_path)
					else
						l_title := l_task
					end

					-- Create example
					create l_example.make (l_title, l_content)
					l_example.set_source ("rosetta")
					l_example.set_tier (a_tier)
					l_example.add_tag ("rosetta")
					l_example.add_tag (a_tier.as_lower)

					-- Add algorithm tag based on content
					add_algorithm_tags (l_example, l_content)

					db.add_example (l_example)
					examples_imported := examples_imported + 1
				else
					errors_count := errors_count + 1
					last_error := "Cannot read: " + a_file_path.out
				end
			end
		rescue
			l_rescued := True
			errors_count := errors_count + 1
			last_error := "Exception importing: " + a_file_path.out
			retry
		end

feature -- Statistics

	stats: TUPLE [imported, errors: INTEGER]
			-- Import statistics
		do
			Result := [examples_imported, errors_count]
		end

feature {NONE} -- Implementation

	extract_rosetta_task (a_content: STRING): STRING
			-- Extract rosetta_task from note section
		local
			l_start, l_end: INTEGER
		do
			Result := ""
			l_start := a_content.substring_index ("rosetta_task:", 1)
			if l_start > 0 then
				l_start := l_start + 13 -- length of "rosetta_task:"
				-- Skip whitespace and quotes
				from
				until
					l_start > a_content.count or else
					(a_content.item (l_start) /= ' ' and
					 a_content.item (l_start) /= '%T' and
					 a_content.item (l_start) /= '"')
				loop
					l_start := l_start + 1
				end
				-- Find end (quote or newline)
				l_end := l_start
				from
				until
					l_end > a_content.count or else
					a_content.item (l_end) = '"' or
					a_content.item (l_end) = '%N'
				loop
					l_end := l_end + 1
				end
				if l_end > l_start then
					Result := a_content.substring (l_start, l_end - 1)
					Result.replace_substring_all ("_", " ")
				end
			end
		end

	extract_filename (a_path: READABLE_STRING_GENERAL): STRING
			-- Extract filename without extension
		local
			l_name: STRING
			l_dot: INTEGER
		do
			l_name := a_path.out
			-- Get just the filename
			if l_name.has ('/') then
				l_name := l_name.substring (l_name.last_index_of ('/', l_name.count) + 1, l_name.count)
			end
			if l_name.has ('\') then
				l_name := l_name.substring (l_name.last_index_of ('\', l_name.count) + 1, l_name.count)
			end
			-- Remove extension
			l_dot := l_name.last_index_of ('.', l_name.count)
			if l_dot > 0 then
				l_name := l_name.substring (1, l_dot - 1)
			end
			-- Convert underscores to spaces
			l_name.replace_substring_all ("_", " ")
			Result := l_name
		end

	add_algorithm_tags (a_example: KB_EXAMPLE; a_content: STRING)
			-- Add relevant algorithm tags based on content
		local
			l_lower: STRING
		do
			l_lower := a_content.as_lower

			if l_lower.has_substring ("sort") then
				a_example.add_tag ("sorting")
			end
			if l_lower.has_substring ("prime") then
				a_example.add_tag ("math")
				a_example.add_tag ("primes")
			end
			if l_lower.has_substring ("fibonacci") then
				a_example.add_tag ("math")
				a_example.add_tag ("sequences")
			end
			if l_lower.has_substring ("search") then
				a_example.add_tag ("search")
			end
			if l_lower.has_substring ("cipher") or l_lower.has_substring ("encrypt") then
				a_example.add_tag ("cryptography")
			end
			if l_lower.has_substring ("string") then
				a_example.add_tag ("strings")
			end
			if l_lower.has_substring ("array") or l_lower.has_substring ("list") then
				a_example.add_tag ("collections")
			end
			if l_lower.has_substring ("file") then
				a_example.add_tag ("io")
			end
			if l_lower.has_substring ("date") or l_lower.has_substring ("time") then
				a_example.add_tag ("datetime")
			end
		end

invariant
	db_not_void: db /= Void

end
