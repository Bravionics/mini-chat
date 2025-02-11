package models

type Room struct {
    ID string `json:"id"`
    Name string `json:"name"`
    NumClients int `json:"num_clients"`
    Messages []Message `json:"messages"`
}

