note
	description: "[
		KB_EXAMPLE - Code Example Model

		Stores code examples from Rosetta Code or manual sources.
		Includes title, source, code, tags, and difficulty tier.
	]"
	author: "Simple Eiffel"
	date: "$Date$"
	revision: "$Revision$"

class
	KB_EXAMPLE

create
	make,
	make_from_row

feature {NONE} -- Initialization

	make (a_title, a_code: READABLE_STRING_GENERAL)
			-- Create example
		require
			title_not_empty: not a_title.is_empty
			code_not_empty: not a_code.is_empty
		do
			title := a_title.to_string_32
			code := a_code.to_string_32
			create source.make_from_string ("manual")
			create tags.make (3)
			create tier.make_empty
		ensure
			title_set: title.same_string_general (a_title)
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
			title := a_row.string_value ("title")
			source := a_row.string_value ("source")
			code := a_row.string_value ("code")
			tier := a_row.string_value ("tier")
			create tags.make (3)

			-- Parse tags JSON
			parse_tags (a_row.string_value ("tags"))
		end

feature -- Access

	id: INTEGER
			-- Database ID

	title: STRING_32
			-- Example title (e.g., "Bubble Sort")

	source: STRING_32
			-- Source: 'rosetta', 'manual', 'generated'

	code: STRING_32
			-- Eiffel code

	tags: ARRAYED_LIST [STRING_32]
			-- Tags for categorization

	tier: STRING_32
			-- Difficulty tier (TIER1, TIER2, etc.)

feature -- Setters

	set_id (a_id: INTEGER)
			-- Set database ID
		do
			id := a_id
		end

	set_source (a_source: READABLE_STRING_GENERAL)
			-- Set source
		do
			source := a_source.to_string_32
		end

	set_tier (a_tier: READABLE_STRING_GENERAL)
			-- Set tier
		do
			tier := a_tier.to_string_32
		end

	add_tag (a_tag: READABLE_STRING_GENERAL)
			-- Add tag
		do
			tags.extend (a_tag.to_string_32)
		end

feature -- Status

	is_valid: BOOLEAN
			-- Is this a valid example?
		do
			Result := not title.is_empty and not code.is_empty
		end

	is_rosetta: BOOLEAN
			-- Is this from Rosetta Code?
		do
			Result := source.same_string ("rosetta")
		end

feature -- JSON Serialization

	tags_json: STRING_32
			-- Tags as JSON array
		local
			l_first: BOOLEAN
		do
			create Result.make (50)
			Result.append_character ('[')
			l_first := True
			across tags as ic loop
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
		local
			l_first: BOOLEAN
		do
			create Result.make (code.count + 200)
			Result.append ("EXAMPLE: ")
			Result.append (title)
			Result.append ("%N")
			Result.append (create {STRING_32}.make_filled ('=', title.count + 9))

			if not source.is_empty then
				Result.append ("%NSource: ")
				Result.append (source)
			end

			if not tier.is_empty then
				Result.append ("%NTier: ")
				Result.append (tier)
			end

			if not tags.is_empty then
				Result.append ("%NTags: ")
				l_first := True
				across tags as ic loop
					if not l_first then
						Result.append (", ")
					end
					Result.append (ic)
					l_first := False
				end
			end

			Result.append ("%N%NCODE:%N")
			Result.append (code)
		end

	brief: STRING_32
			-- Brief one-line display
		do
			create Result.make (100)
			Result.append (title)
			if not tier.is_empty then
				Result.append (" [")
				Result.append (tier)
				Result.append ("]")
			end
			if not source.is_empty then
				Result.append (" (")
				Result.append (source)
				Result.append (")")
			end
		end

feature {NONE} -- Parsing

	parse_tags (a_json: READABLE_STRING_GENERAL)
			-- Parse tags from JSON using simple_json
		local
			l_json: SIMPLE_JSON
			l_value: detachable SIMPLE_JSON_VALUE
			l_arr: SIMPLE_JSON_ARRAY
			l_item: SIMPLE_JSON_VALUE
			i: INTEGER
		do
			create tags.make (3)
			if not a_json.is_empty then
				create l_json
				l_value := l_json.parse (a_json.to_string_32)
				if attached l_value as val and then val.is_array then
					l_arr := val.array_value
					from i := 1 until i > l_arr.count loop
						l_item := l_arr [i]
						if l_item.is_string then
							tags.extend (l_item.string_value)
						end
						i := i + 1
					end
				end
			end
		end

invariant
	title_not_empty: not title.is_empty
	code_not_empty: not code.is_empty
	tags_not_void: tags /= Void

end
