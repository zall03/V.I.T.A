package facility

import (
	"backend/internal/platform"
	"backend/internal/users"
	"github.com/gin-gonic/gin"
)

type Handler struct{ Service *Service }

func (h Handler) Get(c *gin.Context) {
	v, e := h.Service.Get(c.Request.Context(), users.Current(c))
	platform.Respond(c, 200, v, e)
}
func (h Handler) Update(c *gin.Context) {
	var d UpdateDTO
	if !platform.Bind(c, &d) {
		return
	}
	v, e := h.Service.Update(c.Request.Context(), users.Current(c), d)
	platform.Respond(c, 200, v, e)
}
