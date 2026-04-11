package handlers

import (
	"authorization/db"
	"authorization/models"
	"net/http"

	"github.com/gin-gonic/gin"
	"golang.org/x/crypto/bcrypt"
)

func Register(c *gin.Context) {
    var input struct {
<<<<<<< HEAD:backend/handlers/auth.go
        Username string `json:"email"`
=======
        Email    string `json:"email"`
        Name     string `json:"name"`
>>>>>>> main:Authorization/handlers/auth.go
        Password string `json:"password"`
    }

    if err := c.ShouldBindJSON(&input); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": "неверный формат данных"})
        return
    }

    hashedPassword, err := bcrypt.GenerateFromPassword([]byte(input.Password), bcrypt.DefaultCost)
<<<<<<< HEAD:backend/handlers/auth.go

=======
>>>>>>> main:Authorization/handlers/auth.go
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "ошибка сервера"})
        return
    }

    _, err = db.DB.Exec(
<<<<<<< HEAD:backend/handlers/auth.go
        "INSERT INTO users (email, password) VALUES ($1, $2)",
        input.Username,
=======
        "INSERT INTO users (email, name, password) VALUES ($1, $2, $3)",
        input.Email,
        input.Name,
>>>>>>> main:Authorization/handlers/auth.go
        string(hashedPassword),
    )

    if err != nil {
        c.JSON(http.StatusConflict, gin.H{"error": "пользователь уже существует"})
        return
    }

    c.JSON(http.StatusCreated, gin.H{"message": "пользователь создан"})
}

func Login(c *gin.Context) {
    var user models.User

    var input struct {
        Email    string `json:"email"`
        Password string `json:"password"`
    }

    if err := c.ShouldBindJSON(&input); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": "неверный формат данных"})
        return
    }

<<<<<<< HEAD:backend/handlers/auth.go
    err = db.DB.QueryRow(
        "SELECT id, username, password FROM users WHERE username = $1",
        input.Username,
    ).Scan(&user.ID, &user.Email, &user.Password)
=======
    err := db.DB.QueryRow(
        "SELECT id, email, name, password FROM users WHERE email = $1",
        input.Email,
    ).Scan(&user.ID, &user.Email, &user.Name, &user.Password)
>>>>>>> main:Authorization/handlers/auth.go

    if err != nil {
        c.JSON(http.StatusUnauthorized, gin.H{"error": "пользователь не найден"})
        return
    }

    if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(input.Password)); err != nil {
        c.JSON(http.StatusUnauthorized, gin.H{"error": "неверный пароль"})
        return
    }

    token, err := GenerateToken(user.ID)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "ошибка сервера"})
        return
    }

    c.JSON(http.StatusOK, gin.H{
        "token": token,
        "user": gin.H{
            "id":    user.ID,
            "email": user.Email,
            "name":  user.Name,
        },
    })
}