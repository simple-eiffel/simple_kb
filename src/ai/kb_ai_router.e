note
	description: "[
		KB_AI_ROUTER - 4-Phase RAG Query Router

		Phase 1: AI extracts keywords + tags
		Phase 2: Search FAQ cache
		Phase 3: If FAQs found -> synthesize from FAQ context
		Phase 4: If no FAQs -> Raw KB RAG + store as new FAQ
	]"
	author: "Simple Eiffel"

class
	KB_AI_ROUTER

create
	make

feature {NONE} -- Initialization

	make (a_db: KB_DATABASE; a_config: KB_AI_CONFIG)
		require
			db_not_void: a_db /= Void
			config_not_void: a_config /= Void
		do
			db := a_db
			ai_config := a_config
			use_ai_mode := a_config.is_ready
			create last_mode_used.make_empty
			create faq_store.make (a_db.db)
			create tag_vocab
		end

feature -- Access

	db: KB_DATABASE
	ai_config: KB_AI_CONFIG
	faq_store: KB_FAQ_STORE
	tag_vocab: KB_TAG_VOCABULARY
	use_ai_mode: BOOLEAN
	last_mode_used: STRING_32
	last_keywords: detachable STRING_32

feature -- Status

	is_ai_available: BOOLEAN
		do
			Result := ai_config.is_ready and use_ai_mode
		end

	faq_stats: STRING_32
		do
			create Result.make (100)
			Result.append ("FAQs cached: " + faq_store.faq_count.out)
		end

feature -- Mode Control

	enable_ai do use_ai_mode := True end
	disable_ai do use_ai_mode := False end

feature -- Query Processing

	process_query (a_query: STRING_32): KB_QUERY_RESULT
		require
			query_not_empty: not a_query.is_empty
		do
			if is_ai_available then
				Result := process_with_ai_cascade (a_query)
				last_mode_used := "ai"
			else
				Result := process_direct (a_query)
				last_mode_used := "direct"
			end
		ensure
			result_not_void: Result /= Void
		end

	process_direct (a_query: STRING_32): KB_QUERY_RESULT
		local
			l_results: ARRAYED_LIST [KB_RESULT]
		do
			create Result.make (a_query)
			Result.set_mode ("direct")
			l_results := db.search (a_query, 20)
			Result.set_raw_results (l_results)
		end

feature -- 4-Phase AI Cascade

	process_with_ai_cascade (a_query: STRING_32): KB_QUERY_RESULT
		local
			l_client: detachable AI_CLIENT
			l_keywords: STRING_32
			l_tags: ARRAYED_LIST [STRING_32]
			l_faqs: ARRAYED_LIST [KB_FAQ]
		do
			create Result.make (a_query)
			Result.set_mode ("ai-cascade")
			l_client := create_ai_client

			if l_client = Void then
				Result := process_direct (a_query)
				Result.set_ai_note ("Could not initialize AI client")
			else
				if attached ai_config.active_provider as p then
					Result.set_ai_provider (p)
				end
				l_keywords := extract_keywords (l_client, a_query)
				last_keywords := l_keywords
				l_tags := tag_vocab.tags_for_keywords (l_keywords)

				if l_keywords.is_empty then
					Result := process_direct (a_query)
					Result.set_ai_note ("Keyword extraction failed")
				else
					l_faqs := search_faq_cache (l_keywords, l_tags)
					if not l_faqs.is_empty then
						Result := synthesize_from_faqs (l_client, a_query, l_faqs, l_keywords, l_tags)
					else
						Result := raw_kb_rag_and_store (l_client, a_query, l_keywords, l_tags)
					end
				end
			end
		end

feature {NONE} -- Phase 1: Keywords

	extract_keywords (a_client: AI_CLIENT; a_query: STRING_32): STRING_32
		local
			l_response: AI_RESPONSE
		do
			l_response := a_client.ask_with_system (keyword_prompt, a_query)
			if l_response.is_success then
				Result := sanitize_keywords (l_response.text)
			else
				create Result.make_empty
			end
		end

