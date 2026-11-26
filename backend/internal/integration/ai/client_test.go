package ai

import (
	"context"
	"encoding/json"
	"github.com/google/uuid"
	"github.com/stretchr/testify/require"
	"net/http"
	"net/http/httptest"
	"testing"
)

func empty() Clinical {
	return Clinical{Symptoms: []Finding{}, MedicalHistory: []Finding{}, Medications: []Finding{}, Allergies: Allergy{Status: "unknown", Items: []Finding{}}}
}
func TestGateway(t *testing.T) {
	id := uuid.New()
	result := Result{RequestID: id, Status: "success", SchemaVersion: "1.0", PromptVersion: "clinical_extraction_v1", Provider: "mock", Model: "fixture", RequiresVerification: true, Data: empty()}
	status := 200
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		require.Equal(t, "Bearer synthetic-service-token-at-least-32", r.Header.Get("Authorization"))
		w.WriteHeader(status)
		_ = json.NewEncoder(w).Encode(result)
	}))
	defer srv.Close()
	c, e := NewClient(srv.URL, "synthetic-service-token-at-least-32")
	require.NoError(t, e)
	req := Request{RequestID: id, SchemaVersion: "1.0", Transcript: "synthetic"}
	_, e = c.Extract(context.Background(), req)
	require.NoError(t, e)
	result.SchemaVersion = "9"
	_, e = c.Extract(context.Background(), req)
	require.Error(t, e)
	status = 503
	_, e = c.Extract(context.Background(), req)
	var f *Failure
	require.ErrorAs(t, e, &f)
	require.True(t, f.Retryable)
}
func TestMissingAndZero(t *testing.T) {
	c := empty()
	require.NoError(t, c.Validate())
	zero := 0.0
	c.Vitals.SPO2 = &Measurement{Value: &zero, Unit: "%", Availability: "measured", Source: "observation"}
	require.NoError(t, c.Validate())
	c.Vitals.SPO2.Availability = "missing"
	require.Error(t, c.Validate())
}
func TestMinimization(t *testing.T) {
	out := Minimize("Nama: Synthetic Person. NIK: 1234567890123456. MR-123 sesak", "MR-123")
	require.NotContains(t, out, "Synthetic Person")
	require.NotContains(t, out, "1234567890123456")
	require.NotContains(t, out, "MR-123")
	require.Contains(t, out, "sesak")
}
