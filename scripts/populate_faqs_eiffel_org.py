#!/usr/bin/env python3
"""
Populate KB FAQs from Eiffel.org documentation.
Run: python3 populate_faqs_eiffel_org.py
"""

import sqlite3
import os

DB_PATH = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'bin', 'kb.db')

def main():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    faqs = [
        # ============== FROM EIFFEL.ORG - BASICS ==============
        {
            "question": "What is Eiffel?",
            "keywords": "eiffel language method framework introduction",
            "answer": """Eiffel is not just a programming language - it's a full life-cycle framework for software development consisting of three interconnected elements:

1. **The Eiffel Method** - A software development approach emphasizing Design by Contract, information hiding, and seamless development

2. **The Eiffel Language** - A pure object-oriented language with:
   - Multiple inheritance
   - Generics (parametric polymorphism)
   - Design by Contract (preconditions, postconditions, invariants)
   - Void safety (no null pointer errors)
   - SCOOP concurrency

3. **EiffelStudio** - An integrated development environment supporting round-trip engineering, debugging, and documentation

Eiffel prioritizes correctness, reliability, and maintainability over raw performance.""",
            "sources": "https://www.eiffel.org/doc/eiffel/Learning_Eiffel",
            "tags": "introduction,overview,method,language",
            "category": "newcomer",
            "difficulty": 1,
            "source_origin": "eiffel.org"
        },
        {
            "question": "How do I declare a basic Eiffel class?",
            "keywords": "class declaration structure basic",
            "answer": """Basic class structure:

```eiffel
note
    description: "Brief description of class purpose"

class
    MY_CLASS

inherit
    PARENT_CLASS
        redefine feature_name end

create
    make

feature {NONE} -- Initialization

    make
        do
            -- Constructor code
        end

feature -- Access

    my_attribute: STRING

feature -- Operations

    my_feature (arg: INTEGER): BOOLEAN
        require
            valid_arg: arg > 0
        do
            Result := arg < 100
        ensure
            consistent: Result implies arg < 100
        end

invariant
    attribute_set: my_attribute /= Void

end
```

**Key sections:**
- `note` - Documentation
- `class` - Class name (UPPER_CASE)
- `inherit` - Parent classes
- `create` - Creation procedures
- `feature` - Feature groups
- `invariant` - Class invariants""",
            "sources": "https://www.eiffel.org/doc/eiffel/Eiffel_programming_language_syntax",
            "tags": "class,declaration,structure,syntax",
            "category": "newcomer",
            "difficulty": 1,
            "source_origin": "eiffel.org"
        },
        {
            "question": "What class modifiers are available in Eiffel?",
            "keywords": "class modifier deferred expanded frozen",
            "answer": """Three class modifiers control inheritance and semantics:

**deferred** - Abstract class with incomplete implementation:
```eiffel
deferred class SHAPE
feature
    area: REAL
        deferred
        end
end
```

**expanded** - Value semantics (like structs):
```eiffel
expanded class POINT
feature
    x, y: REAL
end
-- Variables are values, not references
-- Assignment copies, not shares
```

**frozen** - Cannot be inherited:
```eiffel
frozen class FINAL_IMPLEMENTATION
-- No subclasses allowed
end
```

**Combinations:**
- `deferred expanded` - Not allowed
- `frozen expanded` - Value type with no inheritance""",
            "sources": "https://www.eiffel.org/doc/eiffel/Eiffel_programming_language_syntax",
            "tags": "class,modifier,deferred,expanded,frozen",
            "category": "newcomer",
            "difficulty": 2,
            "source_origin": "eiffel.org"
        },
        {
            "question": "How do I create an object in Eiffel?",
            "keywords": "create object instance constructor",
            "answer": """Use `create` instruction:

**Basic creation:**
```eiffel
my_list: ARRAYED_LIST [STRING]
create my_list.make (10)  -- Create with initial capacity 10
```

**With type specification:**
```eiffel
shape: SHAPE
create {CIRCLE} shape.make (5.0)  -- Create CIRCLE, assign to SHAPE
```

**Default creation:**
```eiffel
point: POINT
create point  -- Uses default_create
```

**Creation procedure requirements:**
```eiffel
class MY_CLASS
create
    make,        -- Listed in create clause
    make_default

feature
    make (n: INTEGER)
        do
            count := n
        end
end
```

**Local variable shortcut:**
```eiffel
local
    s: STRING
do
    create s.make_empty
    -- or
    s := "Hello"  -- Manifest string creates STRING
end
```""",
            "sources": "https://www.eiffel.org/doc/eiffel/Eiffel_programming_language_syntax",
            "tags": "create,object,instance,constructor",
            "category": "newcomer",
            "difficulty": 1,
            "source_origin": "eiffel.org"
        },
        {
            "question": "What are the basic types in Eiffel?",
            "keywords": "basic types integer boolean string character",
            "answer": """**Numeric types:**
- `INTEGER` (INTEGER_32) - 32-bit signed
- `INTEGER_8`, `INTEGER_16`, `INTEGER_64`
- `NATURAL` (NATURAL_32) - 32-bit unsigned
- `NATURAL_8`, `NATURAL_16`, `NATURAL_64`
- `REAL` (REAL_32) - 32-bit float
- `REAL_64` (DOUBLE) - 64-bit float

**Boolean:**
- `BOOLEAN` - True or False

**Character:**
- `CHARACTER` (CHARACTER_8) - ASCII
- `CHARACTER_32` - Unicode

**String:**
- `STRING` (STRING_8) - ASCII string
- `STRING_32` - Unicode string
- `IMMUTABLE_STRING_32` - Immutable unicode

**Pointer:**
- `POINTER` - C pointer

**Special:**
- `ANY` - Base of all reference types
- `NONE` - Bottom type (inherits from all)

All basic types are **expanded** (value semantics).""",
            "sources": "https://www.eiffel.org/doc/eiffel/Eiffel_programming_language_syntax",
            "tags": "types,basic,integer,string,boolean",
            "category": "newcomer",
            "difficulty": 1,
            "source_origin": "eiffel.org"
        },
        {
            "question": "How do I write a loop in Eiffel?",
            "keywords": "loop from until across iteration",
            "answer": """**Traditional loop (from/until):**
```eiffel
from
    i := 1
until
    i > 10
loop
    io.put_integer (i)
    i := i + 1
end
```

**With invariant and variant (for proofs):**
```eiffel
from
    i := 1
invariant
    i >= 1
variant
    11 - i  -- Must decrease, stay >= 0
until
    i > 10
loop
    process (i)
    i := i + 1
end
```

**Modern across loop:**
```eiffel
across my_list as cursor loop
    io.put_string (cursor.item)
end

-- With index
across my_array as c loop
    io.put_integer (c.cursor_index)
end
```

**Across with quantifiers:**
```eiffel
-- All positive?
if across list as c all c.item > 0 end then ...

-- Any negative?
if across list as c some c.item < 0 end then ...
```""",
            "sources": "https://www.eiffel.org/doc/eiffel/Eiffel_programming_language_syntax",
            "tags": "loop,from,until,across,iteration",
            "category": "newcomer",
            "difficulty": 2,
            "source_origin": "eiffel.org"
        },
        {
            "question": "How do I write conditional statements in Eiffel?",
            "keywords": "if then else conditional inspect",
            "answer": """**If statement:**
```eiffel
if condition then
    -- true branch
elseif other_condition then
    -- alternative
else
    -- false branch
end
```

**Multi-way choice (inspect):**
```eiffel
inspect character
when 'a', 'e', 'i', 'o', 'u' then
    is_vowel := True
when 'y' then
    is_sometimes_vowel := True
else
    is_consonant := True
end
```

**Inspect with ranges:**
```eiffel
inspect score
when 90 .. 100 then grade := 'A'
when 80 .. 89 then grade := 'B'
when 70 .. 79 then grade := 'C'
else grade := 'F'
end
```

**Conditional expression:**
```eiffel
result := if condition then value1 else value2 end
```""",
            "sources": "https://www.eiffel.org/doc/eiffel/Eiffel_programming_language_syntax",
            "tags": "if,conditional,inspect,branch",
            "category": "newcomer",
            "difficulty": 1,
            "source_origin": "eiffel.org"
        },
        {
            "question": "What inheritance adaptation clauses exist in Eiffel?",
            "keywords": "inheritance rename redefine undefine select export",
            "answer": """Five adaptation clauses modify inherited features:

**rename** - Change feature name:
```eiffel
inherit PARENT rename old_name as new_name end
```

**redefine** - Override implementation:
```eiffel
inherit PARENT redefine feature_name end
```

**undefine** - Make feature deferred:
```eiffel
inherit PARENT undefine feature_name end
-- Used to resolve diamond conflicts
```

**export** - Change visibility:
```eiffel
inherit PARENT
    export {NONE} hidden_feature
    export {ANY} public_feature
    end
```

**select** - Choose version for dynamic binding:
```eiffel
inherit
    PARENT_A select feature_x end
    PARENT_B
```

**Combined example:**
```eiffel
inherit
    ARRAYED_LIST [G]
        rename item as list_item
        redefine extend
        export {NONE} all
        end
```""",
            "sources": "https://www.eiffel.org/doc/eiffel/Eiffel_programming_language_syntax",
            "tags": "inheritance,rename,redefine,undefine,select,export",
            "category": "architect",
            "difficulty": 3,
            "source_origin": "eiffel.org"
        },
        {
            "question": "How do I write preconditions and postconditions?",
            "keywords": "precondition postcondition require ensure contract",
            "answer": """**Preconditions (require):**
```eiffel
divide (a, b: REAL): REAL
    require
        non_zero_divisor: b /= 0
    do
        Result := a / b
    end
```

**Postconditions (ensure):**
```eiffel
increment
    do
        count := count + 1
    ensure
        incremented: count = old count + 1
    end
```

**Combined example:**
```eiffel
push (item: G)
    require
        not_full: count < capacity
    do
        count := count + 1
        data [count] := item
    ensure
        one_more: count = old count + 1
        item_on_top: data [count] = item
    end
```

**Tags are optional but recommended:**
```eiffel
require
    valid_index: i >= 1 and i <= count
    -- Tag 'valid_index' helps debugging
```""",
            "sources": "https://www.eiffel.org/doc/eiffel/Eiffel_programming_language_syntax",
            "tags": "precondition,postcondition,require,ensure,contract",
            "category": "dbc",
            "difficulty": 2,
            "source_origin": "eiffel.org"
        },
        {
            "question": "What is a once function in Eiffel?",
            "keywords": "once singleton cached memoization",
            "answer": """A `once` function executes only on first call, caching the result:

```eiffel
config: CONFIGURATION
    once
        create Result.load ("app.conf")
    end
-- First call creates and returns config
-- Subsequent calls return same object
```

**Once per object:**
```eiffel
cache: HASH_TABLE [STRING, INTEGER]
    once ("OBJECT")
        create Result.make (100)
    end
-- Each object gets its own cache
```

**Once per thread:**
```eiffel
thread_local_data: MY_DATA
    once ("THREAD")
        create Result.make
    end
-- Each thread gets its own instance
```

**Once per process (default):**
```eiffel
shared_resource: RESOURCE
    once ("PROCESS")  -- or just 'once'
        create Result.make
    end
-- Single instance for entire application
```

Common uses: singletons, constants, cached computations.""",
            "sources": "https://www.eiffel.org/doc/eiffel/Eiffel_programming_language_syntax",
            "tags": "once,singleton,cached,memoization",
            "category": "architect",
            "difficulty": 2,
            "source_origin": "eiffel.org"
        },
        {
            "question": "How do I handle exceptions in Eiffel?",
            "keywords": "exception rescue retry error handling",
            "answer": """Use `rescue` clause for exception handling:

```eiffel
read_file (path: STRING): STRING
    local
        file: PLAIN_TEXT_FILE
        retried: BOOLEAN
    do
        if not retried then
            create file.make_open_read (path)
            Result := file.read_stream (file.count)
            file.close
        else
            Result := ""  -- Default on failure
        end
    rescue
        retried := True
        if attached file as f and then f.is_open_read then
            f.close
        end
        retry  -- Re-execute do block
    end
```

**Key concepts:**
- `rescue` - Exception handler block
- `retry` - Re-execute do block
- Use local BOOLEAN to detect retry

**Best practice - contracts over exceptions:**
```eiffel
divide (a, b: REAL): REAL
    require
        non_zero: b /= 0  -- Prevent exception with contract
    do
        Result := a / b
    end
```""",
            "sources": "https://www.eiffel.org/doc/eiffel/Eiffel_programming_language_syntax",
            "tags": "exception,rescue,retry,error,handling",
            "category": "architect",
            "difficulty": 3,
            "source_origin": "eiffel.org"
        },
        {
            "question": "What are Certified Attachment Patterns (CAP)?",
            "keywords": "cap certified attachment pattern void safety",
            "answer": """Certified Attachment Patterns (CAP) are compiler-verified patterns ensuring void-safe code:

**Object Test Pattern:**
```eiffel
if attached my_attribute as ma then
    -- ma guaranteed non-void here
    io.put_string (ma)
end
```

**Check Pattern:**
```eiffel
check attached internal_data as id then
    -- Programmer certifies this will succeed
    Result := id.value
end
```

**Stable Attribute Pattern:**
```eiffel
cache: detachable STRING
    note option: stable end

-- Once attached, compiler knows it stays attached
```

**Result Attachment:**
```eiffel
item: G
    require
        not_empty: not is_empty
    do
        Result := data [index]
    ensure
        attached Result  -- Guaranteed by precondition
    end
```

CAPs eliminate null-pointer errors at compile time.""",
            "sources": "https://www.eiffel.org/doc/solutions/Void-safe_programming_in_Eiffel",
            "tags": "cap,certified,attachment,void-safety",
            "category": "architect",
            "difficulty": 3,
            "source_origin": "eiffel.org"
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
                faq.get("source_origin", "eiffel.org")
            ))
            inserted += 1
        except Exception as e:
            print(f"Error: {faq['question'][:40]}... - {e}")

    conn.commit()
    print(f"Inserted {inserted} FAQ pairs from Eiffel.org")

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

    cursor.execute("SELECT source_origin, COUNT(*) FROM faqs GROUP BY source_origin")
    print("\nBy source:")
    for row in cursor.fetchall():
        print(f"  {row[0]}: {row[1]}")

    conn.close()

if __name__ == "__main__":
    main()
