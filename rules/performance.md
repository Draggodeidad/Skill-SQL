# Performance Rules

## PERF-001: Missing LIMIT on potentially large result set

- **Severity:** HIGH
- **Detection:**
  ```
  IF statement_type = SELECT
  AND LIMIT clause is absent
  AND no aggregate function without GROUP BY (not a scalar result)
  AND no INTO @variable or INTO OUTFILE
  THEN finding(severity=HIGH, "SELECT without LIMIT on potentially large result set")
  ```
- **Rationale:** Unbounded SELECT can return millions of rows, exhausting memory and network bandwidth. _Blast radius_ grows with table size.
- **Recommendation:** Add a LIMIT clause. If all rows are needed, document the reason and implement pagination.
- **Note:** Requires context to assess actual risk. If table size is unknown, still flag but note uncertainty.

## PERF-002: Leading wildcard in LIKE

- **Severity:** MEDIUM
- **Detection:**
  ```
  IF WHERE clause contains LIKE pattern
  AND pattern starts with wildcard: LIKE '%...' or LIKE '_...'
  THEN finding(severity=MEDIUM, "leading wildcard prevents index usage")
  ```
- **Rationale:** A leading wildcard (`%term`) prevents B-tree index usage, forcing a full table scan. Performance degrades linearly with table size.
- **Recommendation:** Use full-text search indexes, trigram indexes (PostgreSQL `pg_trgm`), or restructure the query to avoid leading wildcards.

## PERF-003: Missing index on filter or join column

- **Severity:** MEDIUM (INFO when schema is unknown)
- **Detection:**
  ```
  IF WHERE clause filters on column C
  OR JOIN condition uses column C
  AND schema is provided
  AND no index exists on column C
  THEN finding(severity=MEDIUM, "no index on filtered/joined column")

  IF schema is NOT provided
  THEN finding(severity=INFO, "cannot verify index on column — schema not provided")
  ```
- **Rationale:** Queries on unindexed columns require full table scans. Impact scales with table size.
- **Recommendation:** Create an index on frequently filtered/joined columns: `CREATE INDEX idx_table_column ON table(column)`.

## PERF-004: N+1 query pattern

- **Severity:** HIGH
- **Detection:**
  ```
  IF multiple SELECT statements share the same structure
  AND differ only in a parameter value in the WHERE clause
  AND the parameter values appear to come from a prior query's results
  THEN finding(severity=HIGH, "N+1 query pattern detected")
  ```
- **Rationale:** N+1 queries execute one query per row of a parent result set, causing O(n) database round trips. A single JOINed query is O(1) round trips.
- **Recommendation:** Replace with a single query using JOIN or WHERE IN (...).

## PERF-005: Subquery where JOIN suffices

- **Severity:** MEDIUM
- **Detection:**
  ```
  IF statement contains a correlated subquery in SELECT or WHERE
  AND the subquery references the outer table
  AND the subquery could be expressed as a JOIN
  THEN finding(severity=MEDIUM, "correlated subquery could be a JOIN")
  ```
- **Rationale:** Correlated subqueries execute once per row of the outer query. A JOIN typically allows the optimizer to choose a more efficient plan.
- **Recommendation:** Rewrite as a JOIN. Example:
  ```sql
  -- Before (correlated subquery)
  SELECT *, (SELECT name FROM departments d WHERE d.id = e.dept_id)
  FROM employees e

  -- After (JOIN)
  SELECT e.*, d.name
  FROM employees e
  JOIN departments d ON d.id = e.dept_id
  ```

## PERF-006: ORDER BY on large unindexed set

- **Severity:** MEDIUM
- **Detection:**
  ```
  IF ORDER BY clause is present
  AND ordered column has no supporting index (when schema is known)
  AND LIMIT is absent or > 10000
  THEN finding(severity=MEDIUM, "ORDER BY on potentially large unindexed set")
  ```
- **Rationale:** Sorting without an index requires a filesort operation that spills to disk on large result sets.
- **Recommendation:** Add an index that covers the ORDER BY column(s), or add a LIMIT to bound the sort.

## PERF-007: Excessive LIMIT value

- **Severity:** HIGH
- **Detection:**
  ```
  IF LIMIT clause is present
  AND LIMIT value >= 10000000
  THEN finding(severity=HIGH, "excessive LIMIT — effectively unbounded")
  ```
- **Rationale:** A very large LIMIT provides the illusion of safety but still retrieves an excessive number of rows. _Blast radius_ is functionally equivalent to no LIMIT.
- **Recommendation:** Reduce LIMIT to a reasonable value. Use pagination (LIMIT + OFFSET or keyset pagination) for large result sets.

## PERF-008: Implicit type coercion in JOINs

- **Severity:** MEDIUM
- **Detection:**
  ```
  IF JOIN condition compares columns from different tables
  AND column types are known (from schema or DDL)
  AND types differ (e.g., VARCHAR vs INT, CHAR vs VARCHAR)
  THEN finding(severity=MEDIUM, "implicit type coercion in JOIN condition")
  ```
- **Rationale:** Type mismatches in JOIN conditions cause implicit conversion, which bypasses indexes and produces unexpected results.
- **Recommendation:** Align column types across related tables. If alignment is not possible, use explicit CAST in the query.

## PERF-009: SELECT inside unnecessary transaction

- **Severity:** MEDIUM
- **Detection:**
  ```
  IF statement_type = SELECT
  AND statement is inside a BEGIN...COMMIT / START TRANSACTION block
  AND no write operations (INSERT, UPDATE, DELETE) exist in the same transaction
  THEN finding(severity=MEDIUM, "read-only SELECT inside explicit transaction")
  ```
- **Rationale:** Transactions hold locks and consume resources. A read-only transaction adds overhead without providing transactional guarantees beyond what a single SELECT already provides.
- **Recommendation:** Remove the explicit transaction wrapper for read-only operations. Use transactions only when multiple operations need atomicity.

## PERF-010: COUNT(*) where EXISTS suffices

- **Severity:** MEDIUM
- **Detection:**
  ```
  IF statement uses COUNT(*) or COUNT(1)
  AND result is compared to 0 or used in a boolean context
      (IF count > 0, WHERE count > 0, HAVING count > 0)
  THEN finding(severity=MEDIUM, "COUNT(*) where EXISTS would suffice")
  ```
- **Rationale:** COUNT(*) scans all matching rows to produce an exact count. EXISTS stops at the first match, making it O(1) instead of O(n) for existence checks.
- **Recommendation:** Replace `SELECT COUNT(*) FROM t WHERE ...` used for existence with `SELECT EXISTS(SELECT 1 FROM t WHERE ...)`.
