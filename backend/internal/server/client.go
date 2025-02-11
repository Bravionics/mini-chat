package server

import (
	"log"
	"time"

	"mini-chat/backend/internal/models"

	"github.com/gorilla/websocket"
)

const (
	// Max message size allowed from peer
	maxMessageSize = 512
	
	// Time allowed to write message to peer
	writeTime = 10 * time.Second

	// Time allowed to read pong message from peer
	pongTime = 60 * time.Second

	// Send pings to peer at this period. Must be less than pongTime.
	pingPeriod = (pongTime * 9) / 10
)

// Client struct represents a single WebSocket connection
type Client struct {
	hub *Hub
	conn *websocket.Conn
	send chan models.Message // Buffered channel of outbound messages
	room string // Name of room client is in
}

func (c *Client) joinRoom(roomID string) {
    c.room = roomID
}

// Create a new client instance
func newClient(hub *Hub, conn *websocket.Conn) *Client {
	return &Client{
		hub: hub,
		conn: conn,
		send: make(chan models.Message, 256), // Allow buffer of up to 256 msgs
	}
}

// Pumps messages from WebSocket connection to the hub
func (c *Client) readPump() {
	defer func() {
		c.hub.unregister <- c
		c.conn.Close()
	}()

	c.conn.SetReadLimit(maxMessageSize)
	c.conn.SetReadDeadline(time.Now().Add(pongTime))
	c.conn.SetPongHandler(func(string) error {
        c.conn.SetReadDeadline(time.Now().Add(pongTime))
        return nil
    })

	for {
		var message models.Message
		err := c.conn.ReadJSON(&message)
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				log.Printf("error: %v", err)
			}
			break
		}
		message.Timestamp = time.Now().Unix()
		
		// Handle system messages
		if message.Type == models.SystemMessage {
			c.joinRoom(message.Room)
		}
		
		c.hub.broadcast <- message
	}
}


// Pumps messages from the hub to the WebSocket connection
func (c *Client) writePump() {
	ticker := time.NewTicker(pingPeriod)
	defer func() {
		ticker.Stop()
		c.conn.Close()
	}()

	for {
		select {
		case message, ok := <-c.send:
			c.conn.SetWriteDeadline(time.Now().Add(writeTime))
			if !ok {
				// Channel closed by hub
				c.conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}

			err := c.conn.WriteJSON(message)
			if err != nil {
				return
			}

		case <-ticker.C:
			c.conn.SetWriteDeadline(time.Now().Add(writeTime))
			if err := c.conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}
