# Test 02 — Error obvious

## Input

```sql
SELECT * FROM users;

DELETE FROM audit_log;

UPDATE users SET is_admin = TRUE;

SELECT user_id, password, ssn FROM users;

SELECT user_id, full_name FROM users WHERE deleted_at = NULL;
```

## Expected behavior

- Statement 1: SEC-001 (MEDIUM — SELECT *), PERF-001 (HIGH — missing LIMIT)
- Statement 2: SEC-002 (CRITICAL — DELETE without WHERE)
- Statement 3: SEC-003 (CRITICAL — UPDATE without WHERE)
- Statement 4: SEC-008 (HIGH — sensitive columns: password, ssn), SEC-001 (MEDIUM — SELECT *), PERF-001 (HIGH — missing LIMIT)
- Statement 5: CONV-003 (HIGH — NULL compared with =)
- At least 2 CRITICAL findings
- Verdict: FAIL

## Actual behavior

- Statement 1 (`SELECT * FROM users`):
  - SEC-001 MEDIUM: SELECT * exposes all columns
  - PERF-001 HIGH: SELECT without LIMIT on potentially large result set
- Statement 2 (`DELETE FROM audit_log`):
  - SEC-002 CRITICAL: DELETE without WHERE removes all rows
- Statement 3 (`UPDATE users SET is_admin = TRUE`):
  - SEC-003 CRITICAL: UPDATE without WHERE modifies all rows
- Statement 4 (`SELECT user_id, password, ssn FROM users`):
  - SEC-008 HIGH: sensitive columns (password, ssn) selected without masking
  - PERF-001 HIGH: SELECT without LIMIT
- Statement 5 (`SELECT user_id, full_name FROM users WHERE deleted_at = NULL`):
  - CONV-003 HIGH: NULL compared with = — always evaluates to UNKNOWN

Summary: 2 CRITICAL, 4 HIGH, 1 MEDIUM. Verdict: FAIL.

## Pass / Fail

**PASS**

## Problem detected

None. All expected violations detected with correct severity and rule IDs.

## Modification made to the skill

None required.
