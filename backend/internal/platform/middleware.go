package platform

import (
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"log/slog"
	"net/http"
	"sync"
	"time"
)

func Middleware(log *slog.Logger, origins []string) gin.HandlerFunc {
	return func(c *gin.Context) {
		id := uuid.NewString()
		c.Set("request_id", id)
		c.Header("X-Request-ID", id)
		c.Header("Cache-Control", "no-store")
		c.Header("X-Content-Type-Options", "nosniff")
		start := time.Now()
		defer func() {
			if recover() != nil {
				Fail(c, &APIError{500, "internal_error"})
			}
			log.Info("http_request", "request_id", id, "method", c.Request.Method, "route", c.FullPath(), "status", c.Writer.Status(), "duration_ms", time.Since(start).Milliseconds())
		}()
		c.Request.Body = http.MaxBytesReader(c.Writer, c.Request.Body, 16*1024)
		origin := c.GetHeader("Origin")
		if origin != "" {
			allowed := false
			for _, v := range origins {
				if v == origin {
					allowed = true
				}
			}
			if !allowed {
				Fail(c, Forbidden)
				return
			}
			c.Header("Access-Control-Allow-Origin", origin)
			c.Header("Vary", "Origin")
			c.Header("Access-Control-Allow-Headers", "Authorization, Content-Type")
			c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, OPTIONS")
			if c.Request.Method == "OPTIONS" {
				c.AbortWithStatus(204)
				return
			}
		}
		c.Next()
	}
}

type bucket struct {
	count int
	until time.Time
}

// Limiter bounds memory and uses direct peer IP; forwarded headers are not trusted.
func RateLimit() gin.HandlerFunc {
	var mu sync.Mutex
	entries := map[string]bucket{}
	return func(c *gin.Context) {
		mu.Lock()
		now := time.Now()
		for k, b := range entries {
			if !b.until.After(now) {
				delete(entries, k)
			}
		}
		key := c.ClientIP()
		b, exists := entries[key]
		if !exists {
			b = bucket{until: now.Add(time.Minute)}
		}
		deny := b.count >= 10 || (!exists && len(entries) >= 10000)
		if !deny {
			b.count++
			entries[key] = b
		}
		mu.Unlock()
		if deny {
			c.Header("Retry-After", "60")
			Fail(c, &APIError{429, "rate_limited"})
			return
		}
		c.Next()
	}
}
