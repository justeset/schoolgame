package handlers

import (
	"net/http"

	"backend/db"
	"backend/middlewares"

	"github.com/gin-gonic/gin"
)

type CodeErrorRequest struct {
	TaskID        string `json:"task_id" binding:"required"`
	SubmittedCode string `json:"submitted_code" binding:"required"`
	ErrorType     string `json:"error_type" binding:"required"`
	ErrorMessage  string `json:"error_message" binding:"required"`
	TestNumber    *int   `json:"test_number,omitempty"`
}

// SaveCodeError godoc
// @Summary Сохранить ошибку кода
// @Tags code-errors
// @Accept json
// @Produce json
// @Param input body CodeErrorRequest true "Данные об ошибке"
// @Success 200 {object} models.MessageResponse
// @Failure 400 {object} models.ErrorResponse
// @Failure 401 {object} models.ErrorResponse
// @Failure 500 {object} models.ErrorResponse
// @Router /code-errors [post]
// @Security BearerAuth
func SaveCodeError(c *gin.Context) {
	userID := middlewares.GetUserID(c)
	if userID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{
			"success": false,
			"message": "Не авторизован",
		})
		return
	}

	var req CodeErrorRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Неверный формат данных",
		})
		return
	}

	_, err := db.DB.Exec(`
		INSERT INTO code_errors 
		(user_id, task_id, submitted_code, error_type, error_message, test_number)
		VALUES ($1, $2, $3, $4, $5, $6)
	`, userID, req.TaskID, req.SubmittedCode, req.ErrorType, req.ErrorMessage, req.TestNumber)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": "Ошибка при сохранении в базу данных",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Ошибка успешно сохранена",
	})
}

// GetUserCodeErrors godoc
// @Summary Получить список задач с ошибками для пользователя
// @Tags code-errors
// @Produce json
// @Success 200 {array} map[string]interface{}
// @Failure 401 {object} models.ErrorResponse
// @Failure 500 {object} models.ErrorResponse
// @Router /code-errors [get]
// @Security BearerAuth
func GetUserCodeErrors(c *gin.Context) {
	userID := middlewares.GetUserID(c)
	if userID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{
			"success": false,
			"message": "Не авторизован",
		})
		return
	}

	rows, err := db.DB.Query(`
		SELECT task_id, COUNT(*) as error_count
		FROM code_errors
		WHERE user_id = $1
		GROUP BY task_id
		ORDER BY error_count DESC, task_id
	`, userID)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": "Ошибка при получении данных",
		})
		return
	}
	defer rows.Close()

	var taskErrors []map[string]interface{}

	for rows.Next() {
		var taskID string
		var errorCount int
		if err := rows.Scan(&taskID, &errorCount); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{
				"success": false,
				"message": "Ошибка чтения данных",
			})
			return
		}
		taskErrors = append(taskErrors, map[string]interface{}{
			"task_id":     taskID,
			"error_count": errorCount,
		})
	}

	c.JSON(http.StatusOK, taskErrors)
}