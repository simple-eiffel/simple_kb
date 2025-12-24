note
	description: "[
		KB_ERROR_SEEDER - Populates KB with known EiffelStudio error codes

		Seeds the knowledge base with ~30 common compiler error codes,
		their meanings, common causes, and fixes.

		Error Code Categories:
			- VXXX: Validity rules from ECMA-367
			- VDXX: Configuration/dependency errors
			- VWXX: Warning codes
			- Syntax errors
	]"
	author: "Simple Eiffel"
	date: "$Date$"
	revision: "$Revision$"

class
	KB_ERROR_SEEDER

create
	make

feature {NONE} -- Initialization

	make (a_db: KB_DATABASE)
			-- Seed database with error codes
		require
			db_open: a_db.is_open
		do
			db := a_db
			seed_void_safety_errors
			seed_type_errors
			seed_feature_errors
			seed_inheritance_errors
			seed_config_errors
			seed_more_type_errors
			seed_syntax_errors
		end

feature -- Access

	db: KB_DATABASE
			-- Target database

feature {NONE} -- Void Safety Errors

	seed_void_safety_errors
			-- VEVI, VUTA, etc.
		local
			e: KB_ERROR_INFO
		do
			-- VEVI: Variable not properly set
			create e.make ("VEVI", "Variable not properly set")
			e.set_explanation ("An attached local variable or Result must be assigned a value on all possible execution paths before being used.")
			e.add_cause ("Result not assigned in an else branch")
			e.add_cause ("Local variable used before assignment")
			e.add_cause ("Assignment inside conditional that may not execute")
			e.add_fix ("Add else branch", "Ensure all branches assign a value", "if condition then Result := x else Result := y end")
			e.add_fix ("Initialize at declaration", "Give default value immediately", "l_value: STRING; create l_value.make_empty")
			e.set_bad_code ("if condition then%N  Result := x%Nend -- Missing else!")
			e.set_good_code ("if condition then%N  Result := x%Nelse%N  Result := default_value%Nend")
			e.set_ecma_section ("8.19.17")
			db.add_error (e)

			-- VUTA: Target of call may be void
			create e.make ("VUTA", "Target of call might be void")
			e.set_explanation ("You are calling a feature on an expression that could be Void (detachable type).")
			e.add_cause ("Calling feature on detachable attribute")
			e.add_cause ("Function returns detachable type")
			e.add_cause ("Item from HASH_TABLE or other container")
			e.add_fix ("Use attached check", "Guard the call with attached", "if attached my_object as obj then obj.do_something end")
			e.add_fix ("Use check attached", "Assert non-void with check", "check attached my_object as obj then obj.do_something end")
			e.add_fix ("Make it attached", "Change declaration to non-detachable if possible", "my_object: MY_CLASS -- not 'detachable MY_CLASS'")
			e.set_bad_code ("my_object.do_something -- my_object is detachable!")
			e.set_good_code ("if attached my_object as l_obj then%N  l_obj.do_something%Nend")
			e.set_ecma_section ("8.23.14")
			db.add_error (e)

			-- VJAR: Target of assignment not compatible
			create e.make ("VJAR", "Target of assignment attempt not compatible")
			e.set_explanation ("Assignment attempt (?=) target type is not compatible with source type.")
			e.add_cause ("Types are completely unrelated")
			e.add_cause ("Using ?= instead of := for compatible types")
			e.add_fix ("Use regular assignment", "If types are compatible, use :=", "target := source")
			e.add_fix ("Fix type hierarchy", "Ensure target type is ancestor of source", "")
			e.set_ecma_section ("8.18.5")
			db.add_error (e)

			-- VWEQ: Equality with different types
			create e.make ("VWEQ", "Equality comparison between incompatible types")
			e.set_explanation ("Comparing two values of types that can never be equal (no common conforming type).")
			e.add_cause ("Comparing INTEGER with STRING")
			e.add_cause ("Comparing unrelated class types")
			e.add_fix ("Convert types", "Convert one value to match the other", "a.out ~ b.out")
			e.add_fix ("Review logic", "The comparison may be a logic error", "")
			e.set_ecma_section ("8.22.26")
			db.add_error (e)
		end

