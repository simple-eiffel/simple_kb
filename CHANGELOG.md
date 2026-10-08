# Changelog

simple_kb had no version number or changelog before this file; these entries are patch-level changes.

## 2026-10-08 (patch 2)

### Fixed
- **Pattern names are now unique in every database, old ones included.** Opening a database
  (`KB_DATABASE.ensure_schema`) runs a one-time migration when the `idx_patterns_name` index is absent.
  In one transaction it keeps the newest row of each pattern name, deletes the older duplicates and their
  search entries, gives each kept pattern exactly one `kb_search` entry, and adds
  `CREATE UNIQUE INDEX idx_patterns_name ON patterns(name)`. New databases get the index on creation.
  `add_pattern` already deleted every row of the same name (`DELETE FROM patterns WHERE name = ?`, all
  rows, not just one); it now uses a plain `INSERT`, so a conflict is reported instead of silently
  orphaning a search entry.
- **Repository databases cleaned** with the fixed `kb` (opened with `kb stats` on copies, then copied
  back). `bin/kb.db`: 28 pattern rows down to 14 (14 distinct names), 28 pattern search entries down to
  14; errors (31), classes, features, examples, FAQs and the other search entries unchanged;
  `PRAGMA integrity_check` and the FTS5 integrity check pass. `kb.db` (empty) and `data/kb.db`
  (14 patterns, no duplicates) gained the index; both are ignored by git.
- **The `kb` CLI target compiles again.** The 2026-02 rename commits left 33 compile errors in classes
  that only `kb_cli` builds (the test target never compiles them): an attachment local renamed `al_x`
  but still used as `x` (`kb_ai_router.e`, `kb_cli_app.e`, `kb_faq.e`, `kb_mbox_ingester.e`,
  `kb_mbox_parser.e`), setters whose argument became `a_v` while the body still read `v`
  (`kb_mbox_message.e`), and the routine `confirm` renamed `l_confirm`, which collided with a local
  (VRLE). Each name is back to the one its declaration uses.

### Tests
- `test_duplicate_pattern_name_refused`, `test_old_database_migrates_clean` (an old-layout file with
  duplicates, a doubled search entry, an orphan entry and a pattern without one opens clean; re-opening
  changes nothing; seeding it twice adds no duplicates). `test_reseed_replaces_patterns` also checks one
  search entry per pattern. Suite: 42 passed, 0 failed (was 40/40).

## 2026-10-08 (patch)

### Fixed
- **Text damaged by the 2026-02-05/06 naming-standards commits is restored.** The rename scripts also
  rewrote text inside string literals. Every literal was taken from the commits' own diffs (old text
  against new, line by line) and put back, 77 lines in 8 files:
  - `kb_error_seeder.e` (b040466): seeded fix examples for VUTA and VOMB read
    `if attached my_object as al_obj then obj.do_something end` (the name changed in one place only);
    they read `as obj then obj...` again.
  - `kb_pattern_seeder.e` (7adb5e3, b040466): the `expanded_value`, agent and object-test pattern code
    (`a_other`, `a_success`, `al_user`, `al_db_err`, `al_x`) is back to its original text.
  - `kb_cli_app.e` (3177bbb): the `kb` help and usage text (`kb l_error <l_code>`, `kb l_stats`,
    `<l_query>`, `<l_path>`, `l_patterns` ...), printed to users, is restored; plus note text in
    `kb_ai_router.e`, `kb_mbox_ingester.e`, `kb_mbox_parser.e`, `kb_pager.e`, `kb_rosetta_importer.e`.
- **`kb seed` duplicated every pattern.** `add_pattern` used `INSERT OR REPLACE`, but `patterns.name` has
  no UNIQUE constraint, so each seed added a second copy (`bin/kb.db` holds 28 rows for 14 patterns).
  `add_pattern` now deletes the stored pattern of the same name and its search entry first, so re-running
  `kb seed` refreshes patterns, as it already did for errors (`errors.code` is UNIQUE). This is also the
  correction path for any database seeded with the damaged text.

### Tests
- `test_seed_text_not_renamed`, `test_reseed_replaces_patterns`. Suite: 40 passed, 0 failed (was 38/38).
