from selenium.webdriver.common.keys import Keys

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
        elem.clear()
        elem.send_keys(val)

    def set_value_list(self, key, val):
        elem = self.driver.find_element("xpath", key)
        if not elem:
            print('WARNING: element is not found.')
            return
        elem.send_keys(val)
        elem.send_keys(Keys.RETURN)

    def check_button(self, key):
        elem = self.driver.find_element("xpath", key)
        if not elem:
            print('WARNING: element is not found.')
            return
        elem.click()

    def get_country_code(self, country):
        if country == 'UK':
            return 'England'
        else:
            return country