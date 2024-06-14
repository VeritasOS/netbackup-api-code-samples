#!/usr/bin/python3
#
# SYNOPSIS
# This sample script reads a JSON data file to get a list of failed backup
# jobs from the primary servers.
#
# DESCRIPTION
# This script will read the JSON data file to get a list of NetBackup primary
# servers with valid API keys.  For each primary server, the "GET /admin/jobs"
# API will be executed with a filter to get just failed jobs.
#
# EXAMPLE
# ./cli_failed_jobs.py3
#
# Requirements and comments for running this script
#    Tested with Python 3.8
#    Tested with NetBackup 9.1
#    API key uesr must have following minimum  privileges assigned to it's role:
#        Manage -> Jobs -> View

import sys
import argparse
from datetime import datetime, timedelta 
import requests
requests.packages.urllib3.disable_warnings()
from urllib.parse import quote
from urllib.parse import urlencode
import json
from os.path import exists

################################################################
# Parsing the command line to get the policy and API key
################################################################
parser = argparse.ArgumentParser()
parser.add_argument("-v", dest='verbose', action="store_true", help="verbose output for debugging")
cli_args=parser.parse_args()

if cli_args.verbose :
    print("Verbose?: {}.".format(cli_args.verbose))

################################################################
# Setting some variables to be used through the rest of the processing
################################################################
primary_file = "primary_servers.json"
page_limit=2 # 100 is maxium number to retreive at a time
content_type = "application/vnd.netbackup+json;version=6.0"
if cli_args.verbose :
    print("Using {} for server and API keys".format(primary_file))
    print("Collecting {} jobs at a time".format(page_limit))
    print("")


################################################################
# Reading the primary_servers.json file to get list of
# NBU primary servers and API keys to use for authorization
################################################################
if not exists(primary_file) :
    print("Specified file {} does not exist".format(primary_file))
    sys.exit()

with open(primary_file) as json_file :
    primary_data = json.load(json_file)


################################################################
# Loop through all the primary servers getting a list of
# failed jobs
################################################################
print("Master       JobID   Status  Type     Client          Policy               Schedule")
for server in primary_data['primaryServers'] :
    if cli_args.verbose:
        print("Getting job data from",server['name'])

    ####################################
    # Build out the HTTP request details
    uri = "https://" + server['name'] + "/netbackup/admin/jobs/"
    query_params= {
        "page[limit]": page_limit,
        "filter": "status gt 0 and state eq 'DONE' and jobType eq 'BACKUP'",
        "sort": "-jobId" # Sorting by job ID in descending order
    }
    header = {
        "Authorization": server['api-key'],
        "Accept": content_type
    }
    if cli_args.verbose :
        print("Getting list of jobs from {}".format(server['name']))
        print("User URI {}".format(uri))

    ####################################
    # Make the job API call
    response = requests.get(uri, headers=header, params=query_params, verify=False)
    if response.status_code != 200 :
        print("Unable to get the list of NetBackup images!")
        print("API status code = {}".format(response.status_code))
        sys.exit()

    ####################################
    # Printing out this batch of jobs
    tjson=response.json()
    if not "data" in tjson :
        print("No failed backup jobs found for {}".format(server['name']))
        continue
    else :
        for job in tjson['data'] :
            print("{:<12s} ".format(server['name']), end='')
            print("{:<7s} ".format(str(job['attributes']['jobId'])), end='')
            print("{:<7s} ".format(str(job['attributes']['status'])), end='')
            print("{:<8s} ".format(job['attributes']['jobType'][:8]), end='')
            print("{:<15s} ".format(job['attributes']['clientName'][:15]), end='')
            print("{:<20s} ".format(job['attributes']['policyName'][:20]), end='')
            print("{:<20s}".format(job['attributes']['scheduleName'][:20]))

    # If the first call to jobs generates more data than page_limit,
    # then loop through until finished collecting all the pages of jobs
    if "next" in tjson['links'] :
        ####################################
        # Getting the next page URI
        next_uri=tjson['links']['next']['href']

        while True :
            ####################################
            # Make the job API call
            response = requests.get(next_uri, headers=header, verify=False)
            if response.status_code != 200 :
                print("Unable to get the list of NetBackup images!")
                print("API status code = {}".format(response.status_code))
                sys.exit()
            
            ####################################
            # Add information to policy_dict
            tjson=response.json()
            for job in tjson['data'] :
                print("{:<12s} ".format(server['name']), end='')
                print("{:<7s} ".format(str(job['attributes']['jobId'])), end='')
                print("{:<7s} ".format(str(job['attributes']['status'])), end='')
                print("{:<8s} ".format(job['attributes']['jobType'][:8]), end='')
                print("{:<15s} ".format(job['attributes']['clientName'][:15]), end='')
                print("{:<20s} ".format(job['attributes']['policyName'][:20]), end='')
                print("{:<20s}".format(job['attributes']['scheduleName'][:20]))
    
            ####################################
            # Break out of the pagination loop
            # if there is no next href page
            if "next" in tjson['links'] :
                next_uri=tjson['links']['next']['href']
            else :
                break

sys.exit()
