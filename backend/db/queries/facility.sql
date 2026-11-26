-- name: GetFacility :one
SELECT * FROM facilities WHERE id=$1;
-- name: UpdateFacilityName :one
UPDATE facilities SET name=$2 WHERE id=$1 RETURNING *;
