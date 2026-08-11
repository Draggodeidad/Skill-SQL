# Security Rules

## SEC-001: SELECT * usage

- **Severity:** MEDIUM
- **Detection:**
  ```
  IF statement_type = SELECT
  AND column_list contains *
  AND NOT inside a COUNT(*)
  THEN finding(severity=MEDIUM, "SELECT * exposes all columns")
  ```
- **Rationale:** Exposes columns not needed by the caller, including potentially sensitive data. Breaks when schema changes add columns.
- **Recommendation:** List only the columns required. Example: `SELECT id, name, email FROM users`.

## SEC-002: DELETE without WHERE

- **Severity:** CRITICAL
- **Detection:**
  ```
  IF statement_type = DELETE
  AND WHERE clause is absent
  THEN finding(severity=CRITICAL, "DELETE without WHERE removes all rows")
  AND do not recommend executing the statement
  ```
- **Rationale:** Removes every row from the target table. _Blast radius_ is the entire table.
- **Recommendation:** Add a WHERE clause that limits deletion to intended rows. If bulk delete is intentional, use TRUNCATE with explicit confirmation, or add a WHERE that makes intent clear.

## SEC-003: UPDATE without WHERE

- **Severity:** CRITICAL
- **Detection:**
  ```
  IF statement_type = UPDATE
  AND WHERE clause is absent
  THEN finding(severity=CRITICAL, "UPDATE without WHERE modifies all rows")
  AND do not recommend executing the statement
  ```
- **Rationale:** Modifies every row in the target table. _Blast radius_ is the entire table.
- **Recommendation:** Add a WHERE clause targeting specific rows. If bulk update is intentional, document the reason in a comment.

## SEC-004: TRUNCATE or DROP without guard

- **Severity:** CRITICAL
- **Detection:**
  ```
  IF statement_type IN (TRUNCATE, DROP)
  THEN finding(severity=CRITICAL, "destructive operation without guard")
  ```
- **Rationale:** TRUNCATE removes all rows without logging individual deletions. DROP removes the entire object. Neither is recoverable without a backup.
- **Recommendation:** Wrap in a transaction with explicit COMMIT. Add a comment documenting intent. Verify backup exists before execution.

## SEC-005: SQL Injection via string concatenation

- **Severity:** CRITICAL
- **Detection:**
  ```
  IF SQL fragment is embedded in string concatenation
  AND concatenated value is a variable/parameter (not a literal)
  THEN finding(severity=CRITICAL, "potential SQL injection via string concatenation")
  ```
  Patterns detected:
  - `"SELECT ... WHERE id = " + userInput`
  - `` `SELECT ... WHERE id = ${id}` ``
  - `"SELECT ... WHERE name = '" + name + "'"`
  - `"SELECT ... WHERE id = " . $id`
- **Rationale:** Concatenating user input into SQL allows an attacker to inject arbitrary SQL. Most common injection vector.
- **Recommendation:** Use parameterized queries / prepared statements. Example: `SELECT ... WHERE id = ?` with bound parameters.

## SEC-006: Tautological WHERE clause

- **Severity:** CRITICAL
- **Detection:**
  ```
  IF statement_type IN (DELETE, UPDATE)
  AND WHERE clause is present
  AND WHERE evaluates to always-true:
      - WHERE 1 = 1
      - WHERE TRUE
      - WHERE col = col
      - WHERE col IS NOT NULL OR col IS NULL
      - WHERE ... OR 1 = 1  (any OR branch that is tautological)
      - WHERE col > N OR col <= N  (mathematical complement — covers all values)
      - WHERE col >= N OR col < N  (mathematical complement — covers all values)
      - Any logically exhaustive condition (all possible values satisfy it)
  THEN finding(severity=CRITICAL, "tautological WHERE — equivalent to no WHERE")
  AND do not recommend executing the statement
  ```
- **Rationale:** A WHERE clause that always evaluates to true provides no protection. Commonly used to disguise an unrestricted destructive operation.
- **Recommendation:** Replace with a meaningful condition. If all-row operation is intentional, state this explicitly with a comment and use TRUNCATE (for DELETE) instead.

## SEC-007: Excessive privilege grant

- **Severity:** HIGH
- **Detection:**
  ```
  IF statement_type = GRANT
  AND privilege IN (ALL, ALL PRIVILEGES, SUPER, FILE, SHUTDOWN)
  OR grantee = PUBLIC
  OR WITH GRANT OPTION is present
  THEN finding(severity=HIGH, "excessive privilege grant")
  ```
- **Rationale:** Broad grants violate least-privilege principle. GRANT ALL or PUBLIC grants expose the database to unauthorized operations.
- **Recommendation:** Grant only the specific privileges required. Target specific users/roles rather than PUBLIC.

## SEC-008: Sensitive column exposure

- **Severity:** HIGH
- **Detection:**
  ```
  IF statement_type = SELECT
  AND column_list references columns matching patterns:
      - password, passwd, pwd, secret, token, api_key, apikey
      - ssn, credit_card, card_number, cvv
      - private_key, encryption_key
  AND output is not filtered or masked
  THEN finding(severity=HIGH, "sensitive column selected without masking")
  ```
- **Rationale:** Selecting sensitive columns without masking exposes credentials and PII in logs, caches, and API responses.
- **Recommendation:** Mask sensitive columns in queries (e.g., `'***' AS password`), or exclude them from the SELECT list entirely.