feature {NONE} -- Type Errors

	seed_type_errors
			-- VEEN, VKCN, VTCT, etc.
		local
			e: KB_ERROR_INFO
		do
			-- VEEN: Identifier not found
			create e.make ("VEEN", "Identifier not found")
			e.set_explanation ("The identifier used in the code is not defined in the current scope.")
			e.add_cause ("Typo in variable or feature name")
			e.add_cause ("Forgot to declare local variable")
			e.add_cause ("Feature not inherited or defined")
			e.add_fix ("Check spelling", "Verify the identifier spelling", "")
			e.add_fix ("Add declaration", "Declare the local variable", "local%N  my_var: MY_TYPE")
			e.add_fix ("Check inheritance", "Ensure feature is inherited or defined", "")
			e.set_ecma_section ("8.14.4")
			db.add_error (e)

			-- VTCT: Class type not found
			create e.make ("VTCT", "Class type not found")
			e.set_explanation ("The class name used does not exist in the system.")
			e.add_cause ("Class not included in ECF")
			e.add_cause ("Typo in class name")
			e.add_cause ("Library not added to project")
			e.add_fix ("Add library", "Add required library to ECF", "<library name=%"needed_lib%" location=%"...%"/>")
			e.add_fix ("Check spelling", "Verify class name is correct", "")
			e.add_fix ("Check cluster", "Ensure source directory is in ECF", "<cluster name=%"src%" location=%".\\src\\%"/>")
			e.set_ecma_section ("8.12.11")
			db.add_error (e)

			-- VKCN: Invalid creation
			create e.make ("VKCN", "Creation procedure not valid")
			e.set_explanation ("The feature used as creation procedure is not listed in the create clause.")
			e.add_cause ("Feature not listed in create clause")
			e.add_cause ("Trying to use query as creation procedure")
			e.add_fix ("Add to create clause", "List the procedure in create", "create%N  make, make_from_string")
			e.add_fix ("Use valid creator", "Use a procedure that is listed", "create my_object.make")
			e.set_ecma_section ("8.20.10")
			db.add_error (e)

			-- VGCC: Invalid constraint
			create e.make ("VGCC", "Constraint violation in generic")
			e.set_explanation ("Actual generic parameter does not conform to formal constraint.")
			e.add_cause ("Using ARRAYED_LIST[INTEGER] when constraint requires COMPARABLE")
			e.add_cause ("Missing inheritance in actual parameter")
			e.add_fix ("Make class conform", "Inherit required interface", "class MY_CLASS inherit COMPARABLE")
			e.add_fix ("Use conforming type", "Choose type that satisfies constraint", "")
			e.set_ecma_section ("8.12.9")
			db.add_error (e)

			-- VUAR: Wrong number of arguments
			create e.make ("VUAR", "Wrong number of arguments")
			e.set_explanation ("The feature call has a different number of arguments than declared.")
			e.add_cause ("Missing argument")
			e.add_cause ("Extra argument")
			e.add_cause ("Calling wrong feature overload")
			e.add_fix ("Check signature", "Verify feature argument count", "my_feature (arg1, arg2) -- needs 2 args")
			e.add_fix ("Check documentation", "Read feature documentation for correct usage", "")
			e.set_ecma_section ("8.23.9")
			db.add_error (e)
		end

