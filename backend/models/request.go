package models

type RegisterRequest struct {
    Email    string `json:"email" example:"user@example.com"`
    Name     string `json:"name" example:"Иван"`
    Password string `json:"password" example:"1234"`
}

type LoginRequest struct {
    Email    string `json:"email" example:"user@example.com"`
    Password string `json:"password" example:"1234"`
}

type CompleteTaskRequest struct {
    UserID int `json:"user_id" example:"1"`
    TaskID int `json:"task_id" example:"1"`
}

type UpdateUserRequest struct {
	Email    string `json:"email" example:"new@example.com"`
	Name     string `json:"name" example:"Новое имя"`
	Password string `json:"password" example:"newpassword"`
}