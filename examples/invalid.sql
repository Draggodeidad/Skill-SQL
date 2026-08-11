-- Invalid SQL examples
-- These statements contain clear violations that should be detected.

-- SEC-001: SELECT * exposes all columns
SELECT * FROM users;

-- SEC-002: DELETE without WHERE removes all rows
DELETE FROM audit_log;

-- SEC-003: UPDATE without WHERE modifies all rows
UPDATE users SET is_admin = TRUE;

-- SEC-004: TRUNCATE without guard
TRUNCATE TABLE sessions;

-- SEC-005: SQL Injection via string concatenation (pseudocode context)
-- query = "SELECT * FROM users WHERE name = '" + userInput + "'"
-- query = `SELECT * FROM users WHERE id = ${userId}`

-- SEC-008: Sensitive column exposure
SELECT user_id, full_name, password, api_key, ssn
FROM users
WHERE department = 'HR';

-- CONV-003: Incorrect NULL comparison (= NULL always returns UNKNOWN)
SELECT user_id, full_name
FROM users
WHERE deleted_at = NULL;

-- PERF-001: Missing LIMIT on potentially large result
SELECT order_id, customer_id, total_amount
FROM orders
WHERE status = 'completed';

-- PERF-002: Leading wildcard prevents index usage
SELECT user_id, full_name
FROM users
WHERE email LIKE '%@company.com';

-- CONV-004: Data type mismatch in DDL
CREATE TABLE products (
    product_id VARCHAR(10),
    product_name VARCHAR(200),
    price VARCHAR(20),
    created_date VARCHAR(50),
    is_active INT
);

-- SEC-007: Excessive privilege grant
GRANT ALL PRIVILEGES ON *.* TO 'app_user'@'%' WITH GRANT OPTION;
