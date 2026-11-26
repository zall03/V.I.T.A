package patient

import (
	"backend/internal/platform"
	"backend/internal/users"
	"github.com/gin-gonic/gin"
)

type Handler struct{ Service *Service }

func (h Handler) Routes(r *gin.RouterGroup) {
	r.POST("/patients", h.Create)
	r.GET("/patients", h.List)
	r.GET("/patients/:id", h.Get)
	r.PATCH("/patients/:id", h.Update)
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
func (h Handler) List(c *gin.Context) {
	l, o, ok := platform.Page(c)
	if !ok {
		return
	}
	v, e := h.Service.List(c.Request.Context(), users.Current(c), c.Query("search"), l, o)
	platform.Respond(c, 200, v, e)
}
func (h Handler) Update(c *gin.Context) {
	id, ok := platform.PathID(c, "id")
	if !ok {
		return
	}
	var d UpdateDTO
	if !platform.Bind(c, &d) {
		return
	}
	v, e := h.Service.Update(c.Request.Context(), users.Current(c), id, d)
	platform.Respond(c, 200, v, e)
}
