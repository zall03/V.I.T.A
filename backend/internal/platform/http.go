package platform

import (
	"encoding/json"
	"errors"
	"github.com/gin-gonic/gin"
	"github.com/go-playground/validator/v10"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"io"
	"net/http"
)

type APIError struct {
	Status int
	Code   string
}

func (e *APIError) Error() string { return e.Code }

var Unauthorized = &APIError{401, "unauthorized"}
var Forbidden = &APIError{403, "forbidden"}
var NotFound = &APIError{404, "not_found"}
var Invalid = &APIError{400, "invalid_request"}
var validate = validator.New(validator.WithRequiredStructEnabled())

func Bind(c *gin.Context, v any) bool {
	d := json.NewDecoder(c.Request.Body)
	d.DisallowUnknownFields()
	err := d.Decode(v)
	if err == nil {
		if d.Decode(new(any)) != io.EOF {
			err = Invalid
		}
	}
	if err == nil {
		err = validate.Struct(v)
	}
	if err != nil {
		var size *http.MaxBytesError
		if errors.As(err, &size) {
			Fail(c, &APIError{413, "request_too_large"})
		} else {
			Fail(c, Invalid)
		}
		return false
	}
	return true
}
func Fail(c *gin.Context, err error) {
	status, code := 500, "internal_error"
	var ae *APIError
	var pe *pgconn.PgError
	if errors.As(err, &ae) {
		status, code = ae.Status, ae.Code
	} else if errors.Is(err, pgx.ErrNoRows) {
		status, code = 404, "not_found"
	} else if errors.As(err, &pe) && pe.Code == "23505" {
		status, code = 409, "conflict"
	}
	c.AbortWithStatusJSON(status, gin.H{"error": gin.H{"code": code, "message": code}, "request_id": c.GetString("request_id")})
}
func OK(c *gin.Context, status int, data any) {
	c.JSON(status, gin.H{"data": data, "request_id": c.GetString("request_id")})
}
