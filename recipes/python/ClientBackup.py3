#!/usr/bin/python3
#
# SYNOPSIS
# This sample script demonstrates the use of NetBackup REST API for launching
# a manual backup from a Windows client system

# DESCRIPTION
# This script will query the master server for policy information and existing
# client backup images.  If the latest full backup is older than the
# frequency defined within the policy schedule a full backup will be

# launched; otherwise, an incremental backup will be performed.
# EXAMPLE
# ./ClientBackup.py3 -p "ExampleClientBackup-Std" -k "AybRCz3UE_YOpCFD7_5mzQQfJsRXj_pN6WXLA7boX4EAuKD_kwBfXWQ5bFNWDiuJ"
#
# Requirements and comments for running this script
#    Tested with Python 3.8
#    Tested with NetBackup 8.3.0.1
#    NetBackup client software already installed, configured and tested
#    A policy must be defined on the master server with the following details
#        Policy type must be Standard
#        2 schedules define with no backup windows
#            one full named FULL
#            one incremental named INCR
#        Client name added to Clients tab
#    Use command line parameters to specify the following parameters
#        -p (to reference above policy)
#        -k (API key generated through NetBackup web UI)
#    API key uesr must have following minimum  privileges assigned to it's role:
#        Global -> NetBackup management -> NetBackup images -> View
#        Global -> Protection -> Policies -> View
#        Global -> Protection -> Policies -> Manual Backup

import sys
import argparse
from datetime import datetime, timedelta 
import json
import requests
requests.packages.urllib3.disable_warnings()
from urllib.parse import quote

################################################################
# Parsing the command line to get the policy and API key
################################################################
parser = argparse.ArgumentParser()
parser.add_argument("-p", dest='policy', metavar='POLICY', required=True, help="backup policy to run manual backup with")
parser.add_argument("-k", dest='apikey', metavar='APIKEY', required=True, help="specify API key")
parser.add_argument("-t", dest='test', action="store_true", help="test mode, don't run backup")
parser.add_argument("-v", dest='verbose', action="store_true", help="verbose output")
cli_args=parser.parse_args()

if cli_args.verbose :
    print("Policy specified: {}.".format(cli_args.policy))
    print("API key specified: {}.".format(cli_args.apikey))
    print("Test mode?: {}.".format(cli_args.test))
    print("Verbose?: {}.".format(cli_args.verbose))

################################################################
# Looking for the /usr/openv/netbackup/bp.conf file for SERVER and CLIENT
# entries.  Only want to get the first entry for either one
################################################################
nbmaster=False
clientname=False
with open('/usr/openv/netbackup/bp.conf','r') as fh:
    for cnt, line in enumerate(fh):
        data = line.split('=')
        if not nbmaster and data[0].strip() == 'SERVER' :
            nbmaster=data[1].strip()
        if not clientname and data[0].strip() == 'CLIENT_NAME' :
            clientname = data[1].strip()

if cli_args.verbose :
    print("nbmaster={}.".format(nbmaster))
    print("clientname={}.".format(clientname))
    print("")

################################################################
# Setting some variables to be used through the rest of the processing
################################################################
port="1556"
basepath = "https://" + nbmaster + ":" + port + "/netbackup"
content_type = "application/vnd.netbackup+json;version=4.0"
days2lookback = 30
fullname = "FULL"
incrname = "INCR"
if cli_args.verbose :
    print("Base URI = {}".format(basepath))
    print("Looking back {} days for previous backups".format(str(days2lookback)))
    print("")

################################################################
# Getting the policy details for this policy
################################################################
uri = basepath + "/config/policies/" + cli_args.policy
if cli_args.verbose :
    print("Getting {} policy details".format(cli_args.policy))
    print("User URI {}".format(uri))
header = {
    "Authorization": cli_args.apikey ,
    "Accept": content_type
}
response = requests.get(uri, headers=header, verify=False)
if response.status_code != 200 :
    print("Unable to get the list of NetBackup images!")
    sys.exit()

content = response.json()
for schedule in content['data']['attributes']['policy']['schedules'] :
    if schedule['scheduleName'] == fullname :
        fullfrequency = schedule['frequencySeconds']
        fullschedule = schedule['scheduleName']
    if schedule['scheduleName'] == incrname :
        incrfrequency = schedule['frequencySeconds']
        incrschedule = schedule['scheduleName']

if cli_args.verbose :
    print("Incremental schedule {} frequency is {} seconds".format(incrschedule,incrfrequency))
    print("Full schedule {} frequency is {} seconds".format(fullschedule,fullfrequency))

