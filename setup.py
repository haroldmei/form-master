from setuptools import setup

with open("README.md", "r", encoding="utf-8") as fh:
    long_description = fh.read()

with open("src/requirements.txt", "r", encoding="utf-8") as fh:
    requirements = fh.read().splitlines()

setup(
    name="form-master",
    version="0.1.0",
    author="Form-Master Team",
    author_email="maintainer@example.com",  # Replace with actual contact email
    description="Form automation tool for Australian university application processes",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/haroldmei/form-master",
    project_urls={
        "Bug Tracker": "https://github.com/haroldmei/form-master/issues",
    },
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: Microsoft :: Windows",
    ],
    py_modules=["formfiller"],  # Use individual modules instead of packages
    package_dir={"": "src"},    # Source directory where modules can be found
    python_requires="~=3.11.0",  # Specifically require Python 3.11.x
    install_requires=requirements,
    entry_points={
        "console_scripts": [
            "form-master=formfiller:main",  # Direct reference to formfiller.py
        ],
    },
    include_package_data=True,
)
