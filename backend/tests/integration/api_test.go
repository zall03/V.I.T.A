//go:build integration

package integration

import (
	"backend/internal/app"
	"backend/internal/auth"
	"backend/internal/database"
	"backend/internal/platform"
	"backend/internal/users"
	"bytes"
	"context"
	"encoding/json"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/jackc/pgx/v5/stdlib"
	"github.com/pressly/goose/v3"
	"github.com/stretchr/testify/require"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"os"
	"testing"
	"time"
)

// Uses an isolated schema; TEST_DATABASE_URL must point at a disposable test DB.
func TestAPI(t *testing.T) {
	url := os.Getenv("TEST_DATABASE_URL")
	require.NotEmpty(t, url, "TEST_DATABASE_URL is required for integration tests")
	ctx := context.Background()
	base, e := pgxpool.New(ctx, url)
	require.NoError(t, e)
	defer base.Close()
	schema := "test_" + uuid.New().String()[:8]
	_, e = base.Exec(ctx, "CREATE SCHEMA "+schema)
	require.NoError(t, e)
	defer func() { _, _ = base.Exec(ctx, "DROP SCHEMA "+schema+" CASCADE") }()
	cfg, e := pgxpool.ParseConfig(url)
	require.NoError(t, e)
	cfg.ConnConfig.RuntimeParams["search_path"] = schema
	p, e := pgxpool.NewWithConfig(ctx, cfg)
	require.NoError(t, e)
	defer p.Close()
	db := stdlib.OpenDB(*cfg.ConnConfig)
	defer db.Close()
	require.NoError(t, goose.SetDialect("postgres"))
	require.NoError(t, goose.Up(db, "../../db/migrations"))
	q := database.New(p)
	f1, e := q.CreateFacility(ctx, "Synthetic A")
	require.NoError(t, e)
	f2, e := q.CreateFacility(ctx, "Synthetic B")
	require.NoError(t, e)
	password := "Synthetic-test-password-123"
	hash, e := platform.HashPassword(password)
	require.NoError(t, e)
	makeUser := func(email, role string, f uuid.UUID) uuid.UUID {
		id, e := q.CreateUser(ctx, database.CreateUserParams{FacilityID: f, Email: email, Name: "Synthetic User", PasswordHash: hash, Role: role})
		require.NoError(t, e)
		return id
	}
	adminID := makeUser("admin@example.test", "admin", f1)
	_ = adminID
	nurseID := makeUser("nurse@example.test", "nurse", f1)
	foreignID := makeUser("foreign@example.test", "nurse", f2)
	r, e := app.Router(p, platform.Config{JWTKey: []byte("synthetic-test-signing-key-32bytes!")}, slog.New(slog.NewJSONHandler(io.Discard, nil)))
	require.NoError(t, e)
	call := func(method, path, token string, body any) (int, map[string]any) {
		var b []byte
		if body != nil {
			b, e = json.Marshal(body)
			require.NoError(t, e)
		}
		req := httptest.NewRequest(method, path, bytes.NewReader(b))
		req.Header.Set("Content-Type", "application/json")
		if token != "" {
			req.Header.Set("Authorization", "Bearer "+token)
		}
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)
		var out map[string]any
		require.NoError(t, json.Unmarshal(w.Body.Bytes(), &out))
		require.NotContains(t, w.Body.String(), "password_hash")
		require.NotContains(t, w.Body.String(), "token_hash")
		require.NotContains(t, w.Body.String(), hash)
		return w.Code, out
	}
	login := func(email string) map[string]any {
		status, out := call("POST", "/api/v1/auth/login", "", map[string]any{"email": email, "password": password})
		require.Equal(t, 200, status)
		return out["data"].(map[string]any)
	}
	status, _ := call("GET", "/api/v1/users", "", nil)
	require.Equal(t, http.StatusUnauthorized, status)
	admin := login("admin@example.test")
	access := admin["access_token"].(string)
	refresh := admin["refresh_token"].(string)
	status, out := call("GET", "/api/v1/auth/me", access, nil)
	require.Equal(t, 200, status)
	require.Equal(t, "admin", out["data"].(map[string]any)["role"])
	status, _ = call("GET", "/api/v1/users/"+foreignID.String(), access, nil)
	require.Equal(t, 404, status)
	status, out = call("GET", "/api/v1/users", access, nil)
	require.Equal(t, 200, status)
	require.Len(t, out["data"], 2)
	status, _ = call("POST", "/api/v1/users", access, map[string]any{"email": "bad@example.test", "name": "Synthetic", "password": password, "role": "admin"})
	require.Equal(t, 400, status)
	status, out = call("POST", "/api/v1/users", access, map[string]any{"email": "new@example.test", "name": "Synthetic", "password": password, "role": "queue_operator"})
	require.Equal(t, 201, status)
	created := out["data"].(map[string]any)["id"].(string)
	status, _ = call("PUT", "/api/v1/users/"+created, access, map[string]any{"email": "updated@example.test", "name": "Synthetic Updated", "role": "nurse"})
	require.Equal(t, 200, status)
	nurse := login("nurse@example.test")
	nurseAccess := nurse["access_token"].(string)
	status, _ = call("GET", "/api/v1/users", nurseAccess, nil)
	require.Equal(t, 403, status)
	status, _ = call("PATCH", "/api/v1/users/"+foreignID.String()+"/active", access, map[string]any{"active": false})
	require.Equal(t, 404, status)
	status, _ = call("PATCH", "/api/v1/users/"+nurseID.String()+"/active", access, map[string]any{"active": false})
	require.Equal(t, 200, status)
	status, _ = call("GET", "/api/v1/auth/me", nurseAccess, nil)
	require.Equal(t, 401, status)
	status, _ = call("POST", "/api/v1/auth/login", "", map[string]any{"email": "nurse@example.test", "password": password})
	require.Equal(t, 401, status)
	status, _ = call("PATCH", "/api/v1/users/"+nurseID.String()+"/active", access, map[string]any{"active": true})
	require.Equal(t, 200, status)
	status, out = call("POST", "/api/v1/auth/refresh", "", map[string]any{"refresh_token": refresh})
	require.Equal(t, 200, status)
	rotated := out["data"].(map[string]any)["refresh_token"].(string)
	require.NotEqual(t, refresh, rotated)
	status, _ = call("POST", "/api/v1/auth/refresh", "", map[string]any{"refresh_token": refresh})
	require.Equal(t, 401, status)
	status, _ = call("POST", "/api/v1/auth/refresh", "", map[string]any{"refresh_token": rotated})
	require.Equal(t, 401, status)
	// Direct service calls avoid the deliberate HTTP login/refresh rate limit.
	stored, e := q.FindRefresh(ctx, platform.Digest(rotated))
	require.NoError(t, e)
	require.True(t, stored.RevokedAt.Valid)
	status, _ = call("POST", "/api/v1/auth/logout", access, map[string]any{"refresh_token": rotated})
	require.Equal(t, 200, status)
	status, _ = call("POST", "/api/v1/auth/change-password", access, map[string]any{"current_password": password, "new_password": "Synthetic-new-password-456"})
	require.Equal(t, 200, status)
	status, _ = call("GET", "/api/v1/auth/me", access, nil)
	require.Equal(t, 401, status)
	service := &auth.Service{Repo: &auth.Repository{Repository: users.NewRepository(p)}, Tokens: platform.Tokens{Key: []byte("synthetic-test-signing-key-32bytes!")}}
	t.Run("refresh expiry", func(t *testing.T) {
		raw, err := platform.Opaque()
		require.NoError(t, err)
		require.NoError(t, q.InsertRefresh(ctx, database.InsertRefreshParams{UserID: nurseID, FamilyID: uuid.New(), TokenHash: platform.Digest(raw), ExpiresAt: pgtype.Timestamptz{Time: time.Now().Add(-time.Second), Valid: true}}))
		_, err = service.Refresh(ctx, raw)
		require.ErrorIs(t, err, platform.Unauthorized)
	})
	t.Run("logout revokes active family", func(t *testing.T) {
		pair, err := service.Login(ctx, auth.LoginDTO{Email: "nurse@example.test", Password: password})
		require.NoError(t, err)
		u, err := service.Authenticate(ctx, pair.AccessToken)
		require.NoError(t, err)
		require.NoError(t, service.Logout(ctx, u, pair.RefreshToken))
		_, err = service.Refresh(ctx, pair.RefreshToken)
		require.ErrorIs(t, err, platform.Unauthorized)
	})
	require.NoError(t, goose.Down(db, "../../db/migrations"))
}
