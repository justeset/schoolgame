package main

import (
	"backend/db"
	"backend/handlers"
	"backend/middlewares"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
	_ "backend/docs"
	swaggerFiles "github.com/swaggo/files"
	ginSwagger "github.com/swaggo/gin-swagger"
)

func main() {
	godotenv.Load()
	db.Connect()

	r := gin.Default()

	r.Use(func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Methods", "POST, GET, OPTIONS, PUT, DELETE")
		c.Header("Access-Control-Allow-Headers", "Content-Type, Authorization")
		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}
		c.Next()
	})

	authorized := r.Group("/")
	authorized.Use(middlewares.AuthMiddleware())

	r.POST("/auth/register", handlers.Register)
	r.POST("/auth/login", handlers.Login)

	authorized.POST("/code-errors", handlers.SaveCodeError)
	authorized.GET("/code-errors", handlers.GetUserCodeErrors)
	authorized.POST("/tasks/done", handlers.CompleteTask)
	authorized.GET("/tasks", handlers.GetUserTasks)
	authorized.DELETE("/tasks", handlers.ResetUserTasks)
	authorized.DELETE("/users/:id", handlers.DeleteUser)
	authorized.PUT("/users/:id", handlers.UpdateUser)

	r.GET("/swagger/*any", ginSwagger.WrapHandler(swaggerFiles.Handler))

	r.Run(":8080")
}