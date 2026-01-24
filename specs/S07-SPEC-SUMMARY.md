# S07-SPEC-SUMMARY.md

**Library:** simple_kb
**Status:** BACKWASH (reverse-engineered from implementation)
**Date:** 2026-01-23

---

## 1. Library Purpose

simple_kb provides an Eiffel Knowledge Base with FTS5 full-text search capabilities. It indexes:
- Eiffel classes and features from source code
- Compiler error codes with explanations and fixes
- Code examples from Rosetta Code and manual sources
- Design patterns with Eiffel idioms

Key differentiators from generic search tools:
- **Authoritative local source** - indexed from actual code, not hallucinated
- **Error code decoder** - VEVI, VD89, etc. with fixes
- **Cross-reference simple_* ecosystem** - unified search
- **Rosetta Code integration** - 274 working examples

## 2. API Summary

### Two Facades

| Facade | Purpose | Usage |
|--------|---------|-------|
| SIMPLE_KB | Type anchors | Reference KB types |
| KB_QUICK | Operations | One-liner convenience |

### Core Operations

| Category | Key Features |
|----------|--------------|
| Search | search, search_limit |
| Error Lookup | error, print_error |
| Class Lookup | class_info, print_class |
| Examples | example, search_examples |
| Patterns | pattern, print_pattern |
| Stats | stats, print_stats |

### Database Operations (KB_DATABASE)

| Category | Key Features |
|----------|--------------|
| Schema | ensure_schema |
| Error CRUD | get_error, add_error |
| Class CRUD | find_class, add_class, list_classes |
| Feature CRUD | add_feature, get_features |
| Example CRUD | get_example, search_examples, add_example |
| Pattern CRUD | get_pattern, add_pattern |

## 3. Data Model Summary

| Model | Key Fields | Purpose |
|-------|------------|---------|
| KB_RESULT | content_type, title, snippet, rank | FTS5 search result |
| KB_ERROR_INFO | code, meaning, common_causes, fixes | Compiler error |
| KB_CLASS_INFO | library, name, description | Indexed class |
| KB_FEATURE_INFO | name, signature, preconditions, postconditions | Class feature |
| KB_EXAMPLE | title, code, source, tier | Code example |
| KB_PATTERN | name, code, when_to_use, eiffel_idioms | Design pattern |

## 4. Contract Highlights

### Key Preconditions

- Database must be open for all operations
- Search queries must be non-empty
- Result limits must be positive

### Key Postconditions

- Database path set correctly after creation
- Search returns list (possibly empty), never Void

### Invariants

- Database connection always exists
- Database path always non-empty

## 5. Search Engine

### FTS5 Configuration

| Setting | Value |
|---------|-------|
| Tokenizer | porter unicode61 |
| Ranking | BM25 |
| Snippets | 50 tokens, highlighted |

### Query Syntax

| Syntax | Example |
|--------|---------|
| AND | "json parsing" |
| OR | "json OR xml" |
| NOT | "json NOT xml" |
| Prefix | "parse*" |
| Phrase | '"exact phrase"' |
| Field | "title:parser" |

## 6. CLI Summary

```
eiffel-kb <command> [options]

Commands:
  search <query>     - Full-text search
  class <name>       - Class details
  error <code>       - Error explanation
  example <topic>    - Code examples
  pattern <name>     - Design patterns
  stats              - Database statistics

Options:
  --limit N          - Max results
  --json             - JSON output
  --verbose          - Full snippets
```

## 7. Dependencies

| Library | Purpose |
|---------|---------|
| simple_sql | SQLite + FTS5 |
| simple_cli | CLI parsing |
| simple_json | JSON handling |
| simple_file | File operations |
| simple_eiffel_parser | Source parsing |
| simple_rosetta | Example import |

## 8. Usage Patterns

### Quick Lookup

```eiffel
kb: KB_QUICK
create kb.make

-- Error lookup
if attached kb.error ("VEVI") as err then
    print (err.formatted)
end

-- Class lookup
if attached kb.class_info ("JSON_PARSER") as cls then
    print (cls.formatted)
end

-- Search
across kb.search ("json parsing") as result loop
    print (result.item.title)
end
```

### Full Database Control

```eiffel
db: KB_DATABASE
create db.make ("my_kb.db")
db.ensure_schema

-- Add content
db.add_error ("TEST", "Test error", "Explanation", causes, fixes, examples)
db.add_class ("my_lib", "MY_CLASS", description, path, False, False, False, Void)

-- Search
results := db.search ("test", 10)
```

## 9. Limitations

| Limitation | Workaround |
|------------|------------|
| Not thread-safe | One instance per thread |
| FTS5 required | Check fts5_available |
| Manual index sync | Re-run ingester after changes |

---

*Generated as backwash specification from existing implementation.*
