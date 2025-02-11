package server

import (
	"encoding/json"
	"log"
	"mini-chat/backend/internal/models"
	"net/http"

	"github.com/gorilla/websocket"
)

// upgrader converts http connections to WebSocket connections
var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin: func(r *http.Request) bool {
		// Temporary return true, origin check properly in production
		return true
	},
}

// Server configuration and state
type Server struct {
	addr string
	hub *Hub
}

// Create and return a new instance of Server
func NewServer(addr string) *Server {
	return &Server{
		addr: addr,
		hub: newHub(),
	}
}

// Initialize HTTP server and listen for connections
func (s *Server) Start() error{
	// Start hub
	go s.hub.run()

	http.HandleFunc("/ws", s.handleWebSocket) // WebSocket endpoint
	http.HandleFunc("/health", s.handleHealth) // Health check endpoint
	http.HandleFunc("/rooms", s.handleGetRooms) // Get all rooms endpoint
	http.HandleFunc("/rooms/create", s.handleCreateRoom) // Create a room endpoint

	// Start and listen
	return http.ListenAndServe(s.addr, nil)
}

// Responds "OK" and 200 code if server is running
func (s *Server) handleHealth(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	w.Write([]byte("OK"))
}

// Handles incoming WebSocket connections
func (s *Server) handleWebSocket(w http.ResponseWriter, r *http.Request) {
	// Use upgrader to upgrade 
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Printf("error upgrading connection: %v", err)
		return
	}

	// Create a new client instance for this connection
	client := newClient(s.hub, conn)

	// Register this client with the hub
	// Done through a channel so it is thread safe
	client.hub.register <- client

	// Start two goroutines to handle this client's messages
	go client.writePump()
	go client.readPump()
}

// Handlers for rooms
func (s *Server) handleCreateRoom(w http.ResponseWriter, r *http.Request) {
	// Set CORS headers first
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "Content-Type")

	// Handle preflight request
	if r.Method == http.MethodOptions {
		w.WriteHeader(http.StatusOK)
		return
	}

	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var room struct{
		Name string `json:"name"`
	}
	if err := json.NewDecoder(r.Body).Decode(&room); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	log.Printf("Received create room request for name: %s", room.Name)
	w.Header().Set("Content-Type", "application/json")
	newRoom := s.hub.createRoom(room.Name)
	json.NewEncoder(w).Encode(newRoom)
}

func (s *Server) handleGetRooms(w http.ResponseWriter, r *http.Request) {
	// Set CORS headers first
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "GET, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "Content-Type")
	
	if r.Method == http.MethodOptions {
		w.WriteHeader(http.StatusOK)
		return
	}

	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	
	// Convert map to slice for consistent ordering
	rooms := make([]*models.Room, 0, len(s.hub.rooms))
	for _, room := range s.hub.rooms {
		rooms = append(rooms, room)
	}
	
	if err := json.NewEncoder(w).Encode(rooms); err != nil {
		log.Printf("Error encoding rooms: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}
}