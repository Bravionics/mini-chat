package main

import (
	"log"
	"mini-chat/backend/internal/server"
)

func main() {
	srv := server.NewServer(":8080")
	log.Fatal(srv.Start())
}
