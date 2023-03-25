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

import os
import re
import time
import fire

## new session global
driver = None 
students = {}
is_win = (True if os.name == 'nt' else False)
default_dir = ('C:\\work\\data\\13. 懿心ONE Bonnie' if is_win else '/home/hmei/data/13. 懿心ONE Bonnie')
manage_applications_url = None
main_application_handle = None

def create_profile():
    global students

    personal_info = students[-1][0]
    
    #print('Now processing: ', personal_info)
    given_name =  '/html/body/div[1]/form/div/div/div/div[2]/div/div/div[1]/div/input'
    set_value(given_name, personal_info['Given Name'])
    
    family_name = '/html/body/div[1]/form/div/div/div/div[2]/div/div/div[2]/div/input'
    set_value(family_name, personal_info['Family Name'])
    
    dob = '/html/body/div[1]/form/div/div/div/div[2]/div/div/div[3]/div/div/input'
    set_value(dob, personal_info['DOB (dd/mm/yyyy)'])
    
    email = '/html/body/div[1]/form/div/div/div/div[2]/div/div/div[4]/div/input'
    set_value(email, personal_info["Student's Email"])
    
    confirmed_email = '/html/body/div[1]/form/div/div/div/div[2]/div/div/div[5]/div/input'
    set_value(confirmed_email, personal_info["Student's Email"])
    
    username = '/html/body/div[1]/form/div/div/div/div[2]/div/div/div[6]/div/input'
    set_value(username, personal_info["Student's Email"])
    
    password = '/html/body/div[1]/form/div/div/div/div[2]/div/div/div[7]/div/input'
    set_value(password, f"a{personal_info['DOB (dd/mm/yyyy)']}") # default use email as username
    
    confirmed_password = '/html/body/div[1]/form/div/div/div/div[2]/div/div/div[8]/div/input'
    set_value(confirmed_password, f"a{personal_info['DOB (dd/mm/yyyy)']}")
    
    tnc = '/html/body/div[1]/form/div/div/div/div[2]/div/div/div[9]/div/label/input[2]'
    driver.find_element("xpath", tnc).click()
    
    acknowledge = '/html/body/div[1]/form/div/div/div/div[2]/div/div/div[10]/div/label/input[2]'
    driver.find_element("xpath", acknowledge).click()

def login_session(user, password):
    global manage_applications_url
    global main_application_handle
    global students
    # user/password
    username_input = '//*[@id="MUA_CODE.DUMMY.MENSYS"]'
    password_input = '//*[@id="PASSWORD.DUMMY.MENSYS"]'
    login_submit = '/html/body/div/form/div[4]/div/div/div[2]/div/fieldset/div[3]/div[1]/div/input'
    set_value(username_input, user)
    set_value(password_input, password)
    driver.find_element("xpath", login_submit).click()
    
    wait = WebDriverWait(driver, 100)
    wait.until(EC.presence_of_element_located((By.TAG_NAME, "body")))
    applications = '/html/body/header/nav/div[2]/ul/li[2]/a/b'
    driver.find_element("xpath", applications).click()
    manage_applications = '//*[@id="APAGN01"]'
    driver.find_element("xpath", manage_applications).click()

    manage_applications_url = driver.current_url
    main_application_handle = driver.current_window_handle
    print('processing info: ', students[-1][0])
    
def set_value(key, val):
    global driver
    driver.find_element("xpath", key).clear()
    driver.find_element("xpath", key).send_keys(val)
    
