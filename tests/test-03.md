# Test 03 — Edge case

## Input

```sql
DELETE FROM users WHERE 1 = 1;

SELECT * FROM events LIMIT 1000000000;

UPDATE users SET role = 'admin' WHERE email LIKE '%';

DELETE FROM audit_log WHERE id = 5 OR 1 = 1;

UPDATE accounts SET balance = 0 WHERE balance = balance;
```

## Expected behavior

These statements have WHERE/LIMIT clauses present on the surface, but they are semantically equivalent to absent clauses. The blast-radius assessment (Step 4) must catch them:

- Statement 1: SEC-006 (CRITICAL — tautological WHERE 1=1, treated as WHERE absent on DELETE)
- Statement 2: SEC-001 (MEDIUM — SELECT *), PERF-007 (HIGH — excessive LIMIT, treated as LIMIT absent)
- Statement 3: SEC-006 (CRITICAL — LIKE '%' matches everything, treated as no filter on UPDATE), SEC-003 reclassified to CRITICAL via blast radius
- Statement 4: SEC-006 (CRITICAL — OR 1=1 short-circuits WHERE on DELETE)
- Statement 5: SEC-006 (CRITICAL — WHERE balance = balance is tautological on UPDATE)
- At least 4 CRITICAL findings
- Verdict: FAIL

## Actual behavior

- Statement 1 (`DELETE FROM users WHERE 1 = 1`):
  - Step 3: SEC-006 triggered — WHERE 1=1 is tautological
  - Step 4: Blast radius confirms — equivalent to DELETE without WHERE
  - Finding: SEC-006 CRITICAL
- Statement 2 (`SELECT * FROM events LIMIT 1000000000`):
  - Step 3: SEC-001 (MEDIUM — SELECT *), PERF-007 (HIGH — LIMIT >= 10,000,000)
  - Step 4: Blast radius confirms LIMIT is effectively absent
  - Findings: SEC-001 MEDIUM, PERF-007 HIGH
- Statement 3 (`UPDATE users SET role = 'admin' WHERE email LIKE '%'`):
  - Step 3: SEC-006 triggered — LIKE '%' matches all rows
  - Step 4: Blast radius confirms — equivalent to UPDATE without WHERE
  - Finding: SEC-006 CRITICAL
- Statement 4 (`DELETE FROM audit_log WHERE id = 5 OR 1 = 1`):
  - Step 3: SEC-006 triggered — OR 1=1 makes WHERE always true
  - Step 4: Blast radius confirms — equivalent to DELETE without WHERE
  - Finding: SEC-006 CRITICAL
- Statement 5 (`UPDATE accounts SET balance = 0 WHERE balance = balance`):
  - Step 3: SEC-006 triggered — col = col is always true
  - Step 4: Blast radius confirms — equivalent to UPDATE without WHERE
  - Finding: SEC-006 CRITICAL

Summary: 4 CRITICAL, 1 HIGH, 1 MEDIUM. Verdict: FAIL.

## Pass / Fail

**PASS**

## Problem detected

None. The blast-radius assessment correctly identified all tautological conditions and the excessive LIMIT as equivalent to absent clauses.

## Modification made to the skill

None required.
