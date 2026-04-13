package handlers

import (
	"github.com/golang-jwt/jwt/v5"
	"time"
)

var jwtSecret = []byte("tower_game_secret")

func GenerateToken(userID int) (string, error) {
	claims := jwt.MapClaims{
		"user_id": userID,
		"exp":     time.Now().Add(24 * time.Hour).Unix(),
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(jwtSecret)
}
