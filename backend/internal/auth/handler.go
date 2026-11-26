package auth

import (
	"backend/internal/platform"
	"backend/internal/users"
	"github.com/gin-gonic/gin"
	"strings"
)

type Handler struct{ Service *Service }

func (h Handler) Login(c *gin.Context) {
	var d LoginDTO
	if !platform.Bind(c, &d) {
		return
	}
	v, e := h.Service.Login(c.Request.Context(), d)
	if e != nil {
		platform.Fail(c, e)
		return
	}
	platform.OK(c, 200, v)
}
func (h Handler) Refresh(c *gin.Context) {
	var d RefreshDTO
	if !platform.Bind(c, &d) {
		return
	}
	v, e := h.Service.Refresh(c.Request.Context(), d.RefreshToken)
	if e != nil {
		platform.Fail(c, e)
		return
	}
	platform.OK(c, 200, v)
}
func (h Handler) Logout(c *gin.Context) {
	var d RefreshDTO
	if !platform.Bind(c, &d) {
		return
	}
	if e := h.Service.Logout(c.Request.Context(), users.Current(c), d.RefreshToken); e != nil {
		platform.Fail(c, e)
		return
	}
	platform.OK(c, 200, gin.H{"logged_out": true})
}
func (h Handler) Password(c *gin.Context) {
	var d PasswordDTO
	if !platform.Bind(c, &d) {
		return
	}
	if e := h.Service.Password(c.Request.Context(), users.Current(c), d); e != nil {
		platform.Fail(c, e)
		return
	}
	platform.OK(c, 200, gin.H{"password_changed": true})
}
func (h Handler) Me(c *gin.Context) { platform.OK(c, 200, users.Current(c)) }
func (h Handler) Middleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		header := strings.Fields(c.GetHeader("Authorization"))
		if len(header) != 2 || !strings.EqualFold(header[0], "Bearer") {
			platform.Fail(c, platform.Unauthorized)
			return
		}
		u, e := h.Service.Authenticate(c.Request.Context(), header[1])
		if e != nil {
			platform.Fail(c, e)
			return
		}
		c.Set("user", u)
		c.Next()
	}
}
func Admin() gin.HandlerFunc {
	return func(c *gin.Context) {
		if !users.CanManage(users.Current(c)) {
			platform.Fail(c, platform.Forbidden)
			return
		}
		c.Next()
	}
}
