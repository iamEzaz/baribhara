package logger

import (
	"os"

	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
)

// NewLogger creates a new logger instance
func NewLogger() (*zap.Logger, error) {
	config := zap.NewProductionConfig()
	
	// Set log level based on environment
	if os.Getenv("LOG_LEVEL") == "debug" {
		config.Level = zap.NewAtomicLevelAt(zap.DebugLevel)
	}

	// Configure output
	config.OutputPaths = []string{"stdout"}
	config.ErrorOutputPaths = []string{"stderr"}

	// Configure encoder
	config.EncoderConfig.TimeKey = "timestamp"
	config.EncoderConfig.EncodeTime = zapcore.ISO8601TimeEncoder
	config.EncoderConfig.EncodeLevel = zapcore.CapitalLevelEncoder

	return config.Build()
}
