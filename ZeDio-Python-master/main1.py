from datetime import datetime
from kivy import Config
from kivy.core.window import Window
from kivy.metrics import dp
from kivymd.app import MDApp
from kivymd.uix.button import MDIconButton
from kivymd.uix.datatables import MDDataTable
from kivymd.uix.gridlayout import MDGridLayout
from kivymd.uix.label import MDLabel
from kivy.uix.image import AsyncImage
from kivy.uix.anchorlayout import AnchorLayout
from kivy.utils import platform
import os
from kivy.resources import resource_find, resource_add_path

def radio_list():
    return [
        ("1", "Radio Record", "Dance", "RU", "https://radiorecord.hostingradio.ru/rr_main96.aacp", ""),
        ("2", "Record Deep", "Deep House", "RU", "https://radiorecord.hostingradio.ru/deep96.aacp", ""),
        ("3", "Record Chill-Out", "Chill", "RU", "https://radiorecord.hostingradio.ru/chil96.aacp", ""),
        ("4", "Record Remix", "Remix", "RU", "https://radiorecord.hostingradio.ru/rmx96.aacp", ""),
        ("5", "Lofi Girl", "Lo-Fi", "EN", "https://play.streamafrica.net/lofiradio", "")
    ]


class Radio:
    def __init__(self, url, name, record=False):
        self.url = url
        self.name = name
        if platform == 'android':
            from jnius import autoclass
            ExoPlayer = autoclass('com.google.android.exoplayer2.SimpleExoPlayer')
            DefaultDataSourceFactory = autoclass('com.google.android.exoplayer2.upstream.DefaultDataSourceFactory')
            MediaItem = autoclass('com.google.android.exoplayer2.MediaItem')
            
            self.context = autoclass('org.kivy.android.PythonActivity').mActivity
            self.player = ExoPlayer(self.context)
            self.data_source_factory = DefaultDataSourceFactory(self.context, "HidayetRadiolari")
            
            self.media_item = MediaItem.fromUri(self.url)
            self.player.setMediaItem(self.media_item)
            self.player.prepare()
        else:
            import vlc
            self.__instance = vlc.Instance()
            self.__player = self.__instance.media_player_new()
            self.__media = None

    def radio_start(self):
        if platform == 'android':
            if hasattr(self, 'player'):
                self.player.play()
        else:
            self.__media = self.__instance.media_new(self.url)
            self.__player.set_media(self.__media)
            self.__player.play()

    def radio_stop(self):
        if platform == 'android':
            if hasattr(self, 'player'):
                self.player.stop()
                self.player.release()
                self.player = None
        else:
            self.__player.stop()

    def __del__(self):
        if platform == 'android':
            if hasattr(self, 'player') and self.player:
                self.player.release()
                self.player = None
        else:
            self.__player.stop()


class MainLayout(MDGridLayout):

    def __init__(self, **kwargs):
        super(MainLayout, self).__init__(**kwargs)
        
        if platform == 'android':
            width = Window.width
            height = Window.height
        else:
            width = 600
            height = 760
            
        self.data_tables = MDDataTable(
            padding=10,
            size_hint=(1, 0.9),  
            width=width,
            height=height * 0.9,  
            use_pagination=True,
            rows_num=10,
            background_color_header="#1a1a1a",
            background_color_cell="#2d2d2d",
            background_color_selected_cell="#2d2d2d",
            column_data=[
                ("", dp(5)),
                ("", width - dp(25)),  
            ],
            row_data=[
                [
                    i[0],
                    ("play", [39 / 256, 174 / 256, 96 / 256, 1], i[1]),
                ] for i in radio_list()]
        )
        self.radio_play_id = []
        self.cols = 1
        self.spacing = dp(10)  
        self.padding = dp(10)  
        
        self.topWindow = MDGridLayout(
            cols=1,
            size_hint=(1, 0.1),  
            spacing=dp(5),
            padding=dp(5)
        )
        self.topWindow.add_widget(self.new_top())
        self.add_widget(self.topWindow)
        self.table()

    def table(self):
        self.add_widget(self.data_tables)
        self.data_tables.bind(on_row_press=self.play_radio)

    def new_top(self, color=None):
        new_top = MDGridLayout(
            cols=3,
            size_hint=(1, 1),
            spacing=dp(5),
            padding=dp(5)
        )
        new_top.md_bg_color = "#2d2d2d"

        if not self.radio_play_id:
            return new_top

        if len(self.radio_play_id) > 5 and self.radio_play_id[5]:
            new_top.add_widget(AsyncImage(
                source=self.radio_play_id[5]
            ))
        else:
            new_top.add_widget(MDLabel(text=""))

        new_top.add_widget(MDLabel(
            text="%s " % self.radio_play_id[1],
            theme_text_color="Custom",
            halign="right",
            text_color=[1, 1, 1, 1],
            font_style="H5",
            bold=True
        ))

        new_top.add_widget(MDIconButton(
            icon="stop",
            user_font_size="48sp",
            theme_text_color="Custom",
            text_color=[1, 1, 1, 1],
            on_press=self.stop_radio)
        )

        return new_top

    def play_radio(self, instance_table, instance_row):
        if not instance_row.selected:
            self.radio_play_id = []
            return
        
        self.radio_play_id = instance_row.text
        
        if hasattr(self, 'radio'):
            self.radio.radio_stop()
                
        self.topWindow.clear_widgets()
        self.topWindow.add_widget(self.new_top())
        
        # Временно отключаем воспроизведение для проверки
        print(f"Выбрана радиостанция: {self.radio_play_id[1]}")
        # self.radio = Radio(url, self.radio_play_id[1])
        # self.radio.radio_start()

    def stop_radio(self, obj):
        if self.radio_play_id:
            self.radio.radio_stop()
            self.radio_play_id = None
            self.topWindow.clear_widgets()
            self.topWindow.add_widget(self.new_top())


class RadioKivy(MDApp):
    if not platform == 'android':
        Window.size = (600, 760)

    def build(self):
        self.theme_cls.theme_style = "Dark"
        self.theme_cls.primary_palette = "Gray"
        return MainLayout()


if __name__ == '__main__':
    RadioKivy().run()
