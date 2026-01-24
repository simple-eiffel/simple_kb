# S06-BOUNDARIES.md

**Library:** simple_kb
**Status:** BACKWASH (reverse-engineered from implementation)
**Date:** 2026-01-23

---

## 1. Input Boundaries

### Search Queries

| Boundary | Value | Behavior |
|----------|-------|----------|
| Empty | "" | Precondition violation |
| Single char | "a" | Valid, may return many results |
| Long query | 10000+ chars | Truncated or rejected |
| SQL injection | "'; DROP TABLE" | Escaped by parameterized query |
| FTS5 special | "NEAR/5" | Interpreted as FTS5 syntax |

### Error Codes

| Boundary | Value | Behavior |
|----------|-------|----------|
| Empty | "" | Returns Void |
| Unknown | "ZZZZ" | Returns Void |
| Case | "vevi" vs "VEVI" | Case-insensitive lookup |
| Whitespace | " VEVI " | Trimmed |

### Class Names

| Boundary | Value | Behavior |
|----------|-------|----------|
| Empty | "" | Returns Void |
| Unknown | "NONEXISTENT" | Returns Void |
| Case | "json_parser" | Case-insensitive |
| Partial | "JSON*" | Not supported (exact match) |

### Result Limits

| Boundary | Value | Behavior |
|----------|-------|----------|
| Zero | 0 | Precondition violation |
| Negative | -1 | Precondition violation |
| One | 1 | Returns single result |
| Very large | 10000 | Returns available (capped) |

## 2. Output Boundaries

### Search Results

| Condition | Output |
|-----------|--------|
| No matches | Empty list (not Void) |
| Single match | List with 1 item |
| Many matches | List capped at limit |
| All content types | Mixed types in results |

### Single Lookups

| Condition | Output |
|-----------|--------|
| Found | Object with data |
| Not found | Void (detachable) |
| Database error | Void + has_error |

### Statistics

| Boundary | Behavior |
|----------|----------|
| Empty database | All counts = 0 |
| NULL values | Treated as 0 |

## 3. Database State Boundaries

### Connection State

| State | Operations Allowed |
|-------|-------------------|
| is_open = True | All operations |
| is_open = False | None (precondition fails) |

### FTS5 Availability

| State | Behavior |
|-------|----------|
| FTS5 available | Full search functionality |
| FTS5 unavailable | fts5_available = False, search fails |

### Error State

| has_error | Meaning |
|-----------|---------|
| False | Last operation succeeded |
| True | Check last_error for details |

## 4. Content Boundaries

### Code Field Lengths

| Field | Typical | Maximum |
|-------|---------|---------|
| Example code | 100-500 lines | No hard limit |
| Pattern code | 20-100 lines | No hard limit |
| Error examples | 10-30 lines | No hard limit |

### Description Lengths

| Field | Typical | Maximum |
|-------|---------|---------|
| Class description | 1-3 sentences | TEXT (unlimited) |
| Error explanation | 1-5 paragraphs | TEXT |
| Pattern when_to_use | 1-3 sentences | TEXT |

### Collection Sizes

| Field | Format | Typical Size |
|-------|--------|--------------|
| common_causes | JSON array | 2-5 items |
| fixes | JSON array | 1-3 items |
| tags | JSON array | 1-10 items |
| eiffel_idioms | JSON array | 1-5 items |

## 5. FTS5 Boundaries

### Ranking Scores

| Score | Meaning |
|-------|---------|
| Near 0 | Best match |
| Negative | BM25 produces negative scores |
| Large negative | Worse match |

### Snippet Lengths

| Setting | Value |
|---------|-------|
| Max tokens | 50 |
| Highlight start | ">>>" |
| Highlight end | "<<<" |
| Ellipsis | "..." |

### Boolean Logic

| Expression | Behavior |
|------------|----------|
| term1 term2 | AND (both required) |
| term1 OR term2 | Either term |
| NOT term | Exclude term |
| "phrase" | Exact sequence |
| term* | Prefix match |

## 6. File System Boundaries

### Database File

| Boundary | Behavior |
|----------|----------|
| File doesn't exist | Created on first write |
| File is read-only | has_error = True |
| Disk full | has_error = True |
| Path too long | OS-dependent error |

### In-Memory Database

| Boundary | Behavior |
|----------|----------|
| Created | db_path = ":memory:" |
| Closed | Data lost |
| Memory exhausted | OS-dependent error |

## 7. Integration Boundaries

### simple_eiffel_parser

| Boundary | Handling |
|----------|----------|
| Parse error | Skip file, log error |
| Invalid Eiffel | Best-effort extraction |
| Missing file | Skip, continue |

### simple_rosetta

| Boundary | Handling |
|----------|----------|
| Database not found | Return empty |
| Invalid format | Skip entries |
| Duplicate titles | Update existing |

## 8. CLI Boundaries

### Command Arguments

| Boundary | Behavior |
|----------|----------|
| No arguments | Show usage |
| Unknown command | Error message |
| Missing required arg | Error message |

### Output Formatting

| Boundary | Behavior |
|----------|----------|
| Terminal width | Wrapping applied |
| Non-TTY | No pagination |
| Very long output | Paged (if TTY) |

---

*Generated as backwash specification from existing implementation.*
