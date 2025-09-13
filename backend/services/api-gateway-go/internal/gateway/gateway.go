package gateway

import (
	"fmt"
	"baribhara/api-gateway/internal/config"
	"baribhara/api-gateway/internal/handlers"
	"baribhara/api-gateway/internal/middleware"
	"baribhara/api-gateway/pkg/client"
	"baribhara/api-gateway/pkg/logger"

	"github.com/gin-gonic/gin"
	"github.com/redis/go-redis/v9"
	"go.uber.org/zap"
)

// Gateway represents the API Gateway
type Gateway struct {
	config  *config.Config
	logger  *zap.Logger
	redis   *redis.Client
	clients *client.Manager
}

// NewGateway creates a new Gateway instance
func NewGateway(cfg *config.Config, logger *zap.Logger) (*Gateway, error) {
	// Initialize Redis client
	rdb := redis.NewClient(&redis.Options{
		Addr:     fmt.Sprintf("%s:%d", cfg.Redis.Host, cfg.Redis.Port),
		Password: cfg.Redis.Password,
		DB:       cfg.Redis.DB,
	})

	// Initialize service clients
	clients, err := client.NewManager(cfg, logger)
	if err != nil {
		return nil, err
	}

	return &Gateway{
		config:  cfg,
		logger:  logger,
		redis:   rdb,
		clients: clients,
	}, nil
}

// SetupRoutes configures all routes
func (g *Gateway) SetupRoutes() *gin.Engine {
	router := gin.New()

	// Global middleware
	router.Use(gin.Recovery())
	router.Use(middleware.Logger(g.logger))
	router.Use(middleware.CORS())
	router.Use(middleware.RateLimit(g.redis))
	router.Use(middleware.Metrics())

	// Health check
	router.GET("/health", handlers.Health)

	// API v1 routes
	v1 := router.Group("/api/v1")
	{
		// Public routes (no authentication required)
		public := v1.Group("/")
		{
			public.POST("/auth/register", g.handleAuthRegister)
			public.POST("/auth/login", g.handleAuthLogin)
			public.POST("/auth/refresh", g.handleAuthRefresh)
		}

		// Protected routes (authentication required)
		protected := v1.Group("/")
		protected.Use(middleware.JWTAuth(g.config.JWT.Secret))
		{
			// Auth routes
			auth := protected.Group("/auth")
			{
				auth.GET("/profile", g.handleAuthProfile)
				auth.PUT("/profile", g.handleAuthUpdateProfile)
				auth.POST("/logout", g.handleAuthLogout)
			}

			// User routes
			users := protected.Group("/users")
			{
				users.GET("", g.handleGetUsers)
				users.GET("/:id", g.handleGetUser)
				users.PUT("/:id", g.handleUpdateUser)
				users.DELETE("/:id", g.handleDeleteUser)
			}

			// Property routes
			properties := protected.Group("/properties")
			{
				properties.GET("", g.handleGetProperties)
				properties.GET("/search", g.handleSearchProperties)
				properties.GET("/:id", g.handleGetProperty)
				properties.POST("", g.handleCreateProperty)
				properties.PUT("/:id", g.handleUpdateProperty)
				properties.DELETE("/:id", g.handleDeleteProperty)
			}

			// Tenant routes
			tenants := protected.Group("/tenants")
			{
				tenants.GET("", g.handleGetTenants)
				tenants.GET("/search", g.handleSearchTenants)
				tenants.GET("/:id", g.handleGetTenant)
				tenants.POST("", g.handleCreateTenant)
				tenants.PUT("/:id", g.handleUpdateTenant)
				tenants.DELETE("/:id", g.handleDeleteTenant)
			}

			// Caretaker routes
			caretakers := protected.Group("/caretakers")
			{
				caretakers.GET("", g.handleGetCaretakers)
				caretakers.GET("/search", g.handleSearchCaretakers)
				caretakers.GET("/:id", g.handleGetCaretaker)
				caretakers.POST("", g.handleCreateCaretaker)
				caretakers.PUT("/:id", g.handleUpdateCaretaker)
				caretakers.DELETE("/:id", g.handleDeleteCaretaker)
			}

			// Invoice routes
			invoices := protected.Group("/invoices")
			{
				invoices.GET("", g.handleGetInvoices)
				invoices.GET("/:id", g.handleGetInvoice)
				invoices.POST("", g.handleCreateInvoice)
				invoices.PUT("/:id", g.handleUpdateInvoice)
				invoices.POST("/:id/pay", g.handlePayInvoice)
			}

			// Notification routes
			notifications := protected.Group("/notifications")
			{
				notifications.GET("", g.handleGetNotifications)
				notifications.POST("", g.handleSendNotification)
				notifications.PUT("/:id/read", g.handleMarkNotificationRead)
			}

			// Report routes
			reports := protected.Group("/reports")
			{
				reports.GET("/properties", g.handleGetPropertyReport)
				reports.GET("/tenants", g.handleGetTenantReport)
				reports.GET("/invoices", g.handleGetInvoiceReport)
				reports.POST("/generate", g.handleGenerateReport)
			}

			// Admin routes
			admin := protected.Group("/admin")
			admin.Use(middleware.AdminOnly())
			{
				admin.GET("/stats", g.handleAdminStats)
				admin.GET("/users", g.handleAdminUsers)
				admin.PUT("/users/:id/status", g.handleAdminUpdateUserStatus)
			}
		}
	}

	return router
}

