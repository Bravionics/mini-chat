package server

import (
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
}

// Create and return a new instance of Server
func NewServer(addr string) *Server {
	return &Server{
		addr: addr,
	}
}

// Initialize HTTP server and listen for connections
func (s *Server) Start() error{
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
		// Future error handling of upgrade failure
		return
	}

	// Connection closes when the function returns
	defer conn.Close()

	// Loop to handle messages from the connection
	for {
		messageType, p, err := conn.ReadMessage()
		if err != nil {
			// If read fails (client disconnect, etc.) exit the loop
			return
		}

		// Echo the message back for now
		if err := conn.WriteMessage(messageType, p); err != nil {
			return
		}
	}
}