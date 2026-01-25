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

ALTER TABLE `token_sets`
DROP CONSTRAINT `access_token_id`;

ALTER TABLE `token_sets`
DROP CONSTRAINT `refresh_token_id`;

ALTER TABLE `token_sets`
DROP CONSTRAINT `id_token_id`;

ALTER TABLE `auths`
DROP CONSTRAINT `auth_user_id`;

ALTER TABLE `sessions`
DROP CONSTRAINT `user_id`;

ALTER TABLE `redirect_uris`
DROP CONSTRAINT `app_id`;

ALTER TABLE `auths`
DROP CONSTRAINT `app_id`;

ALTER TABLE `oidc_authorizations`
DROP CONSTRAINT `auth_id`;

ALTER TABLE `oidc_authorizations`
DROP CONSTRAINT `consent_id`;

ALTER TABLE `oidc_authorizations`
DROP CONSTRAINT `code_id`;

ALTER TABLE `token_sets`
DROP CONSTRAINT `oidc_authorization_id`;

ALTER TABLE `discords`
DROP CONSTRAINT `user_id`;

ALTER TABLE `user_role`
DROP CONSTRAINT `user_id`;

ALTER TABLE `user_role`
DROP CONSTRAINT `role_id`;

ALTER TABLE `user_app`
DROP CONSTRAINT `app_id`;

ALTER TABLE `user_app`
DROP CONSTRAINT `user_id`;

DROP TABLE `users`;

DROP TABLE `apps`;

DROP TABLE `redirect_uris`;

DROP TABLE `auths`;

DROP TABLE `oidc_authorizations`;

DROP TABLE `token_sets`;

DROP TABLE `code`;

DROP TABLE `access_tokens`;

DROP TABLE `refresh_tokens`;

DROP TABLE `id_tokens`;

DROP TABLE `consents`;

DROP TABLE `sessions`;

DROP TABLE `roles`;

DROP TABLE `discords`;

DROP TABLE `user_role`;

DROP TABLE `user_app`;

DROP TABLE `email_verifications`;

-- create new tables
CREATE TABLE
  users (
    id CHAR(26) PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255),
    birthdate DATE,
    period INT,
    status ENUM ('pending', 'active', 'suspended', 'deleted') NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
  );

CREATE TABLE
  email_verifications (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id CHAR(26) NOT NULL,
    token VARCHAR(255) NOT NULL,
    expires_at DATETIME NOT NULL,
    verified_at DATETIME,
    created_at DATETIME,
    updated_at DATETIME,
    FOREIGN KEY (user_id) REFERENCES users (id)
  );

CREATE TABLE
  user_status_histories (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id CHAR(26) NOT NULL,
    from_status ENUM ('pending', 'active', 'suspended', 'deleted'),
    to_status ENUM ('pending', 'active', 'suspended', 'deleted'),
    reason TEXT,
    until DATETIME NULL,
    changed_by CHAR(26),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users (id)
  );

CREATE TABLE
  roles (id BIGINT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(50) UNIQUE);

CREATE TABLE
  user_roles (
    user_id CHAR(26),
    role_id BIGINT,
    PRIMARY KEY (user_id, role_id),
    FOREIGN KEY (user_id) REFERENCES users (id),
    FOREIGN KEY (role_id) REFERENCES roles (id)
  );

CREATE TABLE
  audit_logs (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    actor_user_id CHAR(26),
    action VARCHAR(100),
    target_type VARCHAR(50),
    target_id CHAR(26),
    ip_address VARCHAR(45),
    user_agent TEXT,
    metadata JSON,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  );

CREATE TABLE
  external_identities (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    provider VARCHAR(30),
    provider_user_id VARCHAR(100),
    user_id CHAR(26),
    access_token TEXT,
    refresh_token TEXT,
    expires_at DATETIME,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE (provider, provider_user_id),
    FOREIGN KEY (user_id) REFERENCES users (id)
  );

CREATE TABLE
  oauth_clients (
    id CHAR(26) PRIMARY KEY,
    name VARCHAR(100),
    type ENUM ('confidential', 'public'),
    client_secret VARCHAR(255),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
  );

CREATE TABLE
  oauth_client_redirect_uris (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    client_id CHAR(26),
    uri TEXT,
    FOREIGN KEY (client_id) REFERENCES oauth_clients (id)
  );

CREATE TABLE
  user_consents (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id CHAR(26),
    client_id CHAR(26),
    SCOPE TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (user_id, client_id),
    FOREIGN KEY (user_id) REFERENCES users (id),
    FOREIGN KEY (client_id) REFERENCES oauth_clients (id)
  );

CREATE TABLE
  auth_sessions (
    id CHAR(26) PRIMARY KEY,
    user_id CHAR(26),
    ip_address VARCHAR(45),
    user_agent TEXT,
    expires_at DATETIME,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users (id)
  );

