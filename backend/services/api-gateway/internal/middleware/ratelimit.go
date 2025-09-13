package middleware

import (
	"context"
	"fmt"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/redis/go-redis/v9"
)

// RateLimit implements rate limiting using Redis
func RateLimit(rdb *redis.Client) gin.HandlerFunc {
	return func(c *gin.Context) {
		clientIP := c.ClientIP()
		key := fmt.Sprintf("rate_limit:%s", clientIP)
		
		// Get current count
		count, err := rdb.Get(context.Background(), key).Int()
		if err != nil && err != redis.Nil {
			c.Next()
			return
		}

		// Check if limit exceeded (100 requests per minute)
		if count >= 100 {
			c.JSON(http.StatusTooManyRequests, gin.H{
				"error": "Rate limit exceeded",
				"retry_after": 60,
			})
			c.Abort()
			return
		}

		// Increment counter
		pipe := rdb.Pipeline()
		pipe.Incr(context.Background(), key)
		pipe.Expire(context.Background(), key, time.Minute)
		_, err = pipe.Exec(context.Background())
		if err != nil {
			c.Next()
			return
		}

		c.Next()
	}
}
