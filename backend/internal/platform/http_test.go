package platform

import (
	"bytes"
	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/require"
	"log/slog"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestHTTPGuards(t *testing.T) {
	gin.SetMode(gin.TestMode)
	var logs bytes.Buffer
	r := gin.New()
	r.Use(Middleware(slog.New(slog.NewJSONHandler(&logs, nil)), []string{"https://allowed.test"}))
	r.POST("/body", func(c *gin.Context) {
		var d struct {
			Value string `json:"value" validate:"required"`
		}
		if Bind(c, &d) {
			OK(c, 200, gin.H{"ok": true})
		}
	})
	r.GET("/panic", func(c *gin.Context) { panic("secret-panic-payload") })
	r.GET("/limited", RateLimit(), func(c *gin.Context) { OK(c, 200, nil) })
	for _, tc := range []struct {
		body   string
		status int
	}{{`{"value":"ok"}`, 200}, {`{"value":"ok","unknown":true}`, 400}, {`{"value":"ok"} {}`, 400}, {`{"value":"` + strings.Repeat("x", 17000) + `"}`, 413}} {
		w := httptest.NewRecorder()
		req := httptest.NewRequest("POST", "/body", strings.NewReader(tc.body))
		r.ServeHTTP(w, req)
		require.Equal(t, tc.status, w.Code)
	}
	w := httptest.NewRecorder()
	r.ServeHTTP(w, httptest.NewRequest("GET", "/panic?password=secret-query", nil))
	require.Equal(t, 500, w.Code)
	require.NotContains(t, logs.String(), "secret-panic-payload")
	require.NotContains(t, logs.String(), "secret-query")
	req := httptest.NewRequest("POST", "/body", strings.NewReader(`{"value":"ok"}`))
	req.Header.Set("Origin", "https://denied.test")
	w = httptest.NewRecorder()
	r.ServeHTTP(w, req)
	require.Equal(t, 403, w.Code)
	for i := 0; i < 11; i++ {
		w = httptest.NewRecorder()
		r.ServeHTTP(w, httptest.NewRequest("GET", "/limited", nil))
		if i < 10 {
			require.Equal(t, 200, w.Code)
		} else {
			require.Equal(t, 429, w.Code)
		}
	}
}
