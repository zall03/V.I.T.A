-- name: UserByEmail :one
SELECT u.*, r.name AS role FROM users u JOIN roles r ON r.id=u.role_id WHERE u.email=$1;
-- name: UserByID :one
SELECT u.*, r.name AS role FROM users u JOIN roles r ON r.id=u.role_id WHERE u.id=$1;
-- name: LockUser :one
SELECT id FROM users WHERE id=$1 FOR UPDATE;
-- name: ListUsers :many
SELECT u.*, r.name AS role FROM users u JOIN roles r ON r.id=u.role_id
WHERE u.facility_id=$1 ORDER BY u.created_at,u.id LIMIT $2 OFFSET $3;
-- name: CreateUser :one
INSERT INTO users(facility_id,role_id,email,name,password_hash,practitioner_ihs)
VALUES($1,(SELECT roles.id FROM roles WHERE roles.name=sqlc.arg(role)), $2,$3,$4,$5) RETURNING users.id;
-- name: UpdateUser :execrows
UPDATE users SET name=$3,email=$4,role_id=(SELECT roles.id FROM roles WHERE roles.name=sqlc.arg(role)),
practitioner_ihs=$5,updated_at=now(),token_version=token_version+1
WHERE users.id=$1 AND users.facility_id=$2;
-- name: SetActive :execrows
UPDATE users SET active=$3,token_version=token_version+1,updated_at=now() WHERE id=$1 AND facility_id=$2;
-- name: ChangePassword :exec
UPDATE users SET password_hash=$2,token_version=token_version+1,updated_at=now() WHERE id=$1;
-- name: InsertRefresh :exec
INSERT INTO refresh_tokens(user_id,family_id,token_hash,expires_at) VALUES($1,$2,$3,$4);
-- name: FindRefresh :one
SELECT * FROM refresh_tokens WHERE token_hash=$1;
-- name: LockRefresh :one
SELECT * FROM refresh_tokens WHERE token_hash=$1 FOR UPDATE;
-- name: ConsumeRefresh :exec
UPDATE refresh_tokens SET consumed_at=now() WHERE id=$1;
-- name: RevokeFamily :exec
UPDATE refresh_tokens SET revoked_at=now() WHERE family_id=$1 AND revoked_at IS NULL;
-- name: RevokeUser :exec
UPDATE refresh_tokens SET revoked_at=now() WHERE user_id=$1 AND revoked_at IS NULL;
-- name: Audit :exec
INSERT INTO audit_logs(facility_id,actor_id,target_id,action) VALUES($1,$2,$3,$4);
-- name: CreateFacility :one
INSERT INTO facilities(name) VALUES($1) RETURNING id;
