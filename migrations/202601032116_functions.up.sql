-- Converted for golang-migrate: use dynamic SQL to avoid client-only `DELIMITER`.

DROP FUNCTION IF EXISTS to_crockford_b32;
SET @s = 'CREATE FUNCTION to_crockford_b32 (src BIGINT, encoded_len INT)
RETURNS TEXT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE result TEXT DEFAULT '''';
    DECLARE b32char CHAR(32) DEFAULT ''0123456789ABCDEFGHJKMNPQRSTVWXYZ'';
    DECLARE i INT DEFAULT 0;

    ENCODE: LOOP
        SET i = i + 1;
        SET result = CONCAT(SUBSTRING(b32char, (src MOD 32) + 1, 1), result);
        SET src = src DIV 32;

        IF i < encoded_len THEN
            ITERATE ENCODE;
        END IF;

        LEAVE ENCODE;
    END LOOP ENCODE;

    RETURN result;
END';
PREPARE stmt FROM @s;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

DROP FUNCTION IF EXISTS gen_ulid;
SET @s = 'CREATE FUNCTION gen_ulid ()
RETURNS CHAR(26)
NOT DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE msec_ts BIGINT DEFAULT FLOOR(UNIX_TIMESTAMP(CURRENT_TIMESTAMP(4)) * 1000);
    DECLARE rand CHAR(20) DEFAULT HEX(RANDOM_BYTES(10));
    DECLARE rand_first BIGINT DEFAULT CONV(SUBSTRING(rand, 1, 10), 16, 10);
    DECLARE rand_last  BIGINT DEFAULT CONV(SUBSTRING(rand, 11, 10), 16, 10);

    RETURN CONCAT(
        to_crockford_b32(msec_ts, 10),
        to_crockford_b32(rand_first, 8),
        to_crockford_b32(rand_last, 8)
    );
END';
PREPARE stmt FROM @s;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

DROP TRIGGER IF EXISTS before_insert_users;
SET @s = 'CREATE TRIGGER before_insert_users
BEFORE INSERT ON users
FOR EACH ROW
BEGIN
    IF NEW.id IS NULL OR NEW.id = '''' THEN
        SET NEW.id = gen_ulid();
    END IF;
END';
PREPARE stmt FROM @s;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

DROP TRIGGER IF EXISTS before_insert_apps;
SET @s = 'CREATE TRIGGER before_insert_apps
BEFORE INSERT ON apps
FOR EACH ROW
BEGIN
    IF NEW.id IS NULL OR NEW.id = '''' THEN
        SET NEW.id = gen_ulid();
    END IF;
END';
PREPARE stmt FROM @s;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

DROP TRIGGER IF EXISTS before_insert_roles;
SET @s = 'CREATE TRIGGER before_insert_roles
BEFORE INSERT ON roles
FOR EACH ROW
BEGIN
    IF NEW.id IS NULL OR NEW.id = '''' THEN
        SET NEW.id = gen_ulid();
    END IF;
END';
PREPARE stmt FROM @s;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

DROP TRIGGER IF EXISTS before_insert_sessions;
SET @s = 'CREATE TRIGGER before_insert_sessions
BEFORE INSERT ON sessions
FOR EACH ROW
BEGIN
    IF NEW.id IS NULL OR NEW.id = '''' THEN
        SET NEW.id = gen_ulid();
    END IF;
END';
PREPARE stmt FROM @s;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Enable event scheduler and create event via dynamic SQL (event body contains semicolon)
SET GLOBAL event_scheduler = ON;
DROP EVENT IF EXISTS delete_expired_sessions;
SET @s = 'CREATE EVENT delete_expired_sessions
ON SCHEDULE EVERY 1 HOUR
DO
    DELETE FROM sessions WHERE expires_at < NOW()';
PREPARE stmt FROM @s;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
