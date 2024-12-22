from kivy.lang import Builder
from kivy.uix.boxlayout import BoxLayout
from kivy.core.window import Window
from kivy.app import App
from kivy.uix.videoplayer import VideoPlayer

KV = """
BoxLayout:
    orientation: 'vertical'

    VideoPlayer:
        id: video_player
        source: 'http://ibrahimiptv.com:1935/mpltv/mpltv/playlist.m3u8'
        state: 'play'
        options: {'allow_stretch': True}
        allow_fullscreen: True
"""

class VideoApp(App):
    def build(self):
        return Builder.load_string(KV)

if __name__ == "__main__":
    VideoApp().run()
