package client

import (
	"baribhara/api-gateway/internal/config"
	"fmt"
	"net/http"
	"net/http/httputil"
	"net/url"
	"time"

	"github.com/gin-gonic/gin"
	"go.uber.org/zap"
)

// Manager manages HTTP clients for microservices
type Manager struct {
	clients map[string]*http.Client
	config  *config.Config
	logger  *zap.Logger
}

// NewManager creates a new client manager
func NewManager(cfg *config.Config, logger *zap.Logger) (*Manager, error) {
	manager := &Manager{
		clients: make(map[string]*http.Client),
		config:  cfg,
		logger:  logger,
	}

	// Initialize clients for each service
	services := map[string]config.ServiceConfig{
		"auth-service":      cfg.Services.AuthService,
		"user-service":      cfg.Services.UserService,
		"property-service":  cfg.Services.PropertyService,
		"tenant-service":    cfg.Services.TenantService,
		"invoice-service":   cfg.Services.InvoiceService,
		"notification-service": cfg.Services.NotificationService,
		"report-service":    cfg.Services.ReportService,
		"admin-service":     cfg.Services.AdminService,
		"caretaker-service": cfg.Services.CaretakerService,
	}

	for name, serviceConfig := range services {
		client := &http.Client{
			Timeout: 30 * time.Second,
		}
		manager.clients[name] = client
	}

	return manager, nil
}

// GetClient returns a client for the specified service
func (m *Manager) GetClient(serviceName string) *ServiceClient {
	client, exists := m.clients[serviceName]
	if !exists {
		return nil
	}

	serviceConfig := m.getServiceConfig(serviceName)
	if serviceConfig == nil {
		return nil
	}

	return &ServiceClient{
		client: client,
		config: *serviceConfig,
		logger: m.logger,
	}
}

// getServiceConfig returns the configuration for a service
func (m *Manager) getServiceConfig(serviceName string) *config.ServiceConfig {
	switch serviceName {
	case "auth-service":
		return &m.config.Services.AuthService
	case "user-service":
		return &m.config.Services.UserService
	case "property-service":
		return &m.config.Services.PropertyService
	case "tenant-service":
		return &m.config.Services.TenantService
	case "invoice-service":
		return &m.config.Services.InvoiceService
	case "notification-service":
		return &m.config.Services.NotificationService
	case "report-service":
		return &m.config.Services.ReportService
	case "admin-service":
		return &m.config.Services.AdminService
	case "caretaker-service":
		return &m.config.Services.CaretakerService
	default:
		return nil
	}
}

// ServiceClient represents a client for a specific service
type ServiceClient struct {
	client *http.Client
	config config.ServiceConfig
	logger *zap.Logger
}

// ProxyRequest proxies a request to the service
func (sc *ServiceClient) ProxyRequest(c *gin.Context, path string) {
	// Build target URL
	targetURL := fmt.Sprintf("http://%s:%d%s", sc.config.Host, sc.config.Port, path)
	
	target, err := url.Parse(targetURL)
	if err != nil {
		sc.logger.Error("Failed to parse target URL", zap.Error(err))
		c.JSON(500, gin.H{"error": "Internal server error"})
		return
	}

	// Create reverse proxy
	proxy := httputil.NewSingleHostReverseProxy(target)
	
	// Modify request
	proxy.Director = func(req *http.Request) {
		req.URL.Scheme = target.Scheme
		req.URL.Host = target.Host
		req.URL.Path = path
		req.Host = target.Host
		
		// Copy headers
		for key, values := range c.Request.Header {
			for _, value := range values {
				req.Header.Add(key, value)
			}
		}
	}

	// Handle errors
	proxy.ErrorHandler = func(w http.ResponseWriter, r *http.Request, err error) {
		sc.logger.Error("Proxy error", zap.Error(err))
		c.JSON(502, gin.H{"error": "Service unavailable"})
	}

	// Serve the request
	proxy.ServeHTTP(c.Writer, c.Request)
}
