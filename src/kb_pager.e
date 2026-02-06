note
	description: "[
		KB_PAGER - Paginated Output Handler

		Shows long output N l_lines at a time with interactive continuation.

		Usage:
			pager: KB_PAGER
			create pager.make (20)  -- 20 l_lines per page
			pager.show (long_text)

		User interaction:
			c/C/Enter = l_continue to next page
			q/Q/blank line = stop and return
	]"
	author: "Simple Eiffel"

class
	KB_PAGER

create
	make

feature {NONE} -- Initialization

	make (a_page_size: INTEGER)
			-- Create pager with specified lines per page
		require
			positive_size: a_page_size > 0
		do
			page_size := a_page_size
			enabled := True
		ensure
			size_set: page_size = a_page_size
		end

feature -- Access

	page_size: INTEGER
			-- Lines to show per page

	enabled: BOOLEAN
			-- Is paging enabled?

feature -- Settings

	set_page_size (a_size: INTEGER)
			-- Set lines per page
		require
			positive_size: a_size > 0
		do
			page_size := a_size
		ensure
			size_set: page_size = a_size
		end

	enable
			-- Turn paging on
		do
			enabled := True
		ensure
			enabled: enabled
		end

	disable
			-- Turn paging off (show all at once)
		do
			enabled := False
		ensure
			disabled: not enabled
		end

feature -- Output

	show (a_text: READABLE_STRING_GENERAL)
			-- Show text with pagination
		local
			l_lines: LIST [STRING_8]
			l_line_num, l_page_count: INTEGER
			l_continue: BOOLEAN
			l_input: STRING
		do
			if not enabled then
				io.put_string (a_text.out)
			else
				l_lines := a_text.out.split ('%N')
				l_page_count := 0
				l_line_num := 0
				l_continue := True

				from l_lines.start until l_lines.after or not l_continue loop
					io.put_string (l_lines.item.out)
					io.put_new_line
					l_line_num := l_line_num + 1
					l_page_count := l_page_count + 1

					if l_page_count >= page_size and not l_lines.islast then
						-- Prompt for continuation
						io.put_string ("-- [c]ontinue, [Enter] to stop (" + l_line_num.out + "/" + l_lines.count.out + " lines) --")
						io.read_line
						l_input := io.last_string.twin
						l_input.left_adjust
						l_input.right_adjust
						l_input.to_lower

						if l_input.is_empty then
							-- Enter pressed - stop
							l_continue := False
						elseif l_input.same_string ("q") then
							l_continue := False
						else
							-- Any other input (c, C, or anything) continues
							l_page_count := 0
							-- Clear the prompt line
							io.put_string ("%R                                                  %R")
						end
					end

					l_lines.forth
				end
			end
		end

	show_lines (a_lines: LIST [STRING_32])
			-- Show list of lines with pagination
		local
			l_line_num, l_page_count: INTEGER
			l_continue: BOOLEAN
			l_input: STRING
		do
			if not enabled then
				across a_lines as line loop
					io.put_string (line.out)
					io.put_new_line
				end
			else
				l_page_count := 0
				l_line_num := 0
				l_continue := True

				from a_lines.start until a_lines.after or not l_continue loop
					io.put_string (a_lines.item.out)
					io.put_new_line
					l_line_num := l_line_num + 1
					l_page_count := l_page_count + 1

					if l_page_count >= page_size and not a_lines.islast then
						io.put_string ("-- [c]ontinue, [Enter] to stop (" + l_line_num.out + "/" + a_lines.count.out + " lines) --")
						io.read_line
						l_input := io.last_string.twin
						l_input.left_adjust
						l_input.right_adjust
						l_input.to_lower

						if l_input.is_empty or l_input.same_string ("q") then
							l_continue := False
						else
							l_page_count := 0
							io.put_string ("%R                                                  %R")
						end
					end

					a_lines.forth
				end
			end
		end

invariant
	positive_page_size: page_size > 0

end
