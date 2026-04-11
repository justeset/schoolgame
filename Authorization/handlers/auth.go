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
        Email    string `json:"email"`
        Name     string `json:"name"`
        Password string `json:"password"`
    }

    if err := c.ShouldBindJSON(&input); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": "неверный формат данных"})
        return
    }

    hashedPassword, err := bcrypt.GenerateFromPassword([]byte(input.Password), bcrypt.DefaultCost)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "ошибка сервера"})
        return
    }

    _, err = db.DB.Exec(
        "INSERT INTO users (email, name, password) VALUES ($1, $2, $3)",
        input.Email,
        input.Name,
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

    err := db.DB.QueryRow(
        "SELECT id, email, name, password FROM users WHERE email = $1",
        input.Email,
    ).Scan(&user.ID, &user.Email, &user.Name, &user.Password)

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