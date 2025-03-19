"""
Form control extraction utilities for FormMaster.
This module provides functions to extract and analyze form controls from HTML pages.
"""

import re
from bs4 import BeautifulSoup
from selenium.webdriver.common.by import By
from selenium.common.exceptions import NoSuchElementException
from forms.utils.logger import get_logger

logger = get_logger('form_extract')

def extract_form_controls(driver, form_selector=None):
    """
    Extract form controls from the current page using Selenium WebDriver.
    
    Args:
        driver: Selenium WebDriver instance
        form_selector: CSS selector for the form element, if None extracts all form controls
        
    Returns:
        dict: Dictionary of form controls grouped by type with their attributes
    """
    try:
        # Get page HTML
        html = driver.page_source
        
        # Parse with BeautifulSoup
        soup = BeautifulSoup(html, 'html.parser')
        
        # Find target form if selector provided, otherwise use whole document
        container = soup.select_one(form_selector) if form_selector else soup
        if not container:
            logger.warning(f"Form selector '{form_selector}' not found")
            return {}
            
        # Extract different control types
        controls = {
            'inputs': extract_inputs(container),
            'selects': extract_selects(container),
            'textareas': extract_textareas(container),
            'buttons': extract_buttons(container),
            'radios': extract_radio_groups(container),
            'checkboxes': extract_checkboxes(container)
        }
        
        return controls
        
    except Exception as e:
        logger.error(f"Error extracting form controls: {str(e)}")
        return {}

def extract_inputs(container):
    """Extract text, email, password, date and number inputs"""
    input_types = ['text', 'email', 'password', 'date', 'number', 'tel', 'hidden']
    inputs = container.find_all('input', type=lambda t: t in input_types)
    
    result = []
    for input_elem in inputs:
        input_info = {
            'id': input_elem.get('id', ''),
            'name': input_elem.get('name', ''),
            'type': input_elem.get('type', 'text'),
            'value': input_elem.get('value', ''),
            'placeholder': input_elem.get('placeholder', ''),
            'required': input_elem.has_attr('required'),
            'max_length': input_elem.get('maxlength', ''),
            'disabled': input_elem.has_attr('disabled'),
            'readonly': input_elem.has_attr('readonly')
        }
        
        # Try to find label
        input_info['label'] = find_label_for(container, input_elem)
        
        result.append(input_info)
    
    return result

def extract_selects(container):
    """Extract select dropdowns and their options"""
    selects = container.find_all('select')
    
    result = []
    for select in selects:
        options = []
        for option in select.find_all('option'):
            options.append({
                'value': option.get('value', ''),
                'text': option.text.strip(),
                'selected': option.has_attr('selected')
            })
        
        select_info = {
            'id': select.get('id', ''),
            'name': select.get('name', ''),
            'required': select.has_attr('required'),
            'disabled': select.has_attr('disabled'),
            'options': options
        }
        
        # Try to find label
        select_info['label'] = find_label_for(container, select)
        
        # Check for Chosen enhancement
        select_info['has_chosen'] = bool(container.select_one(f"#{select.get('id', '')}_chosen"))
        
        result.append(select_info)
    
    return result

def extract_textareas(container):
    """Extract textarea elements"""
    textareas = container.find_all('textarea')
    
    result = []
    for textarea in textareas:
        textarea_info = {
            'id': textarea.get('id', ''),
            'name': textarea.get('name', ''),
            'value': textarea.text,
            'required': textarea.has_attr('required'),
            'placeholder': textarea.get('placeholder', ''),
            'rows': textarea.get('rows', ''),
            'cols': textarea.get('cols', ''),
            'disabled': textarea.has_attr('disabled'),
            'readonly': textarea.has_attr('readonly')
        }
        
        # Try to find label
        textarea_info['label'] = find_label_for(container, textarea)
        
        result.append(textarea_info)
        
    return result

def extract_buttons(container):
    """Extract button elements and input elements with type button/submit/reset"""
    buttons = container.find_all('button')
    button_inputs = container.find_all('input', type=lambda t: t in ['button', 'submit', 'reset'])
    
    result = []
    
    for button in buttons:
        result.append({
            'id': button.get('id', ''),
            'name': button.get('name', ''),
            'type': button.get('type', 'button'),
            'text': button.text.strip(),
            'disabled': button.has_attr('disabled')
        })
    
    for button in button_inputs:
        result.append({
            'id': button.get('id', ''),
            'name': button.get('name', ''),
            'type': button.get('type', 'button'),
            'value': button.get('value', ''),
            'disabled': button.has_attr('disabled')
        })
        
    return result

def extract_radio_groups(container):
    """Extract radio button groups"""
    radio_groups = {}
    radios = container.find_all('input', type='radio')
    
    for radio in radios:
        name = radio.get('name', '')
        if not name:
            continue
            
        if name not in radio_groups:
            radio_groups[name] = {
                'name': name,
                'options': [],
                'label': find_group_label(container, name)
            }
        
        option = {
            'id': radio.get('id', ''),
            'value': radio.get('value', ''),
            'checked': radio.has_attr('checked'),
            'disabled': radio.has_attr('disabled')
        }
        
        # Try to find label for this specific radio button
        option_label = find_label_for(container, radio)
        if option_label:
            option['label'] = option_label
            
        radio_groups[name]['options'].append(option)
    
    return list(radio_groups.values())

