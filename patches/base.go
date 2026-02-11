package channels

import (
	"context"
	"strings"

	"github.com/sipeed/picoclaw/pkg/bus"
)

type Channel interface {
	Name() string
	Start(ctx context.Context) error
	Stop(ctx context.Context) error
	Send(ctx context.Context, msg bus.OutboundMessage) error
	IsRunning() bool
	IsAllowed(senderID string) bool
}

type BaseChannel struct {
	config    interface{}
	bus       *bus.MessageBus
	running   bool
	name      string
	allowList []string
}

func NewBaseChannel(name string, config interface{}, bus *bus.MessageBus, allowList []string) *BaseChannel {
	return &BaseChannel{
		config:    config,
		bus:       bus,
		name:      name,
		allowList: allowList,
		running:   false,
	}
}

func (c *BaseChannel) Name() string {
	return c.name
}

func (c *BaseChannel) IsRunning() bool {
	return c.running
}

// IsAllowed checks if a sender is allowed
// Now supports flexible matching:
// - Exact match: "5619062865|DARKGOLARTE"
// - ID-only match: "5619062865" matches "5619062865|DARKGOLARTE"
// - Username-only match: "DARKGOLARTE" matches "5619062865|DARKGOLARTE"
func (c *BaseChannel) IsAllowed(senderID string) bool {
	if len(c.allowList) == 0 {
		return true
	}

	for _, allowed := range c.allowList {
		// Exact match
		if senderID == allowed {
			return true
		}

		// Flexible matching for Telegram-style IDs ("ID|USERNAME")
		if strings.Contains(senderID, "|") {
			parts := strings.SplitN(senderID, "|", 2)
			userID := parts[0]
			username := parts[1]

			// Match by ID only
			if userID == allowed {
				return true
			}

			// Match by username only
			if username == allowed {
				return true
			}
		}

		// Allow wildcards: "*" allows everyone
		if allowed == "*" {
			return true
		}
	}

	return false
}

func (c *BaseChannel) HandleMessage(senderID, chatID, content string, media []string, metadata map[string]string) {
	if !c.IsAllowed(senderID) {
		return
	}

	msg := bus.InboundMessage{
		Channel:  c.name,
		SenderID: senderID,
		ChatID:   chatID,
		Content:  content,
		Media:    media,
		Metadata: metadata,
	}

	c.bus.PublishInbound(msg)
}

func (c *BaseChannel) setRunning(running bool) {
	c.running = running
}
