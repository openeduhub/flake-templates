#!/usr/bin/env python3
from setuptools import setup, find_packages

setup(
    name="my-python-package",
    version="0.1.0",
    description="A Python package",
    author="",
    author_email="",
    packages=find_packages(),
    install_requires=[
        d for d in open("requirements.txt").readlines() if not d.startswith("--")
    ],
    package_dir={"": "."},
)
