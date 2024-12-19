from kivy.app import App
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.button import Button
from kivy.uix.label import Label
from kivy.uix.video import Video
from kivy.core.window import Window
from kivy.uix.scrollview import ScrollView

class HidayetPlayerApp(App):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.tv_channels = {
            'MPL TV': 'http://ibrahimiptv.com:1935/mpltv/mpltv/playlist.m3u8',
            'NUR TV': 'http://ibrahimiptv.com:1935/nurtv/nurtv/playlist.m3u8',
            'HERAN KURAN HERAN MUTLULUK': 'http://ibrahimiptv.com:1935/herankuran/herankuran/playlist.m3u8',
            'HERAN KURAN HERAN ZİKİR': 'http://ibrahimiptv.com:1935/heranzikir/heranzikir/playlist.m3u8',
            'KURAN LAFZI VE 7 RUHU': 'http://ibrahimiptv.com:1935/kuran/kuran/playlist.m3u8',
            'ABRAHAM TV ALMANCA': 'http://ibrahimiptv.com:1935/abraham/abraham/playlist.m3u8',
            'ABRAHAM TV İNGİLİZCE': 'http://ibrahimiptv.com:1935/hak_en/hak_en/playlist.m3u8',
            'ABRAHAM TV RUSÇA': 'http://ibrahimiptv.com:1935/hak_ru/hak_ru/playlist.m3u8',
            'ABRAHAM TV ARAPÇA': 'http://ibrahimiptv.com:1935/hak_ar/hak_ar/playlist.m3u8',
            'ABRAHAM TV KÜRTÇE': 'http://ibrahimiptv.com:1935/hak_kr/hak_kr/playlist.m3u8',
            'ABRAHAM TV FRANSIZCA': 'http://ibrahimiptv.com:1935/hak_fr/hak_fr/playlist.m3u8',
            'ABRAHAM TV İSPANYOLCA': 'http://ibrahimiptv.com:1935/hak_es/hak_es/playlist.m3u8',
            'ABRAHAM TV ÇİNCE': 'http://ibrahimiptv.com:1935/hak_ch/hak_ch/playlist.m3u8',
            'ABRAHAM TV BULGARCA': 'http://ibrahimiptv.com:1935/hak_bg/hak_bg/playlist.m3u8',
            'ABRAHAM TV FLEMENKÇE': 'http://ibrahimiptv.com:1935/hak_ne/hak_ne/playlist.m3u8',
            'ABRAHAM TV FARSÇA': 'http://ibrahimiptv.com:1935/hak_fa/hak_fa/playlist.m3u8',
        }

    def build(self):
        Window.clearcolor = (0.1, 0.1, 0.1, 1)
        
        main_layout = BoxLayout(orientation='vertical', spacing=10, padding=20)
        
        # Видео плеер
        self.video = Video(
            source='http://ibrahimiptv.com:1935/mpltv/mpltv/playlist.m3u8',
            state='play'
        )
        main_layout.add_widget(self.video)
        
        # Создаем ScrollView для кнопок
        scroll_view = ScrollView(size_hint=(1, 0.3))
        button_layout = BoxLayout(orientation='vertical', size_hint_y=None)
        button_layout.bind(minimum_height=button_layout.setter('height'))
        
        # Заголовок для TV каналов
        tv_label = Label(text='Televizyon Kanalları', font_size=20, size_hint_y=None, height=50)
        button_layout.add_widget(tv_label)
        
        # Кнопки TV каналов
        for name, url in self.tv_channels.items():
            btn = Button(
                text=name, 
                size_hint_y=None, 
                height=50,
                on_press=lambda x, u=url: self.play_stream(u)
            )
            button_layout.add_widget(btn)
        
        scroll_view.add_widget(button_layout)
        main_layout.add_widget(scroll_view)
        
        return main_layout

    def play_stream(self, url):
        self.video.source = url
        self.video.state = 'play'

if __name__ == '__main__':
    HidayetPlayerApp().run()