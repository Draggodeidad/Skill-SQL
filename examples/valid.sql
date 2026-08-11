-- Valid SQL examples
-- These statements follow best practices and should produce no findings above INFO.

-- Specific columns, with LIMIT
SELECT user_id, full_name, email
FROM users
WHERE is_active = TRUE
ORDER BY created_at DESC
LIMIT 50;

-- UPDATE with targeted WHERE
UPDATE users
SET last_login = NOW()
WHERE user_id = 42;

-- DELETE with specific WHERE
DELETE FROM sessions
WHERE expires_at < NOW()
AND user_id = 42;

-- INSERT with named columns
INSERT INTO audit_log (user_id, action, created_at)
VALUES (42, 'login', NOW());

-- JOIN with explicit columns
SELECT o.order_id, o.total_amount, c.full_name, c.email
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE o.status = 'pending'
ORDER BY o.created_at DESC
LIMIT 100;

-- Parameterized query (application code)
-- PreparedStatement: SELECT user_id, full_name FROM users WHERE email = ?

-- Proper NULL check
SELECT user_id, full_name
FROM users
WHERE deleted_at IS NULL;

-- EXISTS for existence check
SELECT user_id, full_name
FROM users u
WHERE EXISTS (
    SELECT 1 FROM orders o WHERE o.customer_id = u.user_id
);

-- Transaction with writes
BEGIN;
UPDATE accounts SET balance = balance - 100 WHERE account_id = 1;
UPDATE accounts SET balance = balance + 100 WHERE account_id = 2;
INSERT INTO transfers (from_account, to_account, amount, created_at)
VALUES (1, 2, 100, NOW());
COMMIT;