feature {NONE} -- Feature Errors

	seed_feature_errors
			-- VDRS, VUEX, VMFN, etc.
		local
			e: KB_ERROR_INFO
		do
			-- VDRS: Redefine not selected
			create e.make ("VDRS", "Redefined feature not selected")
			e.set_explanation ("When inheriting same feature from multiple parents, must select or undefine.")
			e.add_cause ("Multiple inheritance conflict")
			e.add_cause ("Missing select clause")
			e.add_fix ("Add select clause", "Choose which version to use", "inherit PARENT_A select my_feature end")
			e.add_fix ("Undefine one version", "Make one version abstract", "inherit PARENT_A undefine my_feature end")
			e.set_ecma_section ("8.16.13")
			db.add_error (e)

			-- VUEX: Feature not exported to class
			create e.make ("VUEX", "Feature not exported to current class")
			e.set_explanation ("Trying to call a feature that is not exported to the calling class.")
			e.add_cause ("Feature is exported to NONE")
			e.add_cause ("Feature exported to specific class only")
			e.add_cause ("Accessing private implementation feature")
			e.add_fix ("Use exported feature", "Call the public interface instead", "")
			e.add_fix ("Export feature", "Change export status", "feature {ANY} -- exported to all")
			e.set_ecma_section ("8.23.16")
			db.add_error (e)

			-- VMFN: Feature name clash
			create e.make ("VMFN", "Feature name already used")
			e.set_explanation ("Two features in the same class have the same name.")
			e.add_cause ("Defining feature that already exists from parent")
			e.add_cause ("Duplicate feature definition in class")
			e.add_fix ("Rename inherited feature", "Use rename clause", "inherit PARENT rename old_name as new_name end")
			e.add_fix ("Use different name", "Choose unique name for new feature", "")
			e.add_fix ("Use redefine", "If overriding, add to redefine clause", "inherit PARENT redefine my_feature end")
			e.set_ecma_section ("8.14.12")
			db.add_error (e)

			-- VREG: Regular expression invalid
			create e.make ("VREG", "Require else invalid")
			e.set_explanation ("A 'require else' clause strengthens instead of weakens the parent precondition.")
			e.add_cause ("Adding stricter precondition in redefinition")
			e.add_fix ("Use 'require'", "Replace 'require else' with 'require' if not overriding", "require%N  my_condition: x > 0")
			e.add_fix ("Weaken condition", "Make new precondition less restrictive", "require else%N  True -- always accepts")
			e.set_ecma_section ("8.10.8")
			db.add_error (e)

			-- VRLE: Result in precondition
			create e.make ("VRLE", "Result used in precondition")
			e.set_explanation ("Cannot reference Result in require clause since function hasn't executed yet.")
			e.add_cause ("Using Result in require clause")
			e.add_fix ("Move to postcondition", "Put Result check in ensure clause", "ensure%N  valid_result: Result > 0")
			e.add_fix ("Check arguments instead", "Validate inputs, not outputs", "require%N  valid_input: a_value > 0")
			e.set_ecma_section ("8.10.5")
			db.add_error (e)
		end

feature {NONE} -- Inheritance Errors

	seed_inheritance_errors
			-- VHRC, VHPR, ECMA inheritance rules
		local
			e: KB_ERROR_INFO
		do
			-- VHRC: Repeated constraint
			create e.make ("VHRC", "Repeated inheritance constraint violation")
			e.set_explanation ("Sharing or replicating features in repeated inheritance violates rules.")
			e.add_cause ("Same feature inherited twice with different implementations")
			e.add_cause ("Conflicting select clauses")
			e.add_fix ("Use select", "Explicitly select one version", "inherit A select feature_name end")
			e.add_fix ("Use rename", "Give different names to each version", "inherit A rename feat as feat_a end")
			e.set_ecma_section ("8.16.11")
			db.add_error (e)

			-- VHPR: Invalid parent
			create e.make ("VHPR", "Invalid parent clause")
			e.set_explanation ("Parent class cannot be used in inherit clause.")
			e.add_cause ("Trying to inherit from expanded class incorrectly")
			e.add_cause ("Cyclic inheritance")
			e.add_fix ("Check inheritance graph", "Ensure no cycles", "")
			e.add_fix ("Review design", "Expanded classes have special inheritance rules", "")
			e.set_ecma_section ("8.11.1")
			db.add_error (e)

			-- VJRV: Join violation
			create e.make ("VJRV", "Feature join violation")
			e.set_explanation ("Cannot join features with incompatible signatures.")
			e.add_cause ("Different return types when joining")
			e.add_cause ("Different argument counts")
			e.add_fix ("Ensure compatible signatures", "Make signatures match", "")
			e.add_fix ("Use rename", "Avoid joining by renaming", "")
			e.set_ecma_section ("8.16.9")
			db.add_error (e)
		end

