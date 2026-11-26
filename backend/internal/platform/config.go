package platform

import (
	"errors"
	"os"
	"strings"
	"time"
)

type Config struct {
	DatabaseURL, Address, Environment string
	JWTKey                            []byte
	Origins                           []string
	AccessTokenTTL, RefreshTokenTTL   time.Duration
}

func Load() (Config, error) {
	c := Config{DatabaseURL: os.Getenv("DATABASE_URL"), Address: os.Getenv("HTTP_ADDR"), Environment: os.Getenv("APP_ENV"), JWTKey: []byte(os.Getenv("JWT_SECRET"))}
	if c.Address == "" {
		c.Address = ":8080"
	}
	if c.Environment == "" {
		c.Environment = "development"
	}
	if c.DatabaseURL == "" || len(c.JWTKey) < 32 {
		return c, errors.New("DATABASE_URL and JWT_SECRET (at least 32 bytes) are required")
	}
	var err error
	c.AccessTokenTTL, err = tokenDuration("ACCESS_TOKEN_TTL", 15*time.Minute)
	if err != nil {
		return c, err
	}
	c.RefreshTokenTTL, err = tokenDuration("REFRESH_TOKEN_TTL", 7*24*time.Hour)
	if err != nil {
		return c, err
	}
	for _, v := range strings.Split(os.Getenv("CORS_ORIGINS"), ",") {
		v = strings.TrimSpace(v)
		if v == "*" {
			return c, errors.New("CORS_ORIGINS requires explicit origins")
		}
		if v != "" {
			c.Origins = append(c.Origins, v)
		}
	}
	return c, nil
}

func tokenDuration(name string, fallback time.Duration) (time.Duration, error) {
	raw := os.Getenv(name)
	if raw == "" {
		return fallback, nil
	}
	v, err := time.ParseDuration(raw)
	if err != nil || v < time.Second || v%time.Second != 0 {
		return 0, errors.New(name + " must be a positive whole-second Go duration")
	}
	return v, nil
}
