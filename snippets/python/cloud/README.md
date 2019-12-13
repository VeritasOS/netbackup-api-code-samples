### NetBackup API Code Samples for Python

This directory contains code samples to invoke NetBackup REST APIs using Python.

#### Disclaimer

These scripts are only meant to be used as a reference. If you intend to use them in production, use it at your own risk.

#### Pre-requisites:

- NetBackup 8.2 or higher
- python 3.5 or higher
- python modules: `requests, sys, argparse, ssl, json`

#### Executing the snippets in Python

Use the following commands to run the python samples.
- `python cloud_assets_cleanup.py [-h] --nbu_master_host <hostname> --nbu_user_name <user name> --nbu_password <password>`