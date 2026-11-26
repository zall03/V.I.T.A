package core

import (
	"net/http"
)

type HandlerFunc func(w http.ResponseWriter, r *http.Request)

type Engine struct {
	router map[string]map[string]HandlerFunc
}

func New() *Engine {
	return &Engine{
		router: make(map[string]map[string]HandlerFunc),
	}
}

func (engine *Engine) addRoute(method string, pattern string, handler HandlerFunc) {
	if engine.router[method] == nil {
		engine.router[method] = make(map[string]HandlerFunc)
	}
	engine.router[method][pattern] = handler
}

func (engine *Engine) GET(pattern string, handler HandlerFunc) {
	engine.addRoute("GET", pattern, handler)
}

func (engine *Engine) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if handlers, ok := engine.router[r.Method]; ok {
		if handler, ok := handlers[r.URL.Path]; ok {
			handler(w, r)
			return
		}
	}
	http.NotFound(w, r)
}

func (engine *Engine) Run(addr string) error {
	return http.ListenAndServe(addr, engine)
}
