from selenium import webdriver
from selenium.webdriver.chrome.options import Options

from selenium.webdriver import Firefox, FirefoxOptions
from threading import Lock

from pynput.mouse import Listener as MouseListener
from pynput.keyboard import Listener as KeyboardListener

from etl import load
from forms.mod1 import mod1
from forms.mod2 import mod2

import os
import fire
import subprocess
import socket
import time
import sys

lock = Lock()
is_win = (True if os.name == 'nt' else False)
main_application_handle = None
module = None
driver = None
run_mode = 0

def on_click(x, y, button, pressed):
    global main_application_handle
    global driver
    with lock:
        if (button.name == 'right'):
            print('quitting')
            quit()

        if (len(driver.window_handles) == 2) and (not pressed) and (driver.current_window_handle == main_application_handle):
            driver.switch_to.window(driver.window_handles[0] if driver.window_handles[0] != main_application_handle else driver.window_handles[1])
            print('switch main window..........................')

        if (button.name != 'middle') or pressed:
            return
        
        try:
            module.run()
        except Exception as e:
            print(str(e))
            print('%% Failed, please input manually.')


def run(dir = ('C:\\work\\data\\13. 懿心ONE Bonnie' if is_win else '/home/hmei/data/13. 懿心ONE Bonnie'), uni = 'usyd', mode = 0):

    global main_application_handle
    global module
    global driver
    global run_mode

    run_mode = mode

    if is_win:
        server_address = ('127.0.0.1', 9222)
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        try:
            sock.connect(server_address)
        except:    
            print(' start the browser ... ')
            cmd = ['C:\Program Files (x86)\Google\Chrome\Application\chrome.exe', '--remote-debugging-port=9222', '--user-data-dir=C:\selenium\ChromeProfile']
            subprocess.Popen(cmd)
        finally:
            sock.close()
        
        chrome_options = Options()
        chrome_options.add_experimental_option("debuggerAddress", "127.0.0.1:9222")
        driver = webdriver.Chrome(chrome_options=chrome_options)
        #driver = webdriver.Chrome()
    else:
        options = FirefoxOptions()
        options.set_preference("network.protocol-handler.external-default", False)
        options.set_preference("network.protocol-handler.expose-all", True)
        options.set_preference("network.protocol-handler.warn-external-default", False)
        driver = Firefox(options=options)

    students = []
    if not run_mode:
        students = load(dir)
        #print(students)

    if uni == 'usyd':
        module = mod1(driver, students, run_mode)
    elif uni == 'unsw':
        module = mod2(driver, students, run_mode)
    else:
        print('uni not yet supported, exit.')
        return

    main_application_handle = module.login_session()
    try:
        mouse_listener = MouseListener(on_click=on_click)
        mouse_listener.start()

        # do this idle loop
        while True:
            time.sleep(10)
    except:
        print('failing exit')
    finally:
        mouse_listener.stop()

if __name__ == '__main__':
    fire.Fire(run)
