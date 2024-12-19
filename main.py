from kivy.app import App
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.button import Button
from kivy.uix.label import Label
from kivy.uix.textinput import TextInput
from kivy.uix.video import Video

class HLSPlayerApp(App):
    def build(self):
        self.stream_url = 'http://ibrahimiptv.com:1935/abraham/abraham/playlist.m3u8'
        
        self.layout = BoxLayout(orientation='vertical')
        
        self.url_input = TextInput(hint_text='Введите URL HLS потока')
        self.layout.add_widget(self.url_input)
        
        self.play_button = Button(text='Воспроизвести')
        self.play_button.bind(on_press=self.play_stream)
        self.layout.add_widget(self.play_button)
        
        self.video = Video()
        self.layout.add_widget(self.video)
        
        return self.layout

    def play_stream(self, instance):
        self.stream_url = self.url_input.text
        if self.stream_url:
            self.video.source = self.stream_url
            self.video.state = 'play'
        else:
            self.layout.add_widget(Label(text='Введите правильный URL!'))

if __name__ == '__main__':
    HLSPlayerApp().run()