from kivy.app import App
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.button import Button
from kivy.uix.label import Label
from kivy.core.window import Window
from kivy.uix.scrollview import ScrollView
from kivy.uix.widget import Widget
from kivy.uix.video import Video
from kivy.utils import platform
import os

try:
    if platform == 'android':
        from jnius import autoclass
        MediaPlayer = autoclass('android.media.MediaPlayer')
        Surface = autoclass('android.view.Surface')
        TextureView = autoclass('android.view.TextureView')
except Exception as e:
    print(f"Ошибка импорта Android компонентов: {e}")

class HidayetPlayerApp(App):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.tv_channels = {
            'MPL TV': 'http://ibrahimiptv.com:1935/mpltv/mpltv/playlist.m3u8',
            'NUR TV': 'http://ibrahimiptv.com:1935/nurtv/nurtv/playlist.m3u8',
            'HERAN KURAN HERAN MUTLULUK': 'http://ibrahimiptv.com:1935/herankuran/herankuran/playlist.m3u8',
            'HERAN KURAN HERAN ZİKİR': 'http://ibrahimiptv.com:1935/heranzikir/heranzikir/playlist.m3u8',
            'KURAN LAFZI VE 7 RUHU': 'http://ibrahimiptv.com:1935/kuran/kuran/playlist.m3u8',
            'İBRAHİM TV ALMANCA': 'http://ibrahimiptv.com:1935/abraham/abraham/playlist.m3u8',
            'İBRAHİM TV İNGİLİZCE': 'http://ibrahimiptv.com:1935/hak_en/hak_en/playlist.m3u8',
            'İBRAHİM TV RUSÇA': 'http://ibrahimiptv.com:1935/hak_ru/hak_ru/playlist.m3u8',
            'İBRAHİM TV ARAPÇA': 'http://ibrahimiptv.com:1935/hak_ar/hak_ar/playlist.m3u8',
            'İBRAHİM TV KÜRTÇE': 'http://ibrahimiptv.com:1935/hak_kr/hak_kr/playlist.m3u8',
            'İBRAHİM TV FRANSIZCA': 'http://ibrahimiptv.com:1935/hak_fr/hak_fr/playlist.m3u8',
            'İBRAHİM TV İSPANYOLCA': 'http://ibrahimiptv.com:1935/hak_es/hak_es/playlist.m3u8',
            'İBRAHİM TV ÇİNCE': 'http://ibrahimiptv.com:1935/hak_ch/hak_ch/playlist.m3u8',
            'İBRAHİM TV BULGARCA': 'http://ibrahimiptv.com:1935/hak_bg/hak_bg/playlist.m3u8',
            'İBRAHİM TV FLEMENKÇE': 'http://ibrahimiptv.com:1935/hak_ne/hak_ne/playlist.m3u8',
            'İBRAHİM TV FARSÇA': 'http://ibrahimiptv.com:1935/hak_fa/hak_fa/playlist.m3u8',
        }
        self.current_player = None
        if platform == 'android':
            self.media_player = None

    def build(self):
        Window.clearcolor = (0.1, 0.1, 0.1, 1)

        # Основной макет - вертикальный
        main_layout = BoxLayout(orientation='vertical')

        # Видео-плеер с фиксированной высотой
        self.video_widget = BoxLayout(size_hint=(1, None), height=450)
        main_layout.add_widget(self.video_widget)

        # Заголовок
        label = Label(
            text='Televizyon Kanalları',
            size_hint=(1, None),
            height=50,
            color=(1, 1, 1, 1)
        )
        main_layout.add_widget(label)

        # Создаем скролл для кнопок
        scroll = ScrollView(size_hint=(1, 1))
        buttons_layout = BoxLayout(orientation='vertical', size_hint=(1, None))
        buttons_layout.bind(minimum_height=buttons_layout.setter('height'))

        # Добавляем кнопки для каждого канала
        for channel_name, url in self.tv_channels.items():
            btn = Button(
                text=channel_name,
                size_hint=(1, None),
                height=60,
                background_color=(0.2, 0.2, 0.2, 1)
            )
            btn.bind(on_press=lambda btn, url=url: self.play_stream(url))
            buttons_layout.add_widget(btn)

        scroll.add_widget(buttons_layout)
        main_layout.add_widget(scroll)

        # Воспроизводим первый канал по умолчанию
        default_channel = list(self.tv_channels.values())[0]  # Берем URL первого канала
        self.play_stream(default_channel)

        return main_layout

    def stop_current_player(self):
        """Останавливает и удаляет текущий плеер"""
        if platform == 'android':
            if self.media_player:
                try:
                    self.media_player.stop()
                    self.media_player.release()
                    self.media_player = None
                    print("Android MediaPlayer остановлен")
                except Exception as e:
                    print(f"Ошибка при остановке Android MediaPlayer: {e}")
        else:
            if self.current_player:
                try:
                    self.current_player.state = 'stop'
                    self.video_widget.remove_widget(self.current_player)
                    self.current_player = None
                    print("Предыдущий плеер остановлен и удален")
                except Exception as e:
                    print(f"Ошибка при остановке предыдущего плеера: {e}")

    def play_stream(self, url):
        print(f"[DEBUG] Попытка воспроизведения потока: {url}")
        print(f"[DEBUG] Платформа: {platform}")
        try:
            # Останавливаем предыдущий плеер
            print("[DEBUG] Останавливаем предыдущий плеер")
            self.stop_current_player()

            if platform == 'android':
                print("[DEBUG] Инициализация Android MediaPlayer")
                # Создаем новый MediaPlayer для Android
                self.media_player = MediaPlayer()
                print("[DEBUG] MediaPlayer создан")
                print("[DEBUG] Устанавливаем источник данных")
                self.media_player.setDataSource(url)
                print("[DEBUG] Подготовка MediaPlayer")
                self.media_player.prepare()
                print("[DEBUG] MediaPlayer подготовлен")
                print("[DEBUG] Запуск воспроизведения")
                self.media_player.start()
                print("[DEBUG] Android MediaPlayer запущен успешно")
            else:
                # Создаем новый плеер для десктопа
                self.current_player = Video(source=url)
                self.current_player.state = 'play'
                self.current_player.allow_stretch = True
                self.video_widget.add_widget(self.current_player)
                print("Плеер создан и добавлен в интерфейс")

        except Exception as e:
            print(f"Ошибка при воспроизведении: {e}")
            import traceback
            print(traceback.format_exc())

if __name__ == '__main__':
    HidayetPlayerApp().run()