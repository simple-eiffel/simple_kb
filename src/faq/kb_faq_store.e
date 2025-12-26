note
	description: "KB_FAQ_STORE - FAQ Storage and Retrieval"
	author: "Simple Eiffel"

class
	KB_FAQ_STORE

create
	make

feature {NONE} -- Initialization

	make (a_db: SIMPLE_SQL_DATABASE)
		require
			db_not_void: a_db /= Void
		do
			db := a_db
			current_kb_version := 1
		end

feature -- Access

	db: SIMPLE_SQL_DATABASE
	current_kb_version: INTEGER

feature -- Queries

	search_faqs (a_keywords: STRING_32; a_limit: INTEGER): ARRAYED_LIST [KB_FAQ]
		require
			keywords_not_empty: not a_keywords.is_empty
			positive_limit: a_limit > 0
		local
			l_result: SIMPLE_SQL_RESULT
			l_faq: KB_FAQ
			l_fts_query: STRING_32
		do
			create Result.make (a_limit)
			l_fts_query := format_fts5_query (a_keywords)
			l_result := db.query_with_args (
				"SELECT f.* FROM faqs f " +
				"JOIN faq_search fs ON f.id = CAST(fs.faq_id AS INTEGER) " +
				"WHERE faq_search MATCH ? " +
				"ORDER BY bm25(faq_search), f.hit_count DESC " +
				"LIMIT " + a_limit.out,
				<<l_fts_query>>)
			across l_result.rows as row loop
				create l_faq.make_from_row (row)
				Result.extend (l_faq)
			end
		end

	search_by_tags (a_tags: ARRAYED_LIST [STRING_32]; a_limit: INTEGER): ARRAYED_LIST [KB_FAQ]
		require
			tags_not_empty: not a_tags.is_empty
			positive_limit: a_limit > 0
		local
			l_result: SIMPLE_SQL_RESULT
			l_faq: KB_FAQ
			l_placeholders: STRING
			l_args: ARRAY [ANY]
			i: INTEGER
		do
			create Result.make (a_limit)
			create l_placeholders.make (a_tags.count * 2)
			from i := 1 until i > a_tags.count loop
				if i > 1 then l_placeholders.append (",") end
				l_placeholders.append ("?")
				i := i + 1
			end
			create l_args.make_filled ("", 1, a_tags.count)
			from i := 1 until i > a_tags.count loop
				l_args [i] := a_tags [i]
				i := i + 1
			end
			l_result := db.query_with_args (
				"SELECT DISTINCT f.* FROM faqs f " +
				"JOIN faq_tags ft ON f.id = ft.faq_id " +
				"WHERE ft.tag IN (" + l_placeholders + ") " +
				"ORDER BY f.hit_count DESC LIMIT " + a_limit.out,
				l_args)
			across l_result.rows as row loop
				create l_faq.make_from_row (row)
				Result.extend (l_faq)
			end
		end

	faq_count: INTEGER
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := db.query ("SELECT COUNT(*) as cnt FROM faqs")
			if not l_result.rows.is_empty then
				Result := l_result.rows.first.integer_value ("cnt")
			end
		end

	recent_faqs (a_limit: INTEGER): ARRAYED_LIST [KB_FAQ]
			-- Get most recent FAQs
		require
			positive_limit: a_limit > 0
		local
			l_result: SIMPLE_SQL_RESULT
			l_faq: KB_FAQ
		do
			create Result.make (a_limit)
			l_result := db.query_with_args (
				"SELECT * FROM faqs ORDER BY id DESC LIMIT ?",
				<<a_limit>>
			)
			across l_result.rows as row loop
				create l_faq.make_from_row (row)
				Result.extend (l_faq)
			end
		end

feature -- Commands

	store_faq (a_faq: KB_FAQ)
		require
			faq_not_void: a_faq /= Void
			not_persisted: not a_faq.is_persisted
		local
			l_result: SIMPLE_SQL_RESULT
			l_id: INTEGER
		do
			db.execute_with_args (
				"INSERT INTO faqs (question, keywords, answer, sources, tags, kb_version) " +
				"VALUES (?, ?, ?, ?, ?, ?)",
				<<a_faq.question, a_faq.keywords, a_faq.answer,
				  a_faq.sources_as_json, a_faq.tags_as_json, current_kb_version>>)
			l_result := db.query ("SELECT last_insert_rowid() as id")
			if not l_result.rows.is_empty then
				l_id := l_result.rows.first.integer_value ("id")
				a_faq.set_id (l_id)
				across a_faq.tags as tag loop
					db.execute_with_args (
						"INSERT OR IGNORE INTO faq_tags (faq_id, tag) VALUES (?, ?)",
						<<l_id, tag>>)
				end
				db.execute_with_args (
					"INSERT INTO faq_search (faq_id, question, answer, keywords, tags) " +
					"VALUES (?, ?, ?, ?, ?)",
					<<l_id.out, a_faq.question, a_faq.answer, a_faq.keywords, a_faq.tags_as_json>>)
			end
		end

	record_hit (a_faq: KB_FAQ)
		require
			faq_persisted: a_faq.is_persisted
		do
			a_faq.increment_hit_count
			db.execute_with_args (
				"UPDATE faqs SET hit_count = hit_count + 1 WHERE id = ?",
				<<a_faq.id>>)
		end

	bump_kb_version
		do
			current_kb_version := current_kb_version + 1
		end

	has_faq (a_id: INTEGER): BOOLEAN
			-- Does FAQ with this ID exist?
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := db.query_with_args (
				"SELECT id FROM faqs WHERE id = ?", <<a_id>>)
			Result := not l_result.rows.is_empty
		end

	delete_faq (a_id: INTEGER)
			-- Delete FAQ by ID
		require
			faq_exists: has_faq (a_id)
		do
			-- Delete from FTS index first
			db.execute_with_args ("DELETE FROM faq_search WHERE faq_id = ?", <<a_id.out>>)
			-- Delete from tags
			db.execute_with_args ("DELETE FROM faq_tags WHERE faq_id = ?", <<a_id>>)
			-- Delete the FAQ
			db.execute_with_args ("DELETE FROM faqs WHERE id = ?", <<a_id>>)
		end

	delete_all
			-- Delete all FAQs
		do
			db.execute ("DELETE FROM faq_search")
			db.execute ("DELETE FROM faq_tags")
			db.execute ("DELETE FROM faqs")
		end

feature {NONE} -- Implementation

	format_fts5_query (a_query: STRING_32): STRING_32
		local
			l_words: LIST [STRING_32]
			l_word: STRING_32
		do
			create Result.make (a_query.count + 20)
			l_words := a_query.split (' ')
			from l_words.start until l_words.after loop
				l_word := l_words.item
				l_word.left_adjust
				l_word.right_adjust
				if not l_word.is_empty then
					if Result.count > 0 then Result.append (" OR ") end
					Result.append (l_word)
					Result.append_character ('*')
				end
				l_words.forth
			end
			if Result.is_empty then
				Result.append_string_general (a_query)
				Result.append_character ('*')
			end
		end

invariant
	db_not_void: db /= Void

end
