package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/rekall/backend/internal/db"
	"github.com/rekall/backend/internal/engine"
	"github.com/rekall/backend/internal/models"
)

// ApprovalHandler holds the engine client needed to trigger learning.
type ApprovalHandler struct {
	engine *engine.Client
}

func NewApprovalHandler(eng *engine.Client) *ApprovalHandler {
	return &ApprovalHandler{engine: eng}
}

// Approve marks an incident as resolved and triggers the LearningAgent.
func (h *ApprovalHandler) Approve(c *gin.Context) {
	id := c.Param("id")

	var req models.ApprovalRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		// approval fields are optional
		req = models.ApprovalRequest{ReviewedBy: "human"}
	}
	if req.ReviewedBy == "" {
		req.ReviewedBy = "human"
	}

	incident, err := db.GetIncident(c.Request.Context(), id)
	if err != nil || incident == nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "incident not found"})
		return
	}

	if err := db.UpdateIncidentStatus(c.Request.Context(), id, models.StatusResolved); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	if _, err := db.AppendAgentLog(c.Request.Context(), id, "learning", "done",
		"Fix approved by "+req.ReviewedBy+". Vault confidence updated."); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// Best-effort: notify engine service to run LearningAgent
	if fix, err := db.GetLatestFixProposal(c.Request.Context(), id); err == nil && fix != nil {
		vaultID := ""
		if fix.VaultEntryID != nil {
			vaultID = *fix.VaultEntryID
		}
		go func() {
			_, _ = h.engine.Learn(c.Request.Context(), engine.LearnRequest{
				IncidentID:    id,
				FixProposalID: fix.ID,
				Result:        "success",
				ReviewedBy:    req.ReviewedBy,
				Notes:         req.Notes,
				FixTier:       string(fix.Tier),
				VaultEntryID:  vaultID,
			})
		}()
	}

	c.JSON(http.StatusOK, gin.H{"ok": true, "incident_id": id, "action": "approved"})
}

// Reject marks an incident as failed and notifies the LearningAgent.
func (h *ApprovalHandler) Reject(c *gin.Context) {
	id := c.Param("id")

	var req models.ApprovalRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		req = models.ApprovalRequest{ReviewedBy: "human"}
	}
	if req.ReviewedBy == "" {
		req.ReviewedBy = "human"
	}

	incident, err := db.GetIncident(c.Request.Context(), id)
	if err != nil || incident == nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "incident not found"})
		return
	}

	if err := db.UpdateIncidentStatus(c.Request.Context(), id, models.StatusFailed); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	if _, err := db.AppendAgentLog(c.Request.Context(), id, "learning", "done",
		"Fix rejected by "+req.ReviewedBy+". Vault confidence decayed."); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	if fix, err := db.GetLatestFixProposal(c.Request.Context(), id); err == nil && fix != nil {
		vaultID := ""
		if fix.VaultEntryID != nil {
			vaultID = *fix.VaultEntryID
		}
		go func() {
			_, _ = h.engine.Learn(c.Request.Context(), engine.LearnRequest{
				IncidentID:    id,
				FixProposalID: fix.ID,
				Result:        "rejected",
				ReviewedBy:    req.ReviewedBy,
				Notes:         req.Notes,
				FixTier:       string(fix.Tier),
				VaultEntryID:  vaultID,
			})
		}()
	}

	c.JSON(http.StatusOK, gin.H{"ok": true, "incident_id": id, "action": "rejected"})
}
