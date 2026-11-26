package users

import (
	"encoding/json"
	"github.com/stretchr/testify/require"
	"testing"
)

func TestAuthorization(t *testing.T) {
	for _, role := range []string{"nurse", "queue_operator", "unknown", ""} {
		require.False(t, CanManage(User{Active: true, Role: role}))
	}
	require.True(t, CanManage(User{Active: true, Role: "admin"}))
	require.False(t, CanManage(User{Role: "admin"}))
	require.False(t, AllowedRole("admin"))
	require.False(t, AllowedRole("superadmin"))
	require.True(t, AllowedRole("nurse"))
}
func TestSensitiveFieldsHidden(t *testing.T) {
	b, e := json.Marshal(User{PasswordHash: "sensitive-hash", Version: 42})
	require.NoError(t, e)
	require.NotContains(t, string(b), "sensitive-hash")
	require.NotContains(t, string(b), "PasswordHash")
	require.NotContains(t, string(b), "token_version")
}
