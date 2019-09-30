create table users (
  id serial primary key,
  webauthn_user_id varchar(20) not null unique,
  credential_id varchar not null unique,
  display_name varchar not null,
  public_key varchar unique,
  sign_count integer not null default 0,
  name varchar not null unique,
  icon_url varchar,
  created_at timestamp not null default now(),
  updated_at timestamp not null default now(),
  deleted_at timestamp default now()
)
;
