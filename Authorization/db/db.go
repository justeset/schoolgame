package db

import (
	"database/sql"
    "log"
    _ "github.com/lib/pq"
)

var DB *sql.DB

func Connect() {
    var err error
    DB, err = sql.Open("postgres", "host=localhost port=5432 user=macbookair dbname=tower_game sslmode=disable")
    if err != nil {
        log.Fatal(err)
    }
    err = DB.Ping()
    if err != nil {
        log.Fatal(err)
    }
    log.Println("Подключение к БД успешно")
}