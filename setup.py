from setuptools import setup, find_packages

setup(
    name='HidayetRadiolari',
    version='1.0',
    packages=find_packages(),
    install_requires=[
        'kivy==2.3.0',
        'kivymd==1.2.0',
        'requests==2.32.3',
        'pyjnius==1.5.0',
        'plyer==2.1.0',
    ],
    entry_points={
        'console_scripts': [
            'hidayetradiolari=main:main',
        ],
    },
)
