-- Edge case SQL examples
-- These statements appear correct superficially but contain hidden problems
-- that should be caught by blast-radius assessment (Step 4).

-- SEC-006: Tautological WHERE — DELETE with WHERE 1=1
-- Surface: has a WHERE clause. Semantic: equivalent to no WHERE.
DELETE FROM users WHERE 1 = 1;

-- SEC-006: Tautological WHERE — UPDATE with WHERE TRUE
UPDATE users SET role = 'admin' WHERE TRUE;

-- SEC-006: Tautological WHERE via OR short-circuit
DELETE FROM audit_log WHERE id = 5 OR 1 = 1;

-- PERF-007: Excessive LIMIT — effectively unbounded
SELECT * FROM events LIMIT 1000000000;

-- SEC-006 + PERF-007: Combined — tautological WHERE and excessive LIMIT
UPDATE users SET role = 'admin' WHERE email LIKE '%';

-- PERF-005: Correlated subquery that should be a JOIN
SELECT e.employee_id, e.full_name,
    (SELECT d.department_name
     FROM departments d
     WHERE d.department_id = e.department_id) AS dept
FROM employees e;

-- PERF-010: COUNT(*) used for existence check
SELECT user_id, full_name
FROM users
WHERE (SELECT COUNT(*) FROM orders o WHERE o.user_id = users.user_id) > 0;

-- PERF-009: SELECT inside unnecessary transaction
BEGIN;
SELECT user_id, full_name FROM users WHERE user_id = 42;
COMMIT;

-- CONV-004: Implicit type coercion — storing dates as VARCHAR
INSERT INTO events (event_name, event_date)
VALUES ('Launch', '2024-01-15');
-- If event_date is VARCHAR, the date is stored as a string with no validation

-- PERF-008: Type coercion in JOIN
-- Given: orders.customer_id is VARCHAR, customers.customer_id is INT
SELECT o.order_id, c.full_name
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id;

-- SEC-006: Tautological WHERE via column = column
UPDATE accounts SET balance = 0 WHERE balance = balance;

-- SEC-001 + PERF-001: SELECT * without LIMIT — double violation
SELECT * FROM transactions;
