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
    task_id: str | None = None   # "bubble_sort", "remove_duplicates", "binary_search", "count_orders"


# ====================== ТЕСТЫ ======================
TESTS = {
    "bubble_sort": [
        ([5, 2, 8, 1, 9], [9, 8, 5, 2, 1]),
        ([10, 7, 5, 3, 1], [10, 7, 5, 3, 1]),
        ([4, 2, 4, 1, 2], [4, 4, 2, 2, 1]),
        ([], []),
        ([1], [1]),
        ([3, 3, 3, 3], [3, 3, 3, 3]),
        ([1, 2, 3, 4, 5], [5, 4, 3, 2, 1]),
    ],

    "remove_duplicates": [
        ([1, 2, 2, 3, 4, 4, 5], [1, 2, 3, 4, 5]),
        (["a", "b", "a", "c", "b"], ["a", "b", "c"]),
        ([], []),
        ([42], [42]),
        ([1, 1, 1, 1], [1]),
        (["apple", "banana", "apple", "cherry"], ["apple", "banana", "cherry"]),
    ],

    "binary_search": [
        ((["apple", "banana", "cherry", "date", "elderberry"], "cherry"), 2),
        ((["apple", "banana", "cherry", "date", "elderberry"], "apple"), 0),
        ((["apple", "banana", "cherry", "date", "elderberry"], "elderberry"), 4),
        ((["apple", "banana", "cherry", "date", "elderberry"], "grape"), -1),
        (([], "anything"), -1),
        ((["only"], "only"), 0),
        ((["a", "b", "c", "d"], "b"), 1),
        ((["a", "b", "c", "d"], "d"), 3),
    ],

    "count_orders": [
        (["latte", "espresso", "latte", "cappuccino", "espresso", "latte"],
         {"latte": 3, "espresso": 2, "cappuccino": 1}),
        (["tea"], {"tea": 1}),
        ([], {}),
        (["a", "b", "a", "b", "a"], {"a": 3, "b": 2}),
        (["cola", "cola", "water", "cola", "juice", "water"],
         {"cola": 3, "water": 2, "juice": 1}),
        (["same", "same", "same"], {"same": 3}),
    ],
}

# Соответствие task_id → имя функции в коде пользователя
FUNCTION_NAMES = {
    "bubble_sort": "bubble_sort",
    "remove_duplicates": "remove_duplicates_preserve_order",
    "binary_search": "find_book_index",
    "count_orders": "count_orders",
}

def _detect_task_id(namespace: dict) -> str | None:
    detected: list[str] = []
    for task_id, function_name in FUNCTION_NAMES.items():
        if function_name in namespace and callable(namespace[function_name]):
            detected.append(task_id)
    if len(detected) == 1:
        return detected[0]
    return None


@app.post("/check")
def check_code(data: CodeRequest):
    namespace = {}
    try:
        exec(data.code, namespace)
    except Exception as e:
        return {
            "success": False,
            "feedback": {
                "type": "error",
                "title": "Ошибка в коде",
                "explanation": str(e),
                "hint": "Проверь синтаксис и отступы.",
            }
        }

    requested_task_id = (data.task_id or "").strip()
    resolved_task_id = ""

    if requested_task_id in TESTS:
        resolved_task_id = requested_task_id
    else:
        detected_task_id = _detect_task_id(namespace)
        if detected_task_id is None:
            return {
                "success": False,
                "feedback": {
                    "type": "error",
                    "title": "Неизвестное задание",
                    "explanation": f"Не удалось определить задание по task_id={requested_task_id!r} и коду.",
                    "hint": "Передай корректный task_id или объяви одну из функций: bubble_sort, remove_duplicates_preserve_order, find_book_index, count_orders.",
                }
            }
        resolved_task_id = detected_task_id

    func_name = FUNCTION_NAMES[resolved_task_id]
    if func_name not in namespace:
        detected_task_id = _detect_task_id(namespace)
        if detected_task_id is not None:
            resolved_task_id = detected_task_id
            func_name = FUNCTION_NAMES[resolved_task_id]
        else:
            return {
                "success": False,
                "feedback": {
                    "type": "error",
                    "title": "Функция не найдена",
                    "explanation": f"Создай функцию с именем `{func_name}`.",
                    "hint": f"Начни с: def {func_name}(...):",
                }
            }

    func = namespace[func_name]
    tests = TESTS[resolved_task_id]
    passed = 0

    for idx, test in enumerate(tests, 1):
        input_data, expected = test
        try:
            # Особая обработка для binary_search (передаём несколько аргументов)
            if resolved_task_id == "binary_search":
                result = func(*input_data)
            else:
                # Для списков делаем копию, чтобы функция не мутировала оригинал
                if isinstance(input_data, list):
                    result = func(input_data.copy())
                else:
                    result = func(input_data)

            if result != expected:
                return {
                    "success": False,
                    "test_number": idx,
                    "feedback": {
                        "type": "warning",
                        "title": f"Ошибка на тесте №{idx}",
                        "explanation": f"Получили: {result}\nОжидали: {expected}",
                        "hint": "Проверь логику сортировки / поиска / подсчёта.",
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
                    "hint": "Проверь, что функция корректно обрабатывает входные данные.",
                }
            }

    return {
        "success": True,
        "resolved_task_id": resolved_task_id,
        "passed_tests": passed,
        "total_tests": len(tests),
        "feedback": {
            "type": "success",
            "title": "Отлично! Все тесты пройдены",
            "explanation": f"Пройдено {passed}/{len(tests)} тестов.",
            "hint": "",
        }
    }