def fill_personal_info():
    personal_info = students[-1][0]
    title = '/html/body/div[1]/form/div[4]/div[2]/div/div/div[1]/div/div/div/div/input'
    givenname1='/html/body/div[1]/form/div[4]/div[2]/div/div/div[2]/div/div/div[1]/input'
    givenname2='/html/body/div[1]/form/div[4]/div[2]/div/div/div[2]/div/div/div[2]/input'
    givenname3='/html/body/div[1]/form/div[4]/div[2]/div/div/div[2]/div/div/div[3]/input'
    familyname='/html/body/div[1]/form/div[4]/div[2]/div/div/div[3]/div/input'
    akaname=   '/html/body/div[1]/form/div[4]/div[2]/div/div/div[4]/div/input'
    prevname=  '/html/body/div[1]/form/div[4]/div[2]/div/div/div[5]/div/input'
    officialname='/html/body/div[1]/form/div[4]/div[2]/div/div/div[6]/div/input'
    gender = '/html/body/div[1]/form/div[4]/div[2]/div/div/div[7]/div/div/div/div/input'
    dob = '/html/body/div[1]/form/div[4]/div[2]/div/div/div[8]/div/div/input'
    driver.find_element("xpath", title).send_keys('Mr' if personal_info['Gender'] == 'Male' else 'Miss')
    driver.find_element("xpath", title).send_keys(Keys.RETURN)
    set_value(givenname1, personal_info['Given Name'])
    set_value(familyname, personal_info['Family Name'])
    set_value(akaname, personal_info['Given Name'])
    set_value(officialname, personal_info['Given Name'])
    driver.find_element("xpath", gender).send_keys(personal_info['Gender'])
    driver.find_element("xpath", gender).send_keys(Keys.RETURN)
    set_value(dob, personal_info['DOB (dd/mm/yyyy)'])
    
    country =            '/html/body/div[1]/form/div[7]/div[2]/div/div/div[1]/div/div/div/div/input'
    addressline1 =       '/html/body/div[1]/form/div[7]/div[2]/div/div/div[3]/div/input'
    addressline2 =       '/html/body/div[1]/form/div[7]/div[2]/div/div/div[4]/div/input'
    addressline3 =       '/html/body/div[1]/form/div[7]/div[2]/div/div/div[5]/div/input'
    city =               '/html/body/div[1]/form/div[7]/div[2]/div/div/div[6]/div/input'
    province =           '/html/body/div[1]/form/div[7]/div[2]/div/div/div[7]/div/input'
    postcode =           '/html/body/div[1]/form/div[7]/div[2]/div/div/div[8]/div/input'
    check_address_same = '/html/body/div[1]/form/div[7]/div[2]/div/div/div[9]/div[2]/div/label/input'
    driver.find_element("xpath", country).send_keys('China (Excludes SARS and Taiwan)')
    driver.find_element("xpath", country).send_keys(Keys.RETURN)
    set_value(addressline1, personal_info['line1'])
    set_value(addressline2, personal_info['line2'])
    set_value(addressline3, personal_info['line3'])
    set_value(city, personal_info['city'])
    set_value(province, personal_info['province'])
    set_value(postcode, personal_info['Post Code'])
    driver.find_element("xpath", check_address_same).click()
    
    parent_country = '/html/body/div[1]/form/div[8]/div[2]/div/div/div[1]/div/div/div/div/input'
    parent_address1 = '/html/body/div[1]/form/div[8]/div[2]/div/div/div[3]/div/input'
    parent_address2 = '/html/body/div[1]/form/div[8]/div[2]/div/div/div[4]/div/input'
    parent_address3 = '/html/body/div[1]/form/div[8]/div[2]/div/div/div[5]/div/input'
    parent_town = '/html/body/div[1]/form/div[8]/div[2]/div/div/div[6]/div/input'
    parent_state = '/html/body/div[1]/form/div[8]/div[2]/div/div/div[7]/div/input'
    parent_postcode = '/html/body/div[1]/form/div[8]/div[2]/div/div/div[8]/div/input'
    driver.find_element("xpath", parent_country).send_keys('China (Excludes SARS and Taiwan)')
    driver.find_element("xpath", parent_country).send_keys(Keys.RETURN)
    set_value(parent_address1, personal_info['line1'])
    set_value(parent_address2, personal_info['line2'])
    set_value(parent_address3, personal_info['line3'])
    set_value(parent_town, personal_info['city'])
    set_value(parent_state, personal_info['province'])
    set_value(parent_postcode, personal_info['Post Code'])
    
    phone = '/html/body/div[1]/form/div[9]/div[2]/div/div/div[1]/div/input'
    mobile = '/html/body/div[1]/form/div[9]/div[2]/div/div/div[2]/div/input'
    email = '/html/body/div[1]/form/div[9]/div[2]/div/div/div[3]/div/input'
    set_value(phone, personal_info["Student's Tel."])
    set_value(email, personal_info["Student's Email"])
    
    born_country = '/html/body/div[1]/form/div[10]/div[2]/div/div/div[1]/div/div/div/div/input'
    au_citizenship = '/html/body/div[1]/form/div[10]/div[2]/div/div/div[2]/div/div/div/div/input'
    nationality = '/html/body/div[1]/form/div[10]/div[2]/div/div/div[4]/div/div/div/div/input'
    is_aboriginal = '/html/body/div[1]/form/div[10]/div[2]/div/div/div[7]/div/div/div/div/input'
    hometongue = '/html/body/div[1]/form/div[10]/div[2]/div/div/div[8]/div/div/div/div/input'
    driver.find_element("xpath", born_country).send_keys('China (Excludes SARS and Taiwan)')
    driver.find_element("xpath", born_country).send_keys(Keys.RETURN)
    driver.find_element("xpath", au_citizenship).send_keys('Other (non resident)')
    driver.find_element("xpath", au_citizenship).send_keys(Keys.RETURN)
    driver.find_element("xpath", nationality).send_keys('China (Excludes SARS and Taiwan)')
    driver.find_element("xpath", nationality).send_keys(Keys.RETURN)
    driver.find_element("xpath", is_aboriginal).send_keys('Neither Aboriginal nor Torres Strait Islander')
    driver.find_element("xpath", is_aboriginal).send_keys(Keys.RETURN)
    driver.find_element("xpath", hometongue).send_keys('Mandarin')
    driver.find_element("xpath", hometongue).send_keys(Keys.RETURN)
    
    current_at_usyd = '//*[@id="IPQ_APONPAPB"]'
    current_student_usyd = '//*[@id="IPQ_APONLCES1B"]'
    current_enrolled_usyd = '//*[@id="IPQ_APONLCES3B"]'
    fee_waiver = '//*[@id="IPQ_APONLEVV"]'
    driver.find_element("xpath", current_at_usyd).click()
    driver.find_element("xpath", current_student_usyd).click()
    driver.find_element("xpath", current_enrolled_usyd).click()
    driver.find_element("xpath", fee_waiver).click()
    
