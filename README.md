# Form-Master

Form-Master is an automation tool designed to streamline the university application process for students applying to Australian universities. The system uses Selenium WebDriver to interact with university application portals and automatically fill in application forms based on student data.

## Features

- Extracts student information from Word documents (.docx) containing application details
- Supports multiple Australian universities:
  - USYD (Sydney University)
  - UNSW (New South Wales University)
- Provides a user-friendly interface for triggering form filling operations
- Handles repetitive form tasks while allowing manual intervention

## Installation

You can install Form-Master directly from PyPI:

```bash
pip install form-master
```

Or install from source:

```bash
git clone https://github.com/haroldmei/form-master.git
cd form-master
pip install -e .
```

## Usage

After installation, you can run Form-Master in two ways:

### Command Line

```bash
form-master --path /path/to/student/documents --portal usyd
```

### As Python Module

```python
from formmaster import FormFiller

filler = FormFiller(path="/path/to/student/documents", portal="usyd")
filler.run()
```

## Documentation

For detailed documentation, please visit the [GitHub repository](https://github.com/haroldmei/form-master).

## License

This project is licensed under the MIT License - see the LICENSE file for details.