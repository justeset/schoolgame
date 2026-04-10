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
        Username string `json:"email"`
        Password string `json:"password"`
    }

    err := c.ShouldBindJSON(&input)

    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": "неверный формат данных"})
        return
    }

    hashedPassword, err := bcrypt.GenerateFromPassword([]byte(input.Password), bcrypt.DefaultCost)

    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "ошибка сервера"})
        return
    }

    _, err = db.DB.Exec(
        "INSERT INTO users (email, password) VALUES ($1, $2)",
        input.Username,
        string(hashedPassword),
    )

    if err != nil {
        c.JSON(http.StatusConflict, gin.H{"error": "конфликт данных"})
        return
    }

    c.JSON(http.StatusCreated, gin.H{"message": "пользователь создан"})
}

func Login(c *gin.Context) {
    var user models.User
    var input struct {
        Username string `json:"username"`
        Password string `json:"password"`
    }

    err := c.ShouldBindJSON(&input)
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": "неверный формат данных"})
        return
    }

    err = db.DB.QueryRow(
        "SELECT id, username, password FROM users WHERE username = $1",
        input.Username,
    ).Scan(&user.ID, &user.Email, &user.Password)

    if err != nil {
        c.JSON(http.StatusUnauthorized, gin.H{"error": "пользователь не найден"})
        return
    }

    err = bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(input.Password))
    if err != nil {
        c.JSON(http.StatusUnauthorized, gin.H{"error": "неверный пароль"})
    return
    }

    token, err := GenerateToken(user.ID)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "ошибка сервера"})
        return
    }

    c.JSON(http.StatusOK, gin.H{"token": token})
}