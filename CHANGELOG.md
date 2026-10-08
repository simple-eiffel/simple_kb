# Changelog

simple_kb had no version number or changelog before this file; this entry is a patch-level change.

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