feature {NONE} -- Config Errors

	seed_config_errors
			-- VD89, VDRC, ECF errors
		local
			e: KB_ERROR_INFO
		do
			-- VD89: Dependency cycle
			create e.make ("VD89", "Dependency cycle detected")
			e.set_explanation ("Libraries form a circular dependency. Library A depends on B which depends on A.")
			e.add_cause ("Two libraries referencing each other")
			e.add_cause ("Duplicate ECF UUIDs causing cycle detection")
			e.add_cause ("Complex multi-library cycle")
			e.add_fix ("Check ECF UUIDs", "Ensure each library has unique UUID", "Use uuidgen to generate new UUIDs")
			e.add_fix ("Review dependencies", "Check ECF library references", "Restructure to remove cycle")
			e.add_fix ("Use claude_tools", "Run 'claude_tools.exe uuid scan' to find duplicates", "")
			e.set_bad_code ("lib_a.ecf references lib_b.ecf%Nlib_b.ecf references lib_a.ecf")
			e.set_good_code ("lib_a.ecf references lib_b.ecf%Nlib_b.ecf has no reference to lib_a.ecf")
			db.add_error (e)

			-- VDRC: Root class not found
			create e.make ("VDRC", "Root class not found")
			e.set_explanation ("The class specified as root in ECF does not exist in the system.")
			e.add_cause ("Typo in root class name")
			e.add_cause ("Root class file not in cluster")
			e.add_cause ("Wrong cluster location")
			e.add_fix ("Check root clause", "Verify class name in ECF", "<root class=%"MY_APP%" feature=%"make%"/>")
			e.add_fix ("Check clusters", "Ensure source file is in a cluster", "")
			db.add_error (e)

			-- VSRT: Root type error
			create e.make ("VSRT", "Root type error")
			e.set_explanation ("Root class must have a valid creation procedure.")
			e.add_cause ("Root feature not a creation procedure")
			e.add_cause ("Root feature has arguments")
			e.add_fix ("Use creation procedure", "Root feature must be in create clause", "create%N  make")
			e.add_fix ("Make feature argumentless", "Root creation cannot take arguments", "")
			db.add_error (e)

			-- VINH: Library not found
			create e.make ("VINH", "Library not found at location")
			e.set_explanation ("The ECF file for a library cannot be found at the specified path.")
			e.add_cause ("Wrong path in ECF library element")
			e.add_cause ("Environment variable not set")
			e.add_cause ("Library not installed")
			e.add_fix ("Check path", "Verify library location exists", "ls $SIMPLE_EIFFEL/simple_json/simple_json.ecf")
			e.add_fix ("Set environment", "Ensure $ISE_LIBRARY etc. are set", "export ISE_LIBRARY=...")
			e.add_fix ("Use absolute path temporarily", "For debugging, try absolute path", "")
			db.add_error (e)
		end

