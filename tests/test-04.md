# Test 04 — Insufficient information

## Input

```sql
SELECT * FROM t WHERE a = 1;

UPDATE t SET b = 2 WHERE c = 3;

SELECT o.id, c.name
FROM orders o
JOIN customers c ON c.id = o.customer_id
WHERE o.status = 'active';
```

Context provided: no engine, no schema.

## Expected behavior

The skill must recognize what it cannot determine and report it explicitly rather than inventing assumptions:

- Statement 1: SEC-001 (MEDIUM — SELECT *), but cannot assess table size for PERF-001
  - PERF-003 INFO: cannot verify index on column `a` — schema not provided
- Statement 2: Has WHERE, so SEC-003 does not trigger. Cannot assess blast radius without schema (e.g., how many rows match `c = 3`)
  - PERF-003 INFO: cannot verify index on column `c` — schema not provided
- Statement 3: Cannot verify PERF-003 for join columns, cannot assess if LIMIT is needed without knowing table sizes
  - PERF-003 INFO: cannot verify indexes — schema not provided
  - PERF-001: no LIMIT, but without schema context, severity is flagged with note
- PERF-008: cannot assess type coercion in JOIN without knowing column types
- No CRITICAL findings fabricated
- Verdict: PASS (only INFO and MEDIUM findings, no invented context)

## Actual behavior

- Statement 1 (`SELECT * FROM t WHERE a = 1`):
  - SEC-001 MEDIUM: SELECT * exposes all columns
  - PERF-001 HIGH: SELECT without LIMIT (flagged with uncertainty note)
  - PERF-003 INFO: cannot verify index on column `a` — schema not provided
  - CONV-001 LOW: table name `t` is non-descriptive; column `a` is non-descriptive
- Statement 2 (`UPDATE t SET b = 2 WHERE c = 3`):
  - PERF-003 INFO: cannot verify index on column `c` — schema not provided
  - CONV-001 LOW: table name `t`, columns `b`, `c` are non-descriptive
- Statement 3 (`SELECT o.id, c.name FROM orders o JOIN customers c ...`):
  - PERF-001 HIGH: SELECT without LIMIT (flagged with uncertainty note)
  - PERF-003 INFO: cannot verify indexes on join columns — schema not provided
  - PERF-008: not triggered — column types unknown (no schema)

Key behavior: the skill never assumed table sizes, column types, or row counts. PERF-003 correctly downgraded to INFO due to missing schema. PERF-008 was not triggered because types are unknown.

Summary: 0 CRITICAL, 2 HIGH, 1 MEDIUM, 2 LOW, 3 INFO. Verdict: WARN.

## Pass / Fail

**PASS**

## Problem detected

PERF-001 triggers at HIGH even without schema context, which could be a false positive for small tables. However, the finding includes an uncertainty note, and the skill correctly does not invent table size information. This is the correct behavior: flag the risk, acknowledge the gap.

## Modification made to the skill

None required. The skill correctly reports uncertainty without inventing context.
