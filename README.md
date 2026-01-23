<p align="center">
  <img src="https://raw.githubusercontent.com/simple-eiffel/.github/main/profile/assets/logo.png" alt="simple_ library logo" width="400">
</p>

# simple_kb

**[Documentation](https://simple-eiffel.github.io/simple_kb/)** | **[GitHub](https://github.com/simple-eiffel/simple_kb)**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Eiffel](https://img.shields.io/badge/Eiffel-25.02-blue.svg)](https://www.eiffel.org/)
[![Design by Contract](https://img.shields.io/badge/DbC-enforced-orange.svg)]()
[![FTS5](https://img.shields.io/badge/FTS5-BM25-green.svg)]()
[![AI](https://img.shields.io/badge/AI-RAG%20enabled-purple.svg)]()

Searchable Eiffel knowledge base with FTS5 full-text search, AI-enhanced FAQ matching, and comprehensive compiler error documentation.

Part of the [Simple Eiffel](https://github.com/simple-eiffel) ecosystem.

## Status

**Production** - Full-featured CLI and library API

## Library Structure

| Metric | Count |
|--------|-------|
| Source classes | 25 |
| Test methods | 42 |
| Dependencies | 13 |

## Database Content (kb.db)

| Indexed Content | Count |
|-----------------|-------|
| Libraries | 182 |
| Classes | 4,613 |
| Features | 87,780 |
| Error codes | 31 |
| Design patterns | 14 |
| Rosetta examples | 273 |

## Features

- **Full-Text Search**: SQLite FTS5 with BM25 ranking across all content
- **AI-Enhanced RAG**: 4-phase Retrieval-Augmented Generation with Ollama
- **SCOOP-Capable Parsing**: Uses GitHub Gobo 2024 for complete Eiffel syntax
- **Compiler Error Lookup**: 31 error codes with causes, fixes, and examples
- **Design Patterns**: 14 Eiffel-specific pattern implementations
- **Source Indexing**: Parse and index entire codebases with feature contracts
- **Rosetta Examples**: 273 algorithm implementations from Rosetta Code

## What is RAG?

**RAG (Retrieval-Augmented Generation)** combines traditional search with AI language models:

1. **Retrieval**: Find relevant documents from a knowledge base
2. **Augmentation**: Provide retrieved context to an AI model
3. **Generation**: AI synthesizes an answer using the context

Unlike pure LLMs that may hallucinate, RAG grounds answers in actual knowledge base content, providing accurate, verifiable responses about Eiffel.

## How RAG Works in simple_kb

simple_kb implements a 4-phase RAG cascade:

```
User Question: "How do I handle void safety?"
         |
         v
+------------------+     Found?     +------------------------+
| Phase 1: FAQ DB  |--------------->| Return cached answer   |
| (confidence>0.8) |                | (sub-millisecond)      |
+------------------+                +------------------------+
         | Not found
         v
+------------------+     Matches?   +------------------------+
| Phase 2: FTS5   |---------------->| Return ranked results  |
| (BM25 ranking)   |                | from indexed content   |
+------------------+                +------------------------+
         | Poor results
         v
+------------------+     Better?    +------------------------+
| Phase 3: Query   |--------------->| Expanded search with   |
| Expansion        |                | synonyms/related terms |
+------------------+                +------------------------+
         | Still unclear
         v
+------------------+                +------------------------+
| Phase 4: Ollama  |--------------->| AI synthesizes answer  |
| LLM Synthesis    |                | from retrieved context |
+------------------+                +------------------------+
```

### Phase Details

1. **FAQ Match** - Curated Q&A database with confidence scores and tags
2. **FTS5 Search** - Full-text search using SQLite FTS5 with BM25 ranking
3. **Query Expansion** - Semantic synonyms expand the search (void->attached)
4. **LLM Synthesis** - Ollama provides contextual answers for complex queries

## Quick Start

```bash
# Clone and compile
git clone https://github.com/simple-eiffel/simple_kb.git
cd simple_kb
ec -config simple_kb.ecf -target kb_cli -finalize -c_compile

# Initialize database
kb seed                           # Add error codes + patterns
kb ingest /path/to/eiffel/libs    # Index source files
kb rosetta /path/to/simple_rosetta # Import examples

# Search
kb search "json parsing"
kb class SIMPLE_JSON
kb error VEVI
kb pattern singleton

# AI-enhanced query (requires Ollama)
kb ai "How do I handle void safety in Eiffel?"
```

## CLI Commands

| Command | Description |
|---------|-------------|
| `kb search <query>` | Full-text search across all content |
| `kb class <name>` | Show class details and features |
| `kb error <code>` | Look up compiler error (VEVI, VJAR, etc.) |
| `kb pattern <name>` | Show Eiffel design pattern |
| `kb ai <question>` | AI-enhanced RAG query |
| `kb ingest <path>` | Index source files |
| `kb rosetta <path>` | Import Rosetta Code examples |
| `kb seed` | Populate error codes + patterns |
| `kb clear` | Clear all database content |
| `kb stats` | Show database statistics |

## Rebuilding the Database

A pre-built `bin/kb.db` is included with indexed content (see Database Content table above). To rebuild from scratch:

```bash
# 1. Clear existing database
kb clear

# 2. Seed with error codes, patterns, and FAQ entries
kb seed

# 3. Ingest your Eiffel source libraries
kb ingest /d/prod                    # Index all simple_* libraries
kb ingest "$ISE_LIBRARY/library"     # Index EiffelStudio stdlib

# 4. Import Rosetta Code examples (optional)
kb rosetta /d/prod/simple_rosetta

# 5. Verify
kb stats
```

### Ingestion Details

The `ingest` command recursively parses all `.e` files:

- Extracts class names, inheritance, feature signatures
- Indexes feature comments and contracts (require/ensure)
- Stores source file paths for navigation
- Uses SCOOP-capable parser (GitHub Gobo 2024)

Large codebases may take several minutes to index.

## Library API

```eiffel
class MY_APP

feature -- Knowledge Base

    kb: KB_QUICK
        once
            create Result.make_with_path ("kb.db")
        end

    -- Standard search
    search (a_query: STRING): ARRAYED_LIST [KB_RESULT]
        do
            Result := kb.search (a_query)
        end

    -- AI-enhanced RAG query
    ai_answer (a_question: STRING): STRING
        do
            Result := kb.ai_query (a_question)
        end

end
```

## Installation

1. Set environment variable:
```bash
export SIMPLE_KB=/path/to/simple_kb
```

2. Add to ECF:
```xml
<library name="simple_kb" location="$SIMPLE_KB/simple_kb.ecf"/>
```

## Dependencies

- `simple_sql` - SQLite database with FTS5
- `simple_json` - JSON parsing for AI responses
- `simple_eiffel_parser` - SCOOP-capable source parsing (via GitHub Gobo 2024)
- `simple_http` - Ollama API integration

## License

MIT License