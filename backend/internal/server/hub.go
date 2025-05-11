package server

import (
	"mini-chat/backend/internal/models"
	"time"
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

	// Map of rooms. Use room IDs as keys. 
	rooms map[string]*models.Room
}

// Create a instance of Hub
func newHub() *Hub {
	h := &Hub{
		clients:    make(map[*Client]bool),
		broadcast:  make(chan models.Message),
		register:   make(chan *Client),
		unregister: make(chan *Client),
		rooms:      make(map[string]*models.Room),
	}
	
	// Create default general room
	h.createRoom("General")
	
	return h
}

// Function to create a new room. Takes new room name as input.
func (h *Hub) createRoom(name string) *models.Room {
	room := &models.Room{
		ID: name, // Use room name as room ID, so names will have to be unique. Might change later.
		Name: name,
	}
	// Add new room to the hub rooms map
	h.rooms[room.ID] = room

	// Broadcast room update to all clients
	updateMsg := models.Message{
		Type: models.RoomUpdateMessage,
		Content: room.Name,
		Sender: "system",
		Room: room.ID,
		Timestamp: time.Now().Unix(),
	}
	
	// Send to all clients regardless of their current room
	for client := range h.clients {
		select {
		case client.send <- updateMsg:
		default:
			close(client.send)
			delete(h.clients, client)
		}
	}

	return room
}

// Room getter. Takes room id as input.
func (h *Hub) getRoom(id string) *models.Room {
	return h.rooms[id]
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
			room := h.rooms[message.Room]
			if room != nil {
				// Store message in room history
				room.Messages = append(room.Messages, message)
				// Broadcast to all clients in this room
				for client := range h.clients {
					if client.room == message.Room {
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
	}
}