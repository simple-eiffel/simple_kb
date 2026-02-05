note
	description: "[
		KB_RESULT - Search Result Model

		Represents a single result from FTS5 full-text search.
		Contains content type, ID reference, title, snippet, and rank.
	]"
	author: "Simple Eiffel"
	date: "$Date$"
	revision: "$Revision$"

class
	KB_RESULT

create
	make,
	make_from_row

feature {NONE} -- Initialization

	make (a_type, a_id, a_title, a_snippet: READABLE_STRING_GENERAL; a_rank: REAL_64)
			-- Create result
		require
			type_not_empty: not a_type.is_empty
		do
			content_type := a_type.to_string_32
			content_id := a_id.to_string_32
			title := a_title.to_string_32
			snippet := a_snippet.to_string_32
			rank := a_rank
		ensure
			type_set: content_type.same_string_general (a_type)
			title_set: title.same_string_general (a_title)
		end

	make_from_row (a_row: SIMPLE_SQL_ROW)
			-- Create from database row
		require
			row_not_void: a_row /= Void
		do
			content_type := safe_string (a_row.item (1))
			content_id := safe_string (a_row.item (2))
			title := safe_string (a_row.item (3))
			snippet := safe_string (a_row.item (4))
			if attached a_row.item (5) as al_val then
				rank := al_val.out.to_real_64
			end
		end

feature -- Access

	content_type: STRING_32
			-- Type: 'class', 'feature', 'example', 'error', 'pattern'

	content_id: STRING_32
			-- Reference ID in source table

	title: STRING_32
			-- Display title

	snippet: STRING_32
			-- Search result snippet with highlights

	rank: REAL_64
			-- BM25 relevance rank (lower = more relevant)

feature -- Display

	type_label: STRING_32
			-- Formatted type label
		local
			l_upper: STRING_32
		do
			if content_type.same_string ("class") then
				Result := "[CLASS]"
			elseif content_type.same_string ("feature") then
				Result := "[FEATURE]"
			elseif content_type.same_string ("example") then
				Result := "[EXAMPLE]"
			elseif content_type.same_string ("error") then
				Result := "[ERROR]"
			elseif content_type.same_string ("pattern") then
				Result := "[PATTERN]"
			else
				l_upper := content_type.twin
				l_upper.to_upper
				create Result.make (l_upper.count + 2)
				Result.append_character ('[')
				Result.append (l_upper)
				Result.append_character (']')
			end
		end

	formatted: STRING_32
			-- Formatted display string
		do
			create Result.make (100)
			Result.append (type_label)
			Result.append (" ")
			Result.append (title)
			Result.append ("%N   ")
			Result.append (snippet)
		end

feature {NONE} -- Implementation

	safe_string (a_val: detachable ANY): STRING_32
			-- Convert value to string safely
		do
			if attached a_val as al_v then
				Result := al_v.out
			else
				create Result.make_empty
			end
		end

invariant
	type_not_empty: not content_type.is_empty

end
