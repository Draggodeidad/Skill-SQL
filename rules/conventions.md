# Convention Rules

## CONV-001: Non-descriptive names

- **Severity:** LOW
- **Detection:**
  ```
  IF table name is a single letter or abbreviation (e.g., t, tbl, tmp)
  OR column name is a single letter (e.g., a, b, c, n, d)
  OR alias is a single letter in a multi-table query
  THEN finding(severity=LOW, "non-descriptive name")
  ```
- **Rationale:** Single-letter or abbreviated names obscure intent and make maintenance harder.
- **Recommendation:** Use descriptive names that convey purpose. Example: `users` instead of `u`, `created_at` instead of `d`.
- **Exception:** Single-letter aliases are acceptable in short, single-table queries where context is obvious (e.g., `SELECT u.name FROM users u WHERE u.id = 1`).

## CONV-002: Inconsistent naming convention

- **Severity:** LOW
- **Detection:**
  ```
  IF the input contains multiple tables or columns
  AND naming mixes conventions (e.g., camelCase and snake_case in the same script)
  AND prefix patterns are inconsistent (e.g., tbl_ and t_ for tables)
  THEN finding(severity=LOW, "inconsistent naming convention")
  ```
- **Rationale:** Mixed naming conventions within the same codebase create confusion and suggest multiple authors without coordination.
- **Recommendation:** Adopt a single convention (snake_case is standard for SQL) and apply it consistently.

## CONV-003: Incorrect NULL comparison

- **Severity:** HIGH
- **Detection:**
  ```
  IF WHERE clause contains: column = NULL
  OR WHERE clause contains: column != NULL
  OR WHERE clause contains: column <> NULL
  THEN finding(severity=HIGH, "NULL compared with = / != / <> — always evaluates to UNKNOWN")
  ```
- **Rationale:** In SQL, `NULL = NULL` evaluates to UNKNOWN (not TRUE). Comparisons with `=`, `!=`, or `<>` against NULL always return no rows. This is a correctness bug, not a style issue.
- **Recommendation:** Use `IS NULL` and `IS NOT NULL`. Example: `WHERE column IS NULL` instead of `WHERE column = NULL`.

## CONV-004: Data type mismatch

- **Severity:** MEDIUM
- **Detection:**
  ```
  IF DDL defines a column with an inappropriate type:
      - VARCHAR/TEXT for dates (use DATE, TIMESTAMP)
      - VARCHAR for numeric IDs (use INT, BIGINT)
      - INT for boolean flags (use BOOLEAN or TINYINT(1))
      - VARCHAR for currency (use DECIMAL/NUMERIC)
  OR INSERT/UPDATE assigns a value that requires implicit conversion
  THEN finding(severity=MEDIUM, "data type mismatch")
  ```
- **Rationale:** Storing data in the wrong type prevents type-level validation, blocks index optimization, and causes implicit conversion issues.
- **Recommendation:** Use the correct type for the data: DATE for dates, DECIMAL for currency, INT for identifiers, BOOLEAN for flags.

## CONV-005: Missing comments on complex queries

- **Severity:** INFO
- **Detection:**
  ```
  IF statement contains:
      - more than 2 JOINs
      - nested subqueries
      - CTEs (WITH clause)
      - window functions
      - CASE expressions with more than 3 branches
  AND no SQL comment (-- or /* */) is present
  THEN finding(severity=INFO, "complex query without explanatory comment")
  ```
- **Rationale:** Complex queries without comments are difficult to maintain and review. The comment should explain _why_, not _what_.
- **Recommendation:** Add a comment explaining the query's purpose and any non-obvious logic.

## CONV-006: Inconsistent keyword casing

- **Severity:** INFO
- **Detection:**
  ```
  IF SQL keywords in the input mix UPPER and lower case
  (e.g., "Select" and "FROM" and "where" in the same statement)
  THEN finding(severity=INFO, "inconsistent keyword casing")
  ```
- **Rationale:** Mixed casing reduces readability. Consistent casing (typically UPPER for keywords) is the standard convention.
- **Recommendation:** Use UPPER CASE for SQL keywords and lower case for identifiers (or adopt and follow a consistent style).
