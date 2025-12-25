note
	description: "KB_TAG_VOCABULARY - Predefined Tag Categories"
	author: "Simple Eiffel"

class
	KB_TAG_VOCABULARY

feature -- Access

	all_tags: ARRAYED_LIST [STRING_32]
		once
			create Result.make (50)
			Result.compare_objects
			Result.extend ("json"); Result.extend ("xml"); Result.extend ("yaml")
			Result.extend ("toml"); Result.extend ("csv"); Result.extend ("html")
			Result.extend ("file"); Result.extend ("io"); Result.extend ("network")
			Result.extend ("http"); Result.extend ("websocket"); Result.extend ("smtp")
			Result.extend ("database"); Result.extend ("sql"); Result.extend ("cache")
			Result.extend ("parsing"); Result.extend ("serialization"); Result.extend ("validation")
			Result.extend ("encoding"); Result.extend ("encryption"); Result.extend ("hashing")
			Result.extend ("datetime"); Result.extend ("math"); Result.extend ("decimal")
			Result.extend ("uuid"); Result.extend ("regex")
			Result.extend ("api"); Result.extend ("web"); Result.extend ("cli")
			Result.extend ("testing"); Result.extend ("logging"); Result.extend ("config")
			Result.extend ("async"); Result.extend ("process"); Result.extend ("scoop")
			Result.extend ("ai"); Result.extend ("llm")
		end

feature -- Queries

	is_valid_tag (a_tag: STRING_32): BOOLEAN
		do
			Result := all_tags.has (a_tag.as_lower)
		end

	tags_for_keywords (a_keywords: STRING_32): ARRAYED_LIST [STRING_32]
		local
			l_words: LIST [STRING_32]
			l_word, l_lower: STRING_32
		do
			create Result.make (5)
			Result.compare_objects
			l_words := a_keywords.split (' ')
			across l_words as w loop
				l_word := w
				l_word.left_adjust
				l_word.right_adjust
				l_lower := l_word.as_lower
				if all_tags.has (l_lower) and not Result.has (l_lower) then
					Result.extend (l_lower)
				else
					if l_lower.has_substring ("json") then
						add_unique (Result, "json")
						add_unique (Result, "serialization")
					elseif l_lower.has_substring ("http") or l_lower.has_substring ("web") then
						add_unique (Result, "http")
						add_unique (Result, "network")
					elseif l_lower.has_substring ("file") then
						add_unique (Result, "file")
						add_unique (Result, "io")
					elseif l_lower.has_substring ("sql") or l_lower.has_substring ("database") then
						add_unique (Result, "sql")
						add_unique (Result, "database")
					elseif l_lower.has_substring ("date") or l_lower.has_substring ("time") then
						add_unique (Result, "datetime")
					elseif l_lower.has_substring ("test") then
						add_unique (Result, "testing")
					elseif l_lower.has_substring ("xml") then
						add_unique (Result, "xml")
						add_unique (Result, "parsing")
					elseif l_lower.has_substring ("hash") then
						add_unique (Result, "hashing")
					elseif l_lower.has_substring ("mail") or l_lower.has_substring ("smtp") then
						add_unique (Result, "smtp")
						add_unique (Result, "network")
					end
				end
			end
		end

feature {NONE} -- Implementation

	add_unique (a_list: ARRAYED_LIST [STRING_32]; a_tag: STRING_32)
		do
			if not a_list.has (a_tag) then
				a_list.extend (a_tag)
			end
		end

end
