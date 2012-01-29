#!/usr/bin/env python
# encoding=utf-8
# maintainer: rgaudin

""" Requires MySQLdb:
    apt-get install python-mysqldb
"""

HOSTNAME = "localhost"
USERNAME = "childcount"
PASSWORD = "childcount"
DATABASE = "childcount"
SITE = None
SITE = "mayange"
SITE_PREFIX = "#24"

from datetime import date, datetime

import MySQLdb

conn = MySQLdb.connect(host=HOSTNAME, user=USERNAME, \
                        passwd=PASSWORD, db=DATABASE)
