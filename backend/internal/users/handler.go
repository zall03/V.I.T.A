package users

import (
	"backend/internal/platform"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"strconv"
)

type Handler struct{ Service *Service }

func Current(c *gin.Context) User { return c.MustGet("user").(User) }
func (h Handler) List(c *gin.Context) {
	limit, e := strconv.Atoi(c.DefaultQuery("limit", "20"))
	offset, e2 := strconv.Atoi(c.DefaultQuery("offset", "0"))
	if e != nil || e2 != nil || limit < 1 || limit > 100 || offset < 0 || offset > 1000000 {
		platform.Fail(c, platform.Invalid)
		return
	}
	v, err := h.Service.List(c.Request.Context(), Current(c), int32(limit), int32(offset))
	respond(c, 200, v, err)
}
func (h Handler) Create(c *gin.Context) {
	var d CreateDTO
	if !platform.Bind(c, &d) {
		return
	}
	v, e := h.Service.Create(c.Request.Context(), Current(c), d)
	respond(c, 201, v, e)
}
func (h Handler) Detail(c *gin.Context) {
	id, e := uuid.Parse(c.Param("id"))
	if e != nil {
		platform.Fail(c, platform.Invalid)
		return
	}
	v, e := h.Service.Detail(c.Request.Context(), Current(c), id)
	respond(c, 200, v, e)
}
func (h Handler) Update(c *gin.Context) {
	id, e := uuid.Parse(c.Param("id"))
	if e != nil {
		platform.Fail(c, platform.Invalid)
		return
	}
	var d UpdateDTO
	if !platform.Bind(c, &d) {
		return
	}
	v, e := h.Service.Modify(c.Request.Context(), Current(c), id, &d, nil)
	respond(c, 200, v, e)
}
func (h Handler) Active(c *gin.Context) {
	id, e := uuid.Parse(c.Param("id"))
	if e != nil {
		platform.Fail(c, platform.Invalid)
		return
	}
	var d ActiveDTO
	if !platform.Bind(c, &d) {
		return
	}
	v, e := h.Service.Modify(c.Request.Context(), Current(c), id, nil, d.Active)
	respond(c, 200, v, e)
}
func respond(c *gin.Context, status int, v any, e error) {
	if e != nil {
		platform.Fail(c, e)
		return
	}
	platform.OK(c, status, v)
}
