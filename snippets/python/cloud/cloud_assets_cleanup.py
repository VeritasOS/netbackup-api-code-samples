#!/usr/bin/python
import requests
import sys
import argparse
import ssl
import json
from datetime import datetime, timedelta

requests.packages.urllib3.disable_warnings()

args = ()
globals = {}
CLEANUP_TIME = 48 # in hours

# NetBackup APIs
URL_LOGIN = "/login"
URL_NETBACKUP = "/netbackup"
URL_GET_ASSETS = "/assets"
URL_ASSET_CLEANUP = "/assets/asset-cleanup"
CONTENT_TYPE4 = "application/vnd.netbackup+json;version=4.0"

# Build the URL to invoke
def buildURL(url, filter = ""):
    retURL = "https://" + args.nbu_master_host + URL_NETBACKUP + url
    if (filter != ""):
        retURL += "?filter=" + filter
    return retURL

# RestClient
def doRestCall(method, url, reqBody = {}):
    headers = {
        'Content-Type': CONTENT_TYPE4
    }
    if "token" in globals:
        headers["Authorization"] = globals["token"]

    if (method == "POST"):
        response = requests.post (url, headers = headers, data = json.dumps(reqBody), verify = False)

    if (method == "GET"):
        response = requests.get(url, headers=headers, data = json.dumps(reqBody), verify=False)
    return response

# Login to specified NetBackup master server
def loginMaster():
    print ("** Logging in to the NetBackup master host...")
    if "token" in globals:
        return globals["token"]

    reqBody = {
     "userName" : args.nbu_user_name,
        "password" : args.nbu_password
    }
    response = doRestCall("POST", buildURL(URL_LOGIN), reqBody)
    if response.status_code == 201:
        globals["token"] = response.json()["token"]
        return response.json()["token"]
    print("   -> Invalid user name or password")
    print("** Exiting")
    exit(1)

# Get assets using a filter
def getAssets():
    token = loginMaster()
    
    print ("** Retrieving assets to cleanup...")
    assets = []
    cleanupTime = str((datetime.utcnow() - timedelta(hours = CLEANUP_TIME)).isoformat()) + "Z"
    globals["cleanupTime"] = cleanupTime
    count = 0
    pageOffset = 0
    while True:
        queryFilter = "(lastDiscoveredTime  lt " + cleanupTime  \
            + " and workloadType eq 'Cloud')"
        queryFilter += "&page[offset]=" + str(pageOffset) + "&page[limit]=100"
        response = doRestCall("GET", buildURL(URL_GET_ASSETS, queryFilter))
        if response.status_code == 200:
            if "data" not in response.json() or len(response.json()["data"]) == 0:
                break
            assets += response.json()["data"]
            pageOffset += 100
            if count == 0:
                try:
                    count = response.json()["meta"]["pagination"]["count"]
                except:
                    pass
        else:
            if len(assets) == 0:
                print ("   -> No assets found")
                print ("** Exiting")
                exit(1)
            else:
                break
        msg = str(len(assets))
        if count != 0:
            msg = str(len(assets)) + " / " + str(count)
        print ("   -> Received " + msg + " stale assets")
    globals["assets"] = assets

def cleanupAssets():
    assets = []
    if "assets" in globals:
        assets = globals["assets"]

    if len(assets) == 0:
        print("   -> No assets to clean up")
        print("** Exiting")
        exit(1)
    
    print ("** Cleaning up " + str(len(assets)) + " assets")

    assetsCleanup = []
    for asset in assets:
        assetsCleanup.append(asset["id"])

    reqBody = {"data": {
        "type": "assetCleanup",
        "id": "id",
        "attributes": {
            "cleanupTime": globals["cleanupTime"],
            "assetIds": assetsCleanup
            }
        }
    }
    response = doRestCall("POST", buildURL(URL_ASSET_CLEANUP), reqBody)
    if response.status_code == 204:
        print ("** Assets cleaned up successfully")
    else:
        print("** Unable to clean assets")
    print("** Exiting")

def parseArguments():
    global args
    parser = argparse.ArgumentParser()
    parser.add_argument('--nbu_master_host', metavar="<hostname>", \
        help='NetBackup Master Host', required = True)
    parser.add_argument('--nbu_user_name', metavar="<user name>",
        help='NetBackup Username', required = True)
    parser.add_argument('--nbu_password', metavar="<password>", \
        help='NetBackup Password', required = True)
    args = parser.parse_args()

def setup():
    try:
        _create_unverified_https_context = ssl._create_unverified_context
    except AttributeError:
        pass
    else:
        ssl._create_default_https_context = _create_unverified_https_context

if __name__ == "__main__":
    setup()
    parseArguments()
    getAssets()
    cleanupAssets()
