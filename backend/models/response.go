package models

type MessageResponse struct {
    Message string `json:"message"`
}

type ErrorResponse struct {
    Error string `json:"error"`
}

type LoginResponse struct {
    Token string `json:"token"`
    User  User   `json:"user"`
}