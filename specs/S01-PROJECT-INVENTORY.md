# S01-PROJECT-INVENTORY.md

**Library:** simple_kb
**Status:** BACKWASH (reverse-engineered from implementation)
**Date:** 2026-01-23

---

## 1. Project Overview

| Field | Value |
|-------|-------|
| Name | simple_kb |
| Purpose | Eiffel Knowledge Base with FTS5 full-text search |
| Phase | Production |
| Primary Facade | SIMPLE_KB (type anchors), KB_QUICK (operations) |
| ECF | simple_kb.ecf |

## 2. File Inventory

### Source Files - Core

| File | Class | LOC | Purpose |
|------|-------|-----|---------|
| src/simple_kb.e | SIMPLE_KB | ~52 | Type anchor facade |
| src/kb_quick.e | KB_QUICK | ~230 | One-liner convenience facade |
| src/kb_database.e | KB_DATABASE | ~1000 | SQLite + FTS5 database manager |

### Source Files - Data Models

| File | Class | Purpose |
|------|-------|---------|
| src/kb_result.e | KB_RESULT | Search result model |
| src/kb_error_info.e | KB_ERROR_INFO | Compiler error information |
| src/kb_class_info.e | KB_CLASS_INFO | Indexed class metadata |
| src/kb_feature_info.e | KB_FEATURE_INFO | Feature signatures/contracts |
| src/kb_example.e | KB_EXAMPLE | Code examples |
| src/kb_pattern.e | KB_PATTERN | Design patterns |
| src/kb_library_info.e | KB_LIBRARY_INFO | Library metadata |

### Source Files - Ingestion

| File | Class | Purpose |
|------|-------|---------|
| src/kb_ingester.e | KB_INGESTER | Source file parsing/indexing |
| src/kb_error_seeder.e | KB_ERROR_SEEDER | Compiler error database |
| src/kb_pattern_seeder.e | KB_PATTERN_SEEDER | Design pattern database |
| src/kb_rosetta_importer.e | KB_ROSETTA_IMPORTER | Rosetta Code import |

### Source Files - CLI

| File | Class | Purpose |
|------|-------|---------|
| src/kb_cli_app.e | KB_CLI_APP | Command-line interface |
| src/kb_pager.e | KB_PAGER | Output pagination |

### Configuration Files

| File | Purpose |
|------|---------|
| simple_kb.ecf | EiffelStudio project configuration |
| simple_kb.rc | Windows resource file |
| kb.rc | Alternative resource file |

### Data Files

| File | Purpose |
|------|---------|
| kb.db | SQLite database with indexed content |
| data/*.json | Seed data files |

### Documentation Files

| File | Purpose |
|------|---------|
| README.md | Library overview and CLI usage |
| research/SIMPLE_KB_RESEARCH.md | 7-step research document |
| design/*.md | Design documents |
| analysis/*.md | Analysis documents |

## 3. Dependencies

### simple_* Libraries

| Library | Purpose |
|---------|---------|
| simple_sql | SQLite database and FTS5 support |
| simple_cli | Command-line parsing |
| simple_json | JSON handling for metadata |
| simple_file | File operations |
| simple_eiffel_parser | Eiffel source parsing |
| simple_rosetta | Rosetta Code examples |

### ISE Libraries

| Library | ECF Path | Purpose |
|---------|----------|---------|
| base | $ISE_LIBRARY/library/base/base.ecf | Base classes |

## 4. Build Targets

| Target | Type | Purpose |
|--------|------|---------|
| simple_kb | library | Main library build |
| kb | executable | CLI application |

## 5. Database Schema

| Table | Purpose |
|-------|---------|
| classes | Indexed class metadata |
| features | Feature signatures and contracts |
| class_parents | Inheritance relationships |
| libraries | Library metadata |
| examples | Code examples |
| errors | Compiler error codes |
| patterns | Design patterns |
| translations | Language translation mappings |
| kb_search | FTS5 virtual table |

---

*Generated as backwash specification from existing implementation.*
