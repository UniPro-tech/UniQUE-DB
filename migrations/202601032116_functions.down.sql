-- Down migration: drop functions, triggers, and event created by the up migration
DROP TRIGGER IF EXISTS before_insert_sessions;

DROP TRIGGER IF EXISTS before_insert_roles;

DROP TRIGGER IF EXISTS before_insert_apps;

DROP TRIGGER IF EXISTS before_insert_users;

DROP FUNCTION IF EXISTS gen_ulid;

DROP FUNCTION IF EXISTS to_crockford_b32;

DROP EVENT IF EXISTS delete_expired_sessions;

-- Restore event scheduler to off if it was enabled by the up migration
SET
    GLOBAL event_scheduler = OFF;