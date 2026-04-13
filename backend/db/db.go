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

    INSERT INTO tasks (id, title) VALUES
        (1, 'Сортировка пузырьком'),
        (2, 'Бинарный поиск'),
        (3, 'Хеш-таблицы')
    ON CONFLICT (id) DO UPDATE SET
        title = EXCLUDED.title;

    SELECT setval(
        pg_get_serial_sequence('tasks', 'id'),
        GREATEST(COALESCE((SELECT MAX(id) FROM tasks), 1), 1),
        true
    );

    INSERT INTO users (id, email, name, password)
    SELECT 1, 'default-player@schoolgame.local', 'Player', '-'
    WHERE NOT EXISTS (SELECT 1 FROM users WHERE id = 1);

    SELECT setval(
        pg_get_serial_sequence('users', 'id'),
        GREATEST(COALESCE((SELECT MAX(id) FROM users), 1), 1),
        true
    );
    `)
	if err != nil {
		log.Fatal(err)
	}

	log.Println("Подключение к БД успешно")
}