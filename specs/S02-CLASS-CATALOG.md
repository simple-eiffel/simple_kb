# S02-CLASS-CATALOG.md

**Library:** simple_kb
**Status:** BACKWASH (reverse-engineered from implementation)
**Date:** 2026-01-23

---

## 1. Class Summary

| Class | Type | Role |
|-------|------|------|
| SIMPLE_KB | Effective | Type anchor facade |
| KB_QUICK | Effective | One-liner operations facade |
| KB_DATABASE | Effective | Database management |
| KB_RESULT | Effective | Search result model |
| KB_ERROR_INFO | Effective | Error information model |
| KB_CLASS_INFO | Effective | Class metadata model |
| KB_FEATURE_INFO | Effective | Feature metadata model |
| KB_EXAMPLE | Effective | Code example model |
| KB_PATTERN | Effective | Design pattern model |
| KB_LIBRARY_INFO | Effective | Library metadata model |
| KB_INGESTER | Effective | Source indexing |
| KB_ERROR_SEEDER | Effective | Error data seeding |
| KB_PATTERN_SEEDER | Effective | Pattern data seeding |
| KB_ROSETTA_IMPORTER | Effective | Rosetta import |
| KB_CLI_APP | Effective | CLI application |
| KB_PAGER | Effective | Output pagination |

## 2. Facade Classes

### SIMPLE_KB

**Purpose:** Type anchor facade providing references to all KB types.

**Feature Groups:**

| Group | Features | Purpose |
|-------|----------|---------|
| Type Anchors | database_anchor, result_anchor, error_anchor, class_anchor, feature_anchor, example_anchor, pattern_anchor | Type references for clients |

### KB_QUICK

**Purpose:** One-liner convenience facade for common KB operations.

**Creation Procedures:**
- `make` - Create with default database path
- `make_with_path (a_path)` - Create with specific database

**Feature Groups:**

| Group | Features | Purpose |
|-------|----------|---------|
| Access | db, default_db_path | Database access |
| Search | search, search_limit | Full-text search |
| Error Lookup | error, print_error | Compiler error queries |
| Class Lookup | class_info, print_class | Class information |
| Example Lookup | example, search_examples, print_example | Code examples |
| Pattern Lookup | pattern, print_pattern | Design patterns |
| Statistics | stats, print_stats | Database statistics |
| Cleanup | close | Resource cleanup |

## 3. Database Class

### KB_DATABASE

**Purpose:** SQLite database manager with FTS5 full-text search.

**Creation Procedures:**
- `make (a_path)` - Create with file path
- `make_in_memory` - Create in-memory database
- `default_create` - Create with default path

**Feature Groups:**

| Group | Key Features | Purpose |
|-------|--------------|---------|
| Access | db_path, db, default_db_path | Database access |
| Status | is_open, has_error, last_error, fts5_available | State queries |
| Schema | ensure_schema | Initialize tables |
| Search | search | Full-text search with BM25 ranking |
| Error Operations | get_error, add_error | Error code management |
| Class Operations | find_class, add_class, list_classes | Class indexing |
| Feature Operations | add_feature, get_features | Feature indexing |
| Example Operations | get_example, search_examples, add_example | Example management |
| Pattern Operations | get_pattern, add_pattern | Pattern management |
| Statistics | stats | Database counts |

## 4. Data Model Classes

### KB_RESULT

**Purpose:** Generic search result from FTS5 query.

**Attributes:**
- content_type: STRING_32 (class, feature, example, error, pattern)
- content_id: INTEGER
- title: STRING_32
- snippet: STRING_32
- rank: REAL_64

### KB_ERROR_INFO

**Purpose:** Compiler error code information.

**Attributes:**
- id: INTEGER
- code: STRING_32 (e.g., "VEVI", "VD89")
- meaning: STRING_32
- explanation: STRING_32
- common_causes: LIST [STRING_32]
- fixes: LIST [STRING_32]
- examples: STRING_32 (bad code -> good code)

**Features:**
- formatted: STRING_32 (human-readable output)

### KB_CLASS_INFO

**Purpose:** Indexed class metadata.

**Attributes:**
- id: INTEGER
- library: STRING_32
- name: STRING_32
- description: STRING_32
- file_path: STRING_32
- is_deferred, is_expanded, is_frozen: BOOLEAN
- generics: STRING_32

**Features:**
- formatted: STRING_32 (human-readable output)

### KB_FEATURE_INFO

**Purpose:** Feature signature and contract information.

**Attributes:**
- id: INTEGER
- class_id: INTEGER
- name: STRING_32
- signature: STRING_32
- description: STRING_32
- kind: STRING_32 (query, command, creation)
- is_deferred, is_frozen, is_once: BOOLEAN
- preconditions, postconditions: STRING_32

### KB_EXAMPLE

**Purpose:** Code example from Rosetta or manual sources.

**Attributes:**
- id: INTEGER
- title: STRING_32
- source: STRING_32 (rosetta, manual, generated)
- code: STRING_32
- tags: LIST [STRING_32]
- tier: STRING_32 (TIER1, TIER2, etc.)

**Features:**
- formatted: STRING_32 (human-readable output)

### KB_PATTERN

**Purpose:** Design pattern with Eiffel idioms.

**Attributes:**
- id: INTEGER
- name: STRING_32
- description: STRING_32
- code: STRING_32
- when_to_use: STRING_32
- eiffel_idioms: LIST [STRING_32]

**Features:**
- formatted: STRING_32 (human-readable output)

## 5. Ingestion Classes

### KB_INGESTER

**Purpose:** Parse and index Eiffel source files.

**Key Features:**
- ingest_directory (path) - Index all .e files in directory
- ingest_file (path) - Index single file
- ingest_library (name, path) - Index named library

### KB_ERROR_SEEDER

**Purpose:** Populate error code database.

**Key Features:**
- seed_all - Add all known error codes
- Individual error addition methods

### KB_PATTERN_SEEDER

**Purpose:** Populate design pattern database.

**Key Features:**
- seed_all - Add all known patterns
- Individual pattern addition methods

### KB_ROSETTA_IMPORTER

**Purpose:** Import Rosetta Code solutions.

**Key Features:**
- import_from_database (path) - Import from simple_rosetta

## 6. CLI Classes

### KB_CLI_APP

**Purpose:** Command-line interface for KB operations.

**Commands:**
- search <query> - Full-text search
- class <name> - Show class details
- feature <class.feature> - Show feature details
- error <code> - Explain compiler error
- example <topic> - Find code examples
- pattern <name> - Show design pattern
- stats - Show database statistics

### KB_PAGER

**Purpose:** Paginate long output for terminal display.

---

*Generated as backwash specification from existing implementation.*