// Service proxy handlers
func (g *Gateway) handleAuthRegister(c *gin.Context) {
	g.proxyToService(c, "auth-service", "/api/v1/auth/register")
}

func (g *Gateway) handleAuthLogin(c *gin.Context) {
	g.proxyToService(c, "auth-service", "/api/v1/auth/login")
}

func (g *Gateway) handleAuthRefresh(c *gin.Context) {
	g.proxyToService(c, "auth-service", "/api/v1/auth/refresh")
}

func (g *Gateway) handleAuthProfile(c *gin.Context) {
	g.proxyToService(c, "auth-service", "/api/v1/auth/profile")
}

func (g *Gateway) handleAuthUpdateProfile(c *gin.Context) {
	g.proxyToService(c, "auth-service", "/api/v1/auth/profile")
}

func (g *Gateway) handleAuthLogout(c *gin.Context) {
	g.proxyToService(c, "auth-service", "/api/v1/auth/logout")
}

func (g *Gateway) handleGetUsers(c *gin.Context) {
	g.proxyToService(c, "user-service", "/api/v1/users")
}

func (g *Gateway) handleGetUser(c *gin.Context) {
	g.proxyToService(c, "user-service", "/api/v1/users/"+c.Param("id"))
}

func (g *Gateway) handleUpdateUser(c *gin.Context) {
	g.proxyToService(c, "user-service", "/api/v1/users/"+c.Param("id"))
}

func (g *Gateway) handleDeleteUser(c *gin.Context) {
	g.proxyToService(c, "user-service", "/api/v1/users/"+c.Param("id"))
}

func (g *Gateway) handleGetProperties(c *gin.Context) {
	g.proxyToService(c, "property-service", "/api/v1/properties")
}

func (g *Gateway) handleSearchProperties(c *gin.Context) {
	g.proxyToService(c, "property-service", "/api/v1/properties/search")
}

func (g *Gateway) handleGetProperty(c *gin.Context) {
	g.proxyToService(c, "property-service", "/api/v1/properties/"+c.Param("id"))
}

func (g *Gateway) handleCreateProperty(c *gin.Context) {
	g.proxyToService(c, "property-service", "/api/v1/properties")
}

func (g *Gateway) handleUpdateProperty(c *gin.Context) {
	g.proxyToService(c, "property-service", "/api/v1/properties/"+c.Param("id"))
}

func (g *Gateway) handleDeleteProperty(c *gin.Context) {
	g.proxyToService(c, "property-service", "/api/v1/properties/"+c.Param("id"))
}

func (g *Gateway) handleGetTenants(c *gin.Context) {
	g.proxyToService(c, "tenant-service", "/api/v1/tenants")
}

func (g *Gateway) handleSearchTenants(c *gin.Context) {
	g.proxyToService(c, "tenant-service", "/api/v1/tenants/search")
}

func (g *Gateway) handleGetTenant(c *gin.Context) {
	g.proxyToService(c, "tenant-service", "/api/v1/tenants/"+c.Param("id"))
}

func (g *Gateway) handleCreateTenant(c *gin.Context) {
	g.proxyToService(c, "tenant-service", "/api/v1/tenants")
}

