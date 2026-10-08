note
	description: "[
		KB_PATTERN_SEEDER - Seeds database with Eiffel patterns and idioms

		Populates the knowledge base with common Eiffel design patterns,
		idioms, and best practices. Includes Eiffel-specific implementations.
	]"
	author: "Simple Eiffel"
	date: "$Date$"
	revision: "$Revision$"

class
	KB_PATTERN_SEEDER

create
	make

feature {NONE} -- Initialization

	make (a_db: KB_DATABASE)
			-- Create seeder and populate patterns
		require
			db_not_void: a_db /= Void
			db_open: a_db.is_open
		do
			db := a_db
			seed_all_patterns
		ensure
			db_set: db = a_db
		end

feature -- Access

	db: KB_DATABASE
			-- Target database

	patterns_added: INTEGER
			-- Count of patterns added

feature {NONE} -- Seeding

	seed_all_patterns
			-- Add all patterns to database
		do
			seed_singleton
			seed_factory
			seed_builder
			seed_template_method
			seed_observer
			seed_command
			seed_visitor
			seed_iterator
			seed_null_object
			seed_once_per_object
			seed_expanded_value
			seed_agent_callback
			seed_dbc_validation
			seed_attachment_check
		end

	seed_singleton
			-- Singleton pattern using once function
		local
			l_pattern: KB_PATTERN
		do
			create l_pattern.make ("singleton", "[
shared_instance: MY_CLASS
		-- Single shared instance
	once
		create Result.make
	end
]")
			l_pattern.set_description ("Ensure only one instance of a class exists throughout the application.")
			l_pattern.set_when_to_use ("When you need global access to a single shared instance, like configuration, logging, or connection pools.")
			l_pattern.add_idiom ("Use 'once' function, not a class variable")
			l_pattern.add_idiom ("once = once per process by default")
			l_pattern.add_idiom ("Use 'once per object' for instance-level singletons")
			l_pattern.add_idiom ("Thread-safe: use 'once (THREAD)' for per-thread instances")
			db.add_pattern (l_pattern)
			patterns_added := patterns_added + 1
		end

	seed_factory
			-- Factory pattern
		local
			l_pattern: KB_PATTERN
		do
			create l_pattern.make ("factory", "[
new_shape (a_type: STRING): SHAPE
		-- Create shape based on type
	require
		valid_type: is_valid_shape_type (a_type)
	do
		inspect a_type
		when "circle" then
			create {CIRCLE} Result.make
		when "rectangle" then
			create {RECTANGLE} Result.make
		else
			create {NULL_SHAPE} Result.make
		end
	ensure
		result_attached: Result /= Void
	end
]")
			l_pattern.set_description ("Create objects without exposing instantiation logic. Centralizes object creation.")
			l_pattern.set_when_to_use ("When you need to create objects based on runtime conditions, or want to decouple object creation from usage.")
			l_pattern.add_idiom ("Use 'inspect' for type-based dispatch")
			l_pattern.add_idiom ("Return attached type for void-safety")
			l_pattern.add_idiom ("Precondition validates input")
			l_pattern.add_idiom ("Consider using manifest arrays for registration")
			db.add_pattern (l_pattern)
			patterns_added := patterns_added + 1
		end

	seed_builder
			-- Fluent builder pattern
		local
			l_pattern: KB_PATTERN
		do
			create l_pattern.make ("builder", "[
class HTTP_REQUEST_BUILDER

feature -- Building

	set_url (a_url: STRING): like Current
		do
			url := a_url
			Result := Current
		end

	set_method (a_method: STRING): like Current
		do
			method := a_method
			Result := Current
		end

	add_header (a_key, a_value: STRING): like Current
		do
			headers.put (a_value, a_key)
			Result := Current
		end

	build: HTTP_REQUEST
		require
			url_set: url /= Void
		do
			create Result.make (url, method, headers)
		end

end

-- Usage:
-- request := (create {HTTP_REQUEST_BUILDER}).set_url ("https://api.example.com")
--              .set_method ("POST").add_header ("Content-Type", "application/json").build
]")
			l_pattern.set_description ("Construct complex objects step by step with a fluent interface.")
			l_pattern.set_when_to_use ("When creating objects with many optional parameters, or when construction requires multiple steps.")
			l_pattern.add_idiom ("Return 'like Current' for fluent chaining")
			l_pattern.add_idiom ("Use precondition in build for required fields")
			l_pattern.add_idiom ("Parenthesize create expression for chaining: (create {X}).method")
			db.add_pattern (l_pattern)
			patterns_added := patterns_added + 1
		end

	seed_template_method
			-- Template method pattern
		local
			l_pattern: KB_PATTERN
		do
			create l_pattern.make ("template_method", "[
deferred class ALGORITHM

feature -- Template

	execute
			-- Template method - fixed algorithm structure
		do
			prepare
			process
			cleanup
		end

feature {NONE} -- Steps

	prepare
			-- Hook: override for preparation
		do
			-- Default: do nothing
		end

	process
			-- Required step: must be implemented
		deferred
		end

	cleanup
			-- Hook: override for cleanup
		do
			-- Default: do nothing
		end

end
]")
			l_pattern.set_description ("Define algorithm skeleton in base class, let subclasses override specific steps.")
			l_pattern.set_when_to_use ("When you have an algorithm with fixed structure but variable steps, like parsers or processors.")
			l_pattern.add_idiom ("Use 'deferred' for required overrides")
			l_pattern.add_idiom ("Provide default implementation for optional hooks")
			l_pattern.add_idiom ("Template method is not deferred, steps are")
			db.add_pattern (l_pattern)
			patterns_added := patterns_added + 1
		end

	seed_observer
			-- Observer pattern using agents
		local
			l_pattern: KB_PATTERN
		do
			create l_pattern.make ("observer", "[
class OBSERVABLE [G]

feature -- Observers

	subscribe (a_handler: PROCEDURE [G])
			-- Add observer
		do
			observers.extend (a_handler)
		end

	unsubscribe (a_handler: PROCEDURE [G])
			-- Remove observer
		do
			observers.prune (a_handler)
		end

	notify (a_data: G)
			-- Notify all observers
		do
			across observers as obs loop
				obs.call ([a_data])
			end
		end

feature {NONE} -- Implementation

	observers: ARRAYED_LIST [PROCEDURE [G]]
		attribute
			create Result.make (5)
		end

end

-- Usage:
-- events: OBSERVABLE [STRING]
-- events.subscribe (agent handle_event)
-- events.notify ("something happened")
]")
			l_pattern.set_description ("Define one-to-many dependency between objects using agents as callbacks.")
			l_pattern.set_when_to_use ("For event systems, UI updates, or decoupled notification mechanisms.")
			l_pattern.add_idiom ("Use PROCEDURE [G] for typed callbacks")
			l_pattern.add_idiom ("Agents: agent method or agent (x) do ... end")
			l_pattern.add_idiom ("Call with tuple: obs.call ([data])")
			l_pattern.add_idiom ("Use attribute keyword for inline initialization")
			db.add_pattern (l_pattern)
			patterns_added := patterns_added + 1
		end

	seed_command
			-- Command pattern
		local
			l_pattern: KB_PATTERN
		do
			create l_pattern.make ("command", "[
deferred class COMMAND

feature -- Execution

	execute
			-- Perform the command
		deferred
		end

	undo
			-- Reverse the command
		deferred
		end

	description: STRING
			-- Human-readable description
		deferred
		end

end

class INSERT_TEXT_COMMAND
inherit COMMAND

feature {NONE} -- Initialization

	make (a_editor: TEXT_EDITOR; a_text: STRING; a_position: INTEGER)
		do
			editor := a_editor
			text := a_text
			position := a_position
		end

feature -- Execution

	execute
		do
			editor.insert (text, position)
		end

	undo
		do
			editor.delete (position, text.count)
		end

	description: STRING = "Insert text"

end
]")
			l_pattern.set_description ("Encapsulate a request as an object, enabling undo/redo, queuing, and logging.")
			l_pattern.set_when_to_use ("For undo/redo systems, transaction processing, or macro recording.")
			l_pattern.add_idiom ("Deferred class defines command interface")
			l_pattern.add_idiom ("Store state needed for undo")
			l_pattern.add_idiom ("Use command queue for macro recording")
			db.add_pattern (l_pattern)
			patterns_added := patterns_added + 1
		end

	seed_visitor
			-- Visitor pattern
		local
			l_pattern: KB_PATTERN
		do
			create l_pattern.make ("visitor", "[
deferred class AST_VISITOR

feature -- Visiting

	visit_binary (a_node: BINARY_EXPR)
		deferred
		end

	visit_literal (a_node: LITERAL_EXPR)
		deferred
		end

	visit_variable (a_node: VARIABLE_EXPR)
		deferred
		end

end

class PRINTER_VISITOR
inherit AST_VISITOR

feature -- Visiting

	visit_binary (a_node: BINARY_EXPR)
		do
			a_node.left.accept (Current)
			print (a_node.operator)
			a_node.right.accept (Current)
		end

	visit_literal (a_node: LITERAL_EXPR)
		do
			print (a_node.value.out)
		end

	visit_variable (a_node: VARIABLE_EXPR)
		do
			print (a_node.name)
		end

end

-- In AST_NODE:
-- accept (a_visitor: AST_VISITOR)
--   deferred
--   end
]")
			l_pattern.set_description ("Separate algorithm from object structure. Add new operations without modifying classes.")
			l_pattern.set_when_to_use ("For AST traversal, serialization, or when you have fixed class hierarchy but varying operations.")
			l_pattern.add_idiom ("Double dispatch: node.accept(visitor) calls visitor.visit_xxx(node)")
			l_pattern.add_idiom ("Deferred visitor defines interface")
			l_pattern.add_idiom ("Each concrete visitor is a new operation")
			db.add_pattern (l_pattern)
			patterns_added := patterns_added + 1
		end

	seed_iterator
			-- Iterator pattern using across
		local
			l_pattern: KB_PATTERN
		do
			create l_pattern.make ("iterator", "[
-- Eiffel's across construct provides built-in iteration

-- Basic iteration:
across my_list as item loop
	print (item.out)
end

-- With index:
across my_list as item loop
	print (item.cursor_index.out + ": " + item.out)
end

-- All/some quantifiers:
if across my_list as item all item > 0 end then
	print ("All positive")
end

if across my_list as item some item = target end then
	print ("Found it")
end

-- Custom iterable class:
class MY_COLLECTION [G]
inherit ITERABLE [G]

feature -- Iteration

	new_cursor: MY_CURSOR [G]
		do
			create Result.make (items)
		end

end
]")
			l_pattern.set_description ("Traverse elements of a collection without exposing its internal structure.")
			l_pattern.set_when_to_use ("Always prefer 'across' over manual index loops. Use for any collection traversal.")
			l_pattern.add_idiom ("Use 'across list as x' (x is the element)")
			l_pattern.add_idiom ("Use 'all' for universal quantifier")
			l_pattern.add_idiom ("Use 'some' for existential quantifier")
			l_pattern.add_idiom ("Inherit ITERABLE [G] for custom collections")
			l_pattern.add_idiom ("cursor_index gives 1-based position")
			db.add_pattern (l_pattern)
			patterns_added := patterns_added + 1
		end

	seed_null_object
			-- Null object pattern for void safety
		local
			l_pattern: KB_PATTERN
		do
			create l_pattern.make ("null_object", "[
deferred class LOGGER

feature -- Logging

	log (a_message: STRING)
		deferred
		end

end

class CONSOLE_LOGGER
inherit LOGGER

feature -- Logging

	log (a_message: STRING)
		do
			print (a_message + "%N")
		end

end

class NULL_LOGGER
inherit LOGGER

feature -- Logging

	log (a_message: STRING)
		do
			-- Do nothing
		end

end

-- Usage: Never need to check for Void
-- logger: LOGGER
-- if debug_mode then
--   create {CONSOLE_LOGGER} logger
-- else
--   create {NULL_LOGGER} logger
-- end
-- logger.log ("message")  -- Always safe
]")
			l_pattern.set_description ("Provide a do-nothing object instead of Void to eliminate null checks.")
			l_pattern.set_when_to_use ("When you want to avoid null checks and provide default behavior for optional components.")
			l_pattern.add_idiom ("Null object inherits same interface")
			l_pattern.add_idiom ("Methods do nothing or return defaults")
			l_pattern.add_idiom ("Eliminates 'if x /= Void' checks")
			l_pattern.add_idiom ("Works well with void-safe mode")
			db.add_pattern (l_pattern)
			patterns_added := patterns_added + 1
		end

	seed_once_per_object
			-- Once per object pattern
		local
			l_pattern: KB_PATTERN
		do
			create l_pattern.make ("once_per_object", "[
class DATABASE_CONNECTION

feature -- Access

	connection_id: STRING
			-- Unique ID computed once per instance
		once ("OBJECT")
			Result := generate_uuid
		end

	cached_config: CONFIG
			-- Config loaded once per instance
		once ("OBJECT")
			create Result.make
			Result.load_from_file (config_path)
		end

feature {NONE} -- Implementation

	generate_uuid: STRING
		do
			create Result.make_from_string ((create {UUID_GENERATOR}).generate.out)
		end

end

-- Each instance has its own cached value
-- conn1.connection_id /= conn2.connection_id
]")
			l_pattern.set_description ("Cache a value per object instance, computed lazily on first access.")
			l_pattern.set_when_to_use ("When you need instance-level caching or lazy initialization of expensive computations.")
			l_pattern.add_idiom ("once ('OBJECT') = once per instance")
			l_pattern.add_idiom ("once = once per process (global)")
			l_pattern.add_idiom ("once ('THREAD') = once per thread")
			l_pattern.add_idiom ("Great for lazy initialization")
			db.add_pattern (l_pattern)
			patterns_added := patterns_added + 1
		end

	seed_expanded_value
			-- Expanded/value type pattern
		local
			l_pattern: KB_PATTERN
		do
			create l_pattern.make ("expanded_value", "[
expanded class POINT

feature -- Access

	x, y: REAL_64

feature -- Initialization

	make (a_x, a_y: REAL_64)
		do
			x := a_x
			y := a_y
		end

feature -- Operations

	distance (other: POINT): REAL_64
		do
			Result := ((x - other.x)^2 + (y - other.y)^2).sqrt
		end

	plus alias "+" (other: POINT): POINT
		do
			Result.make (x + other.x, y + other.y)
		end

invariant
	-- expanded types cannot be Void

end

-- Usage:
-- p1, p2: POINT  -- No create needed, auto-initialized
-- p1.make (1.0, 2.0)
-- p3 := p1 + p2  -- Value semantics, copies
]")
			l_pattern.set_description ("Create value types with copy semantics, automatically initialized, never Void.")
			l_pattern.set_when_to_use ("For small immutable data like points, colors, money. When you want stack allocation and copy semantics.")
			l_pattern.add_idiom ("expanded = value type, copied on assignment")
			l_pattern.add_idiom ("No Void check needed - always valid")
			l_pattern.add_idiom ("No 'create' needed - auto-initialized")
			l_pattern.add_idiom ("Good for: coordinates, colors, small tuples")
			l_pattern.add_idiom ("Define operators with 'alias'")
			db.add_pattern (l_pattern)
			patterns_added := patterns_added + 1
		end

	seed_agent_callback
			-- Agent callback pattern
		local
			l_pattern: KB_PATTERN
		do
			create l_pattern.make ("agent_callback", "[
class ASYNC_TASK

feature -- Execution

	execute_async (a_work: PROCEDURE; a_on_complete: PROCEDURE [BOOLEAN])
			-- Run work, then call completion handler
		do
			a_work.call (Void)
			a_on_complete.call ([True])
		end

end

-- Usage with named agent:
task.execute_async (
	agent do_heavy_work,
	agent handle_completion
)

-- Usage with inline agent:
task.execute_async (
	agent do
		-- work here
	end,
	agent (success: BOOLEAN) do
		if success then print ("Done!") end
	end
)

-- Function agents for transformations:
names := items.map (agent {ITEM}.name)
adults := people.filter (agent (p: PERSON): BOOLEAN do Result := p.age >= 18 end)
]")
			l_pattern.set_description ("Use agents (function objects) for callbacks, event handlers, and functional programming.")
			l_pattern.set_when_to_use ("For async callbacks, event handlers, functional transformations (map/filter), or delayed execution.")
			l_pattern.add_idiom ("agent feature_name - reference to method")
			l_pattern.add_idiom ("agent {TYPE}.feature - unbound agent")
			l_pattern.add_idiom ("agent (args) do ... end - inline agent")
			l_pattern.add_idiom ("PROCEDURE = no return value")
			l_pattern.add_idiom ("FUNCTION [ARGS, RESULT] = returns value")
			l_pattern.add_idiom ("Call with: my_agent.call ([args]) or my_func.item ([args])")
			db.add_pattern (l_pattern)
			patterns_added := patterns_added + 1
		end

	seed_dbc_validation
			-- Design by Contract validation pattern
		local
			l_pattern: KB_PATTERN
		do
			create l_pattern.make ("dbc_validation", "[
class USER_SERVICE

feature -- Commands

	create_user (a_email: STRING; a_password: STRING): USER
			-- Create new user with validated input
		require
			email_not_empty: not a_email.is_empty
			email_valid: is_valid_email (a_email)
			password_strong: is_strong_password (a_password)
			email_unique: not user_exists (a_email)
		do
			create Result.make (a_email, hash_password (a_password))
			users.extend (Result)
		ensure
			user_created: Result /= Void
			user_registered: users.has (Result)
			password_hashed: Result.password_hash /= a_password
		end

feature -- Queries

	is_valid_email (a_email: STRING): BOOLEAN
		do
			Result := a_email.has ('@') and a_email.has ('.')
		end

	is_strong_password (a_password: STRING): BOOLEAN
		do
			Result := a_password.count >= 8
		end

invariant
	users_not_void: users /= Void
	no_duplicate_emails: across users as u1 all
		across users as u2 all u1 = u2 or u1.email /~ u2.email end
	end

end
]")
			l_pattern.set_description ("Use preconditions, postconditions, and invariants for self-documenting validation.")
			l_pattern.set_when_to_use ("Always. DBC replaces defensive programming. Validates at boundaries, documents intent.")
			l_pattern.add_idiom ("require = caller's responsibility")
			l_pattern.add_idiom ("ensure = implementation's guarantee")
			l_pattern.add_idiom ("invariant = always true for valid objects")
			l_pattern.add_idiom ("Use query features in contracts for readability")
			l_pattern.add_idiom ("'old' in ensure references pre-call state")
			db.add_pattern (l_pattern)
			patterns_added := patterns_added + 1
		end

	seed_attachment_check
			-- Void-safe attachment pattern
		local
			l_pattern: KB_PATTERN
		do
			create l_pattern.make ("attachment_check", "[
-- Pattern 1: check attached with alias
if attached find_user (email) as user then
	-- user is attached (non-void) in this scope
	print (user.name)
end

-- Pattern 2: Object test
if attached {DATABASE_ERROR} last_error as db_err then
	-- Type narrowing: db_err is DATABASE_ERROR
	print (db_err.sql_code.out)
end

-- Pattern 3: Detachable to attached conversion
get_or_default (a_key: STRING): VALUE
	local
		l_found: detachable VALUE
	do
		l_found := table.item (a_key)
		if attached l_found then
			Result := l_found
		else
			Result := default_value
		end
	end

-- Pattern 4: Certified Attachment Pattern (CAP)
-- When you KNOW it's attached but compiler doesn't:
check attached my_detachable as x then
	-- x is attached here
	-- Runtime check in debug, assertion in production
end
]")
			l_pattern.set_description ("Handle detachable (possibly Void) values safely using attachment tests.")
			l_pattern.set_when_to_use ("When working with detachable types, optional values, or narrowing types.")
			l_pattern.add_idiom ("'attached x as y' tests and binds in one step")
			l_pattern.add_idiom ("'attached {TYPE} x as y' tests type AND attachment")
			l_pattern.add_idiom ("Scoped: alias only valid in then-branch")
			l_pattern.add_idiom ("'check attached' for CAP when you know it's safe")
			l_pattern.add_idiom ("Prefer attached over detachable where possible")
			db.add_pattern (l_pattern)
			patterns_added := patterns_added + 1
		end

invariant
	db_not_void: db /= Void

end
