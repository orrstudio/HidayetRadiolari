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
        
        try:
            if platform.system() == 'Android':
                # Используем pyjnius для открытия URL в Android
                from jnius import autoclass
                PythonActivity = autoclass('org.kivy.android.PythonActivity')
                Intent = autoclass('android.content.Intent')
                Uri = autoclass('android.net.Uri')
                
                intent = Intent(Intent.ACTION_VIEW)
                intent.setData(Uri.parse(url))
                current_activity = PythonActivity.mActivity
                current_activity.startActivity(intent)
            elif platform.system() == 'Darwin':  # macOS
                import subprocess
                subprocess.call(['open', url])
            elif platform.system() == 'Windows':
                import os
                os.startfile(url)
            else:  # Linux
                webbrowser.open(url)
        except Exception as e:
            print(f"Не удалось открыть URL: {e}")

def main():
    WebViewApp().run()

if __name__ == '__main__':
    main()