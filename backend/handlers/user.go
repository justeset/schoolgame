package handlers

import (
	"backend/db"
	"net/http"

	"github.com/gin-gonic/gin"
	"golang.org/x/crypto/bcrypt"
)

// DeleteUser godoc
// @Summary Удалить пользователя
// @Tags users
// @Produce json
// @Param id path int true "ID пользователя"
// @Success 200 {object} models.MessageResponse
// @Failure 500 {object} models.ErrorResponse
// @Router /users/{id} [delete]
func DeleteUser(c *gin.Context) {
	id := c.Param("id")

	_, err := db.DB.Exec("DELETE FROM users WHERE id = $1", id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "ошибка сервера"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "пользователь удалён"})
}

// UpdateUser godoc
// @Summary Изменить данные пользователя
// @Tags users
// @Accept json
// @Produce json
// @Param id path int true "ID пользователя"
// @Param input body models.UpdateUserRequest true "Новые данные"
// @Success 200 {object} models.MessageResponse
// @Failure 400 {object} models.ErrorResponse
// @Failure 500 {object} models.ErrorResponse
// @Router /users/{id} [put]
func UpdateUser(c *gin.Context) {
	id := c.Param("id")

	var input struct {
		Email    string `json:"email"`
		Name     string `json:"name"`
		Password string `json:"password"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "неверный формат данных"})
		return
	}

	if input.Password != "" {
		hashed, err := bcrypt.GenerateFromPassword([]byte(input.Password), bcrypt.DefaultCost)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "ошибка сервера"})
			return
		}
		input.Password = string(hashed)

		_, err = db.DB.Exec(
			"UPDATE users SET email=$1, name=$2, password=$3 WHERE id=$4",
			input.Email, input.Name, input.Password, id,
		)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "ошибка сервера"})
			return
		}
	} else {
		_, err := db.DB.Exec(
			"UPDATE users SET email=$1, name=$2 WHERE id=$3",
			input.Email, input.Name, id,
		)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "ошибка сервера"})
			return
		}
	}

	c.JSON(http.StatusOK, gin.H{"message": "данные обновлены"})
}