def fill_scholarships():
    print('>>> scholarship info: ')
    has_scholarship = '//*[@id="IPQ_APONSH13A"]'
    scholarship_name = '//*[@id="IPQ_APONSH14"]'
    no_scholarship = '//*[@id="IPQ_APONSH13B"]'
    driver.find_element("xpath", no_scholarship).click()
    
    applied_scholarship = '//*[@id="IPQ_APONSH15A"]'
    applied_scholarship_name = '//*[@id="IPQ_APONSH16"]'
    no_applied_scholarship = '//*[@id="IPQ_APONSH15B"]'
    driver.find_element("xpath", no_applied_scholarship).click()
    
    #upload docs
    

def fill_your_qualifications():
    qualification = students[-1][1]
    print('>>> qualification info: ', qualification)
    not_first_language = '//*[@id="IPQ_APONEL1B"]'
    driver.find_element("xpath", not_first_language).click()
    
    english_test = False
    taken_english_test = '//*[@id="IPQ_APONEL2A"]'
    no_english_test = '//*[@id="IPQ_APONEL2B"]'
    if english_test:
        driver.find_element("xpath", taken_english_test).click()

        test_type = '/html/body/div[1]/form/div[4]/div[2]/div/div/div[3]/div/div/div/div/input'
        driver.find_element("xpath", test_type).send_keys('IELTS')
        driver.find_element("xpath", test_type).send_keys(Keys.RETURN)

        test_date = '//*[@id="IPQ_APONEL4"]'
        set_value(test_date, '01/Mar/2020')

        overall_score = '//*[@id="IPQ_APONEL5"]'
        driver.find_element("xpath", overall_score).send_keys('7')
        #upload english test result
    else:
        driver.find_element("xpath", no_english_test).click()

        scheduled_test = '//*[@id="IPQ_APONEL10A"]'
        not_scheduled_test = '//*[@id="IPQ_APONEL10B"]'
        driver.find_element("xpath", not_scheduled_test).click()

        tertiary_edu_accessed_in_english = '//*[@id="IPQ_APONEL12A1"]'
        not_tertiary_edu_accessed_in_english = '//*[@id="IPQ_APONEL12A2"]'
        driver.find_element("xpath", not_tertiary_edu_accessed_in_english).click()

        scheduled_test1 = '//*[@id="IPQ_APONEL16A"]'
        not_scheduled_test1 = '//*[@id="IPQ_APONEL16B"]'
        driver.find_element("xpath", not_scheduled_test1).click()

    #record of exclusion
    suspended_course = '//*[@id="IPQ_APONRE1A"]'
    no_suspended_course = '//*[@id="IPQ_APONRE1B"]'
    driver.find_element("xpath", no_suspended_course).click()
    
    asked_cause = '//*[@id="IPQ_APONRE2A"]'
    no_asked_cause = '//*[@id="IPQ_APONRE2B"]'
    driver.find_element("xpath", no_asked_cause).click()
    
    asked_explain = '//*[@id="IPQ_APONRE3A"]'
    no_asked_explain = '//*[@id="IPQ_APONRE3B"]'
    driver.find_element("xpath", no_asked_explain).click()
    
    #upload docs for cause exclusion
    
    #high qualification
    edu_level = '/html/body/div[1]/form/div[8]/div[2]/div/div/div/div/div/div/div/input'
    driver.find_element("xpath", edu_level).send_keys('Secondary Qualification')
    driver.find_element("xpath", edu_level).send_keys(Keys.RETURN)
    
    #upload you docs
    
    # Secondary school studies
    secondary_edu = qualification.loc[0].values.flatten().tolist()
    secondary_qual_name = '//*[@id="IPQ_APONSS1"]'
    set_value(secondary_qual_name, secondary_edu[1])
    secondary_qual_state = '//*[@id="IPQ_APONSS2"]'
    set_value(secondary_qual_state, secondary_edu[3])

    year = re.search('20\d\d', secondary_edu[0])
    if year:
        secondary_qual_year = '/html/body/div[1]/form/div[9]/div[2]/div/div/div[3]/div/div/div/div/input'
        driver.find_element("xpath", secondary_qual_year).send_keys(year.group())
        driver.find_element("xpath", secondary_qual_year).send_keys(Keys.RETURN)

    secondary_qual_score = '//*[@id="IPQ_APMOTHRS"]'
    set_value(secondary_qual_score, secondary_edu[4])

    # Academic school studies
    if False:
        academic_qual_name = ''
        driver.find_element("xpath", academic_qual_name).send_keys('Bachelors degree')
        driver.find_element("xpath", academic_qual_name).send_keys(Keys.RETURN)
        academic_qual_course = ''
        set_value(academic_qual_course, '01/Mar/2020')
        academic_qual_institution = ''
        set_value(academic_qual_institution).send_keys('01/Mar/2020')
        academic_qual_country = ''
        driver.find_element("xpath", academic_qual_name).send_keys('Australia')
        driver.find_element("xpath", academic_qual_name).send_keys(Keys.RETURN)
        academic_qual_start_date = ''
        set_value(academic_qual_start_date, '01/Mar/2020')
        academic_qual_end_date = ''
        set_value(academic_qual_end_date, '01/Mar/2020')
        academic_qual_length = ''
        set_value(academic_qual_length, '01/Mar/2020')
        academic_qual_grade = ''
        set_value(academic_qual_grade, '01/Mar/2020')
        academic_qual_completed = ''
        driver.find_element("xpath", academic_qual_completed).click()
        academic_qual_parttime = ''
        driver.find_element("xpath", academic_qual_parttime).click()


    app_for_cred = '//*[@id="applyForCredit"]'
    no_app_for_cred = '//*[@id="doNotApplyForCredit"]'
    driver.find_element("xpath", no_app_for_cred).click()
    

