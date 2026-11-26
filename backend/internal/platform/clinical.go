package platform

import (
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"strconv"
)

var Conflict = &APIError{409, "version_or_state_conflict"}

func Page(c *gin.Context) (int32, int32, bool) {
	l, e := strconv.Atoi(c.DefaultQuery("limit", "20"))
	o, e2 := strconv.Atoi(c.DefaultQuery("offset", "0"))
	if e != nil || e2 != nil || l < 1 || l > 100 || o < 0 || o > 1000000 {
		Fail(c, Invalid)
		return 0, 0, false
	}
	return int32(l), int32(o), true
}
func PathID(c *gin.Context, key string) (uuid.UUID, bool) {
	id, e := uuid.Parse(c.Param(key))
	if e != nil || id == uuid.Nil {
		Fail(c, Invalid)
		return id, false
	}
	return id, true
}
func Respond(c *gin.Context, status int, data any, e error) {
	if e != nil {
		Fail(c, e)
		return
	}
	OK(c, status, data)
}
