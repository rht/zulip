"""
WSGI config for zulip project.

This module contains the WSGI application used by Django's development server
and any production WSGI deployments. It should expose a module-level variable
named ``application``. Django's ``runserver`` and ``runfcgi`` commands discover
this application via the ``WSGI_APPLICATION`` setting.

Usually you will have the standard Django WSGI application here, but it also
might make sense to replace the whole Django WSGI application with a custom one
that later delegates to the Django one. For example, you could introduce WSGI
middleware here, or combine a Django application with an application of another
framework.

"""
import os
import sys
import ast

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.append(BASE_DIR)
import scripts.lib.setup_path_on_import

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "zproject.settings")

# check if settings file has valid Python syntax
from django.conf import settings
settings_path = "/etc/zulip/settings.py"
if settings.DEVELOPMENT:
    settings_path = "zproject/dev_settings.py"
with open(settings_path, 'r') as settings_file:
    try:
        ast.parse(settings_file.read())
    except SyntaxError:  # nocoverage
        print("The settings file has invalid Python syntax.")  # nocoverage
        with open('/var/log/zulip/workers.log', 'a') as logfile:  # nocoverage
            logfile.write("\nThe settings file has invalid Python syntax.")  # nocoverage
        exit(1)  # nocoverage

import django
django.setup()  # We need to call setup to load applications.

# Because import_module does not correctly handle safe circular imports we
# need to import zerver.models first before the middleware tries to import it.

import zerver.models

# This application object is used by any WSGI server configured to use this
# file. This includes Django's development server, if the WSGI_APPLICATION
# setting points here.
from django.core.wsgi import get_wsgi_application
application = get_wsgi_application()
