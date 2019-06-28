import requests

content_type = "application/vnd.netbackup+json; version=3.0"

def get_all_nb_processes(base_url, jwt, host_uuid):
    url = base_url + "/admin/hosts/" + host_uuid + "/processes"
    headers = {'Content-Type': content_type, 'Authorization': jwt}
    print("\nCalling NB Processes API to list the details of all NB processes on the host: {}\n".format(host_uuid))
	
    resp = requests.get(url, headers=headers, verify=False)
	
    if resp.status_code != 200:
        print("GET NB Processes API failed with status code {} and {}\n".format(resp.status_code, resp.json()))
        raise SystemExit("\n\n")
    
    return resp.json()
	
	
def get_specific_nb_service(base_url, jwt, host_uuid, processName):
    url = base_url + "/admin/hosts" + host_uuid + "/processes"
    headers = {'Content-Type': content_type, 'Authorization': jwt}
    query_params = {'filter': "processName eq '{}'".format(processName)}
    
    print("\nCalling NB Processes API to get the details of the NB process {} on the host {}".format(processName, host_uuid))
    
    resp = requests.get(url, headers=headers, params=query_params, verify=False)
    
    if resp.status_code != 200:
        print('\nGET NB Process API failed with status code {} and {}\n'.format(resp.status_code, resp.json()))
        raise SystemExit("\n\n")

    return resp.json()	
