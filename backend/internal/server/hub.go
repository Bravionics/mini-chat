package server

import (
	"mini-chat/backend/internal/models"
)

// Hub maintains the active clients and broadcasts messages to them
type Hub struct {
	// Registered clients
	clients map[*Client]bool

	// Incoming messages from clients
	broadcast chan models.Message

	// Requests to register from clients
	register chan *Client

	// Requests to unregister from clients
	unregister chan *Client
}

// Create a instance of Hub
func newHub() *Hub {
	return &Hub{
		clients: make(map[*Client]bool),
		broadcast: make(chan models.Message),
		register: make(chan *Client),
		unregister: make(chan *Client),
	}
}

// This function starts the hub's loop
func (h *Hub) run() {
	for {
		select {
		case client := <-h.register:
			h.clients[client] = true

		case client := <-h.unregister:
			if _, ok := h.clients[client]; ok {
				delete(h.clients, client)
				close(client.send)
			}

		case message := <-h.broadcast:
			for client := range h.clients {
				select {
				case client.send <- message:
				default:
					close(client.send)
					delete(h.clients, client)
				}
			}
		}
	}
}