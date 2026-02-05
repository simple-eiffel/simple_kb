note
	description: "[
		KB_LIBRARY_INFO - Library Metadata Model

		Stores information about an Eiffel library extracted from ECF files.
		Includes name, description, UUID, clusters, and dependencies.
	]"
	author: "Simple Eiffel"
	date: "$Date$"
	revision: "$Revision$"

class
	KB_LIBRARY_INFO

create
	make,
	make_from_row

feature {NONE} -- Initialization

	make (a_name: READABLE_STRING_GENERAL)
			-- Create library info
		require
			name_not_empty: not a_name.is_empty
		do
			name := a_name.to_string_32
			create description.make_empty
			create uuid.make_empty
			create file_path.make_empty
			create clusters.make (5)
			create dependencies.make (10)
		ensure
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
			name := a_row.string_value ("name")
			description := a_row.string_value ("description")
			uuid := a_row.string_value ("uuid")
			file_path := a_row.string_value ("file_path")
			create clusters.make (5)
			create dependencies.make (10)
			-- Parse JSON arrays
			parse_json_array (a_row.string_value ("clusters"), clusters)
			parse_json_array (a_row.string_value ("dependencies"), dependencies)
		end

feature -- Access

	id: INTEGER
			-- Database ID

	name: STRING_32
			-- Library name

	description: STRING_32
			-- Library description from ECF

	uuid: STRING_32
			-- Library UUID

	file_path: STRING_32
			-- Path to ECF file

	clusters: ARRAYED_LIST [STRING_32]
			-- Cluster names

	dependencies: ARRAYED_LIST [STRING_32]
			-- Library dependencies (names)

feature -- Setters

	set_id (a_id: INTEGER)
			-- Set database ID
		do
			id := a_id
		end

	set_description (a_desc: READABLE_STRING_GENERAL)
			-- Set description
		do
			description := a_desc.to_string_32
		end

	set_uuid (a_uuid: READABLE_STRING_GENERAL)
			-- Set UUID
		do
			uuid := a_uuid.to_string_32
		end

	set_file_path (a_path: READABLE_STRING_GENERAL)
			-- Set file path
		do
			file_path := a_path.to_string_32
		end

	add_cluster (a_cluster: READABLE_STRING_GENERAL)
			-- Add cluster
		do
			clusters.extend (a_cluster.to_string_32)
		end

	add_dependency (a_dep: READABLE_STRING_GENERAL)
			-- Add dependency
		do
			dependencies.extend (a_dep.to_string_32)
		end

feature -- Display

	formatted: STRING_32
			-- Formatted display
		local
			i: INTEGER
		do
			create Result.make (500)
			Result.append ("LIBRARY: " + name + "%N")
			Result.append ("========================================%N%N")
			if not description.is_empty then
				Result.append ("Description:%N  " + description + "%N%N")
			end
			if not uuid.is_empty then
				Result.append ("UUID: " + uuid + "%N")
			end
			if not file_path.is_empty then
				Result.append ("ECF: " + file_path + "%N")
			end
			if not clusters.is_empty then
				Result.append ("%NCLUSTERS:%N")
				from i := 1 until i > clusters.count loop
					Result.append ("  - " + clusters[i] + "%N")
					i := i + 1
				end
			end
			if not dependencies.is_empty then
				Result.append ("%NDEPENDENCIES:%N")
				from i := 1 until i > dependencies.count loop
					Result.append ("  - " + dependencies[i] + "%N")
					i := i + 1
				end
			end
		end

feature -- JSON Serialization

	clusters_json: STRING_32
			-- Clusters as JSON array
		do
			Result := to_json_array (clusters)
		end

	dependencies_json: STRING_32
			-- Dependencies as JSON array
		do
			Result := to_json_array (dependencies)
		end

feature {NONE} -- Implementation

	to_json_array (a_list: ARRAYED_LIST [STRING_32]): STRING_32
			-- Convert list to JSON array
		local
			l_first: BOOLEAN
		do
			create Result.make (100)
			Result.append_character ('[')
			l_first := True
			across a_list as ic loop
				if not l_first then
					Result.append_character (',')
				end
				Result.append_character ('"')
				Result.append (escape_json (ic))
				Result.append_character ('"')
				l_first := False
			end
			Result.append_character (']')
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

	parse_json_array (a_json: READABLE_STRING_GENERAL; a_list: ARRAYED_LIST [STRING_32])
			-- Parse JSON array into list
		local
			l_json: SIMPLE_JSON
			l_value: detachable SIMPLE_JSON_VALUE
			l_arr: SIMPLE_JSON_ARRAY
			i: INTEGER
		do
			if not a_json.is_empty then
				create l_json
				l_value := l_json.parse (a_json.to_string_32)
				if attached l_value as val and then val.is_array then
					l_arr := val.array_value
					from i := 1 until i > l_arr.count loop
						if l_arr [i].is_string then
							a_list.extend (l_arr [i].string_value)
						end
						i := i + 1
					end
				end
			end
		end

invariant
	name_not_empty: not name.is_empty
	clusters_not_void: clusters /= Void
	dependencies_not_void: dependencies /= Void

end
