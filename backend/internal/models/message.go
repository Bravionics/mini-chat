package models

type MessageType string

const (
	TextMessage MessageType = "text"
	SystemMessage MessageType = "system"
	RoomUpdateMessage MessageType = "room_update"
)

type Message struct {
	Type MessageType `json:"type"`
	Content string `json:"content"`
	Sender string `json:"sender"`
	Room string `json:"room"`
	Timestamp int64 `json:"timestamp"`
}
