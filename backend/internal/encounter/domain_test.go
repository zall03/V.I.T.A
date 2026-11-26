package encounter

import (
	"github.com/stretchr/testify/require"
	"testing"
)

func TestTransitions(t *testing.T) {
	require.True(t, CanTransition("draft", "in_progress"))
	require.True(t, CanTransition("in_progress", "ready_for_triage"))
	require.False(t, CanTransition("draft", "ready_for_triage"))
	require.False(t, CanTransition("cancelled", "in_progress"))
	require.False(t, CanTransition("ready_for_triage", "completed"))
}
