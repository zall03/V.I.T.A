package extraction

import (
	"backend/internal/platform"
	"backend/internal/users"
	"github.com/gin-gonic/gin"
)

type Handler struct{ Service *Service }

func (h Handler) Routes(r *gin.RouterGroup) {
	r.POST("/encounters/:id/extractions", platform.RateLimit(), h.Create)
	r.GET("/encounters/:id/extractions", h.List)
	r.GET("/encounters/:id/extractions/:extraction_id", h.Get)
}
func (h Handler) Create(c *gin.Context) {
	id, ok := platform.PathID(c, "id")
	if !ok {
		return
	}
	var d DTO
	if !platform.Bind(c, &d) {
		return
	}
	v, e := h.Service.Create(c.Request.Context(), users.Current(c), id, d)
	platform.Respond(c, 202, v, e)
}
func (h Handler) Get(c *gin.Context) {
	id, ok := platform.PathID(c, "id")
	if !ok {
		return
	}
	x, ok := platform.PathID(c, "extraction_id")
	if !ok {
		return
	}
	v, e := h.Service.Get(c.Request.Context(), users.Current(c), id, x)
	platform.Respond(c, 200, v, e)
}
func (h Handler) List(c *gin.Context) {
	id, ok := platform.PathID(c, "id")
	if !ok {
		return
	}
	l, o, ok := platform.Page(c)
	if !ok {
		return
	}
	v, e := h.Service.List(c.Request.Context(), users.Current(c), id, l, o)
	platform.Respond(c, 200, v, e)
}
