# S03-CONTRACTS.md

**Library:** simple_kb
**Status:** BACKWASH (reverse-engineered from implementation)
**Date:** 2026-01-23

---

## 1. Class Invariants

### KB_QUICK

```eiffel
invariant
    db_not_void: db /= Void
```

### KB_DATABASE

```eiffel
invariant
    db_path_not_empty: not db_path.is_empty
    db_not_void: db /= Void
```

## 2. Preconditions by Class

### KB_QUICK

| Feature | Precondition | Rationale |
|---------|--------------|-----------|
| make_with_path | path_not_empty: not a_path.is_empty | Valid path required |
| search | db_open: db.is_open | Database must be ready |
| search_limit | db_open, positive_limit: a_limit > 0 | Valid parameters |
| error | db_open: db.is_open | Database must be ready |
| class_info | db_open: db.is_open | Database must be ready |
| example | db_open: db.is_open | Database must be ready |
| search_examples | db_open: db.is_open | Database must be ready |
| pattern | db_open: db.is_open | Database must be ready |
| stats | db_open: db.is_open | Database must be ready |

### KB_DATABASE

| Feature | Precondition | Rationale |
|---------|--------------|-----------|
| make | path_not_empty: not a_path.is_empty | Valid path required |
| ensure_schema | is_open: is_open | Database must be connected |
| fts5_available | is_open: is_open | Database must be connected |
| search | is_open, positive_limit | Valid parameters |
| get_error | is_open | Database must be connected |
| add_error | is_open, code_not_empty | Valid error code |
| find_class | is_open, name_not_empty | Valid class name |
| add_class | is_open, name_not_empty, library_not_empty | Required fields |
| add_feature | is_open, valid_class_id, name_not_empty | Valid references |
| get_example | is_open, title_not_empty | Valid lookup key |
| add_example | is_open, title_not_empty, code_not_empty | Required fields |
| get_pattern | is_open, name_not_empty | Valid lookup key |
| add_pattern | is_open, name_not_empty | Required field |

## 3. Postconditions by Class

### KB_DATABASE

| Feature | Postcondition | Rationale |
|---------|---------------|-----------|
| make | path_set: db_path.same_string_general (a_path) | Path stored correctly |
| make_in_memory | in_memory: db_path ~ ":memory:" | Memory mode indicated |

## 4. Contract Philosophy

### Database Operations

1. **Open State Required:** All database operations require `is_open` to be true. This ensures clean error handling rather than cryptic SQLite errors.

2. **Non-Empty Parameters:** String parameters like codes, names, and paths must be non-empty to prevent meaningless lookups.

3. **Positive Limits:** Search limits must be positive to return meaningful results.

### Search Results

1. **Detachable Results:** Single-item lookups (error, class_info, example, pattern) return detachable types because items may not exist.

2. **List Results:** Search operations return lists (possibly empty) rather than Void.

### Error Handling

1. **has_error Pattern:** After operations, check `has_error` and `last_error` rather than relying on exceptions.

2. **Graceful Degradation:** Missing data returns Void or empty lists, not exceptions.

## 5. FTS5 Query Contracts

### Search Query Format

| Valid | Invalid | Notes |
|-------|---------|-------|
| "json parsing" | (none) | Multiple terms ANDed |
| "json OR xml" | (none) | Boolean OR |
| "json NOT xml" | (none) | Boolean NOT |
| "json*" | (none) | Prefix matching |
| '"exact phrase"' | (none) | Phrase search |

### Implicit Contracts

- Query cannot be empty (precondition)
- Query is sanitized before FTS5 execution
- Special characters are escaped or handled

## 6. Data Integrity Contracts

### Foreign Key Relationships

| Table | Foreign Key | Constraint |
|-------|-------------|------------|
| features | class_id | REFERENCES classes(id) |
| class_parents | class_id | REFERENCES classes(id) |

### Uniqueness Constraints

| Table | Unique On | Purpose |
|-------|-----------|---------|
| classes | (library, name) | No duplicate class entries |
| errors | code | One entry per error code |
| features | (class_id, name) | No duplicate features |

---

*Generated as backwash specification from existing implementation.*
