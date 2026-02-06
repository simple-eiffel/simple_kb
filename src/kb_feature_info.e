note
	description: "[
		KB_FEATURE_INFO - Feature Metadata Model

		Stores information about an Eiffel feature (routine or attribute)
		extracted from source files. Includes signature, contracts, and kind.
	]"
	author: "Simple Eiffel"
	date: "$Date$"
	revision: "$Revision$"

class
	KB_FEATURE_INFO

create
	make,
	make_from_row

feature {NONE} -- Initialization

	make (a_class_id: INTEGER; a_name: READABLE_STRING_GENERAL)
			-- Create feature info
		require
			name_not_empty: not a_name.is_empty
		do
			class_id := a_class_id
			name := a_name.to_string_32
			create signature.make_empty
			create description.make_empty
			create kind.make_from_string ("query")
			create preconditions.make (2)
			create postconditions.make (2)
		ensure
			class_id_set: class_id = a_class_id
			name_set: name.same_string_general (a_name)
		end

	make_from_row (a_row: SIMPLE_SQL_ROW)
			-- Create from database row
		require
			row_not_void: a_row /= Void
		do
			if attached a_row.item (1) as al_val then
				id := al_val.out.to_integer
			end
			class_id := a_row.integer_value ("class_id")
			name := a_row.string_value ("name")
			signature := a_row.string_value ("signature")
			description := a_row.string_value ("description")
			kind := a_row.string_value ("kind")
			is_deferred := a_row.integer_value ("is_deferred") = 1
			is_frozen := a_row.integer_value ("is_frozen") = 1
			is_once := a_row.integer_value ("is_once") = 1
			create preconditions.make (2)
			create postconditions.make (2)

			-- Parse JSON arrays
			parse_contracts (a_row.string_value ("preconditions"), True)
			parse_contracts (a_row.string_value ("postconditions"), False)
		end

feature -- Access

	id: INTEGER
			-- Database ID

	class_id: INTEGER
			-- Parent class ID

	name: STRING_32
			-- Feature name

	signature: STRING_32
			-- Full signature (e.g., "(text: STRING): JSON_OBJECT")

	description: STRING_32
			-- Feature description from comment

	kind: STRING_32
			-- Kind: 'query', 'command', 'creation', 'attribute'

	is_deferred: BOOLEAN
			-- Is this a deferred (abstract) feature?

	is_frozen: BOOLEAN
			-- Is this a frozen (non-overridable) feature?

	is_once: BOOLEAN
			-- Is this a once (cached) feature?

	preconditions: ARRAYED_LIST [TUPLE [tag, expression: STRING_32]]
			-- Precondition contracts

	postconditions: ARRAYED_LIST [TUPLE [tag, expression: STRING_32]]
			-- Postcondition contracts

feature -- Setters

	set_id (a_id: INTEGER)
			-- Set database ID
		do
			id := a_id
		end

	set_signature (a_sig: READABLE_STRING_GENERAL)
			-- Set signature
		do
			signature := a_sig.to_string_32
		end

	set_description (a_desc: READABLE_STRING_GENERAL)
			-- Set description
		do
			description := a_desc.to_string_32
		end

	set_kind (a_kind: READABLE_STRING_GENERAL)
			-- Set kind
		require
			valid_kind: a_kind.same_string ("query") or a_kind.same_string ("command")
				or a_kind.same_string ("creation") or a_kind.same_string ("attribute")
		do
			kind := a_kind.to_string_32
		end

	add_precondition (a_tag, a_expr: READABLE_STRING_GENERAL)
			-- Add precondition
		do
			preconditions.extend ([a_tag.to_string_32, a_expr.to_string_32])
		end

	add_postcondition (a_tag, a_expr: READABLE_STRING_GENERAL)
			-- Add postcondition
		do
			postconditions.extend ([a_tag.to_string_32, a_expr.to_string_32])
		end

	set_deferred (a_val: BOOLEAN)
			-- Set deferred status
		do
			is_deferred := a_val
		end

	set_frozen (a_val: BOOLEAN)
			-- Set frozen status
		do
			is_frozen := a_val
		end

	set_once (a_val: BOOLEAN)
			-- Set once status
		do
			is_once := a_val
		end

