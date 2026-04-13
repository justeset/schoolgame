from fastapi import FastAPI
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["POST"],
    allow_headers=["*"],
)

class CodeRequest(BaseModel):
    code: str

# Тесты
tests = [
    ([5, 2, 8, 1, 9], [9, 8, 5, 2, 1]),
    ([10, 7, 5, 3, 1], [10, 7, 5, 3, 1]),
    ([4, 2, 4, 1, 2], [4, 4, 2, 2, 1]),
    ([], []),
    ([1], [1]),
    ([3, 2, 1], [3, 2, 1]),
]

@app.post("/check")
def check_code(data: CodeRequest):
    namespace = {}
    try:
        exec(data.code, namespace)

        if "bubble_sort" not in namespace:
            return {
                "success": False,
                "test_number": None,
                "feedback": {
                    "type": "error",
                    "title": "Функция не найдена",
                    "explanation": "Ты забыл создать функцию с именем bubble_sort.",
                    "hint": "Начни с def bubble_sort(arr):",
                    "encouragement": "Не переживай, это распространённая ошибка в начале!"
                }
            }

        bubble_sort = namespace["bubble_sort"]
        passed = 0

        for idx, (input_data, expected) in enumerate(tests, 1):
            test_input = input_data.copy()
            try:
                result = bubble_sort(test_input)

                if result != expected:
                    return {
                        "success": False,
                        "test_number": idx,
                        "feedback": {
                            "type": "warning",
                            "title": f"Ошибка на тесте №{idx}",
                            "explanation": f"Функция вернула {result}, хотя ожидался результат {expected}.",
                            "hint": "Проверь условие сравнения. Для сортировки по убыванию нужно менять элементы, если левый меньше правого.",
                            "encouragement": "Хорошая попытка! Ты уже близко."
                        }
                    }
                passed += 1
            except Exception as e:
                return {
                    "success": False,
                    "test_number": idx,
                    "feedback": {
                        "type": "error",
                        "title": f"Ошибка выполнения на тесте №{idx}",
                        "explanation": str(e),
                        "hint": "Убедись, что функция правильно обрабатывает входной массив.",
                        "encouragement": "Давай разберёмся вместе!"
                    }
                }

        return {
            "success": True,
            "passed_tests": passed,
            "total_tests": len(tests),
            "feedback": {
                "type": "success",
                "title": "Отлично! Все тесты пройдены",
                "explanation": "Ты правильно реализовал сортировку пузырьком по убыванию.",
                "hint": "Теперь попробуй оптимизировать алгоритм, добавив флаг swapped.",
                "encouragement": "Ты молодец! Это важный шаг в понимании алгоритмов."
            }
        }

    except Exception as e:
        return {
            "success": False,
            "feedback": {
                "type": "error",
                "title": "Ошибка в коде",
                "explanation": str(e),
                "hint": "Проверь синтаксис и названия переменных.",
                "encouragement": "Каждая ошибка — это возможность научиться."
            }
        }