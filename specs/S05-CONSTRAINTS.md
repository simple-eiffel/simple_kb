# S05-CONSTRAINTS.md

**Library:** simple_kb
**Status:** BACKWASH (reverse-engineered from implementation)
**Date:** 2026-01-23

---

## 1. Database Constraints

### SQLite Requirements

| Requirement | Value | Notes |
|-------------|-------|-------|
| SQLite version | 3.x | FTS5 requires 3.9.0+ |
| FTS5 extension | Required | Compile-time option |
| WAL mode | Recommended | Better concurrency |

### Schema Constraints

| Constraint | Enforcement | Purpose |
|------------|-------------|---------|
| classes(library, name) UNIQUE | SQL | No duplicate class entries |
| errors(code) UNIQUE | SQL | One entry per error code |
| features(class_id, name) UNIQUE | SQL | No duplicate features |
| class_id FOREIGN KEY | SQL | Referential integrity |

### FTS5 Constraints

| Constraint | Value | Notes |
|------------|-------|-------|
| Tokenizer | porter unicode61 | Stemming + Unicode |
| Content columns | content_type, content_id, title, body, tags | Searchable fields |
| Synchronization | Manual | FTS5 not auto-synced |

## 2. Query Constraints

### Search Query Format

| Format | Valid | Example |
|--------|-------|---------|
| Simple terms | Yes | "json parsing" |
| Boolean OR | Yes | "json OR xml" |
| Boolean NOT | Yes | "json NOT xml" |
| Prefix | Yes | "json*" |
| Phrase | Yes | '"exact phrase"' |
| Field scoped | Yes | "title:parser" |

### Query Length

| Constraint | Value | Rationale |
|------------|-------|-----------|
| Minimum | 1 character | Prevent empty queries |
| Maximum | 1000 characters | Practical limit |
| Empty | Invalid | Precondition violation |

### Result Limits

| Constraint | Value | Notes |
|------------|-------|-------|
| Default limit | 10 | KB_QUICK.search |
| Minimum limit | 1 | Precondition enforced |
| Maximum limit | 1000 | Practical limit |

## 3. Content Constraints

### Error Codes

| Field | Constraint | Example |
|-------|------------|---------|
| code | Non-empty, unique | "VEVI", "VD89" |
| meaning | Non-empty | "Variable not properly set" |
| explanation | Optional | Full explanation text |
| common_causes | JSON array | ["Uninitialized variable"] |
| fixes | JSON array | ["Add default value"] |

### Class Information

| Field | Constraint | Example |
|-------|------------|---------|
| library | Non-empty | "simple_json" |
| name | Non-empty, unique per library | "JSON_PARSER" |
| description | Optional | From note clause |
| file_path | Optional | Source file location |

### Feature Information

| Field | Constraint | Example |
|-------|------------|---------|
| class_id | Valid FK | References classes(id) |
| name | Non-empty | "parse" |
| signature | Optional | "(text: STRING): JSON_OBJECT" |
| kind | enum | "query", "command", "creation" |

### Examples

| Field | Constraint | Example |
|-------|------------|---------|
| title | Non-empty, unique | "Bubble Sort" |
| source | enum | "rosetta", "manual", "generated" |
| code | Non-empty | Eiffel source code |
| tier | Optional | "TIER1", "TIER2" |

### Patterns

| Field | Constraint | Example |
|-------|------------|---------|
| name | Non-empty | "singleton" |
| description | Optional | Pattern explanation |
| code | Optional | Example implementation |
| when_to_use | Optional | Usage guidance |

## 4. File System Constraints

### Database Path

| Constraint | Rule |
|------------|------|
| Format | Valid file system path |
| Special | ":memory:" for in-memory |
| Permissions | Read/write access required |
| Directory | Parent must exist |

### Environment Variables

| Variable | Purpose | Default |
|----------|---------|---------|
| SIMPLE_EIFFEL | Root for default db path | Current directory |

## 5. Performance Constraints

### Recommended Limits

| Resource | Recommended | Notes |
|----------|-------------|-------|
| Classes indexed | 10,000 | Tested scale |
| Features indexed | 50,000 | Tested scale |
| Examples | 1,000 | Tested scale |
| Errors | 500 | Tested scale |
| Patterns | 100 | Tested scale |

### Query Performance

| Operation | Target | Notes |
|-----------|--------|-------|
| Search | <100ms | For 10 results |
| Class lookup | <10ms | By name |
| Error lookup | <10ms | By code |
| Stats | <50ms | Count queries |

## 6. Concurrency Constraints

### Thread Safety

| Component | Thread-Safe | Notes |
|-----------|-------------|-------|
| KB_DATABASE | No | Single-threaded access |
| KB_QUICK | No | Wrapper around database |
| SQLite connection | Limited | WAL mode helps |

### Recommended Pattern

```eiffel
-- One KB_DATABASE per thread
-- Or use external synchronization
```

## 7. Character Set Constraints

### String Types

| Type | Usage | Encoding |
|------|-------|----------|
| STRING_32 | All user-facing | UTF-32 |
| STRING_8 | SQL literals | UTF-8 assumed |

### Special Characters

| Character | Handling | Notes |
|-----------|----------|-------|
| Single quote | Escaped in SQL | '' -> ' |
| Double quote | Phrase delimiter | FTS5 syntax |
| NULL | Rejected | Strings must be non-null |
| Newlines | Preserved | In code fields |

---

*Generated as backwash specification from existing implementation.*