def fill_further_references():
    print('>>> reference info: ')
    pass


def fill_form():
    app_form = '/html/body/div[1]/form/div[2]/h1'
    title = driver.find_element("xpath", app_form).text
    if title == 'Your personal information':
        fill_personal_info()
    elif title == 'Scholarships':
        fill_scholarships()
    elif title == 'Your qualifications':
        fill_your_qualifications()
    elif title == 'Further references':
        fill_further_references()
        return new_application()
    elif title == 'Declaration':
        print('Please confirm.')
        new_application()
    else:
        pass
    
    return True

def new_application():
    global manage_applications_url
    global main_application_handle

    driver.close()
    driver.switch_to.window(main_application_handle)
    driver.get(manage_applications_url)
    students.pop()
    if not len(students):
        print('Congrats, you finished processing. ')
        return False
    
    print('Now processing: ', students[-1][0])
    return True

def search_course():
    global students

    df_application = students[-1][2]
    course_applied = df_application[df_application['Proposed School'] == 'Sydney']['Proposed Course with Corresponding Links'].tolist()[0]
    course = '//*[contains(@id,"POP_UDEF") and contains(@id,"POP.MENSYS.1-1")]'
    set_value(course, course_applied)

    #view_report = '/html/body/div[1]/form/div[3]/div/div/div[2]/div[3]/div/input[2]'
    #driver.find_element("xpath", view_report).click()

    return