feature -- Status

	is_valid: BOOLEAN
			-- Is this a valid feature entry?
		do
			Result := class_id > 0 and not name.is_empty
		end

	is_query: BOOLEAN
			-- Is this a query?
		do
			Result := kind.same_string ("query")
		end

	is_command: BOOLEAN
			-- Is this a command?
		do
			Result := kind.same_string ("command")
		end

	is_creation: BOOLEAN
			-- Is this a creation procedure?
		do
			Result := kind.same_string ("creation")
		end

feature -- JSON Serialization

	preconditions_json: STRING_32
			-- Preconditions as JSON array
		local
			l_first: BOOLEAN
		do
			create Result.make (100)
			Result.append_character ('[')
			l_first := True
			across preconditions as ic loop
				if not l_first then
					Result.append_character (',')
				end
				Result.append ("{%"tag%":%"")
				Result.append (escape_json (ic.tag))
				Result.append ("%",%"expression%":%"")
				Result.append (escape_json (ic.expression))
				Result.append ("%"}")
				l_first := False
			end
			Result.append_character (']')
		end

	postconditions_json: STRING_32
			-- Postconditions as JSON array
		local
			l_first: BOOLEAN
		do
			create Result.make (100)
			Result.append_character ('[')
			l_first := True
			across postconditions as ic loop
				if not l_first then
					Result.append_character (',')
				end
				Result.append ("{%"tag%":%"")
				Result.append (escape_json (ic.tag))
				Result.append ("%",%"expression%":%"")
				Result.append (escape_json (ic.expression))
				Result.append ("%"}")
				l_first := False
			end
			Result.append_character (']')
		end

feature -- Display

	formatted: STRING_32
			-- Formatted display
		do
			create Result.make (200)
			Result.append (name)
			if not signature.is_empty then
				Result.append (" ")
				Result.append (signature)
			end
			if not description.is_empty then
				Result.append ("%N    -- ")
				Result.append (description)
			end
			if not preconditions.is_empty then
				Result.append ("%N    require")
				across preconditions as ic loop
					Result.append ("%N      ")
					Result.append (ic.tag)
					Result.append (": ")
					Result.append (ic.expression)
				end
			end
			if not postconditions.is_empty then
				Result.append ("%N    ensure")
				across postconditions as ic loop
					Result.append ("%N      ")
					Result.append (ic.tag)
					Result.append (": ")
					Result.append (ic.expression)
				end
			end
		end

feature {NONE} -- Parsing

	parse_contracts (a_json: READABLE_STRING_GENERAL; a_is_pre: BOOLEAN)
			-- Parse contracts from JSON using simple_json
		local
			l_json: SIMPLE_JSON
			l_value: detachable SIMPLE_JSON_VALUE
			l_arr: SIMPLE_JSON_ARRAY
			l_item: SIMPLE_JSON_VALUE
			l_obj: SIMPLE_JSON_OBJECT
			l_tag, l_expr: STRING_32
			i: INTEGER
		do
			if a_is_pre then
				create preconditions.make (2)
			else
				create postconditions.make (2)
			end

			if not a_json.is_empty then
				create l_json
				l_value := l_json.parse (a_json.to_string_32)
				if attached l_value as val and then val.is_array then
					l_arr := val.array_value
					from i := 1 until i > l_arr.count loop
						l_item := l_arr [i]
						if l_item.is_object then
							l_obj := l_item.object_value
							l_tag := safe_string (l_obj.string_item ("tag"))
							l_expr := safe_string (l_obj.string_item ("expression"))
							if a_is_pre then
								preconditions.extend ([l_tag, l_expr])
							else
								postconditions.extend ([l_tag, l_expr])
							end
						end
						i := i + 1
					end
				end
			end
		end

	escape_json (a_str: STRING_32): STRING_32
			-- Escape string for JSON
		do
			create Result.make (a_str.count + 10)
			across a_str as ic loop
				inspect ic
				when '"' then
					Result.append ("\%"")
				when '\' then
					Result.append ("\\")
				when '%N' then
					Result.append ("\n")
				when '%R' then
					Result.append ("\r")
				when '%T' then
					Result.append ("\t")
				else
					Result.append_character (ic)
				end
			end
		end

	safe_string (a_val: detachable STRING_32): STRING_32
			-- Convert detachable to attached string
		do
			if attached a_val as al_v then
				Result := al_v
			else
				create Result.make_empty
			end
		end

invariant
	name_not_empty: not name.is_empty
	preconditions_not_void: preconditions /= Void
	postconditions_not_void: postconditions /= Void

end
