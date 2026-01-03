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