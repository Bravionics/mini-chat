package main

import (
	"log"
	"mini-chat/backend/internal/server"
	"os"
)

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
		log.Printf("Defaulting to port %s", port)
	}
	listenAddr := ":" + port

	log.Printf("Starting server on %s", listenAddr)

	srv := server.NewServer(listenAddr)
	if err := srv.Start(); err != nil {
		log.Fatalf("Server failed to start: %v", err)
	}
}