feature {NONE} -- Phase 2: FAQ Search

	search_faq_cache (a_keywords: STRING_32; a_tags: ARRAYED_LIST [STRING_32]): ARRAYED_LIST [KB_FAQ]
		local
			l_by_kw, l_by_tags: ARRAYED_LIST [KB_FAQ]
		do
			create Result.make (10)
			if not a_keywords.is_empty then
				l_by_kw := faq_store.search_faqs (a_keywords, 5)
				across l_by_kw as f loop Result.extend (f) end
			end
			if not a_tags.is_empty then
				l_by_tags := faq_store.search_by_tags (a_tags, 5)
				across l_by_tags as f loop
					if not has_faq_id (Result, f.id) then Result.extend (f) end
				end
			end
		end

	has_faq_id (a_list: ARRAYED_LIST [KB_FAQ]; a_id: INTEGER): BOOLEAN
		do
			across a_list as f loop
				if f.id = a_id then Result := True end
			end
		end

feature {NONE} -- Phase 3: FAQ Synthesis

	synthesize_from_faqs (a_client: AI_CLIENT; a_query: STRING_32;
		a_faqs: ARRAYED_LIST [KB_FAQ]; a_keywords: STRING_32;
		a_tags: ARRAYED_LIST [STRING_32]): KB_QUERY_RESULT
		local
			l_response: AI_RESPONSE
			l_context: STRING_32
			l_new_faq: KB_FAQ
			i: INTEGER
		do
			create Result.make (a_query)
			Result.set_mode ("faq-hit")
			l_context := build_faq_context (a_faqs)
			l_response := a_client.ask_with_system (faq_prompt,
				"Question: " + a_query + "%N%NPrevious Q&A:%N" + l_context)

			if l_response.is_success then
				Result.set_synthesized_answer (l_response.text)
				from i := 1 until i > a_faqs.count.min (5) loop
					Result.add_citation ("FAQ: " + a_faqs [i].question.head (50))
					faq_store.record_hit (a_faqs [i])
					i := i + 1
				end
				create l_new_faq.make (a_query, l_response.text)
				l_new_faq.set_keywords (a_keywords)
				across a_tags as t loop l_new_faq.add_tag (t) end
				faq_store.store_faq (l_new_faq)
				Result.set_ai_note ("From " + a_faqs.count.out + " cached FAQs")
			else
				Result := raw_kb_rag_and_store (a_client, a_query, a_keywords, a_tags)
			end
		end

	build_faq_context (a_faqs: ARRAYED_LIST [KB_FAQ]): STRING_32
		local
			i: INTEGER
		do
			create Result.make (2000)
			from i := 1 until i > a_faqs.count.min (5) loop
				Result.append ("Q: " + a_faqs [i].question + "%N")
				Result.append ("A: " + a_faqs [i].answer + "%N%N")
				i := i + 1
			end
		end

