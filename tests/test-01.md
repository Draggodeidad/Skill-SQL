# Test 01 — Happy path

## Input

```sql
SELECT user_id, full_name, email
FROM users
WHERE is_active = TRUE
ORDER BY created_at DESC
LIMIT 50;

UPDATE users
SET last_login = NOW()
WHERE user_id = 42;

DELETE FROM sessions
WHERE expires_at < NOW()
AND user_id = 42;

INSERT INTO audit_log (user_id, action, created_at)
VALUES (42, 'login', NOW());
```

## Expected behavior

- No CRITICAL or HIGH findings
- No MEDIUM findings
- No artificial problems generated from correct SQL
- Possible INFO-level observations only (e.g., CONV-006 if casing is inconsistent)
- Verdict: PASS

## Actual behavior

All four statements analyzed:
- SELECT: specific columns, WHERE present, LIMIT present, ORDER BY present — no violations
- UPDATE: specific WHERE targeting single row — no violations
- DELETE: specific WHERE with compound condition — no violations
- INSERT: named columns — no violations
- CONV-006 INFO: keywords are consistently UPPER CASE — no finding
- PERF-003 INFO: no schema provided, index verification skipped

Verdict: PASS. Zero findings above INFO.

## Pass / Fail

**PASS**

## Problem detected

None. The skill correctly identifies clean SQL and does not generate artificial problems.

## Modification made to the skill

None required.
