# -*- coding: utf-8 -*-
# Generated by Django 1.11.6 on 2017-11-30 20:05
from __future__ import unicode_literals

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('zerver', '0130_text_choice_in_emojiset'),
    ]

    operations = [
        migrations.AddField(
            model_name='realm',
            name='create_generic_bot_by_admins_only',
            field=models.BooleanField(default=False),
        ),
    ]
