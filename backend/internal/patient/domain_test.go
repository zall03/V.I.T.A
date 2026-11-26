package patient

import (
	"github.com/stretchr/testify/require"
	"testing"
	"time"
)

func TestUnknownAndDateValidation(t *testing.T) {
	_, e := (Demographics{IdentityStatus: "temporary", Sex: "unknown"}).Validate()
	require.NoError(t, e)
	_, e = (Demographics{IdentityStatus: "identified"}).Validate()
	require.Error(t, e)
	future := "2999-01-01"
	_, e = (Demographics{IdentityStatus: "temporary", BirthDate: &future}).Validate()
	require.Error(t, e)
	require.Equal(t, 19, Age(time.Date(2000, 12, 1, 0, 0, 0, 0, time.UTC), time.Date(2020, 11, 1, 0, 0, 0, 0, time.UTC)))
}
