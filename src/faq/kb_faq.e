note
	description: "KB_FAQ - FAQ Entry Model for emergent Q&A system with instructional pair support"
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
			-- Instructional pair fields
			create category.make_empty
			difficulty := 1
			create code_example.make_empty
			create see_also.make (3)
			create source_origin.make_from_string ("manual")
			create related_classes.make (5)
			create related_errors.make (3)
			create instruction.make_empty
			create input_context.make_empty
			create output_answer.make_empty
		end

	make_from_row (a_row: SIMPLE_SQL_ROW)
		require
			row_not_void: a_row /= Void
		do
			id := a_row.integer_value ("id")
			question := a_row.string_value ("question")
			keywords := safe_column_string (a_row, "keywords")
			answer := a_row.string_value ("answer")
			sources := parse_json_array (safe_column_string (a_row, "sources"))
			tags := parse_json_array (safe_column_string (a_row, "tags"))
			tags.compare_objects
			hit_count := safe_column_int (a_row, "hit_count")
			helpful_count := safe_column_int (a_row, "helpful_count")
			kb_version := safe_column_int (a_row, "kb_version")
			create created_at.make_now
			-- Instructional pair fields (may not exist in older schemas)
			category := safe_column_string (a_row, "category")
			difficulty := safe_column_int (a_row, "difficulty").max (1)
			code_example := safe_column_string (a_row, "code_example")
			see_also := parse_json_array (safe_column_string (a_row, "see_also"))
			source_origin := safe_column_string (a_row, "source_origin")
			related_classes := parse_json_array (safe_column_string (a_row, "related_classes"))
			related_errors := parse_json_array (safe_column_string (a_row, "related_errors"))
			instruction := safe_column_string (a_row, "instruction")
			input_context := safe_column_string (a_row, "input_context")
			output_answer := safe_column_string (a_row, "output_answer")
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

feature -- Instructional Pair Access

	category: STRING_32
			-- Category: newcomer, architect, scoop, dbc, migrator, debugger

	difficulty: INTEGER
			-- Difficulty level 1-5 (1=beginner, 5=expert)

	code_example: STRING_32
			-- Standalone compilable code example

	see_also: ARRAYED_LIST [STRING_32]
			-- Related FAQ IDs

	source_origin: STRING_32
			-- Origin: manual, ai-generated, eiffel.org, ecma, code-study

	related_classes: ARRAYED_LIST [STRING_32]
			-- Related class names from KB

	related_errors: ARRAYED_LIST [STRING_32]
			-- Related error codes

	instruction: STRING_32
			-- QLoRA format: the instruction/question

	input_context: STRING_32
			-- QLoRA format: optional input context/code

	output_answer: STRING_32
			-- QLoRA format: expected output/answer

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

	set_category (a_category: STRING_32)
		do
			category := a_category.twin
		end

	set_difficulty (a_level: INTEGER)
		require
			valid_level: a_level >= 1 and a_level <= 5
		do
			difficulty := a_level
		end

	set_code_example (a_code: STRING_32)
		do
			code_example := a_code.twin
		end

	set_source_origin (a_origin: STRING_32)
		do
			source_origin := a_origin.twin
		end

	set_instruction (a_instr: STRING_32)
		do
			instruction := a_instr.twin
		end

	set_input_context (a_input: STRING_32)
		do
			input_context := a_input.twin
		end

	set_output_answer (a_output: STRING_32)
		do
			output_answer := a_output.twin
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

	add_related_class (a_class: STRING_32)
		do
			related_classes.extend (a_class.twin)
		end

	add_related_error (a_error: STRING_32)
		do
			related_errors.extend (a_error.twin)
		end

	add_see_also (a_faq_id: STRING_32)
		do
			see_also.extend (a_faq_id.twin)
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

	see_also_as_json: STRING_32
		do
			Result := array_to_json (see_also)
		end

	related_classes_as_json: STRING_32
		do
			Result := array_to_json (related_classes)
		end

	related_errors_as_json: STRING_32
		do
			Result := array_to_json (related_errors)
		end

feature {NONE} -- Implementation

	safe_column_string (a_row: SIMPLE_SQL_ROW; a_col: STRING): STRING_32
			-- Get column value safely (returns empty string if column missing)
		do
			if a_row.has_column (a_col) then
				Result := safe_string (a_row.string_value (a_col))
			else
				create Result.make_empty
			end
		end

	safe_column_int (a_row: SIMPLE_SQL_ROW; a_col: STRING): INTEGER
			-- Get integer column value safely (returns 0 if column missing)
		do
			if a_row.has_column (a_col) then
				Result := a_row.integer_value (a_col)
			end
		end

	safe_string (a_value: detachable STRING_32): STRING_32
			-- Return value or empty string if void
		do
			if attached a_value as al_v then
				Result := v
			else
				create Result.make_empty
			end
		end

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
					if attached item as al_i then
						al_i.left_adjust
						al_i.right_adjust
						if al_i.count > 2 and then al_i.item (1) = '"' then
							Result.extend (al_i.substring (2, al_i.count - 1))
						elseif not al_i.is_empty then
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
