# -*- coding: utf-8 -*-
# Generated by Django 1.11.4 on 2017-08-30 00:26

import rapidjson as ujson
from django.db import migrations
from django.db.backends.postgresql_psycopg2.schema import DatabaseSchemaEditor
from django.db.migrations.state import StateApps

from zerver.lib.fix_unreads import fix

def fix_unreads(apps: StateApps, schema_editor: DatabaseSchemaEditor) -> None:
    UserProfile = apps.get_model("zerver", "UserProfile")
    user_profiles = list(UserProfile.objects.filter(is_bot=False))
    for user_profile in user_profiles:
        fix(user_profile)

class Migration(migrations.Migration):

    dependencies = [
        ('zerver', '0103_remove_userprofile_muted_topics'),
    ]

    operations = [
        migrations.RunPython(fix_unreads),
    ]
