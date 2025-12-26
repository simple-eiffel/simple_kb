note
	description: "[
		KB_MBOX_INGESTER - Convert Mbox Messages to FAQs
		
		Processes mbox files to extract Q&A pairs:
		1. Parse mbox file into messages
		2. Group messages into threads (via In-Reply-To/References)
		3. Identify question/answer pairs
		4. Store as FAQs in the knowledge base
	]"
	author: "Simple Eiffel"

class
	KB_MBOX_INGESTER

create
	make

feature {NONE} -- Initialization

	make (a_faq_store: KB_FAQ_STORE)
		require
			store_not_void: a_faq_store /= Void
		do
			faq_store := a_faq_store
			create parser.make
			create threads.make (100)
			imported_count := 0
			skipped_count := 0
		end

feature -- Access

	faq_store: KB_FAQ_STORE
	parser: KB_MBOX_PARSER
	threads: HASH_TABLE [ARRAYED_LIST [KB_MBOX_MESSAGE], STRING_32]
	imported_count: INTEGER
	skipped_count: INTEGER

feature -- Import

	import_file (a_path: STRING_32; a_verbose: BOOLEAN)
			-- Import mbox file and create FAQs
		local
			l_qa_pairs: ARRAYED_LIST [TUPLE [q: KB_MBOX_MESSAGE; a: KB_MBOX_MESSAGE]]
		do
			imported_count := 0
			skipped_count := 0

			if a_verbose then
				io.put_string ("Parsing mbox file...%N")
			end
			parser.parse_file (a_path)

			if a_verbose then
				io.put_string ("Found " + parser.message_count.out + " messages%N")
			end

			if a_verbose then
				io.put_string ("Building threads...%N")
			end
			build_threads

			if a_verbose then
				io.put_string ("Found " + threads.count.out + " threads%N")
			end

			if a_verbose then
				io.put_string ("Extracting Q&A pairs...%N")
			end
			l_qa_pairs := extract_qa_pairs

			if a_verbose then
				io.put_string ("Found " + l_qa_pairs.count.out + " Q&A pairs%N")
				io.put_string ("Storing FAQs...%N")
			end

			across l_qa_pairs as pair loop
				store_qa_pair (pair.q, pair.a, a_verbose)
			end

			if a_verbose then
				io.put_string ("Done! Imported: " + imported_count.out + ", Skipped: " + skipped_count.out + "%N")
			end
		end

feature {NONE} -- Threading

	build_threads
			-- Group messages into conversation threads
		local
			l_thread_id: STRING_32
			l_thread: ARRAYED_LIST [KB_MBOX_MESSAGE]
		do
			threads.wipe_out

			across parser.messages as msg loop
				l_thread_id := get_thread_id (msg)

				if threads.has (l_thread_id) then
					if attached threads.item (l_thread_id) as l_existing then l_existing.extend (msg) end
				else
					create l_thread.make (5)
					l_thread.extend (msg)
					threads.force (l_thread, l_thread_id)
				end
			end
		end

	get_thread_id (a_msg: KB_MBOX_MESSAGE): STRING_32
			-- Get thread identifier for message
		do
			if not a_msg.in_reply_to.is_empty then
				Result := a_msg.in_reply_to
			elseif not a_msg.references.is_empty then
				Result := a_msg.references.first
			elseif not a_msg.message_id.is_empty then
				Result := a_msg.message_id
			else
				Result := a_msg.clean_subject.as_lower
			end
		end

