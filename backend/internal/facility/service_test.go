package facility

import (
	"backend/internal/platform"
	"backend/internal/users"
	"context"
	"github.com/stretchr/testify/require"
	"testing"
)

func TestDenyBeforeDatabase(t *testing.T) {
	s := Service{}
	for _, u := range []users.User{{Role: "admin"}, {Active: true, Role: "unknown"}} {
		_, e := s.Get(context.Background(), u)
		require.ErrorIs(t, e, platform.Forbidden)
	}
	for _, role := range []string{"nurse", "queue_operator", "unknown"} {
		_, e := s.Update(context.Background(), users.User{Active: true, Role: role}, UpdateDTO{Name: "Synthetic Facility"})
		require.ErrorIs(t, e, platform.Forbidden)
	}
	_, e := s.Update(context.Background(), users.User{Active: true, Role: "admin"}, UpdateDTO{Name: "   "})
	require.ErrorIs(t, e, platform.Invalid)
}