CREATE TABLE
  authorization_codes (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    token VARCHAR(255) UNIQUE,
    user_id CHAR(26),
    client_id CHAR(26),
    SCOPE TEXT,
    nonce VARCHAR(255),
    code_challenge VARCHAR(255),
    code_challenge_method VARCHAR(10),
    redirect_uri TEXT,
    acr VARCHAR(50),
    amr VARCHAR(50),
    expires_at DATETIME,
    used BOOLEAN DEFAULT FALSE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users (id),
    FOREIGN KEY (client_id) REFERENCES oauth_clients (id)
  );

CREATE TABLE
  access_tokens (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    hash CHAR(64),
    user_id CHAR(26),
    client_id CHAR(26),
    SCOPE TEXT,
    expires_at DATETIME,
    revoked BOOLEAN,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  );

CREATE TABLE
  refresh_tokens (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    hash CHAR(64),
    user_id CHAR(26),
    client_id CHAR(26),
    expires_at DATETIME,
    revoked BOOLEAN,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  );

CREATE TABLE
  id_tokens (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    hash CHAR(64),
    user_id CHAR(26),
    client_id CHAR(26),
    nonce VARCHAR(255),
    expires_at DATETIME,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  );

CREATE TABLE
  token_sets (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    authorization_code_id BIGINT,
    access_token_id BIGINT,
    refresh_token_id BIGINT,
    id_token_id BIGINT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  );

-- =========================
-- audit_logs
-- =========================
ALTER TABLE audit_logs ADD CONSTRAINT fk_audit_logs_actor FOREIGN KEY (actor_user_id) REFERENCES users (id);

-- =========================
-- access_tokens
-- =========================
ALTER TABLE access_tokens ADD CONSTRAINT fk_access_tokens_user FOREIGN KEY (user_id) REFERENCES users (id);

ALTER TABLE access_tokens ADD CONSTRAINT fk_access_tokens_client FOREIGN KEY (client_id) REFERENCES oauth_clients (id);

-- =========================
-- refresh_tokens
-- =========================
ALTER TABLE refresh_tokens ADD CONSTRAINT fk_refresh_tokens_user FOREIGN KEY (user_id) REFERENCES users (id);

ALTER TABLE refresh_tokens ADD CONSTRAINT fk_refresh_tokens_client FOREIGN KEY (client_id) REFERENCES oauth_clients (id);

-- =========================
-- id_tokens
-- =========================
ALTER TABLE id_tokens ADD CONSTRAINT fk_id_tokens_user FOREIGN KEY (user_id) REFERENCES users (id);

ALTER TABLE id_tokens ADD CONSTRAINT fk_id_tokens_client FOREIGN KEY (client_id) REFERENCES oauth_clients (id);

-- =========================
-- token_sets
-- =========================
ALTER TABLE token_sets ADD CONSTRAINT fk_token_sets_auth_code FOREIGN KEY (authorization_code_id) REFERENCES authorization_codes (id);

ALTER TABLE token_sets ADD CONSTRAINT fk_token_sets_access FOREIGN KEY (access_token_id) REFERENCES access_tokens (id);

ALTER TABLE token_sets ADD CONSTRAINT fk_token_sets_refresh FOREIGN KEY (refresh_token_id) REFERENCES refresh_tokens (id);

ALTER TABLE token_sets ADD CONSTRAINT fk_token_sets_id FOREIGN KEY (id_token_id) REFERENCES id_tokens (id);


-- =========================
-- user_consents トリガー
-- =========================
-- user_consents が削除されたときに関連する token_sets とその中の access_tokens, refresh_tokens, id_tokens を削除するトリガー
DELIMITER $$

CREATE TRIGGER delete_tokens_after_consent_delete
AFTER DELETE ON user_consents
FOR EACH ROW
BEGIN
  -- access_tokens 削除
  DELETE FROM access_tokens
  WHERE id IN (
    SELECT access_token_id
    FROM token_sets
    WHERE client_id = OLD.client_id
      AND user_id = OLD.user_id
  );

  -- refresh_tokens 削除
  DELETE FROM refresh_tokens
  WHERE id IN (
    SELECT refresh_token_id
    FROM token_sets
    WHERE client_id = OLD.client_id
      AND user_id = OLD.user_id
  );

  -- id_tokens 削除
  DELETE FROM id_tokens
  WHERE id IN (
    SELECT id_token_id
    FROM token_sets
    WHERE client_id = OLD.client_id
      AND user_id = OLD.user_id
  );

  -- 最後に token_sets を削除
  DELETE FROM token_sets
  WHERE client_id = OLD.client_id
    AND user_id = OLD.user_id;
END$$

DELIMITER ;
