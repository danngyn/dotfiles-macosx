---
name: safe-migration
description: Write or review a Rails migration for production safety. Flags unsafe DDL on large tables and rewrites with safe options. Invoke with /safe-migration.
---

# Safe Migration Skill

Review or write a Rails migration with production safety in mind. Always apply safe DDL options for migrations that touch existing tables.

**Context:** A migration adding `clio_thread_id` to `email_messages` without safe options caused a write lock that stalled all write requests and produced a spike of 502s in production.

## Rules

### `add_column` on an existing table
Always use `algorithm: :instant` for nullable columns on MySQL 8.0+:
```ruby
add_column :table_name, :column_name, :bigint, algorithm: :instant
```
- Only works for nullable columns with no default
- For non-null columns or columns with defaults: add nullable first, backfill, then add constraint/default in a separate migration

### `add_index` on an existing table
Always use `algorithm: :inplace, lock: :none`:
```ruby
add_index :table_name, [:col_a, :col_b],
          name: "idx_descriptive_name",
          algorithm: :inplace, lock: :none
```

### `add_foreign_key` on an existing table
Always use `validate: false` to skip the full table scan. Validate separately:
```ruby
# Migration 1 — fast, no table scan
add_foreign_key :table_name, :other_table, column: :fk_col, validate: false

# Migration 2 — can run separately, validates existing rows
validate_foreign_key :table_name, :other_table
```

### `change_column` on a large table
Avoid entirely. Use the expand/contract pattern instead:
1. Add new nullable column
2. Backfill (via job or migration in batches)
3. Add NOT NULL constraint / rename in a separate migration

### `add_column` with a non-null default
Never on a large table — rewrites every row. Instead:
1. Add column as nullable with no default
2. Backfill in batches
3. Add default + NOT NULL in a separate migration after backfill completes

## Steps

1. Read the migration file.
2. Identify every DDL operation that touches an existing table.
3. For each unsafe operation, rewrite it using the safe options above.
4. Add a comment on any operation that could still be slow (e.g. large index build) so the deployer knows to monitor it.
5. Output the rewritten migration and a brief explanation of what was changed and why.

## Large Tables in This Codebase

Tables that are known to be large and require extra care:
- `email_messages`
- `email_threads`
- `mailboxes`

## Example — Unsafe

```ruby
def up
  add_column :email_messages, :clio_thread_id, :bigint
  add_index :email_messages, [:clio_thread_id, :firm_identifier],
            name: "idx_email_messages_clio_thread_firm"
  add_foreign_key :email_messages, :email_clio_threads, column: :clio_thread_id
end
```

## Example — Safe

```ruby
def up
  # INSTANT add — no table rebuild, no lock
  add_column :email_messages, :clio_thread_id, :bigint, algorithm: :instant

  # INPLACE index build — concurrent with reads/writes
  add_index :email_messages, [:clio_thread_id, :firm_identifier],
            name: "idx_email_messages_clio_thread_firm",
            algorithm: :inplace, lock: :none

  # validate: false skips full table scan; validate in a follow-up migration
  add_foreign_key :email_messages, :email_clio_threads,
                  column: :clio_thread_id, validate: false
end
```
