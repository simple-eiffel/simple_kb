note
	description: "[
		SIMPLE_KB - Eiffel Knowledge Base

		Main facade providing type references for the simple_kb library.
		Use KB_QUICK for one-liner operations or KB_DATABASE for full control.

		Usage:
			kb: KB_QUICK
			create kb.make

			-- Search
			results := kb.search ("json parsing")

			-- Error lookup
			error := kb.error ("VEVI")

			-- Class info
			class_info := kb.class_info ("JSON_PARSER")
	]"
	author: "Simple Eiffel"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_KB

feature -- Type Anchors

	database_anchor: detachable KB_DATABASE
			-- Type anchor for KB_DATABASE

	result_anchor: detachable KB_RESULT
			-- Type anchor for KB_RESULT

	error_anchor: detachable KB_ERROR_INFO
			-- Type anchor for KB_ERROR_INFO

	class_anchor: detachable KB_CLASS_INFO
			-- Type anchor for KB_CLASS_INFO

	feature_anchor: detachable KB_FEATURE_INFO
			-- Type anchor for KB_FEATURE_INFO

	example_anchor: detachable KB_EXAMPLE
			-- Type anchor for KB_EXAMPLE

	pattern_anchor: detachable KB_PATTERN
			-- Type anchor for KB_PATTERN

end
