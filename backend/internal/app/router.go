package app

import (
	"backend/internal/assessment"
	"backend/internal/auth"
	"backend/internal/encounter"
	"backend/internal/extraction"
	"backend/internal/facility"
	"backend/internal/patient"
	"backend/internal/platform"
	"backend/internal/transcription"
	"backend/internal/users"
	"context"
	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgxpool"
	"log/slog"
	"time"
)

func Router(pool *pgxpool.Pool, cfg platform.Config, log *slog.Logger) (*gin.Engine, error) {
	gin.SetMode(gin.ReleaseMode)
	r := gin.New()
	if e := r.SetTrustedProxies(nil); e != nil {
		return nil, e
	}
	r.HandleMethodNotAllowed = true
	r.Use(platform.Middleware(log, cfg.Origins))
	r.NoRoute(func(c *gin.Context) { platform.Fail(c, platform.NotFound) })
	r.NoMethod(func(c *gin.Context) { platform.Fail(c, &platform.APIError{Status: 405, Code: "method_not_allowed"}) })
	repo := users.NewRepository(pool)
	dummy, e := platform.HashPassword("synthetic-dummy-password")
	if e != nil {
		return nil, e
	}
	ah := auth.Handler{Service: &auth.Service{Repo: &auth.Repository{Repository: repo}, Tokens: platform.Tokens{Key: cfg.JWTKey, TTL: cfg.AccessTokenTTL}, RefreshTTL: cfg.RefreshTokenTTL, DummyHash: dummy}}
	uh := users.Handler{Service: &users.Service{Repo: repo}}
	r.GET("/health/live", func(c *gin.Context) { platform.OK(c, 200, gin.H{"status": "alive"}) })
	r.GET("/health/ready", func(c *gin.Context) {
		ctx, cancel := context.WithTimeout(c.Request.Context(), 2*time.Second)
		defer cancel()
		if e := pool.Ping(ctx); e != nil {
			platform.Fail(c, &platform.APIError{Status: 503, Code: "not_ready"})
			return
		}
		platform.OK(c, 200, gin.H{"status": "ready"})
	})
	r.GET("/openapi.yaml", func(c *gin.Context) { c.File("docs/openapi.yaml") })
	api := r.Group("/api/v1")
	limited := api.Group("/auth", platform.RateLimit())
	limited.POST("/login", ah.Login)
	limited.POST("/refresh", ah.Refresh)
	secured := api.Group("", ah.Middleware())
	fh := facility.Handler{Service: &facility.Service{Repo: repo}}
	secured.GET("/facilities/me", fh.Get)
	secured.PATCH("/facilities/me", auth.Admin(), fh.Update)
	secured.PATCH("/auth/password", platform.RateLimit(), ah.Password)
	secured.GET("/auth/me", ah.Me)
	secured.POST("/auth/logout", ah.Logout)
	secured.POST("/auth/change-password", platform.RateLimit(), ah.Password)
	admin := secured.Group("/users", auth.Admin())
	admin.POST("", uh.Create)
	admin.GET("", uh.List)
	admin.GET("/:id", uh.Detail)
	admin.PUT("/:id", uh.Update)
	admin.PATCH("/:id", uh.Update)
	admin.PATCH("/:id/status", uh.Active)
	admin.PATCH("/:id/active", uh.Active)
	clinical := secured.Group("", patient.Nurse)
	er := encounter.NewRepository(pool)
	(patient.Handler{Service: &patient.Service{Repo: patient.NewRepository(pool)}}).Routes(clinical)
	(encounter.Handler{Service: &encounter.Service{Repo: er}}).Routes(clinical)
	(transcription.Handler{Service: &transcription.Service{Repo: er}}).Routes(clinical)
	(assessment.Handler{Service: &assessment.Service{Repo: er}}).Routes(clinical)
	(extraction.Handler{Service: &extraction.Service{Repo: er}}).Routes(clinical)
	return r, nil
}
