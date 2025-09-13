package middleware

import (
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"github.com/stretchr/testify/assert"
)

func TestJWTAuth(t *testing.T) {
	gin.SetMode(gin.TestMode)

	tests := []struct {
		name           string
		authHeader     string
		expectedStatus int
		expectedBody   string
	}{
		{
			name:           "No Authorization header",
			authHeader:     "",
			expectedStatus: http.StatusUnauthorized,
			expectedBody:   "Authorization header required",
		},
		{
			name:           "Invalid Bearer token format",
			authHeader:     "InvalidToken",
			expectedStatus: http.StatusUnauthorized,
			expectedBody:   "Bearer token required",
		},
		{
			name:           "Invalid JWT token",
			authHeader:     "Bearer invalid-token",
			expectedStatus: http.StatusUnauthorized,
			expectedBody:   "Invalid token",
		},
		{
			name:           "Valid JWT token",
			authHeader:     "Bearer " + createValidToken(t),
			expectedStatus: http.StatusOK,
			expectedBody:   "success",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			router := gin.New()
			router.Use(JWTAuth("test-secret"))
			router.GET("/test", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{"message": "success"})
			})

			req, _ := http.NewRequest("GET", "/test", nil)
			if tt.authHeader != "" {
				req.Header.Set("Authorization", tt.authHeader)
			}
			w := httptest.NewRecorder()
			router.ServeHTTP(w, req)

			assert.Equal(t, tt.expectedStatus, w.Code)
			if tt.expectedBody != "" {
				assert.Contains(t, w.Body.String(), tt.expectedBody)
			}
		})
	}
}

func TestAdminOnly(t *testing.T) {
	gin.SetMode(gin.TestMode)

	tests := []struct {
		name           string
		userRole       string
		expectedStatus int
		expectedBody   string
	}{
		{
			name:           "Admin user",
			userRole:       "admin",
			expectedStatus: http.StatusOK,
			expectedBody:   "success",
		},
		{
			name:           "Regular user",
			userRole:       "user",
			expectedStatus: http.StatusForbidden,
			expectedBody:   "Admin access required",
		},
		{
			name:           "No role",
			userRole:       "",
			expectedStatus: http.StatusForbidden,
			expectedBody:   "Admin access required",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			router := gin.New()
			router.Use(func(c *gin.Context) {
				c.Set("user_role", tt.userRole)
				c.Next()
			})
			router.Use(AdminOnly())
			router.GET("/test", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{"message": "success"})
			})

			req, _ := http.NewRequest("GET", "/test", nil)
			w := httptest.NewRecorder()
			router.ServeHTTP(w, req)

			assert.Equal(t, tt.expectedStatus, w.Code)
			if tt.expectedBody != "" {
				assert.Contains(t, w.Body.String(), tt.expectedBody)
			}
		})
	}
}

func createValidToken(t *testing.T) string {
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"sub":   "test-user-id",
		"email": "test@example.com",
		"role":  "user",
		"exp":   time.Now().Add(time.Hour).Unix(),
	})

	tokenString, err := token.SignedString([]byte("test-secret"))
	if err != nil {
		t.Fatalf("Failed to create token: %v", err)
	}

	return tokenString
}
