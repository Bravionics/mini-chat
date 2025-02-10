package server

import (
	"log"
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