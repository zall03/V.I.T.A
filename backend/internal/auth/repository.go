package auth

import "backend/internal/users"

// Repository shares user/session transactions through the SQLC unit of work.
type Repository struct{ *users.Repository }
