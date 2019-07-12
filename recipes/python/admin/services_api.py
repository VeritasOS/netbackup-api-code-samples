import requests

content_type = "application/vnd.netbackup+json; version=3.0"

def get_all_nb_services(base_url, jwt, host_uuid):
    url = base_url + "/admin/hosts/" + host_uuid + "/services"
    headers = {'Content-Type': content_type, 'Authorization': jwt}
    print("\nCalling NB Services API to get the details/status of all NB services on the host: {}\n".format(host_uuid))
	
    resp = requests.get(url, headers=headers, verify=False)
	
    if resp.status_code != 200:
        print("GET NB Services API failed with status code {} and {}\n".format(resp.status_code, resp.json()))
        raise SystemExit("\n\n")
	
    return resp.json()
	
	
def get_specific_nb_service(base_url, jwt, host_uuid, serviceName):
    url = base_url + "/admin/hosts" + host_uuid + "/services/" + serviceName
    headers = {'Content-Type': content_type, 'Authorization': jwt}
    
    print("\nCalling NB Services API to get the details/status of the NB service {} on the host {}".format(serviceName, host_uuid))
    
    resp = requests.get(url, headers=headers, verify=False)
    
    if resp.status_code != 200:
        print("GET NB Service API failed with status code {} and {}\n".format(resp.status_code, resp.json()))
        raise SystemExit("\n\n")

    return resp.json()	