lock = Lock()
def on_click(x, y, button, pressed):
    global main_application_handle
    global driver
    with lock:
        if (len(driver.window_handles) == 2) and (not pressed) and (driver.current_window_handle == main_application_handle):
            driver.switch_to.window(driver.window_handles[0] if driver.window_handles[0] != main_application_handle else driver.window_handles[1])
            print('switch main window..........................')

        if (button.name != 'middle') or pressed:
            return
        
        if not len(students):
            print('no more studnets to process.')
            return
        
        wait = WebDriverWait(driver, 10)
        wait.until(EC.presence_of_element_located((By.TAG_NAME, "body")))
        url = driver.current_url

        if re.search('https://sydneystudent.sydney.edu.au/sitsvision/wrd/siw_ipp_cgi.start?', url):
            fill_form()

        elif re.search('https://sydneystudent.sydney.edu.au/sitsvision/wrd/SIW_POD.start_url?.+', url):
            search_course()

        # create profile
        elif re.search('https://sydneystudent.sydney.edu.au/sitsvision/wrd/siw_ipp_lgn.login?.+', url):
            create_profile()
            #new_application()

        else:
            print('no actions for: ', url)
            pass

def run(dir = default_dir):
    from getpass import getpass

    global students
    global driver

    username = os.getenv('SYD_USER', '')
    password = os.getenv('SYD_PASS', '')
    if not username:
        username = input('Username: ')
        password = getpass()

    students = load(dir)
    print(students)
    
    if is_win:
        driver = webdriver.Chrome()
    else:
        options = FirefoxOptions()
        options.set_preference("network.protocol-handler.external-default", False)
        options.set_preference("network.protocol-handler.expose-all", True)
        options.set_preference("network.protocol-handler.warn-external-default", False)
        driver = Firefox(options=options)
    
    driver.get('https://sydneystudent.sydney.edu.au/sitsvision/wrd/siw_lgn')

    wait = WebDriverWait(driver, 100)
    wait.until(EC.presence_of_element_located((By.TAG_NAME, "body")))

    login_session(username, password)
    try:
        with Listener(on_click=on_click) as listener:
            listener.join()
    except:
        print('failing exit')

if __name__ == '__main__':
    fire(run)