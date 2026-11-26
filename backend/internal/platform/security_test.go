package platform

import (
	"encoding/json"
	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"github.com/stretchr/testify/require"
	"testing"
	"time"
)

func TestPassword(t *testing.T) {
	h, e := HashPassword("synthetic-password-123")
	require.NoError(t, e)
	require.True(t, VerifyPassword(h, "synthetic-password-123"))
	require.False(t, VerifyPassword(h, "wrong"))
	require.False(t, VerifyPassword("malformed", "anything"))
	h2, e := HashPassword("synthetic-password-123")
	require.NoError(t, e)
	require.NotEqual(t, h, h2)
}
func TestAccessExpiryAndSignature(t *testing.T) {
	tokens := Tokens{Key: []byte("synthetic-test-signing-key-32bytes!")}
	id := uuid.New()
	raw, e := tokens.Access(id, 1)
	require.NoError(t, e)
	c, e := tokens.Parse(raw)
	require.NoError(t, e)
	require.Equal(t, id.String(), c.Subject)
	require.Equal(t, 15*time.Minute, c.ExpiresAt.Sub(c.IssuedAt.Time))
	c.ExpiresAt = jwt.NewNumericDate(time.Now().Add(-time.Second))
	raw, e = jwt.NewWithClaims(jwt.SigningMethodHS256, c).SignedString(tokens.Key)
	require.NoError(t, e)
	_, e = tokens.Parse(raw)
	require.Error(t, e)
	_, e = (Tokens{Key: []byte("different-key")}).Parse(raw)
	require.Error(t, e)
}
func TestOpaque(t *testing.T) {
	a, e := Opaque()
	require.NoError(t, e)
	b, e := Opaque()
	require.NoError(t, e)
	require.Len(t, a, 43)
	require.NotEqual(t, a, b)
	require.Len(t, Digest(a), 64)
	require.NotContains(t, Digest(a), a)
	_, e = json.Marshal(a)
	require.NoError(t, e)
}
