package controller

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/op/go-logging"

	xuilogger "github.com/Kayjz/Kaygez/v3/internal/logger"
)

func TestServerControllerInstallXrayRegistersRoute(t *testing.T) {
	xuilogger.InitLogger(logging.ERROR)
	gin.SetMode(gin.TestMode)

	router := gin.New()
	controller := &ServerController{}
	router.POST("/server/installXray/:version", controller.installXray)

	req := httptest.NewRequest(http.MethodPost, "/server/installXray/not-a-version", nil)
	rec := httptest.NewRecorder()
	router.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d; body=%s", rec.Code, http.StatusOK, rec.Body.String())
	}

	var envelope struct {
		Success bool `json:"success"`
	}
	if err := json.Unmarshal(rec.Body.Bytes(), &envelope); err != nil {
		t.Fatalf("decode response: %v; body=%s", err, rec.Body.String())
	}

	if envelope.Success {
		t.Fatalf("installXray accepted an invalid version; body=%s", rec.Body.String())
	}
}
