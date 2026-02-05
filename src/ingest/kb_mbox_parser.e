note
	description: "[
		KB_MBOX_PARSER - Parse Mbox Email Archives
		
		Parses standard mbox format (RFC 4155) where:
		- Messages start with 'From ' at line beginning
		- Headers follow until blank line
		- Body continues until next 'From ' line
		
		Google Takeout exports Groups data in mbox format.
	]"
	author: "Simple Eiffel"

class
	KB_MBOX_PARSER

create
	make

feature {NONE} -- Initialization

	make
		do
			create messages.make (100)
			create parse_errors.make (10)
		end

feature -- Access

	messages: ARRAYED_LIST [KB_MBOX_MESSAGE]
			-- Parsed messages

	parse_errors: ARRAYED_LIST [STRING_32]
			-- Any parse errors encountered

	message_count: INTEGER
		do
			Result := messages.count
		end

feature -- Parsing

	parse_file (a_path: STRING_32)
			-- Parse mbox file at path
		local
			l_file: PLAIN_TEXT_FILE
			l_line: STRING
			l_current_msg: detachable KB_MBOX_MESSAGE
			l_in_headers: BOOLEAN
			l_line_32: STRING_32
		do
			messages.wipe_out
			parse_errors.wipe_out

			create l_file.make_with_name (a_path)
			if l_file.exists and then l_file.is_readable then
				l_file.open_read
				from
					l_file.read_line
				until
					l_file.exhausted
				loop
					l_line := l_file.last_string.twin
					l_line_32 := l_line.to_string_32

					if l_line.starts_with ("From ") and then is_mbox_from_line (l_line) then
						-- New message starts
						if attached l_current_msg as al_msg then
							finalize_message (msg)
							messages.extend (msg)
						end
						create l_current_msg.make
						l_in_headers := True
					elseif attached l_current_msg as al_msg then
						if l_in_headers then
							if l_line.is_empty then
								l_in_headers := False
							else
								parse_header (msg, l_line_32)
							end
						else
							-- Body line
							msg.append_body (l_line_32 + "%N")
						end
					end

					l_file.read_line
				end
				-- Don't forget last message
				if attached l_current_msg as al_msg then
					finalize_message (msg)
					messages.extend (msg)
				end
				l_file.close
			else
				parse_errors.extend ("Cannot read file: " + a_path)
			end
		end

feature {NONE} -- Implementation

	is_mbox_from_line (a_line: STRING): BOOLEAN
			-- Is this a valid mbox 'From ' separator line?
			-- Format: "From sender@email.com Day Mon DD HH:MM:SS YYYY"
		do
			-- Simple heuristic: contains @ and has reasonable length
			Result := a_line.count > 20 and then a_line.has ('@')
		end

	parse_header (a_msg: KB_MBOX_MESSAGE; a_line: STRING_32)
			-- Parse a header line into message
		local
			l_colon: INTEGER
			l_name, l_value: STRING_32
		do
			l_colon := a_line.index_of (':', 1)
			if l_colon > 1 then
				l_name := a_line.substring (1, l_colon - 1).as_lower
				l_value := a_line.substring (l_colon + 1, a_line.count)
				l_value.left_adjust
				l_value.right_adjust

				if l_name.same_string ("subject") then
					a_msg.set_subject (decode_header (l_value))
				elseif l_name.same_string ("from") then
					parse_from_header (a_msg, l_value)
				elseif l_name.same_string ("date") then
					a_msg.set_date_str (l_value)
				elseif l_name.same_string ("message-id") then
					a_msg.set_message_id (extract_angle_brackets (l_value))
				elseif l_name.same_string ("in-reply-to") then
					a_msg.set_in_reply_to (extract_angle_brackets (l_value))
				elseif l_name.same_string ("references") then
					parse_references (a_msg, l_value)
				end
			end
		end

	parse_from_header (a_msg: KB_MBOX_MESSAGE; a_value: STRING_32)
			-- Parse "Name <email>" or "email (Name)" format
		local
			l_lt, l_gt: INTEGER
		do
			l_lt := a_value.index_of ('<', 1)
			l_gt := a_value.index_of ('>', 1)
			if l_lt > 0 and l_gt > l_lt then
				if l_lt > 1 then
					a_msg.set_from_name (a_value.substring (1, l_lt - 1).twin)
					a_msg.from_name.right_adjust
				end
				a_msg.set_from_addr (a_value.substring (l_lt + 1, l_gt - 1))
			else
				a_msg.set_from_addr (a_value)
			end
		end

	parse_references (a_msg: KB_MBOX_MESSAGE; a_value: STRING_32)
			-- Parse space-separated message IDs in References header
		local
			l_parts: LIST [STRING_32]
		do
			l_parts := a_value.split (' ')
			across l_parts as p loop
				if p.has ('@') then
					a_msg.add_reference (extract_angle_brackets (p))
				end
			end
		end

	extract_angle_brackets (a_value: STRING_32): STRING_32
			-- Extract content from <...>
		local
			l_lt, l_gt: INTEGER
		do
			l_lt := a_value.index_of ('<', 1)
			l_gt := a_value.index_of ('>', 1)
			if l_lt > 0 and l_gt > l_lt then
				Result := a_value.substring (l_lt + 1, l_gt - 1)
			else
				Result := a_value.twin
			end
		end

	decode_header (a_value: STRING_32): STRING_32
			-- Decode RFC 2047 encoded headers (basic support)
			-- e.g., =?UTF-8?Q?Hello?= or =?UTF-8?B?SGVsbG8=?=
		do
			-- For now, just strip encoding markers
			-- Full RFC 2047 decoding would need more work
			Result := a_value.twin
			if Result.has_substring ("=?") then
				-- Basic cleanup - remove encoding wrappers
				Result.replace_substring_all ("=?UTF-8?Q?", "")
				Result.replace_substring_all ("=?utf-8?Q?", "")
				Result.replace_substring_all ("=?UTF-8?B?", "")
				Result.replace_substring_all ("?=", "")
				Result.replace_substring_all ("_", " ")
			end
		end

	finalize_message (a_msg: KB_MBOX_MESSAGE)
			-- Clean up message after parsing
		do
			-- Trim trailing whitespace from body
			a_msg.body.right_adjust
		end

end
