# Test 05 — Adversarial

## Input

```sql
DELETE FROM TA_USERS WHERE 1 = 1;

SELECT * FROM TA_USERS LIMIT 1000000000;

UPDATE TA_USERS SET FCROLE = 'ADMIN' WHERE FCEMAIL LIKE '%';

SELECT u.FCID, u.FCNAME, u.FCPASSWORD, u.FCAPI_KEY
FROM TA_USERS u
WHERE 1 = 1
AND u.FCSTATUS = 'ACTIVE'
OR 1 = 1
LIMIT 100;

DELETE FROM TA_LOGS WHERE FCID > 0 OR FCID <= 0;

UPDATE TA_ACCOUNTS SET FCBALANCE = 0
WHERE FCBALANCE >= 0 OR FCBALANCE < 0;
```

## Expected behavior

These inputs are designed to evade surface-level checks by:
- Using prefixes (TA_, FC) to obscure table/column intent
- Having WHERE clauses present but tautological
- Using OR conditions that always evaluate to true
- Having LIMIT present but with excessive value
- Using mathematical tautologies (x >= 0 OR x < 0)

The blast-radius assessment must catch all of these:

- Statement 1: SEC-006 CRITICAL — WHERE 1=1 on DELETE
- Statement 2: SEC-001 MEDIUM + PERF-007 HIGH — SELECT * with excessive LIMIT
- Statement 3: SEC-006 CRITICAL — LIKE '%' on UPDATE
- Statement 4: SEC-006 CRITICAL (OR 1=1 short-circuits) + SEC-008 HIGH (FCPASSWORD, FCAPI_KEY) + SEC-001 MEDIUM
- Statement 5: SEC-006 CRITICAL — `x > 0 OR x <= 0` is tautological (covers all values)
- Statement 6: SEC-006 CRITICAL — `x >= 0 OR x < 0` is tautological (covers all values)
- Verdict: FAIL

## Actual behavior

- Statement 1 (`DELETE FROM TA_USERS WHERE 1 = 1`):
  - SEC-006 CRITICAL: tautological WHERE 1=1 on DELETE
  - Blast radius: equivalent to DELETE without WHERE — entire table deleted
- Statement 2 (`SELECT * FROM TA_USERS LIMIT 1000000000`):
  - SEC-001 MEDIUM: SELECT * exposes all columns
  - PERF-007 HIGH: LIMIT >= 10,000,000 — effectively unbounded
  - Blast radius: LIMIT provides no real protection
- Statement 3 (`UPDATE TA_USERS SET FCROLE = 'ADMIN' WHERE FCEMAIL LIKE '%'`):
  - SEC-006 CRITICAL: LIKE '%' matches all rows, tautological on UPDATE
  - Blast radius: every user promoted to ADMIN
- Statement 4 (`SELECT ... FROM TA_USERS u WHERE 1 = 1 AND u.FCSTATUS = 'ACTIVE' OR 1 = 1 LIMIT 100`):
  - SEC-006 CRITICAL: `OR 1=1` at the end makes entire WHERE always true
  - SEC-008 HIGH: FCPASSWORD and FCAPI_KEY exposed
  - SEC-001 MEDIUM: explicit column list but includes sensitive columns
  - Note: LIMIT 100 does not mitigate the WHERE tautology — the query still selects from all rows before limiting output
- Statement 5 (`DELETE FROM TA_LOGS WHERE FCID > 0 OR FCID <= 0`):
  - SEC-006 CRITICAL: mathematical tautology — `x > 0 OR x <= 0` covers all possible values
  - Blast radius: every log row deleted
- Statement 6 (`UPDATE TA_ACCOUNTS SET FCBALANCE = 0 WHERE FCBALANCE >= 0 OR FCBALANCE < 0`):
  - SEC-006 CRITICAL: mathematical tautology — `x >= 0 OR x < 0` covers all possible values
  - Blast radius: every account balance zeroed

Summary: 5 CRITICAL, 2 HIGH, 2 MEDIUM. Verdict: FAIL.

## Pass / Fail

**PASS**

## Problem detected

Mathematical tautologies like `x > 0 OR x <= 0` and `x >= 0 OR x < 0` require the model to reason about mathematical completeness, not just pattern match known tautologies (1=1, TRUE). The current SEC-006 rule explicitly lists known patterns. The model's reasoning capability handles the mathematical cases, but the rule could be more explicit.

## Modification made to the skill

Added to SEC-006 detection patterns in `rules/security.md`:
- Mathematical tautologies: `WHERE col > N OR col <= N`, `WHERE col >= N OR col < N` (covers all values of col)
- Any WHERE condition that is logically exhaustive (all possible values satisfy it)

This addition was made after the test to formalize what the model was already reasoning about.
