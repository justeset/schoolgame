package middlewares

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"backend/jwt"
)

func AuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{
				"success": false,
				"message": "Токен не предоставлен",
			})
			return
		}

		parts := strings.SplitN(authHeader, " ", 2)
		if len(parts) != 2 || parts[0] != "Bearer" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{
				"success": false,
				"message": "Неверный формат токена",
			})
			return
		}

		tokenStr := parts[1]

		claims := &jwt.Claims{}
		token, err := jwt.ParseToken(tokenStr, claims)

		if err != nil || !token.Valid {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{
				"success": false,
				"message": "Неверный или просроченный токен",
			})
			return
		}

		c.Set("user_id", claims.UserID)
		c.Next()
	}
}

func GetUserID(c *gin.Context) int {
	if userID, exists := c.Get("user_id"); exists {
		if id, ok := userID.(int); ok {
			return id
		}
	}
	return 0
}