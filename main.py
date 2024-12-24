import kivy
kivy.require('2.1.0') # Замените на вашу версию Kivy

from kivy.app import App
from kivy.uix.videoplayer import VideoPlayer
from kivy.uix.boxlayout import BoxLayout
import os

os.environ['KIVY_VIDEO'] = 'ffpyplayer' # Указывает Kivy использовать ffpyplayer

class VideoApp(App):
    def build(self):
        layout = BoxLayout(orientation='vertical')
        video = VideoPlayer(source="http://ibrahimiptv.com:1935/mpltv/mpltv/playlist.m3u8", options={'allow_stretch': True})
        layout.add_widget(video)
        return layout

if __name__ == '__main__':
    VideoApp().run()