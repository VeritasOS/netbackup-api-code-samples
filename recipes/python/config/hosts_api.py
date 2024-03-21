import requests

config_hosts_url = "/config/hosts/"
content_type_header = "application/vnd.netbackup+json;version=3.0"
accept_header = "application/vnd.netbackup+json;version=3.0"

def get_host_uuid(base_url, jwt, host_name):
    headers = {'Accept': accept_header, 'Authorization': jwt}
    queryparams = {'filter':"hostName eq '{}'".format(host_name)}
    print("\nCalling Config Hosts API to get the uuid of the host {}.".format(host_name))
    response = requests.get(base_url + config_hosts_url, headers=headers, params=queryparams, verify=False)

    if response.status_code != 200:
        print("\nGET Host API failed with status code {} and {}".format(response.status_code, response.json()))
        raise SystemExit("\n\n")

    print("GET Hosts API returned status: {}".format(response.status_code))
    host_uuid = response.json()['hosts'][0]['uuid']
    print("Returning the host uuid: " + host_uuid)

    return host_uuid

def get_host_configuration(base_url, jwt, host_uuid, config_name):
    headers = {'Accept': accept_header, 'Authorization': jwt}
    print("\nCalling Config Hosts API to get the '{}' configuration setting on the host '{}'.".format(config_name, host_uuid))

    host_config_url = base_url + config_hosts_url + host_uuid + "/configurations/" + config_name
    response = requests.get(host_config_url, headers=headers, verify=False)    
    return response

def create_host_configuration(base_url, jwt, host_uuid, config_name, config_value):
    headers = {'Content-Type': content_type_header, 'Authorization': jwt}
    print("\nCalling Config Hosts API to create the '{}' configuration setting on the host '{}'.".format(config_name, host_uuid))

    host_config_url = base_url + config_hosts_url + host_uuid + "/configurations"
    data = {'data':{'type':'hostConfiguration', 'id':config_name, 'attributes':{'value':config_value}}}

    response = requests.post(host_config_url, headers=headers, json=data, verify=False)
    return response

def update_host_configuration(base_url, jwt, host_uuid, config_name, config_value):
    headers = {'Content-Type': content_type_header, 'Authorization': jwt}
    print("\nCalling Config Hosts API to update the '{}' configuration setting on the host '{}'.".format(config_name, host_uuid))

    host_config_url = base_url + config_hosts_url + host_uuid + "/configurations/" + config_name
    data = {'data':{'type':'hostConfiguration', 'id':config_name, 'attributes':{'value':config_value}}}

    response = requests.put(host_config_url, headers=headers, json=data, verify=False)
    return response
    
