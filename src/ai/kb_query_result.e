note
	description: "[
		KB_QUERY_RESULT - Query Result Container
		
		Holds the result of a KB query, including:
		- The original query
		- The mode used (direct/ai)
		- Raw search results
		- AI-synthesized answer (when available)
		- Source citations
		
		Usage:
			result: KB_QUERY_RESULT
			create result.make ("JSON parsing")
			result.set_raw_results (search_results)
	]"
	author: "Simple Eiffel"
	date: "$Date$"
	revision: "$Revision$"

class
	KB_QUERY_RESULT

create
	make

feature {NONE} -- Initialization

	make (a_query: STRING_32)
			-- Create result for query
		require
			query_not_empty: not a_query.is_empty
		do
			original_query := a_query.twin
			create mode.make_empty
			create query_type.make_empty
			create raw_results.make (0)
			create synthesized_answer.make_empty
			create citations.make (0)
			create ai_provider.make_empty
			create ai_note.make_empty
		ensure
			query_set: original_query.same_string (a_query)
		end

feature -- Access

	original_query: STRING_32
			-- The query that was submitted

	mode: STRING_32
			-- Query mode: "direct", "ai", "ai-fallback"

	query_type: STRING_32
			-- Type of query: "search", "class", "feature", "error", "pattern"

	raw_results: ARRAYED_LIST [KB_RESULT]
			-- Raw search results from database

	synthesized_answer: STRING_32
			-- AI-synthesized answer (empty if direct mode)

	citations: ARRAYED_LIST [STRING_32]
			-- Source citations for the answer

	ai_provider: STRING_32
			-- AI provider used (empty if direct mode)

	ai_note: STRING_32
			-- Optional note about AI processing

feature -- Status

	has_results: BOOLEAN
			-- Are there any results?
		do
			Result := not raw_results.is_empty or else not synthesized_answer.is_empty
		end

	has_synthesized_answer: BOOLEAN
			-- Was an AI-synthesized answer generated?
		do
			Result := not synthesized_answer.is_empty
		end

	is_ai_mode: BOOLEAN
			-- Was AI used for this query?
		do
			Result := mode.same_string ("ai") or else mode.has_substring ("ai")
		end

	result_count: INTEGER
			-- Number of raw results
		do
			Result := raw_results.count
		end

feature -- Setters

	set_mode (a_mode: STRING_32)
			-- Set query mode
		do
			mode := a_mode.twin
		ensure
			mode_set: mode.same_string (a_mode)
		end

	set_query_type (a_type: STRING_32)
			-- Set query type
		do
			query_type := a_type.twin
		ensure
			type_set: query_type.same_string (a_type)
		end

	set_raw_results (a_results: ARRAYED_LIST [KB_RESULT])
			-- Set raw search results
		require
			results_not_void: a_results /= Void
		do
			raw_results := a_results
		ensure
			results_set: raw_results = a_results
		end

	set_synthesized_answer (a_answer: STRING_32)
			-- Set AI-synthesized answer
		do
			synthesized_answer := a_answer.twin
		ensure
			answer_set: synthesized_answer.same_string (a_answer)
		end

	add_citation (a_source: STRING_32)
			-- Add a citation
		do
			citations.extend (a_source.twin)
		ensure
			citation_added: citations.count = old citations.count + 1
		end

	set_ai_provider (a_provider: STRING_32)
			-- Set AI provider name
		do
			ai_provider := a_provider.twin
		ensure
			provider_set: ai_provider.same_string (a_provider)
		end

	set_ai_note (a_note: STRING_32)
			-- Set AI processing note
		do
			ai_note := a_note.twin
		ensure
			note_set: ai_note.same_string (a_note)
		end

feature -- Display

	formatted: STRING_32
			-- Formatted result for display
		local
			i: INTEGER
		do
			create Result.make (1000)

			-- Mode indicator
			if is_ai_mode then
				Result.append ("Mode: AI-assisted")
				if not ai_provider.is_empty then
					Result.append (" (" + ai_provider + ")")
				end
				Result.append ("%N")
			end

			-- Synthesized answer (if available)
			if has_synthesized_answer then
				Result.append ("%N" + synthesized_answer + "%N")
				if not citations.is_empty then
					Result.append ("%NSources:%N")
					from i := 1 until i > citations.count loop
						Result.append ("  - " + citations [i] + "%N")
						i := i + 1
					end
				end
			end

			-- Raw results
			if not raw_results.is_empty then
				if has_synthesized_answer then
					Result.append ("%N--- Raw Results ---%N")
				end
				Result.append ("Found " + result_count.out + " results:%N%N")
				from i := 1 until i > raw_results.count.min (10) loop
					Result.append (raw_results [i].formatted + "%N")
					i := i + 1
				end
				if result_count > 10 then
					Result.append ("... and " + (result_count - 10).out + " more%N")
				end
			elseif not has_synthesized_answer then
				Result.append ("No results found.%N")
			end

			-- AI note
			if not ai_note.is_empty then
				Result.append ("%NNote: " + ai_note + "%N")
			end
		end

invariant
	original_query_not_void: original_query /= Void
	raw_results_not_void: raw_results /= Void
	citations_not_void: citations /= Void

end
