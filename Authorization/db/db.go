package db

import (
    "database/sql"
    "log"
    "os"
    _ "github.com/lib/pq"
)

var DB *sql.DB

func Connect() {
    var err error
    dsn := os.Getenv("DB_DSN")
    if dsn == "" {
        dsn = "host=localhost port=5432 user=macbookair dbname=tower_game sslmode=disable"
    }
    DB, err = sql.Open("postgres", dsn)
    if err != nil {
        log.Fatal(err)
    }
    err = DB.Ping()
    if err != nil {
        log.Fatal(err)
    }
    
    _, err = DB.Exec(`
    CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        email TEXT UNIQUE NOT NULL,
        name TEXT,
        password TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS tasks (
        id SERIAL PRIMARY KEY,
        title TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS user_tasks (
        user_id INT REFERENCES users(id) ON DELETE CASCADE,
        task_id INT REFERENCES tasks(id) ON DELETE CASCADE,
        PRIMARY KEY (user_id, task_id)
    );
    `)
    if err != nil {
        log.Fatal(err)
    }
    
    log.Println("Подключение к БД успешно")
}