package main

import (
    "authorization/db"
    "authorization/handlers"
    "github.com/gin-gonic/gin"
    "github.com/joho/godotenv"
    _ "authorization/docs"
    swaggerFiles "github.com/swaggo/files"
    ginSwagger "github.com/swaggo/gin-swagger"
)

// @title School Game API
// @version 1.0
// @description Бэкенд для школьной игры
// @host localhost:8080
// @BasePath /
func main() {
    godotenv.Load()
    db.Connect()
    r := gin.Default()
    r.Use(func(c *gin.Context) {
        c.Header("Access-Control-Allow-Origin", "*")
        c.Header("Access-Control-Allow-Methods", "POST, GET, OPTIONS")
        c.Header("Access-Control-Allow-Headers", "Content-Type, Authorization")
        if c.Request.Method == "OPTIONS" {
            c.AbortWithStatus(204)
            return
        }
        c.Next()
    })
    // auth
    r.POST("/auth/register", handlers.Register)
    r.POST("/auth/login", handlers.Login)
    // tasks
    r.POST("/tasks/done", handlers.CompleteTask)
    r.GET("/tasks", handlers.GetUserTasks)
    r.DELETE("/tasks", handlers.ResetUserTasks)
    // users
    r.DELETE("/users/:id", handlers.DeleteUser)
    r.PUT("/users/:id", handlers.UpdateUser)

    r.GET("/swagger/*any", ginSwagger.WrapHandler(swaggerFiles.Handler))
    
    r.Run(":8080")
}
