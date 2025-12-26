#!/usr/bin/env python3
"""
Populate KB FAQs from code study findings.
Run: python3 populate_faqs.py
"""

import sqlite3
import os

DB_PATH = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'bin', 'kb.db')

def main():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    # FAQ entries from the 4 studies
    faqs = [
        # ============== STUDY 1: MULTIPLE INHERITANCE ==============
        {
            "question": "How do I combine an interface with an implementation in Eiffel?",
            "keywords": "multiple inheritance mixin interface implementation composition",
            "answer": """Use multiple inheritance with one parent providing implementation and another providing the interface:

```eiffel
class ARRAYED_STACK [G]
inherit
    ARRAYED_LIST [G]      -- Implementation (storage)
        export {NONE} all   -- Hide implementation details
        redefine copy, is_equal
        end
    STACK [G]             -- Interface (operations)
        undefine is_equal, copy
        end
```

Key points:
- ARRAYED_LIST provides the storage mechanism
- STACK defines the abstract dispenser behavior
- `export {NONE}` hides ARRAYED_LIST features from clients
- `undefine` resolves diamond conflicts from common ancestors

This is the dominant pattern in EiffelBase.""",
            "sources": "ISE EiffelStudio 25.02: base/elks/structures/dispenser/arrayed_stack.e",
            "tags": "multiple-inheritance,mixin,composition,patterns",
            "category": "architect",
            "difficulty": 3,
            "related_classes": "ARRAYED_STACK,ARRAYED_QUEUE,LINKED_STACK,STACK,ARRAYED_LIST",
            "source_origin": "code-study"
        },
        {
            "question": "When should I use export {NONE} in inheritance?",
            "keywords": "export none inheritance hiding implementation private",
            "answer": """Use `export {NONE}` when inheriting implementation that should be hidden from clients:

```eiffel
inherit
    ARRAYED_LIST [G]
        export {NONE} all   -- Hide all ARRAYED_LIST features
        end
```

Common use cases:
1. Mixin pattern: Hide storage implementation while exposing interface
2. Implementation inheritance: Use parent's code without exposing its API
3. Selective hiding: `export {NONE} feature_1, feature_2`

Re-export with `export {ANY}` if needed.""",
            "sources": "ISE EiffelStudio 25.02: base/elks/structures/dispenser/arrayed_stack.e",
            "tags": "export,inheritance,encapsulation,visibility",
            "category": "architect",
            "difficulty": 2,
            "related_classes": "ARRAYED_STACK,HASH_TABLE",
            "source_origin": "code-study"
        },
        {
            "question": "What is non-conforming inheritance in Eiffel?",
            "keywords": "non-conforming inheritance inherit none implementation",
            "answer": """Non-conforming inheritance (`inherit {NONE}`) means you use a parent's implementation without establishing a type relationship:

```eiffel
class ROUTINE
inherit
    HASHABLE
inherit {NONE}              -- Non-conforming!
    REFLECTOR
        export {NONE} all
        end
```

ROUTINE uses REFLECTOR's features but is NOT a REFLECTOR subtype. Prevents invalid polymorphic assignments.

Use when the IS-A relationship doesn't make semantic sense.""",
            "sources": "ISE EiffelStudio 25.02: base/elks/kernel/routine.e",
            "tags": "non-conforming,inheritance,implementation,type-system",
            "category": "architect",
            "difficulty": 4,
            "related_classes": "ROUTINE,REFLECTOR",
            "source_origin": "code-study"
        },
        {
            "question": "How do I resolve diamond inheritance conflicts in Eiffel?",
            "keywords": "diamond inheritance conflict resolution undefine select rename",
            "answer": """Eiffel provides four mechanisms:

1. **undefine** - Remove one version:
```eiffel
inherit STACK [G] undefine is_equal end
```

2. **rename** - Different names:
```eiffel
inherit CELL [G] rename item as node_item end
```

3. **select** - Choose for dynamic binding:
```eiffel
inherit PARENT_A select feature_x end
```

4. **redefine** - Override entirely:
```eiffel
inherit PARENT redefine problematic_feature end
```""",
            "sources": "ISE EiffelStudio 25.02: base/elks/structures/tree/linked_tree.e",
            "tags": "diamond,inheritance,conflict-resolution,rename,undefine,select",
            "category": "architect",
            "difficulty": 4,
            "related_classes": "LINKED_TREE,DYNAMIC_TREE,CELL,LINKED_LIST",
            "source_origin": "code-study"
        },
        {
            "question": "How many parents can an Eiffel class have?",
            "keywords": "multiple inheritance parents limit composition",
            "answer": """No fixed limit. Canonical classes commonly have 3-5 parents:

HASH_TABLE has 5:
- TABLE (key-value semantics)
- READABLE_INDEXABLE (array-like access)
- TABLE_ITERABLE (across support)
- MISMATCH_CORRECTOR (serialization)
- DEBUG_OUTPUT (debugging)

Each parent serves a distinct purpose - MI is principled composition.""",
            "sources": "ISE EiffelStudio 25.02: base/elks/structures/table/hash_table.e",
            "tags": "multiple-inheritance,composition,design,parents",
            "category": "architect",
            "difficulty": 2,
            "related_classes": "HASH_TABLE,STRING,LINKED_TREE,ARRAYED_STACK",
            "source_origin": "code-study"
        },

        # ============== STUDY 2: DBC PATTERNS ==============
        {
            "question": "What is the difference between require and require else?",
            "keywords": "require else precondition inheritance contract weakening",
            "answer": """**require** replaces parent precondition.

**require else** ORs with parent (weaker):
```eiffel
class PARENT
    process (n: INTEGER)
        require positive: n > 0

class CHILD inherit PARENT
    process (n: INTEGER)
        require else zero_allowed: n = 0
        -- Effective: n > 0 OR n = 0
```

This implements Liskov Substitution: child accepts at least what parent accepts.""",
            "sources": "ECMA-367 Standard, Meyer OOSC2",
            "tags": "dbc,precondition,inheritance,liskov,contracts",
            "category": "dbc",
            "difficulty": 3,
            "related_errors": "VDRD",
            "source_origin": "code-study"
        },
        {
            "question": "How do I use old in postconditions?",
            "keywords": "old postcondition ensure state before after",
            "answer": """The `old` keyword captures pre-call values:

```eiffel
extend (v: G)
    ensure
        one_more: count = old count + 1
        same_lower: lower = old lower
```

`old count` is evaluated BEFORE the routine, compared AFTER.

Common patterns:
- Size change: `count = old count + 1`
- Unchanged: `attr = old attr`
- Relations: `balance = old balance - amount`""",
            "sources": "ISE EiffelStudio 25.02: base/elks/structures/list/arrayed_list.e",
            "tags": "dbc,postcondition,old,ensure,contracts",
            "category": "dbc",
            "difficulty": 2,
            "related_classes": "ARRAYED_LIST,LINKED_LIST,HASH_TABLE",
            "source_origin": "code-study"
        },
        {
            "question": "What makes a good class invariant?",
            "keywords": "invariant class design contract representation",
            "answer": """A good invariant captures what it MEANS to be valid. From ARRAY:

```eiffel
invariant
    non_negative_count: count >= 0
    count_bounded: count <= capacity
    consistent_bounds: upper - lower + 1 = count
```

Categories:
1. Representation: `count <= capacity`
2. Structural: `upper - lower + 1 = count`
3. Ordering (COMPARABLE): `not (Current < Current)`
4. Bidirectional: `attached parent implies parent.has (Current)`

Invariants hold BETWEEN public calls, not during execution.""",
            "sources": "ISE EiffelStudio 25.02: base/elks/kernel/array.e",
            "tags": "dbc,invariant,design,contracts,class-design",
            "category": "dbc",
            "difficulty": 3,
            "related_classes": "ARRAY,COMPARABLE,LINKED_LIST",
            "source_origin": "code-study"
        },
        {
            "question": "How do I prove a loop terminates in Eiffel?",
            "keywords": "loop variant termination proof from until",
            "answer": """Use a loop variant - decreasing non-negative integer:

```eiffel
from i := count
invariant i >= 0
variant i
until i = 0
loop
    process (item (i))
    i := i - 1
end
```

Rules:
1. Must be INTEGER
2. Must be >= 0 at start and each iteration
3. Must DECREASE each iteration
4. Terminates when would become negative""",
            "sources": "ISE EiffelStudio 25.02: base/elks/structures/list/linked_list.e",
            "tags": "dbc,loop,variant,termination,proof",
            "category": "dbc",
            "difficulty": 3,
            "source_origin": "code-study"
        },
        {
            "question": "How does contract inheritance work in Eiffel?",
            "keywords": "contract inheritance precondition postcondition liskov",
            "answer": """Follows Liskov Substitution:

**Preconditions WEAKEN** (require else = OR):
Child accepts at least what parent accepts.

**Postconditions STRENGTHEN** (ensure then = AND):
Child guarantees at least what parent guarantees.

```eiffel
class CHILD inherit PARENT
    feature_x
        require else weaker_pre
        do ...
        ensure then stronger_post
    end
```

This is LSP implemented in the type system.""",
            "sources": "ECMA-367, Meyer OOSC2 Chapter 16",
            "tags": "dbc,inheritance,liskov,contracts,lsp",
            "category": "dbc",
            "difficulty": 4,
            "source_origin": "code-study"
        },

        # ============== STUDY 3: ITERATION PATTERNS ==============
        {
            "question": "How do I iterate over a list in Eiffel?",
            "keywords": "iterate list loop across cursor",
            "answer": """Use `across` (modern, preferred):

```eiffel
across my_list as cursor loop
    io.put_string (cursor.item.out)
end
```

With index:
```eiffel
across my_array as c loop
    print (c.cursor_index.out + ": " + c.item.out)
end
```

Traditional style:
```eiffel
from list.start until list.after loop
    print (list.item.out)
    list.forth
end
```""",
            "sources": "ISE EiffelStudio 25.02: base/elks/kernel/iterable.e",
            "tags": "iteration,across,loop,cursor,list",
            "category": "newcomer",
            "difficulty": 1,
            "related_classes": "ITERABLE,ITERATION_CURSOR,ARRAYED_LIST,LINKED_LIST",
            "source_origin": "code-study"
        },
        {
            "question": "What is the difference between across and from/until/loop?",
            "keywords": "across from until loop iteration difference",
            "answer": """**across** (modern):
- External cursor object
- Multiple simultaneous iterations
- Cleaner syntax

**from/until/loop** (traditional):
- Internal cursor (container state)
- One iteration at a time
- Can use variant/invariant for proofs

Use `across` by default. Use `from/until` when you need loop proofs.""",
            "sources": "ISE EiffelStudio 25.02",
            "tags": "iteration,across,loop,comparison",
            "category": "newcomer",
            "difficulty": 2,
            "related_classes": "ITERABLE,ITERATION_CURSOR",
            "source_origin": "code-study"
        },
        {
            "question": "How do I check if all elements satisfy a condition?",
            "keywords": "all quantifier across every element condition",
            "answer": """Use `across ... all` (universal quantifier):

```eiffel
if across list as c all c.item > 0 end then
    print ("All positive")
end
```

Empty collection returns True (vacuous truth).

In postconditions:
```eiffel
ensure
    all_valid: across items as i all i.item.is_valid end
```""",
            "sources": "ISE EiffelStudio 25.02",
            "tags": "iteration,quantifier,all,across,condition",
            "category": "newcomer",
            "difficulty": 2,
            "source_origin": "code-study"
        },
        {
            "question": "How do I check if any element satisfies a condition?",
            "keywords": "some any quantifier across exists element",
            "answer": """Use `across ... some` (existential quantifier):

```eiffel
if across list as c some c.item < 0 end then
    print ("Found negative")
end
```

Empty collection returns False.

Stops at first True (efficient for search).""",
            "sources": "ISE EiffelStudio 25.02",
            "tags": "iteration,quantifier,some,across,exists",
            "category": "newcomer",
            "difficulty": 2,
            "source_origin": "code-study"
        },
        {
            "question": "How do I iterate over a hash table's keys and values?",
            "keywords": "hash table iterate keys values across cursor",
            "answer": """The cursor provides both `key` and `item`:

```eiffel
across my_hash as c loop
    print ("Key: " + c.key.out)
    print (", Value: " + c.item.out)
end
```

TABLE_ITERATION_CURSOR exposes:
- `c.item` - the value
- `c.key` - the key""",
            "sources": "ISE EiffelStudio 25.02: base/elks/support/table_iteration_cursor.e",
            "tags": "iteration,hash-table,keys,values,across",
            "category": "newcomer",
            "difficulty": 2,
            "related_classes": "HASH_TABLE,TABLE_ITERATION_CURSOR,TABLE",
            "source_origin": "code-study"
        },
        {
            "question": "How do I make my own class work with across?",
            "keywords": "iterable across custom class new_cursor",
            "answer": """Inherit ITERABLE and implement `new_cursor`:

```eiffel
class MY_CONTAINER [G]
inherit ITERABLE [G]

feature
    new_cursor: ITERATION_CURSOR [G]
        do
            create {MY_CURSOR [G]} Result.make (Current)
        end
end
```

Create a cursor class with `item`, `after`, and `forth`.""",
            "sources": "ISE EiffelStudio 25.02: base/elks/kernel/iterable.e",
            "tags": "iterable,cursor,custom-class,across",
            "category": "architect",
            "difficulty": 3,
            "related_classes": "ITERABLE,ITERATION_CURSOR",
            "source_origin": "code-study"
        },
        {
            "question": "Why can't I modify a collection during across iteration?",
            "keywords": "modify collection iteration concurrent modification",
            "answer": """Modifying invalidates the cursor:

DON'T:
```eiffel
across list as c loop
    if c.item < 0 then list.remove end  -- BAD!
end
```

DO: Collect then modify:
```eiffel
across list as c loop
    if c.item < 0 then to_remove.extend (c.item) end
end
across to_remove as c loop
    list.prune (c.item)
end
```""",
            "sources": "General principle",
            "tags": "iteration,modification,concurrent,collection",
            "category": "newcomer",
            "difficulty": 2,
            "source_origin": "code-study"
        },

        # ============== STUDY 4: OBSERVER/EVENT PATTERNS ==============
        {
            "question": "How do I implement the Observer pattern in Eiffel?",
            "keywords": "observer pattern event action_sequence subscribe notify",
            "answer": """Use ACTION_SEQUENCE - Eiffel's componentized Observer:

```eiffel
class SENSOR
feature
    temp_changed: ACTION_SEQUENCE [TUPLE [INTEGER]]

    set_temp (t: INTEGER)
        do
            temperature := t
            temp_changed.call ([t])  -- Notify all
        end
end
```

Subscribe:
```eiffel
sensor.temp_changed.extend (agent display.update (?))
```

No explicit Observer interface needed - agents are type-safe callbacks.""",
            "sources": "ISE EiffelStudio 25.02: base/ise/event/action_sequence.e",
            "tags": "observer,pattern,action-sequence,event,subscribe",
            "category": "architect",
            "difficulty": 3,
            "related_classes": "ACTION_SEQUENCE,EVENT_TYPE,PROCEDURE",
            "source_origin": "code-study"
        },
        {
            "question": "What is ACTION_SEQUENCE and how do I use it?",
            "keywords": "action_sequence event container procedure",
            "answer": """A list of procedures that execute when `call` is invoked:

```eiffel
on_save: ACTION_SEQUENCE [TUPLE [STRING]]

-- Subscribe
on_save.extend (agent backup (?))

-- Notify
on_save.call ([filename])

-- Unsubscribe
on_save.prune (agent backup)

-- Control
on_save.pause / on_save.resume / on_save.block
```""",
            "sources": "ISE EiffelStudio 25.02: base/ise/event/action_sequence.e",
            "tags": "action-sequence,event,procedure,callback",
            "category": "architect",
            "difficulty": 2,
            "related_classes": "ACTION_SEQUENCE,INTERACTIVE_LIST,PROCEDURE",
            "source_origin": "code-study"
        },
        {
            "question": "How do I subscribe to button clicks in Vision2?",
            "keywords": "vision2 button click event subscribe gui",
            "answer": """Use `select_actions`:

```eiffel
create button.make_with_text ("Click Me")
button.select_actions.extend (agent on_clicked)
```

Common Vision2 events:
- `button.select_actions` - click
- `window.close_request_actions` - close
- `text_field.change_actions` - text change
- `list.select_actions` - selection""",
            "sources": "ISE EiffelStudio 25.02: vision2/interface/widgets/primitives/ev_button.e",
            "tags": "vision2,gui,button,click,event",
            "category": "newcomer",
            "difficulty": 2,
            "related_classes": "EV_BUTTON,EV_ACTION_SEQUENCE,EV_WIDGET",
            "source_origin": "code-study"
        },
        {
            "question": "What is the difference between ACTION_SEQUENCE and EVENT_TYPE?",
            "keywords": "action_sequence event_type difference patterns",
            "answer": """ACTION_SEQUENCE (EiffelBase):
- Direct `extend/prune/call`
- pause/block/resume
- Lighter weight

EVENT_TYPE (Patterns Library):
- Formal `subscribe/unsubscribe/publish`
- suspend/restore semantics
- Interface-based (EVENT_TYPE_I)

Use ACTION_SEQUENCE for simple events, EVENT_TYPE for formal systems.""",
            "sources": "ISE EiffelStudio 25.02",
            "tags": "action-sequence,event-type,comparison,patterns",
            "category": "architect",
            "difficulty": 3,
            "related_classes": "ACTION_SEQUENCE,EVENT_TYPE",
            "source_origin": "code-study"
        },
        {
            "question": "How do I pause event notifications temporarily?",
            "keywords": "pause event notification action_sequence suspend",
            "answer": """ACTION_SEQUENCE:
```eiffel
events.pause      -- Buffer events
do_bulk_work
events.resume     -- Execute buffered

events.block      -- Discard events
cleanup
events.resume
```

EVENT_TYPE:
```eiffel
event.suspend_subscriptions
do_work
event.restore_subscriptions
```""",
            "sources": "ISE EiffelStudio 25.02: base/ise/event/action_sequence.e",
            "tags": "pause,suspend,event,action-sequence,batch",
            "category": "architect",
            "difficulty": 2,
            "related_classes": "ACTION_SEQUENCE,EVENT_TYPE",
            "source_origin": "code-study"
        },
        {
            "question": "How do I create a one-time event subscription?",
            "keywords": "one-time single subscription kamikaze event",
            "answer": """Use `extend_kamikaze`:

```eiffel
init_events.extend_kamikaze (agent on_first_init)
-- Auto-unsubscribes after first call
```

Or EVENT_TYPE:
```eiffel
init_ready.subscribe_for_single_notification (agent on_complete)
```""",
            "sources": "ISE EiffelStudio 25.02: base/ise/event/action_sequence.e",
            "tags": "one-time,kamikaze,subscription,event",
            "category": "architect",
            "difficulty": 2,
            "related_classes": "ACTION_SEQUENCE,EVENT_TYPE",
            "source_origin": "code-study"
        },
        {
            "question": "How do I pass data with events in Eiffel?",
            "keywords": "event data tuple parameter action_sequence",
            "answer": """Use TUPLE to define event data:

```eiffel
mouse_clicked: ACTION_SEQUENCE [TUPLE [x, y: INTEGER; button: CHARACTER]]

-- Call
mouse_clicked.call ([100, 200, 'L'])

-- Subscribe
mouse_clicked.extend (agent on_mouse (?, ?, ?))

-- Partial application
mouse_clicked.extend (agent log (?, ?, "mouse.log"))
```""",
            "sources": "ISE EiffelStudio 25.02",
            "tags": "event,data,tuple,parameter,agent",
            "category": "architect",
            "difficulty": 2,
            "related_classes": "ACTION_SEQUENCE,TUPLE,PROCEDURE",
            "source_origin": "code-study"
        },
        {
            "question": "How do I unsubscribe from an event in Eiffel?",
            "keywords": "unsubscribe remove event handler prune",
            "answer": """Use `prune` with the same agent reference:

```eiffel
my_handler: PROCEDURE

subscribe
    do
        my_handler := agent on_data (?)
        events.extend (my_handler)
    end

unsubscribe
    do
        events.prune (my_handler)
    end
```

Must keep reference to exact agent used for subscription.""",
            "sources": "ISE EiffelStudio 25.02",
            "tags": "unsubscribe,prune,event,cleanup",
            "category": "architect",
            "difficulty": 2,
            "related_classes": "ACTION_SEQUENCE,EVENT_TYPE,PROCEDURE",
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
            print(f"Error inserting FAQ: {faq['question'][:50]}... - {e}")

    conn.commit()
    print(f"Successfully inserted {inserted} FAQ pairs")

    # Show stats
    cursor.execute("SELECT COUNT(*) FROM faqs")
    total = cursor.fetchone()[0]
    print(f"Total FAQs in database: {total}")

    cursor.execute("SELECT category, COUNT(*) FROM faqs GROUP BY category")
    print("\nFAQs by category:")
    for row in cursor.fetchall():
        print(f"  {row[0] or 'uncategorized'}: {row[1]}")

    conn.close()

if __name__ == "__main__":
    main()
