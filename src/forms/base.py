
class form_base:
    def __init__(self, _driver, _data):
        self.driver = _driver
        self.data = _data

    def set_value(self, key, val):
        self.driver.find_element("xpath", key).clear()
        self.driver.find_element("xpath", key).send_keys(val)

    def get_country_code(self, country):
        if country == 'UK':
            return 'England'
        else:
            return country