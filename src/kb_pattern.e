note
	description: "[
		KB_PATTERN - Design Pattern Model

		Stores design pattern information with Eiffel-specific idioms.
		Includes name, description, example code, and when to use.
	]"
	author: "Simple Eiffel"
	date: "$Date$"
	revision: "$Revision$"

class
	KB_PATTERN

create
	make,
	make_from_row

feature {NONE} -- Initialization

	make (a_name, a_code: READABLE_STRING_GENERAL)
			-- Create pattern
		require
			name_not_empty: not a_name.is_empty
			code_not_empty: not a_code.is_empty
		do
			name := a_name.to_string_32
			code := a_code.to_string_32
			create description.make_empty
			create when_to_use.make_empty
			create eiffel_idioms.make (3)
		ensure
			name_set: name.same_string_general (a_name)
			code_set: code.same_string_general (a_code)
		end

	make_from_row (a_row: SIMPLE_SQL_ROW)
			-- Create from database row
		require
			row_not_void: a_row /= Void
		do
			if attached a_row.item (1) as al_val then
				id := al_val.out.to_integer
			end
			name := a_row.string_value ("name")
			description := a_row.string_value ("description")
			code := a_row.string_value ("code")
			when_to_use := a_row.string_value ("when_to_use")
			create eiffel_idioms.make (3)

			-- Parse idioms JSON
			parse_idioms (a_row.string_value ("eiffel_idioms"))
		end

feature -- Access

	id: INTEGER
			-- Database ID

	name: STRING_32
			-- Pattern name (e.g., "singleton", "factory")

	description: STRING_32
			-- Pattern description

	code: STRING_32
			-- Example Eiffel implementation

	when_to_use: STRING_32
			-- When to use this pattern

	eiffel_idioms: ARRAYED_LIST [STRING_32]
			-- Eiffel-specific notes

feature -- Setters

	set_id (a_id: INTEGER)
			-- Set database ID
		do
			id := a_id
		end

	set_description (a_desc: READABLE_STRING_GENERAL)
			-- Set description
		do
			description := a_desc.to_string_32
		end

	set_when_to_use (a_when: READABLE_STRING_GENERAL)
			-- Set when to use
		do
			when_to_use := a_when.to_string_32
		end

	add_idiom (a_idiom: READABLE_STRING_GENERAL)
			-- Add Eiffel idiom note
		do
			eiffel_idioms.extend (a_idiom.to_string_32)
		end

feature -- Status

	is_valid: BOOLEAN
			-- Is this a valid pattern?
		do
			Result := not name.is_empty and not code.is_empty
		end

feature -- JSON Serialization

	eiffel_idioms_json: STRING_32
			-- Idioms as JSON array
		local
			l_first: BOOLEAN
		do
			create Result.make (100)
			Result.append_character ('[')
			l_first := True
			across eiffel_idioms as ic loop
				if not l_first then
					Result.append_character (',')
				end
				Result.append_character ('"')
				Result.append (ic)
				Result.append_character ('"')
				l_first := False
			end
			Result.append_character (']')
		end

feature -- Display

	formatted: STRING_32
			-- Full formatted display
		do
			create Result.make (code.count + 300)
			Result.append ("PATTERN: ")
			Result.append (name)
			Result.append ("%N")
			Result.append (create {STRING_32}.make_filled ('=', name.count + 9))

			if not description.is_empty then
				Result.append ("%N%N")
				Result.append (description)
			end

			if not when_to_use.is_empty then
				Result.append ("%N%NWHEN TO USE:%N")
				Result.append (when_to_use)
			end

			if not eiffel_idioms.is_empty then
				Result.append ("%N%NEIFFEL IDIOMS:%N")
				across eiffel_idioms as ic loop
					Result.append ("  - ")
					Result.append (ic)
					Result.append ("%N")
				end
			end

			Result.append ("%NCODE:%N")
			Result.append (code)
		end

	brief: STRING_32
			-- Brief one-line display
		do
			create Result.make (100)
			Result.append (name)
			if not description.is_empty then
				Result.append (" - ")
				if description.count > 60 then
					Result.append (description.substring (1, 57))
					Result.append ("...")
				else
					Result.append (description)
				end
			end
		end

feature {NONE} -- Parsing

	parse_idioms (a_json: READABLE_STRING_GENERAL)
			-- Parse idioms from JSON using simple_json
		local
			l_json: SIMPLE_JSON
			l_value: detachable SIMPLE_JSON_VALUE
			l_arr: SIMPLE_JSON_ARRAY
			l_item: SIMPLE_JSON_VALUE
			i: INTEGER
		do
			create eiffel_idioms.make (3)
			if not a_json.is_empty then
				create l_json
				l_value := l_json.parse (a_json.to_string_32)
				if attached l_value as val and then val.is_array then
					l_arr := val.array_value
					from i := 1 until i > l_arr.count loop
						l_item := l_arr [i]
						if l_item.is_string then
							eiffel_idioms.extend (l_item.string_value)
						end
						i := i + 1
					end
				end
			end
		end

invariant
	name_not_empty: not name.is_empty
	code_not_empty: not code.is_empty
	idioms_not_void: eiffel_idioms /= Void

end
