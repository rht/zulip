from argparse import ArgumentParser
from typing import Any

from django.conf import settings
from django.core.management.base import BaseCommand

from zerver.lib.server_initialization import create_internal_realm
from zerver.models import Realm

settings.TORNADO_SERVER = None

class Command(BaseCommand):
    help = "Populate an initial database for Zulip Voyager"

    def add_arguments(self, parser: ArgumentParser) -> None:
        parser.add_argument('--extra-users',
                            dest='extra_users',
                            type=int,
                            default=0,
                            help='The number of extra users to create')

    def handle(self, *args: Any, **options: Any) -> None:
        if Realm.objects.count() > 0:
            print("Database already initialized; doing nothing.")
            return
        create_internal_realm()

        self.stdout.write("Successfully populated database with initial data.\n")
        self.stdout.write("Please run ./manage.py generate_realm_creation_link "
                          "to generate link for creating organization")
