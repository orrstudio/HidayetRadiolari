from kivy.app import App
from kivy.uix.floatlayout import FloatLayout
from kivy.uix.button import Button
from kivy.uix.label import Label
from kivy.uix.image import Image
from jnius import autoclass
from time import sleep

# Список радиостанций
RADIO_STATIONS = {
    "Radyo Nur": "https://canli.hidayetradyolari.com/listen/radyo_nur/radio.mp3",
    "MPL Radyo": "https://canli.hidayetradyolari.com/listen/mpl_radyo/radio.mp3",
}

# Получаем доступ к классам Android
MediaPlayer = autoclass('android.media.MediaPlayer')
PythonActivity = autoclass('org.kivy.android.PythonActivity')


class RadioPlayer(FloatLayout):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        # Фоновое изображение
        self.add_widget(Image(source='images/background.jpg', fit_mode='fill'))

        # Верхний текст состояния
        self.status_label = Label(text="Select a radio station", font_size=20, color=(1, 1, 1, 1),
                                  size_hint=(1, 0.1), pos_hint={"x": 0, "y": 0.85})
        self.add_widget(self.status_label)

        # Контейнер для кнопок
        button_layout = FloatLayout(size_hint=(1, 0.2), pos_hint={"center_x": 0.5, "y": 0.05})
        self.add_widget(button_layout)

        # Создаем кнопки для каждой радиостанции
        button_y_pos = 0.7  # Начальная позиция для кнопок
        for name, url in RADIO_STATIONS.items():
            button = Button(text=name, font_size=18, size_hint=(0.3, 0.2), pos_hint={"center_x": 0.5, "y": button_y_pos})
            button.bind(on_press=self.create_on_press_handler(name, url))
            button_layout.add_widget(button)

            button_y_pos -= 0.25  # Сдвигаем кнопку ниже

        # Инициализация проигрывателя
        self.player = None

    def create_on_press_handler(self, name, url):
        """Создаем обработчик нажатия с правильными параметрами."""
        def on_press(instance):
            self.play_radio(name, url)
        return on_press

    def play_radio(self, name, url):
        # Останавливаем текущий проигрыватель, если есть
        if self.player:
            self.player.stop()

        # Обновляем статус
        self.status_label.text = f"Playing: {name}"

        # Создаем новый плеер для выбранного потока
        self.player = MediaPlayer()
        self.player.setDataSource(url)
        self.player.prepare()  # Подготовка плеера
        self.player.start()    # Запуск воспроизведения

    def stop_radio(self):
        if self.player:
            self.player.stop()
            self.status_label.text = "Select a radio station"


class RadioApp(App):
    def build(self):
        self.title = "Radio Player"
        return RadioPlayer()


if __name__ == "__main__":
    RadioApp().run()

