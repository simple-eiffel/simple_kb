note
	description: "[
		KB_ERROR_INFO - Compiler Error Code Information

		Stores detailed information about an EiffelStudio compiler error code,
		including meaning, explanation, common causes, and fixes.

		Error codes follow patterns:
			- VXXX: Validity errors (from ECMA-367)
			- VDXX: Configuration/dependency errors
			- Syntax errors
	]"
	author: "Simple Eiffel"
	date: "$Date$"
	revision: "$Revision$"

class
	KB_ERROR_INFO

create
	make,
	make_from_row

feature {NONE} -- Initialization

	make (a_code, a_meaning: READABLE_STRING_GENERAL)
			-- Create with code and meaning
		require
			code_not_empty: not a_code.is_empty
			meaning_not_empty: not a_meaning.is_empty
		do
			code := a_code.to_string_32
			meaning := a_meaning.to_string_32
			create explanation.make_empty
			create common_causes.make (3)
			create fixes.make (2)
			create bad_code.make_empty
			create good_code.make_empty
			create ecma_section.make_empty
		ensure
			code_set: code.same_string_general (a_code)
			meaning_set: meaning.same_string_general (a_meaning)
		end

	make_from_row (a_row: SIMPLE_SQL_ROW)
			-- Create from database row
		require
			row_not_void: a_row /= Void
		do
			code := a_row.string_value ("code")
			meaning := a_row.string_value ("meaning")
			explanation := a_row.string_value ("explanation")
			ecma_section := a_row.string_value ("ecma_section")
			create common_causes.make (3)
			create fixes.make (2)
			create bad_code.make_empty
			create good_code.make_empty

			-- Parse JSON arrays
			parse_common_causes (a_row.string_value ("common_causes"))
			parse_fixes (a_row.string_value ("fixes"))
			parse_examples (a_row.string_value ("examples"))
		end

feature -- Access

	code: STRING_32
			-- Error code (e.g., "VEVI", "VD89")

	meaning: STRING_32
			-- Short meaning (e.g., "Variable not properly set")

	explanation: STRING_32
			-- Full explanation

	common_causes: ARRAYED_LIST [STRING_32]
			-- List of common causes

	fixes: ARRAYED_LIST [TUPLE [title, description, example: STRING_32]]
			-- List of fix strategies

	bad_code: STRING_32
			-- Example of code that causes this error

	good_code: STRING_32
			-- Example of corrected code

	ecma_section: STRING_32
			-- ECMA-367 section reference

feature -- Setters

	set_explanation (a_text: READABLE_STRING_GENERAL)
			-- Set explanation
		do
			explanation := a_text.to_string_32
		end

	set_ecma_section (a_section: READABLE_STRING_GENERAL)
			-- Set ECMA reference
		do
			ecma_section := a_section.to_string_32
		end

	add_cause (a_cause: READABLE_STRING_GENERAL)
			-- Add common cause
		do
			common_causes.extend (a_cause.to_string_32)
		end

	add_fix (a_title, a_description, a_example: READABLE_STRING_GENERAL)
			-- Add fix strategy
		do
			fixes.extend ([a_title.to_string_32, a_description.to_string_32, a_example.to_string_32])
		end

	set_bad_code (a_code: READABLE_STRING_GENERAL)
			-- Set bad code example
		do
			bad_code := a_code.to_string_32
		end

	set_good_code (a_code: READABLE_STRING_GENERAL)
			-- Set good code example
		do
			good_code := a_code.to_string_32
		end

feature -- Status

	is_valid: BOOLEAN
			-- Is this a valid error entry?
		do
			Result := not code.is_empty and not meaning.is_empty
		end

