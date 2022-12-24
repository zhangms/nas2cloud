CREATE DATABASE nas2cloud DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;

CREATE USER 'nas2cloud'@'%' IDENTIFIED BY 'nas2cloud';
GRANT ALL ON nas2cloud.* TO 'nas2cloud'@'%';
FLUSH PRIVILEGES;

create table nas2cloud.user_auth_token
(
    id           bigint auto_increment
        primary key,
    gmt_create   datetime     not null,
    git_modified datetime     not null,
    user_name    varchar(64)  not null,
    token        varchar(128) not null,
    device       varchar(256) null,
    status       tinyint      not null
);

create index user_auth_token_token_index
    on nas2cloud.user_auth_token (token);



