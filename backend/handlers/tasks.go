package handlers

import (
	"authorization/db"
	"authorization/models"
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

type LeaderboardEntry struct {
	UserID      int    `json:"user_id"`
	Name        string `json:"name"`
	SolvedCount int    `json:"solved_count"`
}

// GetLeaderboard godoc
// @Summary Таблица лидеров по решенным заданиям
// @Tags tasks
// @Produce json
// @Success 200 {array} LeaderboardEntry
// @Failure 500 {object} models.ErrorResponse
// @Router /leaderboard [get]
func GetLeaderboard(c *gin.Context) {
	rows, err := db.DB.Query(`
		SELECT u.id, COALESCE(NULLIF(u.name, ''), u.email) AS display_name, COUNT(ut.task_id) AS solved_count
		FROM users u
		LEFT JOIN user_tasks ut ON u.id = ut.user_id
		GROUP BY u.id, display_name
		ORDER BY solved_count DESC, display_name ASC
		LIMIT 20
	`)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "ошибка сервера"})
		return
	}
	defer rows.Close()

	var leaderboard []LeaderboardEntry
	for rows.Next() {
		var entry LeaderboardEntry
		if err := rows.Scan(&entry.UserID, &entry.Name, &entry.SolvedCount); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "ошибка чтения"})
			return
		}
		leaderboard = append(leaderboard, entry)
	}

	c.JSON(http.StatusOK, leaderboard)
}
