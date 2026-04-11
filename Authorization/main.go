package main

import (
    "authorization/db"
    "authorization/handlers"
    "github.com/gin-gonic/gin"
)

func main() {
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
    r.POST("/tasks", handlers.CreateTask)
    r.POST("/tasks/done", handlers.CompleteTask)
    r.GET("/tasks", handlers.GetUserTasks)

    r.GET("/ping", func(c *gin.Context) {
        c.JSON(200, gin.H{"message": "ok"})
    })

    r.Run(":8080")
}
