# simple_kb

Eiffel Knowledge Base - A searchable repository of Eiffel compiler errors, design patterns, class documentation, and code examples.

## Features

- **31 Compiler Error Codes**: Detailed explanations with causes, fixes, and code examples
- **14 Eiffel Design Patterns**: Singleton, Factory, Builder, Observer, and more with Eiffel-specific idioms
- **Source Code Indexing**: Parse and index any Eiffel codebase for class/feature lookup
- **Rosetta Code Examples**: 273 algorithm implementations from Rosetta Code
- **Full-Text Search**: SQLite FTS5 with BM25 ranking across all content

## Installation

```bash
# Clone the repository
git clone https://github.com/simple-eiffel/simple_kb.git
cd simple_kb

# Compile the CLI
ec -config simple_kb.ecf -target kb_cli -c_compile

# Run the CLI
./EIFGENs/kb_cli/W_code/simple_kb.exe help
```

## CLI Usage

### Initialize the Database

```bash
# Seed with error codes and patterns
kb seed

# Index source files
kb ingest /d/prod/simple_json

# Import Rosetta Code examples
kb rosetta /d/prod/simple_rosetta
```

### Search Commands

```bash
# Full-text search
kb search json
kb search "void safety"

# Look up class details
kb class SIMPLE_JSON
kb class HTTP_CLIENT

# Look up compiler error
kb error VEVI
kb error VUAR

# Look up design pattern
kb pattern singleton
kb pattern builder
kb pattern list
```

### Admin Commands

```bash
# Show database statistics
kb stats

# Show help
kb help
```

## Example Output

### Error Lookup

```
> kb error VEVI

ERROR: VEVI - Variable not properly set
==================================================

MEANING:
  An attached local variable or Result must be assigned a value
  on all possible execution paths before being used.

COMMON CAUSES:
  1. Result not assigned in an else branch
  2. Local variable used before assignment
  3. Assignment inside conditional that may not execute

FIX OPTIONS:
  Option 1: Add else branch
    Ensure all branches assign a value
    Example: if condition then Result := x else Result := y end

REFERENCE: ECMA-367 Section 8.19.17
```

### Pattern Lookup

```
> kb pattern singleton

PATTERN: singleton
==================

Ensure only one instance of a class exists throughout the application.

WHEN TO USE:
When you need global access to a single shared instance, like
configuration, logging, or connection pools.

EIFFEL IDIOMS:
  - Use 'once' function, not a class variable
  - once = once per process by default
  - Use 'once per object' for instance-level singletons
  - Thread-safe: use 'once (THREAD)' for per-thread instances

CODE:
shared_instance: MY_CLASS
    once
        create Result.make
    end
```

## Library API

```eiffel
class MY_APP

feature -- KB Integration

    kb: KB_QUICK
        once
            create Result.make_with_path ("kb.db")
        end

    lookup_error (a_code: STRING): detachable KB_ERROR_INFO
        do
            Result := kb.lookup_error (a_code)
        end

    search (a_query: STRING): ARRAYED_LIST [KB_RESULT]
        do
            Result := kb.search (a_query)
        end

end
```

## Database Schema

- `errors`: Compiler error codes with causes, fixes, and examples
- `classes`: Indexed class information with descriptions
- `features`: Feature signatures, contracts, and descriptions
- `examples`: Rosetta Code and other code examples
- `patterns`: Design patterns with Eiffel idioms
- `kb_fts`: FTS5 virtual table for full-text search

## Dependencies

- simple_sql (SQLite wrapper)
- simple_json (JSON parsing for idioms)
- simple_eiffel_parser (Source code parsing)

## Testing

```bash
# Compile and run tests
ec -config simple_kb.ecf -target simple_kb_tests -c_compile
./EIFGENs/simple_kb_tests/W_code/simple_kb.exe

# Expected: 23/23 tests passing
```

## License

MIT License - See LICENSE file for details.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Submit a pull request

---

Part of the [Simple Eiffel](https://github.com/simple-eiffel) ecosystem.
