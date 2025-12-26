#!/usr/bin/env python3
"""
Populate KB FAQs from Studies 5-8.
Run: python3 populate_faqs_5_8.py
"""

import sqlite3
import os

DB_PATH = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'bin', 'kb.db')

def main():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    faqs = [
        # ============== STUDY 5: SCOOP ==============
        {
            "question": "What is SCOOP in Eiffel?",
            "keywords": "scoop concurrency separate processor parallel",
            "answer": """SCOOP (Simple Concurrent Object-Oriented Programming) is Eiffel's built-in concurrency model. It uses Design by Contract for synchronization instead of explicit locks.

Key concepts:
- `separate` keyword marks objects on different processors
- Preconditions on separate objects become **wait conditions**
- Mutual exclusion is automatic - no explicit locking needed

```eiffel
launch (counter: separate COUNTER)
    require
        counter.value >= 100  -- WAITS until true
    do
        counter.run (50)
    end
```

SCOOP eliminates race conditions and deadlocks through compiler analysis.""",
            "sources": "ISE EiffelStudio 25.02: library/base/elks/kernel/ise_scoop_runtime.e",
            "tags": "scoop,concurrency,separate,parallel",
            "category": "scoop",
            "difficulty": 3,
            "related_classes": "ISE_SCOOP_RUNTIME",
            "source_origin": "code-study"
        },
        {
            "question": "How do I declare a separate object in SCOOP?",
            "keywords": "separate declaration scoop processor",
            "answer": """Use the `separate` keyword on parameters or attributes:

```eiffel
-- Separate parameter
process (worker: separate WORKER)
    do
        worker.execute
    end

-- Separate attribute
my_worker: separate WORKER

-- Creating separate object
create my_worker.make
process (my_worker)  -- Passes to separate processor
```

Each `separate` object lives on its own processor (logical thread). Calls to separate objects are automatically synchronized.""",
            "sources": "ISE EiffelStudio 25.02: examples/scoop/counter/",
            "tags": "scoop,separate,declaration,processor",
            "category": "scoop",
            "difficulty": 2,
            "source_origin": "code-study"
        },
        {
            "question": "How do preconditions work with separate objects in SCOOP?",
            "keywords": "precondition separate wait condition scoop",
            "answer": """Preconditions on separate objects become **wait conditions**:

```eiffel
consume (buffer: separate BUFFER)
    require
        not buffer.is_empty  -- WAITS until buffer has items
    do
        process (buffer.get_item)
    end
```

The caller blocks until the precondition is satisfied. This replaces condition variables and explicit waiting.

**Key difference from regular preconditions:**
- Regular: Raises exception if false
- Separate: Blocks until true""",
            "sources": "ISE EiffelStudio 25.02: examples/scoop/dining_savages/pot.e",
            "tags": "scoop,precondition,wait,synchronization",
            "category": "scoop",
            "difficulty": 3,
            "source_origin": "code-study"
        },
        {
            "question": "How do I pass data between SCOOP processors?",
            "keywords": "scoop data transfer import separate",
            "answer": """Use `make_from_separate` to import data across processor boundaries:

```eiffel
process (msg: separate STRING)
    local
        local_copy: STRING
    do
        -- Import: copy from separate to local processor
        create local_copy.make_from_separate (msg)

        -- Now local_copy is non-separate, safe to use freely
        io.put_string (local_copy)
    end
```

Direct assignment from separate to non-separate is not allowed - you must explicitly import.""",
            "sources": "ISE EiffelStudio 25.02: library/net/test/client_stub.e",
            "tags": "scoop,import,data,transfer",
            "category": "scoop",
            "difficulty": 3,
            "source_origin": "code-study"
        },
        {
            "question": "What is the inline separate syntax in SCOOP?",
            "keywords": "inline separate scoop modern syntax",
            "answer": """Modern SCOOP provides inline separate blocks for scoped access:

```eiffel
if attached args[i] as sep_arg then
    separate sep_arg as arg do
        Result.append (arg.out)
    end
end
```

The `separate ... as ... do ... end` block:
- Creates temporary synchronized access
- Limits scope of synchronization
- Cleaner than passing to helper feature

Available in EiffelStudio 17.05+.""",
            "sources": "ISE EiffelStudio 25.02: library/argument_parser/support/string_formatter.e",
            "tags": "scoop,inline,separate,syntax",
            "category": "scoop",
            "difficulty": 3,
            "source_origin": "code-study"
        },
        {
            "question": "How do I avoid deadlock in SCOOP?",
            "keywords": "deadlock scoop lock ordering",
            "answer": """SCOOP prevents deadlock through compiler analysis:

```eiffel
eat (left, right: separate FORK)
    -- Two separate args = compiler analyzes lock order
    do
        left.pick (Current)
        right.pick (Current)
        -- Use forks
        left.put (Current)
        right.put (Current)
    end
```

**SCOOP guarantees:**
1. Arguments are acquired atomically
2. Compiler ensures consistent lock ordering
3. No circular wait possible

**Best practices:**
- Use preconditions for synchronization (not busy-waiting)
- Minimize separate calls in tight loops
- Let SCOOP handle ordering""",
            "sources": "ISE EiffelStudio 25.02: examples/scoop/dining_philosophers/",
            "tags": "scoop,deadlock,prevention,lock",
            "category": "scoop",
            "difficulty": 4,
            "source_origin": "code-study"
        },

        # ============== STUDY 6: AGENTS ==============
        {
            "question": "What are agents in Eiffel?",
            "keywords": "agent lambda closure function object",
            "answer": """Agents are first-class function objects (like lambdas/closures):

```eiffel
-- Agent to existing feature
action := agent my_object.compute

-- Inline agent (lambda)
action := agent (x: INTEGER) do
    io.put_integer (x)
end

-- Agent with return value
func := agent (s: STRING): INTEGER do
    Result := s.count
end
```

**Class hierarchy:**
- PROCEDURE [ARGS] - no return value
- FUNCTION [ARGS, RESULT] - returns value
- PREDICATE [ARGS] - returns BOOLEAN""",
            "sources": "ISE EiffelStudio 25.02: library/base/elks/kernel/routine.e",
            "tags": "agent,lambda,closure,function-object",
            "category": "architect",
            "difficulty": 2,
            "related_classes": "ROUTINE,PROCEDURE,FUNCTION,PREDICATE",
            "source_origin": "code-study"
        },
        {
            "question": "What is the difference between PROCEDURE and FUNCTION?",
            "keywords": "procedure function agent difference return",
            "answer": """PROCEDURE has no return value, FUNCTION returns a value:

**PROCEDURE [ARGS]:**
```eiffel
printer: PROCEDURE [STRING]
printer := agent io.put_string
printer.call (["Hello"])  -- No return
```

**FUNCTION [ARGS, RESULT]:**
```eiffel
counter: FUNCTION [STRING, INTEGER]
counter := agent (s: STRING): INTEGER do Result := s.count end
length := counter.item (["Hello"])  -- Returns 5
```

**PREDICATE [ARGS]** = FUNCTION [ARGS, BOOLEAN]:
```eiffel
is_empty: PREDICATE [STRING]
is_empty := agent (s: STRING): BOOLEAN do Result := s.is_empty end
```""",
            "sources": "ISE EiffelStudio 25.02: library/base/elks/kernel/",
            "tags": "procedure,function,agent,predicate",
            "category": "architect",
            "difficulty": 2,
            "related_classes": "PROCEDURE,FUNCTION,PREDICATE",
            "source_origin": "code-study"
        },
        {
            "question": "How do I create an inline agent (lambda) in Eiffel?",
            "keywords": "inline agent lambda anonymous function",
            "answer": """Use `agent (args) do ... end` syntax:

**No return value:**
```eiffel
printer := agent (x: INTEGER) do
    io.put_integer (x)
    io.put_new_line
end
```

**With return value:**
```eiffel
doubler := agent (x: INTEGER): INTEGER do
    Result := x * 2
end
```

**Multiline:**
```eiffel
processor := agent (data: STRING): BOOLEAN
    local
        count: INTEGER
    do
        count := data.count
        io.put_string ("Processing " + count.out + " chars%N")
        Result := count > 0
    end
```""",
            "sources": "ISE EiffelStudio 25.02",
            "tags": "inline,agent,lambda,anonymous",
            "category": "newcomer",
            "difficulty": 2,
            "source_origin": "code-study"
        },
        {
            "question": "How do I use partial application with placeholders?",
            "keywords": "partial application placeholder currying agent",
            "answer": """Use `?` as placeholder for unfilled arguments:

```eiffel
-- Original: send_card (age: INTEGER; name, from: STRING)

-- Partial application: fix "from" argument
birthday_actions.extend (agent send_card (?, ?, "Sam"))
-- Creates PROCEDURE [TUPLE [INTEGER, STRING]]

-- Multiple fixed arguments
birthday_actions.extend (agent buy_gift (?, ?, "Wine", "Sam"))
-- Creates PROCEDURE [TUPLE [INTEGER, STRING]]

-- Calling fills in placeholders
birthday_actions.call ([35, "Julia"])
-- Executes: send_card (35, "Julia", "Sam")
```""",
            "sources": "ISE EiffelStudio 25.02: library/base/ise/event/action_sequence.e",
            "tags": "partial,application,placeholder,currying",
            "category": "architect",
            "difficulty": 3,
            "source_origin": "code-study"
        },
        {
            "question": "How do I apply a function to all list elements?",
            "keywords": "do_all iterate list agent higher-order",
            "answer": """Use `do_all` with an agent:

```eiffel
-- Print all elements
my_list.do_all (agent io.put_string)

-- Custom action
my_list.do_all (agent (s: STRING) do
    io.put_string ("Item: " + s + "%N")
end)

-- With index
my_list.do_all_with_index (agent (s: STRING; i: INTEGER) do
    io.put_string (i.out + ": " + s + "%N")
end)
```

Similar features: `do_if`, `there_exists`, `for_all`.""",
            "sources": "ISE EiffelStudio 25.02: library/base/elks/structures/list/arrayed_list.e",
            "tags": "do_all,iterate,higher-order,agent",
            "category": "newcomer",
            "difficulty": 2,
            "related_classes": "ARRAYED_LIST,LINKED_LIST",
            "source_origin": "code-study"
        },
        {
            "question": "How do I filter elements with an agent?",
            "keywords": "filter do_if agent predicate",
            "answer": """Use `do_if` with action and test agents:

```eiffel
-- Print only positive numbers
numbers.do_if (
    agent (x: INTEGER) do io.put_integer (x) end,
    agent (x: INTEGER): BOOLEAN do Result := x > 0 end
)

-- Collect matching elements
filtered: ARRAYED_LIST [STRING]
create filtered.make (10)
names.do_if (
    agent (s: STRING) do filtered.extend (s) end,
    agent (s: STRING): BOOLEAN do Result := s.count > 5 end
)
```

Use `there_exists` to check if any match, `for_all` to check if all match.""",
            "sources": "ISE EiffelStudio 25.02: library/base/elks/structures/list/arrayed_list.e",
            "tags": "filter,do_if,predicate,agent",
            "category": "newcomer",
            "difficulty": 2,
            "source_origin": "code-study"
        },
        {
            "question": "What is the difference between call and item for agents?",
            "keywords": "call item agent invoke",
            "answer": """**call** is for PROCEDURE, **item** is for FUNCTION:

**PROCEDURE.call:**
```eiffel
action: PROCEDURE [INTEGER]
action.call ([42])  -- Executes, no return
```

**FUNCTION.item:**
```eiffel
func: FUNCTION [INTEGER, STRING]
result := func.item ([42])  -- Returns value

-- Alternative: call sets last_result
func.call ([42])
io.put_string (func.last_result)
```

Both accept TUPLE arguments: `call ([arg1, arg2])`.""",
            "sources": "ISE EiffelStudio 25.02: library/base/elks/kernel/",
            "tags": "call,item,agent,invoke",
            "category": "newcomer",
            "difficulty": 2,
            "related_classes": "PROCEDURE,FUNCTION",
            "source_origin": "code-study"
        },

        # ============== STUDY 7: GENERICS ==============
        {
            "question": "How do I create a generic class in Eiffel?",
            "keywords": "generic class type parameter",
            "answer": """Use square brackets with type parameter:

```eiffel
class MY_CONTAINER [G]

feature
    item: G

    put (v: G)
        do
            item := v
        end
end
```

**Multiple type parameters:**
```eiffel
class MY_TABLE [K, V]

feature
    items: HASH_TABLE [V, K]
end
```

**Instantiation:**
```eiffel
strings: MY_CONTAINER [STRING]
numbers: MY_CONTAINER [INTEGER]
config: MY_TABLE [STRING, ANY]
```""",
            "sources": "ISE EiffelStudio 25.02: library/base/elks/structures/list/arrayed_list.e",
            "tags": "generic,class,type-parameter",
            "category": "newcomer",
            "difficulty": 2,
            "source_origin": "code-study"
        },
        {
            "question": "How do I constrain a generic type parameter?",
            "keywords": "generic constraint comparable hashable",
            "answer": """Use `->` to specify constraint:

```eiffel
class SORTED_LIST [G -> COMPARABLE]
    -- G must implement < > = operators

class HASH_SET [G -> HASHABLE]
    -- G must implement hash_code

class PRIORITY_QUEUE [G -> PART_COMPARABLE]
    -- G must implement partial ordering
```

**Multiple constraints:**
```eiffel
class MY_CLASS [G -> {COMPARABLE, HASHABLE}]
```

**Detachable constraint:**
```eiffel
class HASH_TABLE [G, K -> detachable HASHABLE]
    -- K can be Void
```""",
            "sources": "ISE EiffelStudio 25.02: library/base/elks/structures/",
            "tags": "generic,constraint,comparable,hashable",
            "category": "architect",
            "difficulty": 3,
            "related_classes": "COMPARABLE,HASHABLE,PART_COMPARABLE",
            "source_origin": "code-study"
        },
        {
            "question": "What does like Current mean in Eiffel?",
            "keywords": "like current anchored type covariant",
            "answer": """`like Current` is an anchored type that returns the exact type of the object:

```eiffel
class ANIMAL
feature
    twin: like Current
        -- Returns ANIMAL for ANIMAL, DOG for DOG
        do
            Result := standard_twin
        end

    duplicate: like Current
        do
            create Result
            Result.copy (Current)
        end
end

class DOG inherit ANIMAL end

dog: DOG
dog2: DOG
dog2 := dog.twin  -- Returns DOG, not ANIMAL
```

Essential for proper covariant return types in inheritance.""",
            "sources": "ISE EiffelStudio 25.02: library/base/elks/kernel/any.e",
            "tags": "like,current,anchored,covariant",
            "category": "architect",
            "difficulty": 3,
            "source_origin": "code-study"
        },
        {
            "question": "What does like item mean in Eiffel?",
            "keywords": "like item anchored type container",
            "answer": """`like item` anchors to the type of the container's element:

```eiffel
class LIST [G]
feature
    item: G
        -- Current element

    first: like item
        -- Same type as item (G)

    last: like item
        -- Same type as item (G)

    has (v: like item): BOOLEAN
        -- Check if list contains v
end
```

Used extensively in container classes to ensure type consistency.

```eiffel
strings: LIST [STRING]
s: STRING
s := strings.first  -- Returns STRING
```""",
            "sources": "ISE EiffelStudio 25.02: library/base/elks/structures/list/arrayed_list.e",
            "tags": "like,item,anchored,container",
            "category": "architect",
            "difficulty": 3,
            "source_origin": "code-study"
        },
        {
            "question": "How do I get the default value of a generic type?",
            "keywords": "generic default value type query",
            "answer": """Use type query syntax `({G}).default`:

```eiffel
class MY_ARRAY [G]
feature
    make_filled (n: INTEGER)
        require
            has_default: ({G}).has_default  -- Check first
        do
            across 1 |..| n as i loop
                put (({G}).default, i.item)
            end
        end

    item_or_default (i: INTEGER): G
        do
            if valid_index (i) then
                Result := item (i)
            else
                Result := ({G}).default
            end
        end
end
```

`({G}).has_default` returns True if G has a default value.""",
            "sources": "ISE EiffelStudio 25.02: library/base/elks/kernel/array.e",
            "tags": "generic,default,type-query",
            "category": "architect",
            "difficulty": 3,
            "source_origin": "code-study"
        },

        # ============== STUDY 8: VOID SAFETY ==============
        {
            "question": "What is void safety in Eiffel?",
            "keywords": "void safety null pointer attached detachable",
            "answer": """Void safety eliminates null pointer errors at compile time:

```eiffel
-- Attached: guaranteed non-void
name: attached STRING  -- or just STRING (default in void-safe mode)

-- Detachable: can be void
cached_value: detachable STRING

-- Compiler prevents:
cached_value.count  -- ERROR: might be void

-- Must check first:
if attached cached_value as cv then
    io.put_integer (cv.count)  -- OK: cv proven attached
end
```

Void-safe Eiffel code has zero null pointer exceptions.""",
            "sources": "ISE EiffelStudio 25.02: library/base/elks/kernel/any.e",
            "tags": "void-safety,null,attached,detachable",
            "category": "newcomer",
            "difficulty": 2,
            "source_origin": "code-study"
        },
        {
            "question": "What is the difference between attached and detachable?",
            "keywords": "attached detachable void null",
            "answer": """**attached** - guaranteed never void:
```eiffel
name: attached STRING
-- Compiler ensures name always refers to valid object

create name.make_empty  -- Must initialize
name.append ("Hello")   -- Always safe
```

**detachable** - can be void:
```eiffel
cache: detachable STRING
-- cache might be Void

cache.count  -- COMPILE ERROR: might be void

if attached cache as c then
    c.count  -- OK: c proven attached in this block
end
```

Default in void-safe mode: attached for local variables, detachable for attributes unless specified.""",
            "sources": "ISE EiffelStudio 25.02",
            "tags": "attached,detachable,void,null",
            "category": "newcomer",
            "difficulty": 2,
            "source_origin": "code-study"
        },
        {
            "question": "How do I safely access a possibly-void reference?",
            "keywords": "void safe access object test attached",
            "answer": """Use the object test pattern:

```eiffel
cache: detachable STRING

-- Pattern 1: Simple check
if attached cache then
    io.put_string (cache)  -- cache known attached here
end

-- Pattern 2: With local (preferred)
if attached cache as c then
    io.put_string (c)  -- c is attached local
    io.put_integer (c.count)
end

-- Pattern 3: Type check + attachment
if attached {READABLE_STRING_32} value as s32 then
    io.put_string_32 (s32)
end

-- Pattern 4: Chained checks
if attached x as lx and then attached lx.child as lc then
    process (lc)
end
```""",
            "sources": "ISE EiffelStudio 25.02: library/base/elks/kernel/any.e",
            "tags": "void-safe,object-test,attached",
            "category": "newcomer",
            "difficulty": 2,
            "source_origin": "code-study"
        },
        {
            "question": "What is the object test pattern in Eiffel?",
            "keywords": "object test attached as pattern",
            "answer": """Object test (`attached ... as ...`) certifies attachment:

```eiffel
if attached expression as local_name then
    -- local_name is guaranteed attached here
    -- Use local_name safely
end
```

**Variants:**

1. **Simple attachment:**
```eiffel
if attached my_attr then ...
```

2. **With local binding:**
```eiffel
if attached my_attr as m then
    io.put_string (m)
end
```

3. **Type refinement:**
```eiffel
if attached {MY_TYPE} expression as typed then
    -- typed is MY_TYPE, not just ANY
end
```

4. **In check blocks:**
```eiffel
check attached internal_data as d then
    Result := d.value
end
```""",
            "sources": "ISE EiffelStudio 25.02",
            "tags": "object-test,attached,pattern,cap",
            "category": "newcomer",
            "difficulty": 2,
            "source_origin": "code-study"
        },
        {
            "question": "What is a stable attribute in Eiffel?",
            "keywords": "stable attribute void safety",
            "answer": """Stable attributes remain attached once set:

```eiffel
internal_ptr: detachable MANAGED_POINTER
    note option: stable attribute end
```

**Behavior:**
- Initially can be void
- Once attached through object test, stays attached
- Compiler knows subsequent accesses are safe

```eiffel
ensure_initialized
    do
        if not attached internal_ptr then
            create internal_ptr.make (100)
        end
    end

use_pointer
    require
        initialized: attached internal_ptr
    do
        -- internal_ptr guaranteed attached here
        internal_ptr.put_integer (42, 0)
    end
```

Used for lazy initialization with void safety.""",
            "sources": "ISE EiffelStudio 25.02: library/base/elks/kernel/directory.e",
            "tags": "stable,attribute,void-safety",
            "category": "architect",
            "difficulty": 3,
            "source_origin": "code-study"
        },
        {
            "question": "How do I fix VEVI compiler errors?",
            "keywords": "vevi error void safety fix",
            "answer": """VEVI = Variable not properly set (void access error).

**Error:**
```eiffel
x: detachable STRING
io.put_string (x)  -- VEVI: x might be void
```

**Fixes:**

1. **Object test:**
```eiffel
if attached x as lx then
    io.put_string (lx)
end
```

2. **Make attached:**
```eiffel
x: STRING  -- Remove detachable
create x.make_empty
io.put_string (x)
```

3. **Check block (when you can prove it):**
```eiffel
check attached x as lx then
    io.put_string (lx)
end
```

4. **Provide default:**
```eiffel
io.put_string (if attached x as lx then lx else "" end)
```""",
            "sources": "ISE EiffelStudio 25.02",
            "tags": "vevi,error,fix,void-safety",
            "category": "debugger",
            "difficulty": 2,
            "related_errors": "VEVI",
            "source_origin": "code-study"
        },
        {
            "question": "What does 'and then' do for void safety?",
            "keywords": "and then lazy evaluation void safety",
            "answer": """`and then` provides lazy (short-circuit) evaluation:

```eiffel
-- WRONG: both sides evaluated
if x /= Void and x.count > 0 then  -- May crash!

-- CORRECT: second side only if first true
if x /= Void and then x.count > 0 then  -- Safe!
```

**With object tests:**
```eiffel
if attached parent as p and then attached p.child as c then
    process (c)
end
```

Similarly, `or else` for lazy OR:
```eiffel
if x = Void or else x.is_empty then
    use_default
end
```""",
            "sources": "ISE EiffelStudio 25.02: library/base/elks/kernel/any.e",
            "tags": "and-then,lazy,evaluation,void-safety",
            "category": "newcomer",
            "difficulty": 2,
            "source_origin": "code-study"
        }
    ]

    # Insert all FAQs
    inserted = 0
    for faq in faqs:
        try:
            cursor.execute("""
                INSERT INTO faqs (
                    question, keywords, answer, sources, tags,
                    category, difficulty, code_example, related_classes,
                    related_errors, source_origin
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                faq["question"],
                faq.get("keywords", ""),
                faq["answer"],
                faq.get("sources", ""),
                faq.get("tags", ""),
                faq.get("category", ""),
                faq.get("difficulty", 1),
                faq.get("code_example", ""),
                faq.get("related_classes", ""),
                faq.get("related_errors", ""),
                faq.get("source_origin", "code-study")
            ))
            inserted += 1
        except Exception as e:
            print(f"Error: {faq['question'][:40]}... - {e}")

    conn.commit()
    print(f"Inserted {inserted} FAQ pairs from Studies 5-8")

    # Update FTS index
    cursor.execute('DELETE FROM faq_search')
    cursor.execute('''
        INSERT INTO faq_search (faq_id, question, answer, keywords, tags)
        SELECT id, question, answer, keywords, tags FROM faqs
    ''')
    conn.commit()

    # Stats
    cursor.execute("SELECT COUNT(*) FROM faqs")
    total = cursor.fetchone()[0]
    print(f"Total FAQs: {total}")

    cursor.execute("SELECT category, COUNT(*) FROM faqs GROUP BY category ORDER BY COUNT(*) DESC")
    print("\nBy category:")
    for row in cursor.fetchall():
        print(f"  {row[0] or 'uncategorized'}: {row[1]}")

    conn.close()

if __name__ == "__main__":
    main()
