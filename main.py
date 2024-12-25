import kivy
kivy.require('2.3.0')

from kivy.app import App
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.label import Label
from kivy.uix.button import Button
import webbrowser
import platform

class WebViewApp(App):
    def build(self):
        layout = BoxLayout(orientation='vertical')
        
        label = Label(text='Hidayet Radiolari', font_size='20sp')
        layout.add_widget(label)
        
        button = Button(
            text='Открыть YouTube', 
            on_press=self.open_url
        )
        layout.add_widget(button)
        
        return layout
    
    def open_url(self, instance):
        url = "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
        
        # Кроссплатформенное открытие URL
        try:
            if platform.system() == 'Darwin':  # macOS
                import subprocess
                subprocess.call(['open', url])
            elif platform.system() == 'Windows':
                import os
                os.startfile(url)
            else:  # Linux, Android
                webbrowser.open(url)
        except Exception as e:
            print(f"Не удалось открыть URL: {e}")

def main():
    WebViewApp().run()

if __name__ == '__main__':
    main()