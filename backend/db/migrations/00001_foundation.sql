-- +goose Up
CREATE TABLE facilities (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), name text NOT NULL,
 organization_ihs text UNIQUE, created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE roles (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), name text NOT NULL UNIQUE
 CHECK (name IN ('admin','nurse','queue_operator'))
);
INSERT INTO roles(name) VALUES ('admin'),('nurse'),('queue_operator');
CREATE TABLE users (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 facility_id uuid NOT NULL REFERENCES facilities(id),
 role_id uuid NOT NULL REFERENCES roles(id),
 email text NOT NULL UNIQUE CHECK(email = lower(email)),
 name text NOT NULL, password_hash text NOT NULL,
 practitioner_ihs text UNIQUE, active boolean NOT NULL DEFAULT true,
 token_version bigint NOT NULL DEFAULT 1,
 created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX users_facility_idx ON users(facility_id,created_at,id);
CREATE INDEX users_role_idx ON users(role_id);
CREATE TABLE refresh_tokens (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), user_id uuid NOT NULL REFERENCES users(id),
 family_id uuid NOT NULL, token_hash text NOT NULL UNIQUE,
 expires_at timestamptz NOT NULL, consumed_at timestamptz, revoked_at timestamptz,
 created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX refresh_user_idx ON refresh_tokens(user_id);
CREATE INDEX refresh_family_idx ON refresh_tokens(family_id);
CREATE INDEX refresh_expiry_idx ON refresh_tokens(expires_at);
CREATE TABLE audit_logs (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), facility_id uuid NOT NULL REFERENCES facilities(id),
 actor_id uuid NOT NULL REFERENCES users(id), target_id uuid REFERENCES users(id),
 action text NOT NULL, created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX audit_facility_time_idx ON audit_logs(facility_id,created_at);
CREATE INDEX audit_actor_idx ON audit_logs(actor_id);
CREATE INDEX audit_target_idx ON audit_logs(target_id);
-- +goose Down
DROP TABLE audit_logs, refresh_tokens, users, roles, facilities;
