package encounter

import (
	"backend/internal/platform"
	"backend/internal/users"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type Handler struct{ Service *Service }

func (h Handler) Routes(r *gin.RouterGroup) {
	r.POST("/encounters", h.Create)
	r.GET("/encounters", h.List)
	r.GET("/encounters/:id", h.Get)
	r.GET("/encounters/:id/history", h.History)
	r.POST("/encounters/:id/start", h.Transition("in_progress"))
	r.POST("/encounters/:id/cancel", h.Transition("cancelled"))
	r.GET("/patients/:id/encounters", h.PatientHistory)
}
func (h Handler) Create(c *gin.Context) {
	var d CreateDTO
	if !platform.Bind(c, &d) {
		return
	}
	v, e := h.Service.Create(c.Request.Context(), users.Current(c), d)
	platform.Respond(c, 201, v, e)
}
func (h Handler) Get(c *gin.Context) {
	id, ok := platform.PathID(c, "id")
	if !ok {
		return
	}
	v, e := h.Service.Get(c.Request.Context(), users.Current(c), id)
	platform.Respond(c, 200, v, e)
}
func (h Handler) List(c *gin.Context) { h.list(c, uuid.Nil) }
func (h Handler) PatientHistory(c *gin.Context) {
	id, ok := platform.PathID(c, "id")
	if ok {
		h.list(c, id)
	}
}
func (h Handler) list(c *gin.Context, id uuid.UUID) {
	l, o, ok := platform.Page(c)
	if !ok {
		return
	}
	v, e := h.Service.List(c.Request.Context(), users.Current(c), id, l, o)
	platform.Respond(c, 200, v, e)
}
func (h Handler) History(c *gin.Context) {
	id, ok := platform.PathID(c, "id")
	if !ok {
		return
	}
	v, e := h.Service.History(c.Request.Context(), users.Current(c), id)
	platform.Respond(c, 200, v, e)
}
func (h Handler) Transition(to string) gin.HandlerFunc {
	return func(c *gin.Context) {
		id, ok := platform.PathID(c, "id")
		if !ok {
			return
		}
		var d TransitionDTO
		if !platform.Bind(c, &d) {
			return
		}
		v, e := h.Service.Transition(c.Request.Context(), users.Current(c), id, to, d)
		platform.Respond(c, 200, v, e)
	}
}
