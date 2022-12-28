CREATE DATABASE IF NOT EXISTS nas2cloud DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;

CREATE USER 'nas2cloud'@'%' IDENTIFIED BY 'nas2cloud';
GRANT ALL ON nas2cloud.* TO 'nas2cloud'@'%';
FLUSH PRIVILEGES;

CREATE TABLE IF NOT EXISTS nas2cloud.user_auth_token
(
    id           BIGINT AUTO_INCREMENT PRIMARY KEY,
    gmt_create   DATETIME     NOT NULL,
    git_modified DATETIME     NOT NULL,
    user_name    VARCHAR(64)  NOT NULL,
    token        VARCHAR(128) NOT NULL,
    device_type  VARCHAR(64)  NOT NULL,
    device       VARCHAR(256) NULL,
    status       TINYINT      NOT NULL
);

CREATE INDEX user_auth_token_token_index ON nas2cloud.user_auth_token (token);