################################################################
# Getting backup images for this client
################################################################
uri = basepath + "/catalog/images"
if cli_args.verbose :
    print("Looking for most recent backup images to see what kind of backup to run")
    print("using URI {}".format(uri))

# Note that currentDate and lookbackDate are DateTime objects while
# backupTimeStart and backupTimeEnd are string date in ISO 8601 format
# using Zulu (Greenwich Mean Time) time:  YYYY-MM-DDThh:mm:ssZ
# Date/Time format example:
#    November 19, 1969 at 3:22:00 PM = 1969-11-19T15:22:00Z
# currentDate and backupTimeStart are both datetime objects
# Getting current date
currentDate = datetime.utcnow()
# Set starting date to 30 days from current date
backupTimeStart = currentDate - timedelta(days=days2lookback)

if cli_args.verbose :
    print("currentDate = {}Z".format(currentDate.isoformat()))
    print("backupTimeStart = {}Z.".format(backupTimeStart.isoformat()))

# Because the filter query requires use of %20 for space instead of +
# have to use the quote method to properly substitute this instead of native
# library from requests.
page_limit=quote("page[limit]")+"=50";
filter="filter="+quote("clientName eq '{}' and backupTime ge {}Z".format(clientname,backupTimeStart.isoformat()))
header = {
    "Authorization": cli_args.apikey
}

# Build out the actual URL with filter and page_limit
url=uri+"?"+page_limit+"&"+filter
response=requests.get(url, headers=header, verify=False)
if response.status_code != 200 :
    print("Unable to get list of NetBackup images!")
    sys.exit()

content=response.json()
#print(content)
#print(content['data'])

schedulerun="none"
fulltime=datetime.strptime("2000-01-01", "%Y-%m-%d")
incrtime=datetime.strptime("2000-01-01", "%Y-%m-%d")
for image in content['data'] :
    # Converting image timestamp to datetime object
    a=datetime.strptime(image['attributes']['backupTime'], "%Y-%m-%dT%H:%M:%S.000Z")
    if image['attributes']['scheduleName'] == fullname :
        if a > fulltime :
            fulltime=a
    if image['attributes']['scheduleName'] == incrname :
        if a > incrtime :
            incrtime=a

# Define the full and incr window by subtracting the schedule frequency from
#  the current time.
fullwindow = currentDate - timedelta(seconds=fullfrequency)
incrwindow = currentDate - timedelta(seconds=incrfrequency)

# Now, run through the logic to determine what kind of backup to run
if fulltime.strftime("%Y-%m-%d") == "2000-01-01" :
    # No recent backup images found for this client, run full backup
    schedulerun = fullname
elif fullwindow >= fulltime :
    # Found a FULL backup older than the current full window
    schedulerun = fullname
elif fulltime.strftime("%Y-%m-%d") != "2000-01-01" and incrtime.strftime("%Y-%m-%d") == "2000-01-01" :
    # Full backup found but less than window and no incremental
    schedulerun = incrname
elif incrwindow >= incrtime :
    # Full backup less than window and incremental older than window
    schedulerun = incrname
else :
    schedulerun = "none"

if cli_args.verbose :
    print("schedulerun={}.".format(schedulerun))
    print("fulltime={}.".format(fulltime))
    print("incrtime={}.".format(incrtime))
    print("")

# If schedulerun is equal to none, then skip running anything
if schedulerun == "none" :
    print("Too soon to take a backup")
    sys.exit()

################################################################
# Running this in testing mode which means we don't want to run a backup,
# just see what would be run
################################################################
if cli_args.test :
    sys.exit()

################################################################
# Launch the backup now
################################################################
uri = basepath+"/admin/manual-backup"
if cli_args.verbose :
    print("Lauching the backup now")
    print("Using URI {}".format(uri))

header = {
    "Authorization": cli_args.apikey,
    "Content-Type": "application/vnd.netbackup+json;version=4.0"
}
backup_dict = {
    "data": {
        "type": "backupRequest",
        "attributes": {
            "policyName": cli_args.policy,
            "scheduleName": schedulerun,
            "clientName": clientname
        }
    }
}
response=requests.post(uri, data=json.dumps(backup_dict), headers=header, verify=False)

if response.status_code != 202 :
    print("API status code={}".format(response.status_code))
    print("response text={}".format(response.text))
    print("Unable to start the backup for {} with schedule {} for policy {}.".format(clientname,schedulerun,cli_args.policy))
    sys.exit()

if cli_args.verbose :
    print("Backup {} successfully started".format(schedulerun))
