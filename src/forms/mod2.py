from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.by import By

from .base import form_base
from getpass import getpass

import os
import re

class mod2(form_base):
    
    def __init__(self, _driver, _data, _mode):
        super(mod2, self).__init__(_driver, _data, _mode)
        self.manage_applications_url = None
        self.main_application_handle = None
        self.entry_url = 'https://applyonline.unsw.edu.au/agent-login'

    def create_profile(self):
        pass

    def login_session(self):
        students = self.data
        driver = self.driver
        
        if not re.search('https://applyonline.unsw.edu.au/agent/homepage', driver.current_url):
            username = os.getenv('NSW_USER', '')
            password = os.getenv('NSW_PASS', '')
            if not username:
                username = input('Username: ')
                password = getpass()

            driver.get(self.entry_url)

            wait = WebDriverWait(driver, 100)
            wait.until(EC.presence_of_element_located((By.TAG_NAME, "body")))

            self.check_button('//*[@id="login"]/div/form/div[1]/span/span[1]/span/span[2]')
            self.set_value_list('/html/body/span/span/span[1]/input', 'Shinyway Sydney')
            self.set_value('//*[@id="_email"]', username)
            self.set_value('//*[@id="_password"]', password)
            self.check_button('//*[@id="login"]/div/form/p[1]/input')
            self.check_button('//*[@id="loginButtonAgent"]')

        self.manage_applications_url = driver.current_url
        self.main_application_handle = driver.current_window_handle
        return self.main_application_handle
    

    def fill_personal_info(self):
        pass

    def fill_scholarships(self):
        pass
    
    def fill_your_qualifications(self):
        pass

    def fill_further_references(self):
        pass

    def fill_form(self):        
        return True

    def new_application(self):
        driver = self.driver
        students = self.data

        driver.close()
        driver.switch_to.window(self.main_application_handle)
        driver.get(self.manage_applications_url)
        students.pop()
        if not len(students):
            print('Congrats, you finished processing. ')
            return False

        print('Now processing: ', students[-1][0])
        return True

    def search_course(self):
        students = self.data
        df_application = students[-1][2]
        course_applied = df_application[df_application['Proposed School'] == 'USYD']['Proposed Course with Corresponding Links'].tolist()[0]
        course = '//*[contains(@id,"POP_UDEF") and contains(@id,"POP.MENSYS.1-1")]'
        self.set_value(course, course_applied)
        #view_report = '/html/body/div[1]/form/div[3]/div/div/div[2]/div[3]/div/input[2]'
        #driver.find_element("xpath", view_report).click()
        return

    def run(self):
        if self.collect_mode:
            self.collect_info()
            return
        
        students = self.data
        if not len(students):
            print('no more studnets to process.')
            return
        
        wait = WebDriverWait(self.driver, 10)
        wait.until(EC.presence_of_element_located((By.TAG_NAME, "body")))
        url = self.driver.current_url
    