def extract_checkboxes(container):
    """Extract checkbox inputs"""
    checkboxes = container.find_all('input', type='checkbox')
    
    result = []
    for checkbox in checkboxes:
        checkbox_info = {
            'id': checkbox.get('id', ''),
            'name': checkbox.get('name', ''),
            'value': checkbox.get('value', ''),
            'checked': checkbox.has_attr('checked'),
            'disabled': checkbox.has_attr('disabled')
        }
        
        # Try to find label
        checkbox_info['label'] = find_label_for(container, checkbox)
        
        result.append(checkbox_info)
        
    return result

def find_label_for(container, element):
    """Find label text for an input element"""
    element_id = element.get('id')
    if not element_id:
        return None
        
    # Look for a label with matching 'for' attribute
    label = container.find('label', attrs={'for': element_id})
    if label:
        # Remove any child elements from label text
        for child in label.find_all():
            child.extract()
        return label.text.strip()
    
    # If no direct label found, look for wrapping label
    parent = element.parent
    if parent and parent.name == 'label':
        # Clone label to avoid modifying original
        parent_clone = parent.copy()
        # Remove the input element from cloned label
        for child in parent_clone.find_all():
            if child.get('id') == element_id:
                child.extract()
        return parent_clone.text.strip()
        
    return None

def find_group_label(container, group_name):
    """Try to find a label for a group of form controls (like radio buttons)"""
    # This is more heuristic-based since groups often don't have explicit labels with 'for' attributes
    # Look for preceding label or legend
    
    # First try to find any element with the group name in title attributes
    title_elements = container.find_all(attrs={'title': re.compile(group_name, re.IGNORECASE)})
    if title_elements:
        return title_elements[0].text.strip()
    
    # Next look for legends in fieldsets
    for radio in container.find_all('input', attrs={'name': group_name}):
        fieldset = find_parent_by_tag(radio, 'fieldset')
        if fieldset:
            legend = fieldset.find('legend')
            if legend:
                return legend.text.strip()
    
    # Finally, look for nearby labels or headings
    for radio in container.find_all('input', attrs={'name': group_name}):
        parent = radio.parent
        while parent and parent != container:
            prev = parent.find_previous_sibling(['label', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'p', 'div'])
            if prev and prev.name in ['label', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'p']:
                return prev.text.strip()
            parent = parent.parent
    
    return None

def find_parent_by_tag(element, tag_name):
    """Find parent element with specific tag name"""
    parent = element.parent
    while parent:
        if parent.name == tag_name:
            return parent
        parent = parent.parent
    return None

def identify_form_groups(driver, controls):
    """
    Identify logical groups of form controls based on layout and DOM structure
    
    Args:
        driver: Selenium WebDriver instance
        controls: Dictionary of form controls from extract_form_controls
        
    Returns:
        list: List of form control groups
    """
    # Implementation would depend on specific form structure
    # Could use visual proximity, container elements, etc.
    # For a basic implementation, group by common parent elements
    
    # This is a placeholder for more sophisticated grouping logic
    return []

def generate_code_from_controls(controls):
    """
    Generate Python code to interact with the extracted form controls
    
    Args:
        controls: Dictionary of form controls from extract_form_controls
        
    Returns:
        str: Python code snippet for form interaction
    """
    code = []
    code.append("# Generated code for form interaction")
    code.append("from selenium.webdriver.common.by import By")
    code.append("from forms.utils.form_utils import set_value_by_id, select_chosen_option_by_id, ensure_radio_selected")
    code.append("")
    
    # Process text inputs
    for input_ctrl in controls.get('inputs', []):
        if input_ctrl['type'] in ['text', 'email', 'tel', 'number', 'date', 'password']:
            id_val = input_ctrl['id']
            if id_val:
                comment = f"# {input_ctrl['label']}" if input_ctrl['label'] else ""
                code.append(f"set_value_by_id(driver, '{id_val}', 'value') {comment}")
    
    # Process selects
    for select in controls.get('selects', []):
        id_val = select['id']
        if id_val:
            comment = f"# {select['label']}" if select['label'] else ""
            if select['has_chosen']:
                code.append(f"select_chosen_option_by_id(driver, '{id_val}', 'option text') {comment}")
            else:
                code.append(f"select_option_by_id(driver, '{id_val}', 'option text') {comment}")
    
    # Process radio groups
    for radio_group in controls.get('radios', []):
        comment = f"# {radio_group['label']}" if radio_group.get('label') else ""
        code.append(f"# Radio group: {radio_group['name']} {comment}")
        for option in radio_group['options']:
            if option['id']:
                label = f" # {option['label']}" if option.get('label') else ""
                code.append(f"ensure_radio_selected(driver, '{option['id']}'){label}")
    
    # Process checkboxes
    for checkbox in controls.get('checkboxes', []):
        id_val = checkbox['id']
        if id_val:
            comment = f" # {checkbox['label']}" if checkbox['label'] else ""
            code.append(f"check_button_by_id(driver, '{id_val}'){comment}")
    
    return "\n".join(code)
