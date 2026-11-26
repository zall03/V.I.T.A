package transcription

import (
	"backend/internal/platform"
	"backend/internal/users"
	"github.com/gin-gonic/gin"
)

type Handler struct{ Service *Service }

func (h Handler) Routes(r *gin.RouterGroup) {
	r.POST("/encounters/:id/transcriptions", h.Create)
	r.GET("/encounters/:id/transcriptions", h.List)
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
	platform.Respond(c, 201, v, e)
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
