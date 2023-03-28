from selenium.webdriver.common.keys import Keys
from datetime import datetime

import re

class form_base:
    def __init__(self, _driver, _data, _mode):
        self.driver = _driver
        self.data = _data
        self.collect_mode = _mode
        self.entry_url = None

    def set_value(self, key, val):
        elem = self.driver.find_element("xpath", key)
        if not elem:
            print('WARNING: element is not found.')
            return
        try:
            elem.clear()
            elem.send_keys(val)
        except Exception as e:
            print(str(e))
            print('%% Failed, please input manually.')

    def set_value_list(self, key, val):
        elem = self.driver.find_element("xpath", key)
        if not elem:
            print('WARNING: element is not found.')
            return
        try:
            elem.send_keys(val)
            elem.send_keys(Keys.RETURN)
        except Exception as e:
            print(str(e))
            print('%% Failed, please input manually.')

    def check_button(self, key):
        elem = self.driver.find_element("xpath", key)
        if not elem:
            print('WARNING: element is not found.')
            return
        try:
            elem.click()
        except Exception as e:
            print(str(e))
            print('%% Failed, please input manually.')

    def get_country_code(self, country):
        if country == 'UK':
            return 'England'
        else:
            return country
        
    # find two dates form the string
    def get_date_range(self, dates):
        ss = re.findall('(\d\d?\/)?\d\d?\/20\d\d', dates)
        now = datetime.now()
        if len(ss) >= 2:
            return ss[0], ss[1]
        elif len(ss) == 1:
            return ss[0], now.strftime("%d/%m/%Y")
        elif len(ss) == 0:
            return now.strftime("%d/%m/%Y"), now.strftime("%d/%m/%Y")