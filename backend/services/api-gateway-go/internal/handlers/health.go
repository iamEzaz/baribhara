package handlers

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
)

// Health handles health check requests
func Health(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"status":    "ok",
		"timestamp": time.Now().UTC().Format(time.RFC3339),
		"service":   "api-gateway-go",
		"version":   "1.0.0",
	})
}
