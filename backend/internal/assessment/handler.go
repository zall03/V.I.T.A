package assessment

import (
	"backend/internal/platform"
	"backend/internal/users"
	"github.com/gin-gonic/gin"
)

type Handler struct{ Service *Service }

func (h Handler) Routes(r *gin.RouterGroup) {
	r.POST("/encounters/:id/assessments", h.Save(true))
	r.PATCH("/encounters/:id/assessment", h.Save(false))
	r.GET("/encounters/:id/assessment", h.Current)
	r.GET("/encounters/:id/assessment/history", h.History)
	r.POST("/encounters/:id/assessment/verify", h.Verify)
}
func (h Handler) Save(create bool) gin.HandlerFunc {
	return func(c *gin.Context) {
		id, ok := platform.PathID(c, "id")
		if !ok {
			return
		}
		var d DTO
		if !platform.Bind(c, &d) {
			return
		}
		v, e := h.Service.Save(c.Request.Context(), users.Current(c), id, d, create)
		platform.Respond(c, 201, v, e)
	}
}
func (h Handler) Current(c *gin.Context) {
	id, ok := platform.PathID(c, "id")
	if !ok {
		return
	}
	v, e := h.Service.Current(c.Request.Context(), users.Current(c), id)
	platform.Respond(c, 200, v, e)
}
func (h Handler) History(c *gin.Context) {
	id, ok := platform.PathID(c, "id")
	if !ok {
		return
	}
	l, o, ok := platform.Page(c)
	if !ok {
		return
	}
	v, e := h.Service.History(c.Request.Context(), users.Current(c), id, l, o)
	platform.Respond(c, 200, v, e)
}
func (h Handler) Verify(c *gin.Context) {
	id, ok := platform.PathID(c, "id")
	if !ok {
		return
	}
	var d VerifyDTO
	if !platform.Bind(c, &d) {
		return
	}
	v, e := h.Service.Verify(c.Request.Context(), users.Current(c), id, d)
	platform.Respond(c, 200, v, e)
}