feature {NONE} -- Syntax Errors

	seed_more_type_errors
			-- Additional type errors
		local
			e: KB_ERROR_INFO
		do
			-- VTUG: Invalid generic type usage
			create e.make ("VTUG", "Type used as generic is not valid")
			e.set_explanation ("The actual generic parameter is not a valid class type.")
			e.add_cause ("Using basic type incorrectly")
			e.add_cause ("Forward reference to undefined class")
			e.add_fix ("Check class exists", "Ensure the type is defined", "")
			e.set_ecma_section ("8.12.10")
			db.add_error (e)

			-- VOMB: Object test scope
			create e.make ("VOMB", "Object test local out of scope")
			e.set_explanation ("An object test local is used outside its valid scope.")
			e.add_cause ("Using 'attached x as y' variable y outside the then-branch")
			e.add_cause ("Object test local used in else branch")
			e.add_fix ("Keep in scope", "Only use object test local in its then-branch", "if attached x as lx then%N  lx.use%Nend")
			e.set_bad_code ("if attached x as lx then%N  -- ok here%Nend%Nlx.use -- ERROR: out of scope!")
			e.set_good_code ("if attached x as lx then%N  lx.use -- Only here!%Nend")
			e.set_ecma_section ("8.24.7")
			db.add_error (e)

			-- VWMA: Manifest array type
			create e.make ("VWMA", "Manifest array type mismatch")
			e.set_explanation ("Elements in manifest array are not compatible with declared type.")
			e.add_cause ("Mixing STRING and INTEGER in same array")
			e.add_cause ("Manifest array type differs from target")
			e.add_fix ("Use same types", "All elements must conform to array type", "<<1, 2, 3>> -- all INTEGER")
			e.add_fix ("Specify type", "Use explicit type annotation", "{ARRAY [STRING]} <<%"a%", %"b%">>")
			db.add_error (e)

			-- VWOE: Once result
			create e.make ("VWOE", "Once expression result type issue")
			e.set_explanation ("Once expression used where attached type expected but once returns detachable.")
			e.add_cause ("Once may return Void on first call failure")
			e.add_fix ("Use once function", "Prefer once function over once expression for attached results", "")
			db.add_error (e)
		end

	seed_syntax_errors
			-- Common syntax mistakes
		local
			e: KB_ERROR_INFO
		do
			-- Syntax: Missing 'then'
			create e.make ("SYNT_THEN", "Syntax: Missing 'then' after condition")
			e.set_explanation ("An 'if' or 'elseif' condition must be followed by 'then'.")
			e.add_cause ("Forgot 'then' keyword")
			e.add_cause ("Extra expression before 'then'")
			e.add_fix ("Add 'then'", "Complete the if statement", "if x > 0 then -- action end")
			e.set_bad_code ("if x > 0%N  do_something%Nend")
			e.set_good_code ("if x > 0 then%N  do_something%Nend")
			db.add_error (e)

			-- Syntax: Missing 'do'
			create e.make ("SYNT_DO", "Syntax: Missing 'do' keyword")
			e.set_explanation ("A routine body must start with 'do', 'once', 'deferred', or 'external'.")
			e.add_cause ("Forgot 'do' after 'local' or declaration")
			e.add_cause ("Typed 'does' instead of 'do'")
			e.add_fix ("Add 'do'", "Insert 'do' before routine body", "feature%N  my_routine%N    do%N      -- implementation%N    end")
			e.set_bad_code ("my_routine%N  Result := 5%Nend")
			e.set_good_code ("my_routine%N  do%N    Result := 5%N  end")
			db.add_error (e)

			-- Syntax: Missing 'end'
			create e.make ("SYNT_END", "Syntax: Missing 'end' keyword")
			e.set_explanation ("Every block construct (class, feature, if, loop, etc.) needs matching 'end'.")
			e.add_cause ("Unbalanced if/end, loop/end")
			e.add_cause ("Missing 'end' after feature body")
			e.add_cause ("Missing class 'end'")
			e.add_fix ("Balance blocks", "Count opens and closes", "Use editor matching feature")
			e.add_fix ("Check indentation", "Misindented code often reveals missing end", "")
			db.add_error (e)

			-- Syntax: Semicolon in wrong place
			create e.make ("SYNT_SEMI", "Syntax: Unexpected semicolon")
			e.set_explanation ("Eiffel uses newlines as statement separators; semicolons are optional.")
			e.add_cause ("Using C/Java style semicolons")
			e.add_cause ("Semicolon after 'do' or 'then'")
			e.add_fix ("Remove semicolon", "Semicolons are usually not needed", "do%N  statement_1%N  statement_2")
			e.add_fix ("Use for lists only", "Semicolons are standard in formal arguments", "make (a: INTEGER; b: STRING)")
			db.add_error (e)

			-- Syntax: Wrong boolean operator
			create e.make ("SYNT_BOOL", "Syntax: Wrong boolean operator")
			e.set_explanation ("Eiffel uses 'and', 'or', 'not' instead of &&, ||, !.")
			e.add_cause ("Using && instead of 'and'")
			e.add_cause ("Using || instead of 'or'")
			e.add_cause ("Using ! instead of 'not'")
			e.add_fix ("Use Eiffel operators", "Replace with Eiffel keywords", "if a and b then")
			e.add_fix ("Short-circuit", "Use 'and then', 'or else'", "if a /= Void and then a.is_valid then")
			e.set_bad_code ("if a && b || !c then")
			e.set_good_code ("if a and b or not c then%Nif a and then b then -- short-circuit")
			db.add_error (e)

			-- Syntax: Assignment operator
			create e.make ("SYNT_ASSIGN", "Syntax: Wrong assignment operator")
			e.set_explanation ("Eiffel uses ':=' for assignment, not '=' which is comparison.")
			e.add_cause ("Using = for assignment")
			e.add_cause ("C/Java habits")
			e.add_fix ("Use :=", "Assignment operator is :=", "my_variable := 42")
			e.add_fix ("Use = for comparison", "= and /= are equality tests", "if x = y then -- comparing")
			e.set_bad_code ("x = 5 -- This is a boolean comparison!")
			e.set_good_code ("x := 5 -- This is assignment")
			db.add_error (e)
		end

end
