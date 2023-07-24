#!/usr/bin/env python3
from setuptools import setup

setup(
    name="my-python-app",
    version="0.1.0",
    description="A Python application",
    author="",
    author_email="",
    packages=[""],
    install_requires=[
        d for d in open("requirements.txt").readlines() if not d.startswith("--")
    ],
    package_dir={"": "."},
    entry_points={"console_scripts": ["my-python-app = my_python_app.main:main"]},
)
