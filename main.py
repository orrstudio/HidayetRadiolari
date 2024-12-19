import kivy
from kivy.app import App
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.button import Button
from kivy.uix.videoplayer import VideoPlayer
import vlc

class HLSPlayer(BoxLayout):
    def __init__(self, **kwargs):
        super(HLSPlayer, self).__init__(**kwargs)
        self.orientation = 'vertical'

        self.video_player = VideoPlayer(source='http://ibrahimiptv.com:1935/mpltv/mpltv/playlist.m3u8', state='play')
        self.add_widget(self.video_player)

        self.play_button = Button(text='Play', size_hint=(1, 0.1))
        self.play_button.bind(on_press=self.play_video)
        self.add_widget(self.play_button)

        self.pause_button = Button(text='Pause', size_hint=(1, 0.1))
        self.pause_button.bind(on_press=self.pause_video)
        self.add_widget(self.pause_button)

    def play_video(self, instance):
        self.video_player.state = 'play'

    def pause_video(self, instance):
        self.video_player.state = 'pause'

class HLSPlayerApp(App):
    def build(self):
        return HLSPlayer()

if __name__ == '__main__':
    HLSPlayerApp().run()