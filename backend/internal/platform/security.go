package platform

import (
	"crypto/rand"
	"crypto/sha256"
	"crypto/subtle"
	"encoding/base64"
	"encoding/hex"
	"errors"
	"strings"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"golang.org/x/crypto/argon2"
)

func HashPassword(password string) (string, error) {
	salt := make([]byte, 16)
	if _, err := rand.Read(salt); err != nil {
		return "", err
	}
	hash := argon2.IDKey([]byte(password), salt, 3, 64*1024, 2, 32)
	return "$argon2id$v=19$m=65536,t=3,p=2$" + base64.RawStdEncoding.EncodeToString(salt) + "$" + base64.RawStdEncoding.EncodeToString(hash), nil
}
func VerifyPassword(encoded, password string) bool {
	p := strings.Split(encoded, "$")
	if len(p) != 6 || p[1] != "argon2id" || p[2] != "v=19" || p[3] != "m=65536,t=3,p=2" {
		return false
	}
	salt, e := base64.RawStdEncoding.DecodeString(p[4])
	if e != nil || len(salt) != 16 {
		return false
	}
	want, e := base64.RawStdEncoding.DecodeString(p[5])
	if e != nil || len(want) != 32 {
		return false
	}
	got := argon2.IDKey([]byte(password), salt, 3, 64*1024, 2, 32)
	return subtle.ConstantTimeCompare(got, want) == 1
}
func Opaque() (string, error) {
	b := make([]byte, 32)
	_, e := rand.Read(b)
	return base64.RawURLEncoding.EncodeToString(b), e
}
func Digest(s string) string { b := sha256.Sum256([]byte(s)); return hex.EncodeToString(b[:]) }

type Claims struct {
	Version int64 `json:"ver"`
	jwt.RegisteredClaims
}
type Tokens struct {
	Key []byte
	TTL time.Duration
}

func (t Tokens) Lifetime() time.Duration {
	if t.TTL == 0 {
		return 15 * time.Minute
	}
	return t.TTL
}

func (t Tokens) Access(id uuid.UUID, version int64) (string, error) {
	now := time.Now()
	return jwt.NewWithClaims(jwt.SigningMethodHS256, Claims{version, jwt.RegisteredClaims{Issuer: "vita", Audience: jwt.ClaimStrings{"vita-api"}, Subject: id.String(), ID: uuid.NewString(), IssuedAt: jwt.NewNumericDate(now), ExpiresAt: jwt.NewNumericDate(now.Add(t.Lifetime()))}}).SignedString(t.Key)
}
func (t Tokens) Parse(raw string) (*Claims, error) {
	c := new(Claims)
	tok, e := jwt.ParseWithClaims(raw, c, func(*jwt.Token) (any, error) { return t.Key, nil }, jwt.WithValidMethods([]string{"HS256"}), jwt.WithIssuer("vita"), jwt.WithAudience("vita-api"), jwt.WithExpirationRequired(), jwt.WithIssuedAt())
	if e != nil || !tok.Valid {
		return nil, errors.New("invalid token")
	}
	if _, e = uuid.Parse(c.Subject); e != nil {
		return nil, e
	}
	return c, nil
}
