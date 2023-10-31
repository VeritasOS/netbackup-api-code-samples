import requests

vmware_access_hosts_url = "/config/vmware/access-hosts/"
content_type_header = "application/vnd.netbackup+json;version=3.0"
accept_header = "application/vnd.netbackup+json;version=3.0"

def get_access_hosts(base_url, jwt, filter):
    headers = {'Accept': accept_header, 'Authorization': jwt}
    long_url = base_url + vmware_access_hosts_url + filter
    response = requests.get(long_url, headers=headers, verify=False)
    return response

def add_access_host(base_url, jwt, hostName):
    headers = {'Content-Type': content_type_header, 'Authorization': jwt}
    long_url = base_url + vmware_access_hosts_url
    data = {'data':{'type':'accessHostRequest', 'id':'vmware', 'attributes':{'hostname':hostName, 'validate': 'false'}}}
    response = requests.post(long_url, headers=headers, json=data, verify=False)
    return response

def delete_access_host(base_url, jwt, hostName):
    headers = {'Content-Type': content_type_header, 'Authorization': jwt}
    long_url = base_url + vmware_access_hosts_url + hostName
    response = requests.delete(long_url, headers=headers, verify=False)
    return response