note
	description: "[
		KB_MBOX_MESSAGE - Single Email Message from Mbox
		
		Represents one email from an mbox file with:
		- Headers (from, to, subject, date, message-id, in-reply-to)
		- Body text
		- Thread detection via In-Reply-To and References
	]"
	author: "Simple Eiffel"

class
	KB_MBOX_MESSAGE

create
	make

feature {NONE} -- Initialization

	make
		do
			create message_id.make_empty
			create subject.make_empty
			create from_addr.make_empty
			create from_name.make_empty
			create date_str.make_empty
			create body.make_empty
			create in_reply_to.make_empty
			create references.make (3)
		end

feature -- Access

	message_id: STRING_32
	subject: STRING_32
	from_addr: STRING_32
	from_name: STRING_32
	date_str: STRING_32
	body: STRING_32
	in_reply_to: STRING_32
	references: ARRAYED_LIST [STRING_32]

feature -- Status

	is_question: BOOLEAN
			-- Does this look like a question?
		do
			Result := subject.has ('?') or else
				body.substring (1, body.count.min (500)).has ('?') or else
				subject.as_lower.has_substring ("how") or else
				subject.as_lower.has_substring ("what") or else
				subject.as_lower.has_substring ("why") or else
				subject.as_lower.has_substring ("help")
		end

	is_reply: BOOLEAN
			-- Is this a reply to another message?
		do
			Result := not in_reply_to.is_empty or else
				subject.as_lower.has_substring ("re:")
		end

	clean_subject: STRING_32
			-- Subject without Re: prefixes
		do
			Result := subject.twin
			Result.left_adjust
			if Result.as_lower.starts_with ("re:") then
				Result := Result.substring (4, Result.count)
				Result.left_adjust
			end
			-- Recurse for multiple Re: Re:
			if Result.as_lower.starts_with ("re:") then
				Result := Result.substring (4, Result.count)
				Result.left_adjust
			end
		end

feature -- Setters

	set_message_id (a_v: STRING_32) do message_id := v.twin end
	set_subject (a_v: STRING_32) do subject := v.twin end
	set_from_addr (a_v: STRING_32) do from_addr := v.twin end
	set_from_name (a_v: STRING_32) do from_name := v.twin end
	set_date_str (a_v: STRING_32) do date_str := v.twin end
	set_body (a_v: STRING_32) do body := v.twin end
	set_in_reply_to (a_v: STRING_32) do in_reply_to := v.twin end

	add_reference (a_v: STRING_32)
		do
			references.extend (a_v.twin)
		end

	append_body (a_v: STRING_32)
		do
			body.append (a_v)
		end

feature -- Output

	summary: STRING_32
			-- Short summary for display
		do
			create Result.make (200)
			Result.append ("From: " + from_name)
			if not from_addr.is_empty then
				Result.append (" <" + from_addr + ">")
			end
			Result.append ("%NSubject: " + subject)
			Result.append ("%NDate: " + date_str)
			if is_question then
				Result.append (" [QUESTION]")
			end
			if is_reply then
				Result.append (" [REPLY]")
			end
		end

end
