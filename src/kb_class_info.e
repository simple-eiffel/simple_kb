note
	description: "[
		KB_CLASS_INFO - Class Metadata Model

		Stores information about an Eiffel class extracted from source files.
		Includes library, name, description, and associated features.
	]"
	author: "Simple Eiffel"
	date: "$Date$"
	revision: "$Revision$"

class
	KB_CLASS_INFO

create
	make,
	make_from_row

feature {NONE} -- Initialization

	make (a_library, a_name: READABLE_STRING_GENERAL)
			-- Create class info
		require
			library_not_empty: not a_library.is_empty
			name_not_empty: not a_name.is_empty
		do
			library := a_library.to_string_32
			name := a_name.to_string_32
			create description.make_empty
			create file_path.make_empty
			create features.make (10)
		ensure
			library_set: library.same_string_general (a_library)
			name_set: name.same_string_general (a_name)
		end

	make_from_row (a_row: SIMPLE_SQL_ROW)
			-- Create from database row
		require
			row_not_void: a_row /= Void
		do
			if attached a_row.item (1) as val then
				id := val.out.to_integer
			end
			library := a_row.string_value ("library")
			name := a_row.string_value ("name")
			description := a_row.string_value ("description")
			file_path := a_row.string_value ("file_path")
			create features.make (10)
		end

feature -- Access

	id: INTEGER
			-- Database ID

	library: STRING_32
			-- Library name (e.g., "simple_json", "base")

	name: STRING_32
			-- Class name (e.g., "JSON_PARSER")

	description: STRING_32
			-- Class description from note clause

	file_path: STRING_32
			-- Path to source file

	features: ARRAYED_LIST [KB_FEATURE_INFO]
			-- Features of this class

feature -- Derived

	creation_features: ARRAYED_LIST [KB_FEATURE_INFO]
			-- Creation procedures
		do
			create Result.make (3)
			across features as ic loop
				if ic.kind.same_string ("creation") then
					Result.extend (ic)
				end
			end
		end

	query_features: ARRAYED_LIST [KB_FEATURE_INFO]
			-- Query features
		do
			create Result.make (10)
			across features as ic loop
				if ic.kind.same_string ("query") then
					Result.extend (ic)
				end
			end
		end

	command_features: ARRAYED_LIST [KB_FEATURE_INFO]
			-- Command features
		do
			create Result.make (10)
			across features as ic loop
				if ic.kind.same_string ("command") then
					Result.extend (ic)
				end
			end
		end

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

	set_file_path (a_path: READABLE_STRING_GENERAL)
			-- Set file path
		do
			file_path := a_path.to_string_32
		end

	add_feature (a_feature: KB_FEATURE_INFO)
			-- Add feature to class
		require
			feature_not_void: a_feature /= Void
		do
			features.extend (a_feature)
		ensure
			added: features.has (a_feature)
		end

feature -- Status

	is_valid: BOOLEAN
			-- Is this a valid class entry?
		do
			Result := not library.is_empty and not name.is_empty
		end

feature -- Display

	formatted: STRING_32
			-- Full formatted display
		do
			create Result.make (500)
			Result.append ("CLASS: ")
			Result.append (name)
			Result.append ("%N")
			Result.append (create {STRING_32}.make_filled ('=', name.count + 7))
			Result.append ("%NLibrary: ")
			Result.append (library)

			if not description.is_empty then
				Result.append ("%NDescription: ")
				Result.append (description)
			end

			if not creation_features.is_empty then
				Result.append ("%N%NCREATION:%N")
				across creation_features as ic loop
					Result.append ("  ")
					Result.append (ic.name)
					if not ic.signature.is_empty then
						Result.append (" ")
						Result.append (ic.signature)
					end
					Result.append ("%N")
				end
			end

			if not query_features.is_empty then
				Result.append ("%NFEATURES (Query):%N")
				across query_features as ic loop
					Result.append ("  ")
					Result.append (ic.name)
					if not ic.signature.is_empty then
						Result.append (" ")
						Result.append (ic.signature)
					end
					Result.append ("%N")
					if not ic.description.is_empty then
						Result.append ("      -- ")
						Result.append (ic.description)
						Result.append ("%N")
					end
				end
			end

			if not command_features.is_empty then
				Result.append ("%NFEATURES (Command):%N")
				across command_features as ic loop
					Result.append ("  ")
					Result.append (ic.name)
					if not ic.signature.is_empty then
						Result.append (" ")
						Result.append (ic.signature)
					end
					Result.append ("%N")
				end
			end
		end

	brief: STRING_32
			-- Brief one-line display
		do
			create Result.make (100)
			Result.append (name)
			Result.append (" (")
			Result.append (library)
			Result.append (")")
			if not description.is_empty then
				Result.append (" - ")
				if description.count > 60 then
					Result.append (description.substring (1, 57))
					Result.append ("...")
				else
					Result.append (description)
				end
			end
		end

feature {NONE} -- Implementation

	safe_string (a_val: detachable ANY): STRING_32
			-- Convert value to string safely
		do
			if attached a_val as v then
				Result := v.out
			else
				create Result.make_empty
			end
		end

invariant
	library_not_empty: not library.is_empty
	name_not_empty: not name.is_empty
	features_not_void: features /= Void

end
