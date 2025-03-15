"""
Utility functions for Form-Master, particularly for browser automation.
"""
import os
from selenium import webdriver
from selenium.webdriver.chrome.service import Service as ChromeService
from selenium.webdriver.firefox.service import Service as FirefoxService

def get_chrome_driver():
    """
    Get Chrome WebDriver instance, preferring local installation if available.
    
    Returns:
        WebDriver: Configured Chrome WebDriver instance
    """
    # Check for environment variable pointing to local ChromeDriver
    chrome_driver_path = os.environ.get('CHROME_DRIVER_PATH')
    
    if chrome_driver_path and os.path.exists(chrome_driver_path):
        # Use local ChromeDriver if available
        service = ChromeService(executable_path=chrome_driver_path)
        return webdriver.Chrome(service=service)
    else:
        # Fall back to webdriver-manager
        try:
            from webdriver_manager.chrome import ChromeDriverManager
            service = ChromeService(ChromeDriverManager().install())
            return webdriver.Chrome(service=service)
        except Exception as e:
            print(f"Error initializing Chrome WebDriver: {e}")
            raise

def get_firefox_driver():
    """
    Get Firefox WebDriver instance, preferring local installation if available.
    
    Returns:
        WebDriver: Configured Firefox WebDriver instance
    """
    # Check for environment variable pointing to local GeckoDriver
    gecko_driver_path = os.environ.get('GECKO_DRIVER_PATH')
    
    if gecko_driver_path and os.path.exists(gecko_driver_path):
        # Use local GeckoDriver if available
        service = FirefoxService(executable_path=gecko_driver_path)
        return webdriver.Firefox(service=service)
    else:
        # Fall back to webdriver-manager
        try:
            from webdriver_manager.firefox import GeckoDriverManager
            service = FirefoxService(GeckoDriverManager().install())
            return webdriver.Firefox(service=service)
        except Exception as e:
            print(f"Error initializing Firefox WebDriver: {e}")
            raise
