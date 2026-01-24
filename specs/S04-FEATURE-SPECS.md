# S04-FEATURE-SPECS.md

**Library:** simple_kb
**Status:** BACKWASH (reverse-engineered from implementation)
**Date:** 2026-01-23

---

## 1. KB_QUICK Features

### Creation

```eiffel
make
    -- Create with default database path.
    -- Path resolved from SIMPLE_EIFFEL environment variable or current directory.

make_with_path (a_path: READABLE_STRING_GENERAL)
    -- Create with specific database path.
    require
        path_not_empty: not a_path.is_empty
```

### Search Operations

```eiffel
search (a_query: READABLE_STRING_GENERAL): ARRAYED_LIST [KB_RESULT]
    -- Search knowledge base (default 10 results).
    require
        db_open: db.is_open
```

**Behavior:** Performs FTS5 full-text search across all indexed content. Returns results ranked by BM25 relevance score.

```eiffel
search_limit (a_query: READABLE_STRING_GENERAL; a_limit: INTEGER): ARRAYED_LIST [KB_RESULT]
    -- Search with custom result limit.
    require
        db_open: db.is_open
        positive_limit: a_limit > 0
```

### Error Lookup

```eiffel
error (a_code: READABLE_STRING_GENERAL): detachable KB_ERROR_INFO
    -- Get error info by code (e.g., "VEVI", "VD89").
    require
        db_open: db.is_open
```

**Behavior:** Looks up compiler error code and returns explanation, causes, and fixes.

```eiffel
print_error (a_code: READABLE_STRING_GENERAL)
    -- Print error info to stdout.
```

**Behavior:** Prints formatted error explanation or "Error code not found" message.

### Class Lookup

```eiffel
class_info (a_name: READABLE_STRING_GENERAL): detachable KB_CLASS_INFO
    -- Get class info by name.
    require
        db_open: db.is_open
```

```eiffel
print_class (a_name: READABLE_STRING_GENERAL)
    -- Print class info to stdout.
```

### Example Lookup

```eiffel
example (a_title: READABLE_STRING_GENERAL): detachable KB_EXAMPLE
    -- Get example by exact title.
    require
        db_open: db.is_open

search_examples (a_query: READABLE_STRING_GENERAL): ARRAYED_LIST [KB_EXAMPLE]
    -- Search examples by keyword.
    require
        db_open: db.is_open

print_example (a_title: READABLE_STRING_GENERAL)
    -- Print example to stdout.
```

### Pattern Lookup

```eiffel
pattern (a_name: READABLE_STRING_GENERAL): detachable KB_PATTERN
    -- Get pattern by name (e.g., "singleton", "factory").
    require
        db_open: db.is_open

print_pattern (a_name: READABLE_STRING_GENERAL)
    -- Print pattern to stdout.
```

### Statistics

```eiffel
stats: TUPLE [classes, features, examples, errors, patterns: INTEGER]
    -- Database content counts.
    require
        db_open: db.is_open

print_stats
    -- Print statistics to stdout.
```

### Cleanup

```eiffel
close
    -- Close database connection.
```

## 2. KB_DATABASE Features

### Schema Management

```eiffel
ensure_schema
    -- Create all tables if not exists.
    require
        is_open: is_open
```

**Creates Tables:**
- classes (id, library, name, description, file_path, is_deferred, is_expanded, is_frozen, generics)
- features (id, class_id, name, signature, description, kind, is_deferred, is_frozen, is_once, preconditions, postconditions)
- class_parents (class_id, parent_name)
- libraries (name, path, description)
- examples (id, title, source, code, tags, tier)
- errors (id, code, meaning, explanation, common_causes, fixes, examples)
- patterns (id, name, description, code, when_to_use, eiffel_idioms)
- translations (id, source_lang, source_pattern, eiffel_pattern, notes)
- kb_search (FTS5 virtual table)

### Search

```eiffel
search (a_query: READABLE_STRING_GENERAL; a_limit: INTEGER): ARRAYED_LIST [KB_RESULT]
    -- Full-text search across all content.
    require
        is_open: is_open
        positive_limit: a_limit > 0
```

**Behavior:**
1. Executes FTS5 MATCH query against kb_search table
2. Results ranked by BM25 algorithm
3. Returns KB_RESULT objects with snippets

### Error Operations

```eiffel
get_error (a_code: READABLE_STRING_GENERAL): detachable KB_ERROR_INFO
    -- Lookup error by code.

add_error (a_code, a_meaning, a_explanation: READABLE_STRING_GENERAL;
           a_causes, a_fixes: LIST [STRING_32]; a_examples: READABLE_STRING_GENERAL)
    -- Add or update error entry.
```

### Class Operations

```eiffel
find_class (a_name: READABLE_STRING_GENERAL): detachable KB_CLASS_INFO
    -- Find class by name.

add_class (a_library, a_name: READABLE_STRING_GENERAL;
           a_description, a_file_path: detachable STRING_32;
           a_is_deferred, a_is_expanded, a_is_frozen: BOOLEAN;
           a_generics: detachable STRING_32): INTEGER
    -- Add class, return id.

list_classes (a_library: detachable READABLE_STRING_GENERAL): ARRAYED_LIST [KB_CLASS_INFO]
    -- List classes, optionally filtered by library.
```

### Feature Operations

```eiffel
add_feature (a_class_id: INTEGER; a_name: READABLE_STRING_GENERAL;
             a_signature, a_description, a_kind: detachable STRING_32;
             a_is_deferred, a_is_frozen, a_is_once: BOOLEAN;
             a_preconditions, a_postconditions: detachable STRING_32)
    -- Add feature to class.

get_features (a_class_id: INTEGER): ARRAYED_LIST [KB_FEATURE_INFO]
    -- Get all features for class.
```

### Example Operations

```eiffel
get_example (a_title: READABLE_STRING_GENERAL): detachable KB_EXAMPLE
    -- Get example by exact title.

search_examples (a_query: READABLE_STRING_GENERAL; a_limit: INTEGER): ARRAYED_LIST [KB_EXAMPLE]
    -- Search examples.

add_example (a_title, a_code: READABLE_STRING_GENERAL;
             a_source: detachable STRING_32;
             a_tags: detachable LIST [STRING_32];
             a_tier: detachable STRING_32)
    -- Add example.
```

### Pattern Operations

```eiffel
get_pattern (a_name: READABLE_STRING_GENERAL): detachable KB_PATTERN
    -- Get pattern by name.

add_pattern (a_name: READABLE_STRING_GENERAL;
             a_description, a_code, a_when_to_use: detachable STRING_32;
             a_idioms: detachable LIST [STRING_32])
    -- Add pattern.
```

## 3. CLI Commands

### eiffel-kb CLI

| Command | Usage | Description |
|---------|-------|-------------|
| search | `eiffel-kb search "query"` | Full-text search |
| class | `eiffel-kb class JSON_PARSER` | Show class details |
| feature | `eiffel-kb feature SIMPLE_HTTP.get` | Show feature details |
| error | `eiffel-kb error VEVI` | Explain error code |
| example | `eiffel-kb example "bubble sort"` | Find example |
| pattern | `eiffel-kb pattern singleton` | Show pattern |
| stats | `eiffel-kb stats` | Database statistics |

### CLI Options

| Option | Description |
|--------|-------------|
| --limit N | Max results (default 10) |
| --json | Output as JSON |
| --verbose | Include full code snippets |

---

*Generated as backwash specification from existing implementation.*