func (g *Gateway) handleUpdateTenant(c *gin.Context) {
	g.proxyToService(c, "tenant-service", "/api/v1/tenants/"+c.Param("id"))
}

func (g *Gateway) handleDeleteTenant(c *gin.Context) {
	g.proxyToService(c, "tenant-service", "/api/v1/tenants/"+c.Param("id"))
}

func (g *Gateway) handleGetCaretakers(c *gin.Context) {
	g.proxyToService(c, "caretaker-service", "/api/v1/caretakers")
}

func (g *Gateway) handleSearchCaretakers(c *gin.Context) {
	g.proxyToService(c, "caretaker-service", "/api/v1/caretakers/search")
}

func (g *Gateway) handleGetCaretaker(c *gin.Context) {
	g.proxyToService(c, "caretaker-service", "/api/v1/caretakers/"+c.Param("id"))
}

func (g *Gateway) handleCreateCaretaker(c *gin.Context) {
	g.proxyToService(c, "caretaker-service", "/api/v1/caretakers")
}

func (g *Gateway) handleUpdateCaretaker(c *gin.Context) {
	g.proxyToService(c, "caretaker-service", "/api/v1/caretakers/"+c.Param("id"))
}

func (g *Gateway) handleDeleteCaretaker(c *gin.Context) {
	g.proxyToService(c, "caretaker-service", "/api/v1/caretakers/"+c.Param("id"))
}

func (g *Gateway) handleGetInvoices(c *gin.Context) {
	g.proxyToService(c, "invoice-service", "/api/v1/invoices")
}

func (g *Gateway) handleGetInvoice(c *gin.Context) {
	g.proxyToService(c, "invoice-service", "/api/v1/invoices/"+c.Param("id"))
}

func (g *Gateway) handleCreateInvoice(c *gin.Context) {
	g.proxyToService(c, "invoice-service", "/api/v1/invoices")
}

func (g *Gateway) handleUpdateInvoice(c *gin.Context) {
	g.proxyToService(c, "invoice-service", "/api/v1/invoices/"+c.Param("id"))
}

func (g *Gateway) handlePayInvoice(c *gin.Context) {
	g.proxyToService(c, "invoice-service", "/api/v1/invoices/"+c.Param("id")+"/pay")
}

func (g *Gateway) handleGetNotifications(c *gin.Context) {
	g.proxyToService(c, "notification-service", "/api/v1/notifications")
}

func (g *Gateway) handleSendNotification(c *gin.Context) {
	g.proxyToService(c, "notification-service", "/api/v1/notifications")
}

func (g *Gateway) handleMarkNotificationRead(c *gin.Context) {
	g.proxyToService(c, "notification-service", "/api/v1/notifications/"+c.Param("id")+"/read")
}

func (g *Gateway) handleGetPropertyReport(c *gin.Context) {
	g.proxyToService(c, "report-service", "/api/v1/reports/properties")
}

func (g *Gateway) handleGetTenantReport(c *gin.Context) {
	g.proxyToService(c, "report-service", "/api/v1/reports/tenants")
}

func (g *Gateway) handleGetInvoiceReport(c *gin.Context) {
	g.proxyToService(c, "report-service", "/api/v1/reports/invoices")
}

func (g *Gateway) handleGenerateReport(c *gin.Context) {
	g.proxyToService(c, "report-service", "/api/v1/reports/generate")
}

func (g *Gateway) handleAdminStats(c *gin.Context) {
	g.proxyToService(c, "admin-service", "/api/v1/admin/stats")
}

func (g *Gateway) handleAdminUsers(c *gin.Context) {
	g.proxyToService(c, "admin-service", "/api/v1/admin/users")
}

func (g *Gateway) handleAdminUpdateUserStatus(c *gin.Context) {
	g.proxyToService(c, "admin-service", "/api/v1/admin/users/"+c.Param("id")+"/status")
}

// proxyToService proxies requests to the appropriate microservice
func (g *Gateway) proxyToService(c *gin.Context, serviceName, path string) {
	client := g.clients.GetClient(serviceName)
	if client == nil {
		c.JSON(500, gin.H{"error": "Service unavailable"})
		return
	}

	// Forward the request to the microservice
	client.ProxyRequest(c, path)
}
