from setuptools import setup, find_packages

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
    package_dir={"": "src"},
    packages=find_packages(where="src"),
    python_requires=">=3.9",
    install_requires=requirements,
    entry_points={
        "console_scripts": [
            "form-master=formmaster.formfiller:main",
        ],
    },
    include_package_data=True,
)
