package handlers

import (
	"backend/db"
	"backend/models"
	"net/http"

	"github.com/gin-gonic/gin"
)

// CompleteTask godoc
// @Summary Отметить задачу выполненной
// @Tags tasks
// @Accept json
// @Produce json
// @Param input body models.CompleteTaskRequest true "ID пользователя и задачи"
// @Success 200 {object} models.MessageResponse
// @Failure 400 {object} models.ErrorResponse
// @Failure 500 {object} models.ErrorResponse
// @Router /tasks/done [post]
func CompleteTask(c *gin.Context) {
	var input struct {
		UserID int `json:"user_id"`
		TaskID int `json:"task_id"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "неверный формат"})
		return
	}

	_, err := db.DB.Exec(
		`INSERT INTO user_tasks (user_id, task_id)
		 VALUES ($1, $2)
		 ON CONFLICT DO NOTHING`,
		input.UserID,
		input.TaskID,
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "ошибка сервера"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "задача выполнена"})
}

// GetUserTasks godoc
// @Summary Получить выполненные задачи пользователя
// @Tags tasks
// @Produce json
// @Param user_id query int true "ID пользователя"
// @Success 200 {array} models.Task
// @Failure 500 {object} models.ErrorResponse
// @Router /tasks [get]
func GetUserTasks(c *gin.Context) {
	userID := c.Query("user_id")

	rows, err := db.DB.Query(`
		SELECT t.id, t.title
		FROM tasks t
		JOIN user_tasks ut ON t.id = ut.task_id
		WHERE ut.user_id = $1
	`, userID)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "ошибка сервера"})
		return
	}
	defer rows.Close()

	var tasks []models.Task

	for rows.Next() {
		var t models.Task
		if err := rows.Scan(&t.ID, &t.Title); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "ошибка чтения"})
			return
		}
		tasks = append(tasks, t)
	}

	c.JSON(http.StatusOK, tasks)
}

// ResetUserTasks godoc
// @Summary Сбросить прогресс пользователя
// @Tags tasks
// @Produce json
// @Param user_id query int true "ID пользователя"
// @Success 200 {object} models.MessageResponse
// @Failure 500 {object} models.ErrorResponse
// @Router /tasks [delete]
func ResetUserTasks(c *gin.Context) {
	userID := c.Query("user_id")

	_, err := db.DB.Exec(`
		DELETE FROM user_tasks
		WHERE user_id = $1
	`, userID)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "ошибка сервера"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "прогресс сброшен"})
}