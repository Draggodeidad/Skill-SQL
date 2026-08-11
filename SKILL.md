---
name: sql-reviewer
description: SQL code review. Use when analyzing SQL statements, scripts, migrations, or queries embedded in application code for security, performance, and convention issues.
---

# SQL Reviewer

## Purpose

Technical SQL reviewer. Applies deterministic rules to classify every finding by severity. Assesses _blast radius_ — the scope of damage a statement can cause — beyond surface syntax. Never invents context to fill gaps.

## When to activate

- SQL statements or scripts submitted for review
- SQL embedded in application code (string concatenation, template literals, ORM raw queries)
- Database migration files (DDL/DML)
- Stored procedures, functions, triggers
- User asks to review, audit, or analyze SQL

## When NOT to activate

- NoSQL query languages (MongoDB, Cypher, Gremlin, GraphQL)
- ORM configuration or model definitions without raw SQL
- Conceptual questions about databases with no code to review
- Configuration files (connection strings, pool settings)

## Inputs

| Parameter | Required | Description |
|-----------|----------|-------------|
| `sql` | Yes | SQL statement(s) or script(s) to review |
| `engine` | No | Target database engine (MySQL, PostgreSQL, SQL Server, Oracle, SQLite). Default: `unknown` |
| `schema` | No | Table definitions, indexes, constraints |

## Procedure

### Step 1: Parse

Identify every statement in the input. For each statement:
- Classify type: SELECT, INSERT, UPDATE, DELETE, DDL (CREATE/ALTER/DROP), DCL (GRANT/REVOKE), TCL (BEGIN/COMMIT/ROLLBACK)
- Extract target tables and referenced columns
- Identify presence/absence of: WHERE, LIMIT, ORDER BY, GROUP BY, HAVING clauses

**Completion:** every statement has a type classification and clause inventory, or is marked `unparseable` with the offending fragment quoted.

### Step 2: Classify engine

Assign engine from input. If absent, mark as `unknown`. Engine-specific rules are skipped when engine is `unknown`; each skip produces an INFO note listing the skipped rule.

**Completion:** every statement has an engine value.

### Step 3: Apply rules

Load each rules file and apply every rule to every statement:
- [`rules/security.md`](rules/security.md) — injection, destructive operations, authorization, data exposure
- [`rules/performance.md`](rules/performance.md) — unbounded queries, missing indexes, type coercion, suboptimal patterns
- [`rules/conventions.md`](rules/conventions.md) — naming, type choice, NULL handling, style

Record every finding with: rule ID, severity, offending SQL fragment.

**Completion:** every statement checked against every applicable rule; every finding recorded with rule ID and evidence.

### Step 4: Assess blast radius

For each finding from Step 3, evaluate semantic effect beyond surface syntax:

| Surface pattern | Semantic effect |
|-----------------|-----------------|
| WHERE clause present but tautological (`1=1`, `TRUE`, `col = col`) | Treat as WHERE absent |
| LIMIT present but value >= 10,000,000 | Treat as LIMIT absent |
| `LIKE '%'` or `LIKE '%%'` on UPDATE/DELETE WHERE | Treat as no filter |
| WHERE with OR that short-circuits filter (`WHERE id = 5 OR 1=1`) | Treat as WHERE absent |
| Nested subquery equivalent of `SELECT *` | Treat as `SELECT *` |

Reclassify severity upward when blast radius exceeds the rule's base severity.

**Completion:** every finding has a blast-radius assessment; no tautological clause went undetected.

### Step 5: Produce verdict

Generate report in the expected output format. Include:
- Summary counts by severity
- Overall verdict: PASS (no findings above LOW), WARN (MEDIUM or HIGH, no CRITICAL), FAIL (any CRITICAL)
- All findings ordered by severity (CRITICAL first)
- Recommendations for remediation

**Completion:** report contains all findings, summary, and verdict.

## Severity levels

| Level | Definition | Example |
|-------|-----------|---------|
| **CRITICAL** | Data loss or unauthorized access certain if executed | DELETE without WHERE on production table |
| **HIGH** | Significant performance degradation or likely incorrect results | Full table scan on million-row table; NULL compared with `=` |
| **MEDIUM** | Maintainability or convention issue with moderate future impact | SELECT * in a view; leading-wildcard LIKE |
| **LOW** | Minor naming or style improvement | Single-letter alias; inconsistent casing |
| **INFO** | Observation or suggestion — not a defect | Missing comment on complex CTE; engine-specific rule skipped |

## Rules

Rules are organized into three files by category. Every rule has a unique ID (`SEC-xxx`, `PERF-xxx`, `CONV-xxx`) and a fixed base severity.

- [`rules/security.md`](rules/security.md) — 8 rules covering injection, destructive operations, authorization, and data exposure
- [`rules/performance.md`](rules/performance.md) — 10 rules covering unbounded queries, missing indexes, type coercion, and suboptimal patterns
- [`rules/conventions.md`](rules/conventions.md) — 6 rules covering naming, types, NULL handling, and style

**Conflict resolution:** when two rules produce contradictory recommendations on the same statement, the higher severity rule wins. If severities are equal: security > performance > convention.

## Expected output

```
# SQL Review Report

## Summary
| Severity | Count |
|----------|-------|
| CRITICAL | n     |
| HIGH     | n     |
| MEDIUM   | n     |
| LOW      | n     |
| INFO     | n     |

**Verdict:** PASS | WARN | FAIL
- PASS: no findings above LOW
- WARN: MEDIUM or HIGH findings present, no CRITICAL
- FAIL: at least one CRITICAL finding

## Findings

### [RULE-ID] — Severity
- **Statement:** `SELECT * FROM users`
- **Fragment:** `SELECT *`
- **Blast radius:** exposes all columns including sensitive data
- **Recommendation:** list specific columns needed

## Skipped rules (engine unknown)
- PERF-003: requires schema context
- ...
```

## Validation

- Every finding references a valid rule ID from the rules files
- Every finding includes the exact offending SQL fragment
- Severity matches the rule's defined base severity, adjusted only by blast-radius assessment (Step 4)
- No finding is generated without evidence present in the input
- When two rules trigger on the same fragment, both findings appear (no silent deduplication)

## Failure handling

| Condition | Action |
|-----------|--------|
| Insufficient schema context | Report finding at INFO: `insufficient context: [what is needed]`. Never assume table structure, column types, or row counts. |
| Insufficient engine context | Apply engine-agnostic rules only. List skipped rules in report. Never assume engine-specific behavior. |
| Unparseable input | Report INFO: `could not parse` with offending fragment quoted. Continue processing remaining statements. |
| Empty input | Report INFO: `no SQL statements found`. Produce empty report. |
| Non-SQL input | Report INFO: `input does not appear to be SQL`. Suggest providing SQL statements. |
| Conflicting rules | Higher severity wins. Equal severity: security > performance > convention. Document conflict in finding. |
