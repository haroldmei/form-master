from selenium import webdriver
from selenium.webdriver.chrome.service import Service

from selenium.webdriver import Firefox, FirefoxOptions
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.by import By
from threading import Lock

from pynput.mouse import Listener
from glob import glob

from etl import load
from forms.mod1 import mod1

import os
import re
import time
import fire

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


def run(dir = ('C:\\work\\data\\13. 懿心ONE Bonnie' if is_win else '/home/hmei/data/13. 懿心ONE Bonnie'), mode = 0):
    from getpass import getpass
    global main_application_handle
    global module
    global driver
    global run_mode

    run_mode = mode
    
    username = os.getenv('SYD_USER', '')
    password = os.getenv('SYD_PASS', '')
    if not username:
        username = input('Username: ')
        password = getpass()

    if is_win:
        driver = webdriver.Chrome()
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

    module = mod1(driver, students, run_mode)
    main_application_handle = module.login_session(username, password)
    try:
        with Listener(on_click=on_click) as listener:
            listener.join()
    except:
        print('failing exit')

if __name__ == '__main__':
    fire.Fire(run)