feature {NONE} -- Phase 4: Raw KB RAG

	raw_kb_rag_and_store (a_client: AI_CLIENT; a_query: STRING_32;
		a_keywords: STRING_32; a_tags: ARRAYED_LIST [STRING_32]): KB_QUERY_RESULT
		local
			l_response: AI_RESPONSE
			l_results: ARRAYED_LIST [KB_RESULT]
			l_context: STRING_32
			l_new_faq: KB_FAQ
			i: INTEGER
		do
			create Result.make (a_query)
			Result.set_mode ("raw-kb")
			l_results := db.search (a_keywords, 10)
			Result.set_raw_results (l_results)

			if not l_results.is_empty then
				l_context := build_kb_context (l_results)
				l_response := a_client.ask_with_system (synthesis_prompt,
					"Question: " + a_query + "%N%NContext:%N" + l_context)

				if l_response.is_success then
					Result.set_synthesized_answer (l_response.text)
					from i := 1 until i > l_results.count.min (5) loop
						Result.add_citation (l_results [i].title)
						i := i + 1
					end
					create l_new_faq.make (a_query, l_response.text)
					l_new_faq.set_keywords (a_keywords)
					across a_tags as t loop l_new_faq.add_tag (t) end
					across l_results as r loop l_new_faq.add_source (r.title) end
					faq_store.store_faq (l_new_faq)
					Result.set_ai_note ("New FAQ #" + l_new_faq.id.out)
				else
					if attached l_response.error_message as e then
						Result.set_ai_note ("Synthesis failed: " + e.out)
					end
				end
			else
				Result.set_ai_note ("No KB results for: " + a_keywords.out)
			end
		end

	build_kb_context (a_results: ARRAYED_LIST [KB_RESULT]): STRING_32
		local
			i: INTEGER
		do
			create Result.make (2000)
			from i := 1 until i > a_results.count.min (5) loop
				Result.append ("--- " + a_results [i].title + " ---%N")
				Result.append (a_results [i].snippet + "%N%N")
				i := i + 1
			end
		end

feature {NONE} -- AI Client

	create_ai_client: detachable AI_CLIENT
		do
			if attached ai_config.active_provider as p then
				if p.same_string ("claude") then
					if attached ai_config.provider_api_key ("claude") as k then
						create {CLAUDE_CLIENT} Result.make_with_api_key (k)
					end
				elseif p.same_string ("ollama") then
					create {OLLAMA_CLIENT} Result.make
				elseif p.same_string ("grok") then
					if attached ai_config.provider_api_key ("grok") as k then
						create {GROK_CLIENT} Result.make_with_api_key (k)
					end
				end
			end
		end

feature {NONE} -- Prompts

	keyword_prompt: STRING_32
		once
			Result := {STRING_32} "TASK: Extract FTS5 search terms from Eiffel question. Return ONLY UPPER_SNAKE_CASE class names separated by OR. No explanations. 1-3 terms. Examples: JSON->SIMPLE_JSON, HTTP->SIMPLE_HTTP, files->SIMPLE_FILE. SEARCH TERMS ONLY:"
		end

	synthesis_prompt: STRING_32
		once
			Result := {STRING_32} "You are an Eiffel expert. Answer using ONLY the provided context. Be concise. Include class names and code examples."
		end

	faq_prompt: STRING_32
		once
			Result := {STRING_32} "You are an Eiffel expert. Answer the NEW question using the previous Q&A pairs. Synthesize a cohesive answer. Be concise."
		end

feature {NONE} -- Sanitization

	sanitize_keywords (a_raw: STRING_32): STRING_32
		local
			l_words: LIST [STRING_32]
			l_word, l_clean: STRING_32
		do
			create Result.make (a_raw.count)
			l_words := a_raw.split (' ')
			from l_words.start until l_words.after loop
				l_word := l_words.item
				l_word.left_adjust
				l_word.right_adjust
				if not l_word.is_empty then
					l_clean := extract_upper (l_word)
					if not l_clean.is_empty then
						if Result.count > 0 then Result.append (" ") end
						Result.append (l_clean)
					elseif l_word.same_string ("OR") and Result.count > 0 then
						Result.append (" OR")
					end
				end
				l_words.forth
			end
		end

	extract_upper (a_word: STRING_32): STRING_32
		local
			i: INTEGER
			c: CHARACTER_32
		do
			create Result.make (a_word.count)
			from i := 1 until i > a_word.count loop
				c := a_word.item (i)
				if c.is_upper or c = '_' or c.is_digit then
					Result.append_character (c)
				end
				i := i + 1
			end
		end

invariant
	db_not_void: db /= Void
	ai_config_not_void: ai_config /= Void
	faq_store_not_void: faq_store /= Void

end
