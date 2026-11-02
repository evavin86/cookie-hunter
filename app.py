import time
import cv2
import mss
import numpy as np
import pyautogui
from ultralytics import YOLO


class Upgrade:
    """Класс для распознавания объектов на экране (печенька, улучшения) с помощью YOLO."""

    def __init__(self, model_path: str, confidence_threshold: float = 0.7):
        self.model = YOLO(model_path)
        self.confidence_threshold = confidence_threshold
        
        # TODO: Проверьте индексы классов вашей обученной модели!
        # Обычно они идут в алфавитном порядке или в порядке разметки.
        # Например: 0 — 'cookie' (печенька), 1 — 'upgrade' (улучшение/здание)
        self.COOKIE_CLASS_ID = 0  
        self.UPGRADE_CLASS_ID = 1  

    def _find_object_by_class(self, screenshot_bgr: np.ndarray, class_id: int):
        """Внутренний метод для поиска объекта конкретного класса."""
        results = self.model(screenshot_bgr, verbose=False)

        for result in results:
            for box in result.boxes:
                # Получаем ID класса, уверенность и координаты
                current_class_id = int(box.cls[0])
                confidence = float(box.conf)

                if current_class_id == class_id and confidence > self.confidence_threshold:
                    x1, y1, x2, y2 = box.xyxy.tolist()[0]
                    # Вычисляем центр объекта
                    center_x = int((x1 + x2) / 2)
                    center_y = int((y1 + y2) / 2)
                    return center_x, center_y
        return None

    def find_cookie(self, screenshot_bgr: np.ndarray):
        """Ищет большую печеньку для кликов."""
        return self._find_object_by_class(screenshot_bgr, self.COOKIE_CLASS_ID)

    def find_upgrade(self, screenshot_bgr: np.ndarray):
        """Ищет доступные улучшения или постройки."""
        return self._find_object_by_class(screenshot_bgr, self.UPGRADE_CLASS_ID)


class Game:
    """Класс управления игровым процессом и распределения приоритетов кликов."""

    def __init__(self, model_path: str):
        self.upgrade_detector = Upgrade(model_path)
        self.sct = mss.mss()
        self.monitor = self.sct.monitors[1]  # Основной монитор

    def take_screenshot(self) -> np.ndarray:
        """Быстрый захват экрана."""
        sct_img = self.sct.grab(self.monitor)
        frame = np.array(sct_img)
        return cv2.cvtColor(frame, cv2.COLOR_BGRA2BGR)

    def click_target(self, x: int, y: int, clicks_count: int = 1, delay: float = 0.01):
        """Выполняет клики по координатам."""
        for _ in range(clicks_count):
            pyautogui.click(x, y)
            if delay > 0:
                time.sleep(delay)

    def run(self):
        print("Бот вайбится и начинает играть...")
        try:
            while True:
                screenshot = self.take_screenshot()

                # ПРИОРИТЕТ 1: Проверяем, появилось ли улучшение, которое можно купить
                upgrade_coords = self.upgrade_detector.find_upgrade(screenshot)
                if upgrade_coords:
                    x, y = upgrade_coords
                    print(f"Покупаем улучшение в координатах: ({x}, {y})")
                    self.click_target(x, y, clicks_count=1)
               
                    

                # ПРИОРИТЕТ 2: Если улучшений нет, яростно кликаем по печеньке
                cookie_coords = self.upgrade_detector.find_cookie(screenshot)
                if cookie_coords:
                    x, y = cookie_coords
                    # Кликаем по печеньке пачкой по 10 кликов за цикл для скорости
                    self.click_target(x, y, clicks_count=10, delay=0.005)
               
                    time.sleep(0.5)

        except KeyboardInterrupt:
            print("\nБот успешно остановлен.")
        finally:
            self.sct.close()


if __name__ == "__main__":
    MODEL_PATH = "best.pt"
    game_bot = Game(model_path=MODEL_PATH)
    game_bot.run()