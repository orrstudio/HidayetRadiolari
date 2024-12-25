from kivy.app import App
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.label import Label
from kivy.uix.videoplayer import VideoPlayer
import os

class VideoTestApp(App):
    def build(self):
        layout = BoxLayout(orientation='vertical')
        
        status_label = Label(text='Тест видео')
        layout.add_widget(status_label)
        
        try:
            # Путь к локальному файлу
            video_path = 'http://ibrahimiptv.com:1935/mpltv/mpltv/playlist.m3u8'
            print(f"Источник: {video_path}")
            
            video_player = VideoPlayer(
                source=video_path, 
                state='play', 
                options={'allow_stretch': True}
            )
            layout.add_widget(video_player)
            
            status_label.text = 'Видео проигрывается'
        except Exception as e:
            print(f"Полная ошибка: {e}")
            status_label.text = f'Ошибка: {str(e)}'
        
        return layout

if __name__ == '__main__':
    VideoTestApp().run()
