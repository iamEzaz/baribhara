package config

import (
	"fmt"
	"time"

	"github.com/spf13/viper"
)

// Config holds all configuration for the application
type Config struct {
	Server   ServerConfig   `mapstructure:"server"`
	Services ServicesConfig `mapstructure:"services"`
	Redis    RedisConfig    `mapstructure:"redis"`
	JWT      JWTConfig      `mapstructure:"jwt"`
	Metrics  MetricsConfig  `mapstructure:"metrics"`
}

// ServerConfig holds server configuration
type ServerConfig struct {
	Port         int    `mapstructure:"port"`
	Mode         string `mapstructure:"mode"`
	ReadTimeout  int    `mapstructure:"read_timeout"`
	WriteTimeout int    `mapstructure:"write_timeout"`
	IdleTimeout  int    `mapstructure:"idle_timeout"`
}

// ServicesConfig holds microservices configuration
type ServicesConfig struct {
	AuthService      ServiceConfig `mapstructure:"auth_service"`
	UserService      ServiceConfig `mapstructure:"user_service"`
	PropertyService  ServiceConfig `mapstructure:"property_service"`
	TenantService    ServiceConfig `mapstructure:"tenant_service"`
	InvoiceService   ServiceConfig `mapstructure:"invoice_service"`
	NotificationService ServiceConfig `mapstructure:"notification_service"`
	ReportService    ServiceConfig `mapstructure:"report_service"`
	AdminService     ServiceConfig `mapstructure:"admin_service"`
	CaretakerService ServiceConfig `mapstructure:"caretaker_service"`
}

// ServiceConfig holds individual service configuration
type ServiceConfig struct {
	Host string `mapstructure:"host"`
	Port int    `mapstructure:"port"`
	GRPCPort int `mapstructure:"grpc_port"`
}

// RedisConfig holds Redis configuration
type RedisConfig struct {
	Host     string `mapstructure:"host"`
	Port     int    `mapstructure:"port"`
	Password string `mapstructure:"password"`
	DB       int    `mapstructure:"db"`
}

// JWTConfig holds JWT configuration
type JWTConfig struct {
	Secret     string        `mapstructure:"secret"`
	Expiration time.Duration `mapstructure:"expiration"`
}

// MetricsConfig holds metrics configuration
type MetricsConfig struct {
	Enabled bool   `mapstructure:"enabled"`
	Path    string `mapstructure:"path"`
}

// Load loads configuration from file and environment variables
func Load() (*Config, error) {
	viper.SetConfigName("config")
	viper.SetConfigType("yaml")
	viper.AddConfigPath("./configs")
	viper.AddConfigPath(".")

	// Set default values
	setDefaults()

	// Enable reading from environment variables
	viper.AutomaticEnv()

	// Read config file
	if err := viper.ReadInConfig(); err != nil {
		if _, ok := err.(viper.ConfigFileNotFoundError); !ok {
			return nil, fmt.Errorf("error reading config file: %w", err)
		}
	}

	var config Config
	if err := viper.Unmarshal(&config); err != nil {
		return nil, fmt.Errorf("error unmarshaling config: %w", err)
	}

	return &config, nil
}

// setDefaults sets default configuration values
func setDefaults() {
	// Server defaults
	viper.SetDefault("server.port", 8080)
	viper.SetDefault("server.mode", "debug")
	viper.SetDefault("server.read_timeout", 30)
	viper.SetDefault("server.write_timeout", 30)
	viper.SetDefault("server.idle_timeout", 120)

	// Services defaults
	viper.SetDefault("services.auth_service.host", "localhost")
	viper.SetDefault("services.auth_service.port", 3001)
	viper.SetDefault("services.auth_service.grpc_port", 50051)

	viper.SetDefault("services.user_service.host", "localhost")
	viper.SetDefault("services.user_service.port", 3002)
	viper.SetDefault("services.user_service.grpc_port", 50052)

	viper.SetDefault("services.property_service.host", "localhost")
	viper.SetDefault("services.property_service.port", 3003)
	viper.SetDefault("services.property_service.grpc_port", 50053)

	viper.SetDefault("services.tenant_service.host", "localhost")
	viper.SetDefault("services.tenant_service.port", 3004)
	viper.SetDefault("services.tenant_service.grpc_port", 50054)

	viper.SetDefault("services.invoice_service.host", "localhost")
	viper.SetDefault("services.invoice_service.port", 3005)
	viper.SetDefault("services.invoice_service.grpc_port", 50055)

	viper.SetDefault("services.notification_service.host", "localhost")
	viper.SetDefault("services.notification_service.port", 3006)
	viper.SetDefault("services.notification_service.grpc_port", 50056)

	viper.SetDefault("services.report_service.host", "localhost")
	viper.SetDefault("services.report_service.port", 3007)
	viper.SetDefault("services.report_service.grpc_port", 50057)

	viper.SetDefault("services.admin_service.host", "localhost")
	viper.SetDefault("services.admin_service.port", 3008)
	viper.SetDefault("services.admin_service.grpc_port", 50058)

	viper.SetDefault("services.caretaker_service.host", "localhost")
	viper.SetDefault("services.caretaker_service.port", 3009)
	viper.SetDefault("services.caretaker_service.grpc_port", 50059)

	// Redis defaults
	viper.SetDefault("redis.host", "localhost")
	viper.SetDefault("redis.port", 6379)
	viper.SetDefault("redis.password", "")
	viper.SetDefault("redis.db", 0)

	// JWT defaults
	viper.SetDefault("jwt.secret", "your-secret-key")
	viper.SetDefault("jwt.expiration", "24h")

	// Metrics defaults
	viper.SetDefault("metrics.enabled", true)
	viper.SetDefault("metrics.path", "/metrics")
}
