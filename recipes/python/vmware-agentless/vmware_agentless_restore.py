import argparse
import os
import getpass
import requests
import texttable as tt
from requests.packages.urllib3.exceptions import InsecureRequestWarning

parser = argparse.ArgumentParser(description="Sample script demonstrating NetBackup agentless restore for VMware")
parser.add_argument("--master", type=str, help="NetBackup master server")
parser.add_argument("--username", type=str, help="NetBackup user name")
parser.add_argument("--password", type=str, help="NetBackup password")
parser.add_argument("--port", type=int, help="NetBackup port (default is 1556)", default=1556)
parser.add_argument("--vm_name", type=str, help="VM name")
parser.add_argument("--vm_username", type=str, help="VM user name")
parser.add_argument("--vm_password", type=str, help="VM password")
parser.add_argument("--file", type=str, help="File to be restored")
parser.add_argument("--destination", type=str, help="Destination path of file")
parser.add_argument("--no_check_certificate", action="store_true", help="Disable certificate verification", default=False)

args = parser.parse_args()

if not args.master:
    args.master = input("NetBackup master server: ")
if not args.username:
    args.username = input("NetBackup user name: ")
if not args.password:
    args.password = getpass.getpass("NetBackup password: ")
if not args.vm_name:
    args.vm_name = input("VM name: ")
if not args.vm_username:
    args.vm_username = input("VM username: ")
if not args.vm_password:
    args.vm_password = getpass.getpass("VM password: ")
if not args.file:
    args.file = input("File to be restored: ")
if not args.destination:
    args.destination = input("File destination: ")
if args.no_check_certificate:
    requests.packages.urllib3.disable_warnings(InsecureRequestWarning)

base_url = "https://" + args.master + ":" + str(args.port) + "/netbackup"
content_type = "application/vnd.netbackup+json;version=3.0"

url = base_url + "/login"
headers = {"Content-Type": content_type}
resp = requests.post(
    url,
    headers=headers,
    json={"userName": args.username, "password": args.password},
    verify=not args.no_check_certificate,
)
if resp.status_code != 201:
    print("NetBackup login failed")
    exit(1)
jwt = resp.json()["token"]

headers = {"Content-Type": content_type, "Authorization": jwt}

url = base_url + "/assets"
params = {"filter": "displayName eq '" + args.vm_name + "'"}
resp = requests.get(url, headers=headers, params=params, verify=not args.no_check_certificate)
vm_found = False
vm_attributes = None
for asset in resp.json()["data"]:
    if asset["attributes"]["displayName"] == args.vm_name:
        vm_attributes = asset["attributes"]["extendedAttributes"]
        vm_found = True
        break
if not vm_found:
    print("VM not found in NetBackup asset database")
    exit(1)

url = base_url + "/recovery/workloads/vmware/scenarios/guestfs-agentless/pre-recovery-check"
payload = {
    "data": {
        "type": "vmAgentlessFilePreRecoveryCheckRequest",
        "attributes": {
            "recoveryOptions": {
                "recoveryHost": args.master,
                "vCenter": vm_attributes["vCenter"],
                "esxiServer": vm_attributes["hostName"],
                "instanceUuid": vm_attributes["instanceUuid"],
                "datastore": vm_attributes["datastore"][0],
                "vmUsername": args.vm_username,
                "vmPassword": args.vm_password,
            }
        },
    }
}
resp = requests.post(url, headers=headers, json=payload, verify=not args.no_check_certificate)
pre_check_failed = False
tab = tt.Texttable()
headings = ["Pre-recovery check", "Result", "Description"]
tab.header(headings)
for data_item in resp.json()["data"]:
    tuple_value = (
        data_item["attributes"]["name"],
        data_item["attributes"]["result"],
        data_item["attributes"].get("description", ""),
    )
    tab.add_row(tuple_value)
    if data_item["attributes"]["result"] == "fail":
        pre_check_failed = True
print(tab.draw())
if pre_check_failed:
    exit(1)

url = base_url + "/recovery/workloads/vmware/scenarios/guestfs-agentless/recover"
payload = {
    "data": {
        "type": "vmAgentlessFileRecoveryRequest",
        "attributes": {
            "recoveryPoint": {"client": vm_attributes["instanceUuid"]},
            "recoveryObject": {
                "vmFiles": [{"source": args.file, "destination": args.destination}],
                "vmRecoveryDestination": {
                    "instanceUuid": vm_attributes["instanceUuid"],
                    "vmUsername": args.vm_username,
                    "vmPassword": args.vm_password,
                },
            },
        },
    }
}
resp = requests.post(url, headers=headers, json=payload, verify=not args.no_check_certificate)
if resp.status_code != 201:
    print("Failed to start restore")
    print(resp.json().get("errorMessage"))
    exit(1)
print(resp.json()["data"]["attributes"]["msg"])
