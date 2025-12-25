note
	description: "KB_FAQ - FAQ Entry Model for emergent Q&A system"
	author: "Simple Eiffel"

class
	KB_FAQ

create
	make,
	make_from_row

feature {NONE} -- Initialization

	make (a_question, a_answer: STRING_32)
		require
			question_not_empty: not a_question.is_empty
			answer_not_empty: not a_answer.is_empty
		do
			id := 0
			question := a_question.twin
			answer := a_answer.twin
			create keywords.make_empty
			create sources.make (5)
			create tags.make (5)
			tags.compare_objects
			hit_count := 0
			helpful_count := 0
			kb_version := 1
			create created_at.make_now
		end

	make_from_row (a_row: SIMPLE_SQL_ROW)
		require
			row_not_void: a_row /= Void
		do
			id := a_row.integer_value ("id")
			question := a_row.string_value ("question")
			keywords := a_row.string_value ("keywords")
			answer := a_row.string_value ("answer")
			sources := parse_json_array (a_row.string_value ("sources"))
			tags := parse_json_array (a_row.string_value ("tags"))
			tags.compare_objects
			hit_count := a_row.integer_value ("hit_count")
			helpful_count := a_row.integer_value ("helpful_count")
			kb_version := a_row.integer_value ("kb_version")
			create created_at.make_now
		end

feature -- Access

	id: INTEGER
	question: STRING_32
	keywords: STRING_32
	answer: STRING_32
	sources: ARRAYED_LIST [STRING_32]
	tags: ARRAYED_LIST [STRING_32]
	hit_count: INTEGER
	helpful_count: INTEGER
	kb_version: INTEGER
	created_at: DATE_TIME

feature -- Status

	is_persisted: BOOLEAN
		do
			Result := id > 0
		end

feature -- Modification

	set_id (a_id: INTEGER)
		do
			id := a_id
		end

	set_keywords (a_keywords: STRING_32)
		do
			keywords := a_keywords.twin
		end

	add_source (a_source: STRING_32)
		do
			sources.extend (a_source.twin)
		end

	add_tag (a_tag: STRING_32)
		require
			tag_not_empty: not a_tag.is_empty
		local
			l_lower: STRING_32
		do
			l_lower := a_tag.as_lower
			if not tags.has (l_lower) then
				tags.extend (l_lower)
			end
		end

	increment_hit_count
		do
			hit_count := hit_count + 1
		end

	mark_helpful
		do
			helpful_count := helpful_count + 1
		end

feature -- Conversion

	sources_as_json: STRING_32
		do
			Result := array_to_json (sources)
		end

	tags_as_json: STRING_32
		do
			Result := array_to_json (tags)
		end

feature {NONE} -- Implementation

	parse_json_array (a_json: detachable STRING_32): ARRAYED_LIST [STRING_32]
		local
			l_content: STRING_32
			l_items: LIST [STRING_32]
		do
			create Result.make (5)
			if attached a_json as j and then j.count > 2 then
				l_content := j.substring (2, j.count - 1)
				l_items := l_content.split (',')
				across l_items as item loop
					if attached item as i then
						i.left_adjust
						i.right_adjust
						if i.count > 2 and then i.item (1) = '"' then
							Result.extend (i.substring (2, i.count - 1))
						elseif not i.is_empty then
							Result.extend (i)
						end
					end
				end
			end
		end

	array_to_json (a_list: ARRAYED_LIST [STRING_32]): STRING_32
		do
			create Result.make (100)
			Result.append_character ('[')
			across a_list as item loop
				if Result.count > 1 then
					Result.append (",")
				end
				Result.append ("%"" + item + "%"")
			end
			Result.append_character (']')
		end

invariant
	question_not_void: question /= Void
	answer_not_void: answer /= Void

end
