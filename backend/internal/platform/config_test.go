package platform

import (
	"github.com/google/uuid"
	"github.com/stretchr/testify/require"
	"testing"
	"time"
)

func TestTokenDurationConfiguration(t *testing.T) {
	t.Setenv("DATABASE_URL", "postgres://synthetic")
	t.Setenv("JWT_SECRET", "synthetic-test-signing-key-32bytes!")
	t.Setenv("CORS_ORIGINS", "")
	t.Setenv("ACCESS_TOKEN_TTL", "")
	t.Setenv("REFRESH_TOKEN_TTL", "")
	c, e := Load()
	require.NoError(t, e)
	require.Equal(t, 15*time.Minute, c.AccessTokenTTL)
	require.Equal(t, 168*time.Hour, c.RefreshTokenTTL)
	for _, raw := range []string{"0s", "-1m", "invalid", "1.5s", "999999999999999999h"} {
		t.Setenv("ACCESS_TOKEN_TTL", raw)
		_, e = Load()
		require.Error(t, e)
	}
	t.Setenv("ACCESS_TOKEN_TTL", "5m")
	t.Setenv("REFRESH_TOKEN_TTL", "24h")
	c, e = Load()
	require.NoError(t, e)
	tokens := Tokens{Key: c.JWTKey, TTL: c.AccessTokenTTL}
	raw, e := tokens.Access(uuid.New(), 1)
	require.NoError(t, e)
	claims, e := tokens.Parse(raw)
	require.NoError(t, e)
	require.Equal(t, 5*time.Minute, claims.ExpiresAt.Sub(claims.IssuedAt.Time))
	require.Equal(t, 24*time.Hour, c.RefreshTokenTTL)
}
