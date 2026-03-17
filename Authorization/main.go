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
    r.POST("/auth/register", handlers.Register)
    r.POST("/auth/login", handlers.Login)
    r.Run(":8080")
}