feature {NONE} -- Q&A Extraction

	extract_qa_pairs: ARRAYED_LIST [TUPLE [q: KB_MBOX_MESSAGE; a: KB_MBOX_MESSAGE]]
			-- Find question/answer pairs from threads
		local
			l_question: detachable KB_MBOX_MESSAGE
			l_best_answer: detachable KB_MBOX_MESSAGE
			l_answer_score, l_best_score: INTEGER
		do
			create Result.make (threads.count)

			across threads as thread loop
				l_question := Void
				l_best_answer := Void
				l_best_score := 0

				across thread as msg loop
					if l_question = Void and then msg.is_question and then not msg.is_reply then
						l_question := msg
					end
				end

				if attached l_question as q then
					across thread as msg loop
						if msg.is_reply then
							l_answer_score := score_answer (msg)
							if l_answer_score > l_best_score then
								l_best_score := l_answer_score
								l_best_answer := msg
							end
						end
					end

					if attached l_best_answer as a and then l_best_score > 10 then
						Result.extend ([q, a])
					end
				end
			end
		end

	score_answer (a_msg: KB_MBOX_MESSAGE): INTEGER
			-- Score an answer based on quality indicators
		local
			l_body: STRING_32
		do
			l_body := a_msg.body
			Result := 0

			Result := Result + (l_body.count // 100).min (20)

			if l_body.has_substring ("class ") then Result := Result + 10 end
			if l_body.has_substring ("feature") then Result := Result + 10 end
			if l_body.has_substring ("do") then Result := Result + 5 end
			if l_body.has_substring ("end") then Result := Result + 5 end
			if l_body.has_substring ("```") then Result := Result + 15 end
			if l_body.has_substring ("you can") then Result := Result + 5 end
			if l_body.has_substring ("example") then Result := Result + 5 end

			if l_body.count < 50 then Result := Result - 10 end
		end

feature {NONE} -- Storage

	store_qa_pair (a_question, a_answer: KB_MBOX_MESSAGE; a_verbose: BOOLEAN)
			-- Create and store FAQ from Q&A pair
		local
			l_faq: KB_FAQ
			l_q_text, l_a_text: STRING_32
		do
			l_q_text := a_question.clean_subject
			if l_q_text.count < 10 then
				l_q_text := a_question.body.substring (1, a_question.body.count.min (200))
				l_q_text.right_adjust
				if l_q_text.index_of ('?', 1) > 0 then
					l_q_text := l_q_text.substring (1, l_q_text.index_of ('?', 1))
				end
			end

			l_a_text := clean_answer_body (a_answer.body)

			if l_q_text.count < 10 or l_a_text.count < 30 then
				skipped_count := skipped_count + 1
				if a_verbose then
					io.put_string ("  Skipped (too short): " + l_q_text.head (50).out + "%N")
				end
			else
				create l_faq.make (l_q_text, l_a_text)
				l_faq.set_source_origin ("eiffel-users")
				l_faq.add_tag ("mailing-list")
				l_faq.add_tag ("community")
				l_faq.set_keywords (extract_keywords (l_q_text + " " + l_a_text))

				faq_store.store_faq (l_faq)
				imported_count := imported_count + 1

				if a_verbose then
					io.put_string ("  Imported: " + l_q_text.head (60).out + "%N")
				end
			end
		end

	clean_answer_body (a_body: STRING_32): STRING_32
			-- Clean up email body for FAQ storage
		do
			Result := a_body.twin
			remove_quoted_text (Result)
			Result.left_adjust
			Result.right_adjust

			if Result.count > 2000 then
				Result := Result.substring (1, 2000)
				Result.append ("...")
			end
		end

	remove_quoted_text (a_text: STRING_32)
			-- Remove lines starting with > (quoted text)
		local
			l_lines: LIST [STRING_32]
			l_result: STRING_32
		do
			l_lines := a_text.split ('%N')
			create l_result.make (a_text.count)
			across l_lines as line loop
				line.left_adjust
				if not line.starts_with (">") and not line.starts_with ("On ") then
					l_result.append (line)
					l_result.append ("%N")
				end
			end
			a_text.wipe_out
			a_text.append (l_result)
		end

	extract_keywords (a_text: STRING_32): STRING_32
			-- Extract keywords from text
		local
			l_words: LIST [STRING_32]
			l_word: STRING_32
			l_seen: HASH_TABLE [BOOLEAN, STRING_32]
		do
			create Result.make (100)
			create l_seen.make (20)
			l_words := a_text.as_lower.split (' ')

			across l_words as w loop
				l_word := w.twin
				l_word.prune_all ('?')
				l_word.prune_all ('.')
				l_word.prune_all (',')

				if l_word.count >= 4 and then not is_stopword (l_word) and then not l_seen.has (l_word) then
					l_seen.force (True, l_word)
					if Result.count > 0 then Result.append (" ") end
					Result.append (l_word)
				end
			end
		end

	is_stopword (a_word: STRING_32): BOOLEAN
		do
			Result := a_word.same_string ("the") or else
				a_word.same_string ("and") or else
				a_word.same_string ("for") or else
				a_word.same_string ("that") or else
				a_word.same_string ("this") or else
				a_word.same_string ("with") or else
				a_word.same_string ("from")
		end

invariant
	faq_store_not_void: faq_store /= Void

end