feature -- JSON Serialization

	common_causes_json: STRING_32
			-- Common causes as JSON array
		local
			l_first: BOOLEAN
		do
			create Result.make (100)
			Result.append_character ('[')
			l_first := True
			across common_causes as ic loop
				if not l_first then
					Result.append_character (',')
				end
				Result.append_character ('"')
				Result.append (escape_json (ic))
				Result.append_character ('"')
				l_first := False
			end
			Result.append_character (']')
		end

	fixes_json: STRING_32
			-- Fixes as JSON array
		local
			l_first: BOOLEAN
		do
			create Result.make (200)
			Result.append_character ('[')
			l_first := True
			across fixes as ic loop
				if not l_first then
					Result.append_character (',')
				end
				Result.append ("{%"title%":%"")
				Result.append (escape_json (ic.title))
				Result.append ("%",%"description%":%"")
				Result.append (escape_json (ic.description))
				Result.append ("%",%"example%":%"")
				Result.append (escape_json (ic.example))
				Result.append ("%"}")
				l_first := False
			end
			Result.append_character (']')
		end

	examples_json: STRING_32
			-- Examples as JSON object
		do
			create Result.make (200)
			Result.append ("{%"bad%":%"")
			Result.append (escape_json (bad_code))
			Result.append ("%",%"good%":%"")
			Result.append (escape_json (good_code))
			Result.append ("%"}")
		end

feature -- Display

	formatted: STRING_32
			-- Full formatted display
		local
			l_idx: INTEGER
		do
			create Result.make (500)
			Result.append ("ERROR: ")
			Result.append (code)
			Result.append (" - ")
			Result.append (meaning)
			Result.append ("%N")
			Result.append (create {STRING_32}.make_filled ('=', 50))
			Result.append ("%N%N")

			if not explanation.is_empty then
				Result.append ("MEANING:%N  ")
				Result.append (explanation)
				Result.append ("%N%N")
			end

			if not common_causes.is_empty then
				Result.append ("COMMON CAUSES:%N")
				l_idx := 1
				across common_causes as ic loop
					Result.append ("  ")
					Result.append (l_idx.out)
					Result.append (". ")
					Result.append (ic)
					Result.append ("%N")
					l_idx := l_idx + 1
				end
				Result.append ("%N")
			end

			if not bad_code.is_empty then
				Result.append ("EXAMPLE (BAD):%N")
				Result.append (bad_code)
				Result.append ("%N%N")
			end

			if not fixes.is_empty then
				Result.append ("FIX OPTIONS:%N")
				l_idx := 1
				across fixes as ic loop
					Result.append ("%N  Option ")
					Result.append (l_idx.out)
					Result.append (": ")
					Result.append (ic.title)
					Result.append ("%N    ")
					Result.append (ic.description)
					if not ic.example.is_empty then
						Result.append ("%N    Example: ")
						Result.append (ic.example)
					end
					Result.append ("%N")
					l_idx := l_idx + 1
				end
			end

			if not ecma_section.is_empty then
				Result.append ("%NREFERENCE: ECMA-367 Section ")
				Result.append (ecma_section)
				Result.append ("%N")
			end
		end

feature {NONE} -- Parsing

	parse_common_causes (a_json: READABLE_STRING_GENERAL)
			-- Parse common causes from JSON using simple_json
		local
			l_json: SIMPLE_JSON
			l_value: detachable SIMPLE_JSON_VALUE
			l_arr: SIMPLE_JSON_ARRAY
			l_item: SIMPLE_JSON_VALUE
			i: INTEGER
		do
			create common_causes.make (3)
			if not a_json.is_empty then
				create l_json
				l_value := l_json.parse (a_json.to_string_32)
				if attached l_value as val and then val.is_array then
					l_arr := val.array_value
					from i := 1 until i > l_arr.count loop
						l_item := l_arr [i]
						if l_item.is_string then
							common_causes.extend (l_item.string_value)
						end
						i := i + 1
					end
				end
			end
		end

	parse_fixes (a_json: READABLE_STRING_GENERAL)
			-- Parse fixes from JSON using simple_json
		local
			l_json: SIMPLE_JSON
			l_value: detachable SIMPLE_JSON_VALUE
			l_arr: SIMPLE_JSON_ARRAY
			l_item: SIMPLE_JSON_VALUE
			l_obj: SIMPLE_JSON_OBJECT
			l_title, l_desc, l_ex: STRING_32
			i: INTEGER
		do
			create fixes.make (2)
			if not a_json.is_empty then
				create l_json
				l_value := l_json.parse (a_json.to_string_32)
				if attached l_value as val and then val.is_array then
					l_arr := val.array_value
					from i := 1 until i > l_arr.count loop
						l_item := l_arr [i]
						if l_item.is_object then
							l_obj := l_item.object_value
							l_title := safe_string (l_obj.string_item ("title"))
							l_desc := safe_string (l_obj.string_item ("description"))
							l_ex := safe_string (l_obj.string_item ("example"))
							fixes.extend ([l_title, l_desc, l_ex])
						end
						i := i + 1
					end
				end
			end
		end

	parse_examples (a_json: READABLE_STRING_GENERAL)
			-- Parse examples from JSON using simple_json
		local
			l_json: SIMPLE_JSON
			l_value: detachable SIMPLE_JSON_VALUE
			l_obj: SIMPLE_JSON_OBJECT
		do
			create bad_code.make_empty
			create good_code.make_empty
			if not a_json.is_empty then
				create l_json
				l_value := l_json.parse (a_json.to_string_32)
				if attached l_value as val and then val.is_object then
					l_obj := val.object_value
					bad_code := safe_string (l_obj.string_item ("bad"))
					good_code := safe_string (l_obj.string_item ("good"))
				end
			end
		end

	escape_json (a_str: STRING_32): STRING_32
			-- Escape string for JSON
		do
			create Result.make (a_str.count + 10)
			across a_str as ic loop
				inspect ic
				when '"' then
					Result.append ("\%"")
				when '\' then
					Result.append ("\\")
				when '%N' then
					Result.append ("\n")
				when '%R' then
					Result.append ("\r")
				when '%T' then
					Result.append ("\t")
				else
					Result.append_character (ic)
				end
			end
		end

	safe_string (a_val: detachable STRING_32): STRING_32
			-- Convert detachable to attached string
		do
			if attached a_val as al_v then
				Result := v
			else
				create Result.make_empty
			end
		end

invariant
	code_not_empty: not code.is_empty
	meaning_not_empty: not meaning.is_empty
	causes_not_void: common_causes /= Void
	fixes_not_void: fixes /= Void

end
