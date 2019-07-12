//This script consists of the helper functions to excute NetBackup APIs

// 1. Get the HTTP client to perform API requests
// 2. Login to the NetBackup webservices
// 3. Create a policy with default values for the policy attributes
// 4. Create a policy with specific values for the policy attributes, schedules, clients, and backup selection
// 5. Read a policy
// 6. List all policies
// 7. Add/Update a schedule
// 8. Delete a schedule
// 9. Add/Update a client
// 10. Delete a client
// 11. Add/Update backup selection
// 12. Delete a policy
// 13. Get exclude list for a host
// 14. Set exclude list for a host
// 15. Get NetBackup processes running on a host
// 16. Get NetBackup processes matching a filter criteria
// 17. Get NetBackup services available on a host
// 18. Get NetBackup service with a name on a host

package apihelper

import (
    "bytes"
    "crypto/tls"
    "encoding/json"
    "fmt"
    "io/ioutil"
    "net/http"
    "net/http/httputil"
)

//###################
// Global Variables
//###################
const (
    port              = "1556"
    policiesUri       = "config/policies/"
    contentTypeV2       = "application/vnd.netbackup+json;version=2.0"
    contentTypeV3       = "application/vnd.netbackup+json;version=3.0"
    testPolicyName    = "vmware_test_policy"
    testClientName    = "MEDIA_SERVER"
    testScheduleName  = "vmware_test_schedule"
)

//##############################################################
// Setup the HTTP client to make NetBackup Policy API requests
//##############################################################
func GetHTTPClient() *http.Client {
    tlsConfig := &tls.Config {
        InsecureSkipVerify: true, //for this test, ignore ssl certificate
    }

    tr := &http.Transport{TLSClientConfig: tlsConfig}
    client := &http.Client{Transport: tr}

    return client
}

//#####################################
// Login to the NetBackup webservices
//#####################################
func Login(nbmaster string, httpClient *http.Client, username string, password string, domainName string, domainType string) string {
    fmt.Printf("\nLog into the NetBackup webservices...\n")

    loginDetails := map[string]string{"userName": username, "password": password}
    if len(domainName) > 0 {
        loginDetails["domainName"] = domainName
    }
    if len(domainType) > 0 {
        loginDetails["domainType"] = domainType
    }
    loginRequest, _ := json.Marshal(loginDetails)

    uri :=  "https://" + nbmaster + ":" + port + "/netbackup/login"

    request, _ := http.NewRequest(http.MethodPost, uri, bytes.NewBuffer(loginRequest))
    request.Header.Add("Content-Type", contentTypeV2);

    response, err := httpClient.Do(request)

    token := ""
    if err != nil {
        fmt.Printf("The HTTP request failed with error: %s\n", err)
        panic("Unable to login to the NetBackup webservices.")
    } else {
        if response.StatusCode == 201 {
            data, _ := ioutil.ReadAll(response.Body)
            var obj interface{}
            json.Unmarshal(data, &obj)
            loginResponse := obj.(map[string]interface{})
            token = loginResponse["token"].(string)
        } else {
            printErrorResponse(response)
        }
    }

    return token
}

//#######################################################################
// Create a policy consisting of a client, schedule and backup selection
//#######################################################################
func CreatePolicy(nbmaster string, httpClient *http.Client, jwt string) {
    fmt.Printf("\nSending a POST request to create %s with defaults...\n", testPolicyName)

    policy := map[string]interface{}{
        "data": map[string]interface{}{
            "type": "policy",
            "id": testPolicyName,
            "attributes": map[string]interface{}{
                "policy": map[string]interface{}{
                    "policyName": testPolicyName,
                    "policyType": "VMware",
                    "policyAttributes": map[string]interface{}{
                        "active": true,
                        "applicationConsistent": true,
                        "applicationDiscovery": true,
                        "applicationProtection": []string{},
                        "autoManagedLabel": nil,
                        "autoManagedType": 0,
                        "backupHost": "MEDIA_SERVER",
                        "blockIncremental": true,
                        "dataClassification": nil,
                        "disableClientSideDeduplication": false,
                        "discoveryLifetime": 28800,
                        "effectiveDateUTC": "2018-06-19T18:47:25Z",
                        "jobLimit": 2147483647,
                        "keyword": testPolicyName,
                        "mediaOwner": "*ANY*",
                        "priority": 0,
                        "secondarySnapshotMethodArgs": nil,
                        "snapshotMethodArgs": "skipnodisk=0,post_events=1,multi_org=0,Virtual_machine_backup=2,continue_discovery=0,nameuse=0,exclude_swap=1,tags_unset=0,ignore_irvm=1,rLim=10,snapact=3,enable_quiesce_failover=0,file_system_optimization=1,drive_selection=0,disable_quiesce=0,enable_vCloud=0,trantype=san:hotadd:nbd:nbdssl,rHz=10,rTO=0",
                        "storage": nil,
                        "storageIsSLP": false,
                        "useAccelerator": false,
                        "useReplicationDirector": false,
                        "volumePool": "NetBackup"},
                    "clients":[]map[string]string{{
                        "hardware": "VMware",
                        "hostName": testClientName,
                        "OS": "VMware"}},
                    "schedules":[]map[string]interface{}{{
                        "acceleratorForcedRescan": false,
                        "backupCopies": map[string]interface{}{
                        "priority": 9999,
                        "copies": []map[string]interface{}{{
                            "mediaOwner": "owner1",
                            "storage": nil,
                            "retentionPeriod": map[string]interface{}{
                                "value": 9,
                                "unit": "WEEKS"},
                            "volumePool": "NetBackup",
                            "failStrategy": "Continue"}}},
                        "backupType": "Full Backup",
                        "excludeDates": map[string]interface{}{
                        "lastDayOfMonth": true,
                        "recurringDaysOfWeek": []string{"4:6", "2:5"},
                        "recurringDaysOfMonth": []int{10},
                        "specificDates": []string{"2018-1-1", "2018-2-30"}},
                        "frequencySeconds": 4800,
                        "includeDates": map[string]interface{}{
                            "lastDayOfMonth": true,
                            "recurringDaysOfWeek": []string{"2:3", "3:4"},
                            "recurringDaysOfMonth": []int{10,13},
                            "specificDates": []string{"2018-12-31"}},
                        "mediaMultiplexing": 2,
                        "retriesAllowedAfterRunDay": true,
                        "scheduleName": testScheduleName,
                        "scheduleType": "Calendar",
                        "snapshotOnly": false,
                        "startWindow": []map[string]interface{}{{
                            "dayOfWeek": 1,
                            "startSeconds": 14600,
                            "durationSeconds": 24600},
                            {"dayOfWeek": 2,
                             "startSeconds": 14600,
                             "durationSeconds": 24600},
                            {"dayOfWeek": 3,
                             "startSeconds": 14600,
                             "durationSeconds": 24600},
                            {"dayOfWeek": 4,
                             "startSeconds": 14600,
                             "durationSeconds": 24600},
                            {"dayOfWeek": 5,
                             "startSeconds": 14600,
                             "durationSeconds": 24600},
                            {"dayOfWeek": 6,
                             "startSeconds": 14600,
                             "durationSeconds": 24600},
                            {"dayOfWeek": 7,
                             "startSeconds": 14600,
                             "durationSeconds": 24600}},
                        "syntheticBackup": false,
                        "storageIsSLP": false}},
                    "backupSelections": map[string]interface{}{
                        "selections": []string{"vmware:/?filter=Displayname Contains 'rsv' OR Displayname Contains 'mtv'"}}}}}}

    policyRequest, _ := json.Marshal(policy)

    uri := "https://" + nbmaster + ":" + port + "/netbackup/" + policiesUri

    request, _ := http.NewRequest(http.MethodPost, uri, bytes.NewBuffer(policyRequest))
    request.Header.Add("Content-Type", contentTypeV2);
    request.Header.Add("Authorization", jwt);
    request.Header.Add("X-NetBackup-Audit-Reason", "created policy " + testPolicyName);

    response, err := httpClient.Do(request)

    if err != nil {
        fmt.Printf("The HTTP request failed with error: %s\n", err)
        panic("Unable to create policy.\n")
    } else {
        if response.StatusCode != 204 {
            printErrorResponse(response)
        } else {
            fmt.Printf("%s created successfully.\n", testPolicyName);
            responseDetails, _ := httputil.DumpResponse(response, true);
            fmt.Printf(string(responseDetails))
        }
    }
}

//################################################
// Create a policy with default attribute values
//################################################
func CreatePolicyWithDefaults(nbmaster string, httpClient *http.Client, jwt string) {
    fmt.Printf("\nSending a POST request to create %s with defaults...\n", testPolicyName)

    policy := map[string]interface{}{
        "data": map[string]interface{}{
            "type": "policy",
            "id": testPolicyName,
            "attributes": map[string]interface{}{
                "policy": map[string]interface{}{
                    "policyName": testPolicyName,
                    "policyType": "VMware",
                    "policyAttributes": map[string]interface{}{},
                    "clients":[]interface{}{},
                    "schedules":[]interface{}{},
                    "backupSelections": map[string]interface{}{
                        "selections": []interface{}{}}}}}}

    policyRequest, _ := json.Marshal(policy)

    uri := "https://" + nbmaster + ":" + port + "/netbackup/" + policiesUri

    request, _ := http.NewRequest(http.MethodPost, uri, bytes.NewBuffer(policyRequest))
    request.Header.Add("Content-Type", contentTypeV2);
    request.Header.Add("Authorization", jwt);

    response, err := httpClient.Do(request)

    if err != nil {
        fmt.Printf("The HTTP request failed with error: %s\n", err)
        panic("Unable to create policy.\n")
    } else {
        if response.StatusCode != 204 {
            printErrorResponse(response)
        } else {
            fmt.Printf("%s created successfully.\n", testPolicyName);
            responseDetails, _ := httputil.DumpResponse(response, true);
            fmt.Printf(string(responseDetails))
        }
    }
}

//####################
// List all policies
//####################
func ListPolicies(nbmaster string, httpClient *http.Client, jwt string) {
    fmt.Printf("\nSending a GET request to list all policies...\n")

    uri := "https://" + nbmaster + ":" + port + "/netbackup/" + policiesUri

    request, _ := http.NewRequest(http.MethodGet, uri, nil)
    request.Header.Add("Authorization", jwt);

    response, err := httpClient.Do(request)

    if err != nil {
        fmt.Printf("The HTTP request failed with error: %s\n", err)
        panic("Unable to list policies.\n")
    } else {
        if response.StatusCode != 200 {
            printErrorResponse(response)
        } else {
            responseBody, _ := ioutil.ReadAll(response.Body)
            fmt.Printf("%s\n", responseBody)
        }
    }
}

//################
// Read a policy
//################
func ReadPolicy(nbmaster string, httpClient *http.Client, jwt string) {
    fmt.Printf("\nSending a GET request to read policy %s...\n", testPolicyName)

    uri := "https://" + nbmaster + ":" + port + "/netbackup/" + policiesUri + testPolicyName

    request, _ := http.NewRequest(http.MethodGet, uri, nil)
    request.Header.Add("Authorization", jwt);

    response, err := httpClient.Do(request)

    if err != nil {
        fmt.Printf("The HTTP request failed with error: %s\n", err)
        panic("Unable to read policy.\n")
    } else {
        if response.StatusCode != 200 {
            printErrorResponse(response)
        } else {
            responseBody, _ := ioutil.ReadAll(response.Body)
            fmt.Printf("%s\n", responseBody)
        }
    }
}

//##################
// Delete a policy
//##################
func DeletePolicy(nbmaster string, httpClient *http.Client, jwt string) {
    fmt.Printf("\nSending a DELETE request to delete policy %s...\n", testPolicyName)

    uri := "https://" + nbmaster + ":" + port + "/netbackup/" + policiesUri + testPolicyName

    request, _ := http.NewRequest(http.MethodDelete, uri, nil)
    request.Header.Add("Authorization", jwt);

    response, err := httpClient.Do(request)

    if err != nil {
        fmt.Printf("The HTTP request failed with error: %s\n", err)
        panic("Unable to delete policy.\n")
    } else {
        if response.StatusCode != 204 {
            printErrorResponse(response)
        } else {
            fmt.Printf("%s deleted successfully.\n", testPolicyName);
        }
    }
}

//###########################
// Add a client to a policy
//###########################
func AddClient(nbmaster string, httpClient *http.Client, jwt string) {
    fmt.Printf("\nSending a PUT request to add client %s to policy %s...\n", testClientName, testPolicyName)

    client := map[string]interface{}{
        "data": map[string]interface{}{
            "type": "client",
            "attributes": map[string]string{
                "hardware": "VMware",
                "hostName": "MEDIA_SERVER",
                "OS": "VMware"}}}

    clientRequest, _ := json.Marshal(client)

    uri := "https://" + nbmaster + ":" + port + "/netbackup/" + policiesUri + testPolicyName + "/clients/" + testClientName

    request, _ := http.NewRequest(http.MethodPut, uri, bytes.NewBuffer(clientRequest))
    request.Header.Add("Content-Type", contentTypeV2);
    request.Header.Add("Authorization", jwt);
    request.Header.Add("If-Match", "1");
    request.Header.Add("X-NetBackup-Audit-Reason", "added client " + testClientName + " to policy " + testPolicyName);

    response, err := httpClient.Do(request)

    if err != nil {
        fmt.Printf("The HTTP request failed with error: %s\n", err)
        panic("Unable to add client to policy.\n")
    } else {
        if response.StatusCode != 201 {
            printErrorResponse(response)
        } else {
            fmt.Printf("%s added to %s successfully.\n", testClientName, testPolicyName);
            responseDetails, _ := httputil.DumpResponse(response, true);
            fmt.Printf(string(responseDetails))
        }
    }
}

//#################################
// Delete a client from a policy
//#################################
func DeleteClient(nbmaster string, httpClient *http.Client, jwt string) {
    fmt.Printf("\nSending a DELETE request to delete client %s from policy %s...\n", testClientName, testPolicyName)

    uri := "https://" + nbmaster + ":" + port + "/netbackup/" + policiesUri + testPolicyName + "/clients/" + testClientName

    request, _ := http.NewRequest(http.MethodDelete, uri, nil)
    request.Header.Add("Authorization", jwt);

    response, err := httpClient.Do(request)

    if err != nil {
        fmt.Printf("The HTTP request failed with error: %s\n", err)
        panic("Unable to delete client.\n")
    } else {
        if response.StatusCode != 204 {
            printErrorResponse(response)
        } else {
            fmt.Printf("%s deleted successfully.\n", testClientName);
        }
    }
}

//###########################
// Add a schedule to policy
//###########################
func AddSchedule(nbmaster string, httpClient *http.Client, jwt string) {
    fmt.Printf("\nSending a PUT request to add schedule %s to policy %s...\n", testScheduleName, testPolicyName)

    schedule := map[string]interface{}{
        "data": map[string]interface{}{
            "type": "schedule",
            "id": testScheduleName,
            "attributes": map[string]interface{}{
                "acceleratorForcedRescan": false,
                "backupCopies": map[string]interface{}{
                    "priority": 9999,
                    "copies": []map[string]interface{}{{
                        "mediaOwner": "owner1",
                        "storage": nil,
                        "retentionPeriod": map[string]interface{}{
                            "value": 9,
                            "unit": "WEEKS"},
                        "volumePool": "NetBackup",
                        "failStrategy": "Continue"}}},
                "backupType": "Full Backup",
                "excludeDates": map[string]interface{}{
                    "lastDayOfMonth": true,
                    "recurringDaysOfWeek": []string{"4:6", "2:5"},
                    "recurringDaysOfMonth": []int{10},
                    "specificDates": []string{"2000-1-1", "2016-2-30"}},
                "frequencySeconds": 4800,
                "includeDates": map[string]interface{}{
                    "lastDayOfMonth": true,
                    "recurringDaysOfWeek": []string{"2:3", "3:4"},
                    "recurringDaysOfMonth": []int{10,13},
                    "specificDates": []string{"2016-12-31"}},
                "mediaMultiplexing": 2,
                "retriesAllowedAfterRunDay": true,
                "scheduleType": "Calendar",
                "snapshotOnly": false,
                "startWindow": []map[string]interface{}{{
                    "dayOfWeek": 1,
                    "startSeconds": 14600,
                    "durationSeconds": 24600},
                    {"dayOfWeek": 2,
                     "startSeconds": 14600,
                     "durationSeconds": 24600},
                    {"dayOfWeek": 3,
                     "startSeconds": 14600,
                     "durationSeconds": 24600},
                    {"dayOfWeek": 4,
                     "startSeconds": 14600,
                     "durationSeconds": 24600},
                    {"dayOfWeek": 5,
                     "startSeconds": 14600,
                     "durationSeconds": 24600},
                    {"dayOfWeek": 6,
                     "startSeconds": 14600,
                     "durationSeconds": 24600},
                    {"dayOfWeek": 7,
                     "startSeconds": 14600,
                     "durationSeconds": 24600}},
                "syntheticBackup": false,
                "storageIsSLP": false}}}

    scheduleRequest, _ := json.Marshal(schedule)

    uri := "https://" + nbmaster + ":" + port + "/netbackup/" + policiesUri + testPolicyName + "/schedules/" + testScheduleName

    request, _ := http.NewRequest(http.MethodPut, uri, bytes.NewBuffer(scheduleRequest))
    request.Header.Add("Content-Type", contentTypeV2);
    request.Header.Add("Authorization", jwt);

    response, err := httpClient.Do(request)

    if err != nil {
        fmt.Printf("The HTTP request failed with error: %s\n", err)
        panic("Unable to add schedule to policy.\n")
    } else {
        if response.StatusCode != 201 {
            printErrorResponse(response)
        } else {
            fmt.Printf("%s added to %s successfully.\n", testScheduleName, testPolicyName);
        }
    }
}

//#################################
// Delete a schedule from a policy
//#################################
func DeleteSchedule(nbmaster string, httpClient *http.Client, jwt string) {
    fmt.Printf("\nSending a DELETE request to delete schedule %s from policy %s...\n", testScheduleName, testPolicyName)

    uri := "https://" + nbmaster + ":" + port + "/netbackup/" + policiesUri + testPolicyName + "/schedules/" + testScheduleName

    request, _ := http.NewRequest(http.MethodDelete, uri, nil)
    request.Header.Add("Authorization", jwt);

    response, err := httpClient.Do(request)

    if err != nil {
        fmt.Printf("The HTTP request failed with error: %s\n", err)
        panic("Unable to delete schedule.\n")
    } else {
        if response.StatusCode != 204 {
            printErrorResponse(response)
        } else {
            fmt.Printf("%s deleted successfully.\n", testScheduleName);
        }
    }
}

//#####################################
// Add a backup selection to a policy
//#####################################
func AddBackupSelection(nbmaster string, httpClient *http.Client, jwt string) {
    fmt.Printf("\nSending a PUT request to add backupselection to policy %s...\n", testPolicyName)

    bkupSelection := map[string]interface{}{
        "data": map[string]interface{}{
            "type": "backupSelection",
            "attributes": map[string]interface{}{
                "selections": []string{"vmware:/?filter=Displayname Contains 'rsv' OR Displayname Contains 'mtv'"}}}}

    bkupSelectionRequest, _ := json.Marshal(bkupSelection)

    uri := "https://" + nbmaster + ":" + port + "/netbackup/" + policiesUri + testPolicyName + "/backupselections"

    request, _ := http.NewRequest(http.MethodPut, uri, bytes.NewBuffer(bkupSelectionRequest))
    request.Header.Add("Content-Type", contentTypeV2);
    request.Header.Add("Authorization", jwt);

    response, err := httpClient.Do(request)

    if err != nil {
        fmt.Printf("The HTTP request failed with error: %s\n", err)
        panic("Unable to add backupselection to policy.\n")
    } else {
        if response.StatusCode != 204 {
            printErrorResponse(response)
        } else {
            fmt.Printf("backupselection added to %s successfully.\n", testPolicyName);
        }
    }
}

//#####################################################
// Get the host UUID 
//#####################################################
func GetHostUUID(nbmaster string, httpClient *http.Client, jwt string, host string) string {
    fmt.Printf("\nGet the UUID of host %s...\n", host)

    uri := "https://" + nbmaster + ":" + port + "/netbackup/config/hosts";

    request, _ := http.NewRequest(http.MethodGet, uri, nil)
    query := request.URL.Query()
    query.Add("filter", "hostName eq '" + host + "'")
    request.URL.RawQuery = query.Encode()

    request.Header.Add("Authorization", jwt);
    request.Header.Add("Accept", contentTypeV3);

    response, err := httpClient.Do(request)

    hostUuid := ""
    if err != nil {
        fmt.Printf("The HTTP request failed with error: %s\n", err)
        panic("Unable to get the host UUID")
    } else {
        if response.StatusCode == 200 {
            data, _ := ioutil.ReadAll(response.Body)
            var obj interface{}
            json.Unmarshal(data, &obj)
            response := obj.(map[string]interface{})
            hosts := response["hosts"].([]interface{})
            hostUuid = ((hosts[0].(map[string]interface{}))["uuid"]).(string)
            fmt.Printf("Host UUID: %s\n", hostUuid);
        } else {
            printErrorResponse(response)
        }
    }

    return hostUuid
}

//#################################
// Get exclude lists for this host
//#################################
func GetExcludeLists(nbmaster string, httpClient *http.Client, jwt string, hostUuid string) {
    fmt.Printf("\nGet exclude list for host %s...\n", hostUuid)

    uri :=  "https://" + nbmaster + ":" + port + "/netbackup/config/hosts/" + hostUuid + "/configurations/exclude"

    request, _ := http.NewRequest(http.MethodGet, uri, nil)
    request.Header.Add("Authorization", jwt);
    request.Header.Add("Content-Type", contentTypeV3);

    response, err := httpClient.Do(request)

    if err != nil {
        fmt.Printf("The HTTP request failed with error: %s\n", err)
        panic("Unable to get exclude list")
    } else {
        if response.StatusCode == 200 {
            resp, _ := ioutil.ReadAll(response.Body)
            var obj interface{}
            json.Unmarshal(resp, &obj)
            data := obj.(map[string]interface{})
            var excludeLists []interface{} = ((((data["data"].(map[string]interface{}))["attributes"]).(map[string]interface{}))["value"]).([]interface{})
            for _, list := range excludeLists {
                fmt.Printf("%s\n", list)
            }
        } else {
            printErrorResponse(response)
        }
    }
}

//#################################
// Set exclude lists for this host
//#################################
func SetExcludeLists(nbmaster string, httpClient *http.Client, jwt string, hostUuid string) {
    fmt.Printf("\nSet exclude list for host %s...\n", hostUuid)

    uri :=  "https://" + nbmaster + ":" + port + "/netbackup/config/hosts/" + hostUuid + "/configurations/exclude"

    excludeList := map[string]interface{}{
        "data": map[string]interface{}{
            "type": "hostConfiguration",
            "attributes": map[string]interface{}{
                "name": "exclude",
                "value": []string{"C:\\Program Files\\Veritas\\NetBackup\\bin\\*.lock",
                          "C:\\Program Files\\Veritas\\NetBackup\\bin\\bprd.d\\*.lock",
                          "C:\\Program Files\\Veritas\\NetBackup\\bin\\bpsched.d\\*.lock",
                          "C:\\Program Files\\Veritas\\Volmgr\\misc\\*",
                          "C:\\Program Files\\Veritas\\NetBackupDB\\data\\*",
                          "C:\\tmp"}}}}

    excludeListRequest, _ := json.Marshal(excludeList)
    request, _ := http.NewRequest(http.MethodPut, uri, bytes.NewBuffer(excludeListRequest))
    request.Header.Add("Content-Type", contentTypeV3);
    request.Header.Add("Authorization", jwt);

    response, err := httpClient.Do(request)

    if err != nil {
        fmt.Printf("The HTTP request failed with error: %s\n", err)
        panic("Unable to set exclude list")
    } else {
        if response.StatusCode == 204 {
            fmt.Printf("Exclude list was configured successfully.\n");
        } else {
            if response.StatusCode == 404 {
                uri := "https://" + nbmaster + ":" + port + "/netbackup/config/hosts/" + hostUuid + "/configurations"
                request, _ := http.NewRequest(http.MethodPost, uri, bytes.NewBuffer(excludeListRequest))
                request.Header.Add("Content-Type", contentTypeV3);
                request.Header.Add("Authorization", jwt);

                response, err := httpClient.Do(request)
                if err != nil {
                    fmt.Printf("The HTTP request failed with error: %s\n", err)
                } else {
                    if response.StatusCode == 204 {
                        fmt.Printf("Exclude list was configured successfully.\n");
                    } else {
                        printErrorResponse(response)
                    }
                }
            } else {
                printErrorResponse(response)
            }
        }
    }
}

//#############################################
// Get NetBackup processes running on this host
//#############################################
func GetProcesses(nbmaster string, httpClient *http.Client, jwt string, host string, hostUuid string, filter string) {
    uri :=  "https://" + nbmaster + ":" + port + "/netbackup/admin/hosts/" + hostUuid + "/processes"

    request, _ := http.NewRequest(http.MethodGet, uri, nil)
    request.Header.Add("Authorization", jwt);
    request.Header.Add("Content-Type", contentTypeV3);

    if filter != "" {
        query := request.URL.Query()
        query.Add("filter", filter)
        request.URL.RawQuery = query.Encode()
        fmt.Printf("\nGet NetBackup processes with filter criteria %s running on %s...\n\n", filter, host)
    } else {
        fmt.Printf("\nGet NetBackup processes running on %s...\n\n", host)
    }

    response, err := httpClient.Do(request)

    if err != nil {
        fmt.Printf("The HTTP request failed with error: %s\n", err)
        panic("Unable to get processes.")
    } else {
        if response.StatusCode == 200 {
            resp, _ := ioutil.ReadAll(response.Body)
            var obj interface{}
            json.Unmarshal(resp, &obj)
            data := obj.(map[string]interface{})
            var processes []interface{} = data["data"].([]interface{})

            fmt.Printf("pid     processName      priority memoryUsageMB startTime              elapsedTime\n");
            fmt.Printf("=======.================.========.=============.======================.======================\n");
            for _, process := range processes {
                attributes := ((process.(map[string]interface{}))["attributes"]).(map[string]interface{})

                pid := attributes["pid"].(float64)
                processName := attributes["processName"]
                priority := attributes["priority"].(float64)
                memoryUsageMB := attributes["memoryUsageMB"].(float64)
                startTime := attributes["startTime"]
                elapsedTime := attributes["elapsedTime"]

                fmt.Printf("%7.0f %-16s %8.0f %13.2f %22s %22s\n", pid, processName, priority, memoryUsageMB, startTime, elapsedTime);
            }
        } else {
            printErrorResponse(response)
        }
    }
}

//##############################################
// Get NetBackup services available on this host
//##############################################
func GetServices(nbmaster string, httpClient *http.Client, jwt string, host string, hostUuid string) {
    fmt.Printf("\nGet NetBackup services available on %s...\n\n", host)

    uri :=  "https://" + nbmaster + ":" + port + "/netbackup/admin/hosts/" + hostUuid + "/services"

    request, _ := http.NewRequest(http.MethodGet, uri, nil)
    request.Header.Add("Authorization", jwt);
    request.Header.Add("Content-Type", contentTypeV3);

    response, err := httpClient.Do(request)

    if err != nil {
        fmt.Printf("The HTTP request failed with error: %s\n", err)
        panic("Unable to get services")
    } else {
        if response.StatusCode == 200 {
            resp, _ := ioutil.ReadAll(response.Body)
            var obj interface{}
            json.Unmarshal(resp, &obj)
            data := obj.(map[string]interface{})
            var services []interface{} = data["data"].([]interface{})

            fmt.Printf("id           status\n");
            fmt.Printf("============.=========\n");
            for _, service := range services {
                id := (service.(map[string]interface{}))["id"]
                status := (((service.(map[string]interface{}))["attributes"]).(map[string]interface{}))["status"]

                fmt.Printf("%-12s %s\n", id, status);
            }
        } else {
            printErrorResponse(response)
        }
    }
}

//#####################################################
// Get NetBackup service with the given id on this host
//#####################################################
func GetService(nbmaster string, httpClient *http.Client, jwt string, host string, hostUuid string, serviceName string) {
    fmt.Printf("\nGet NetBackup service %s on %s...\n\n", serviceName, host)

    uri :=  "https://" + nbmaster + ":" + port + "/netbackup/admin/hosts/" + hostUuid + "/services/" + serviceName

    request, _ := http.NewRequest(http.MethodGet, uri, nil)
    request.Header.Add("Authorization", jwt);
    request.Header.Add("Content-Type", contentTypeV3);

    response, err := httpClient.Do(request)

    if err != nil {
        fmt.Printf("The HTTP request failed with error: %s\n", err)
        panic("Unable to get services")
    } else {
        if response.StatusCode == 200 {
            resp, _ := ioutil.ReadAll(response.Body)
            var obj interface{}
            json.Unmarshal(resp, &obj)
            service := obj.(map[string]interface{})["data"].(map[string]interface{})

            fmt.Printf("id           status\n");
            fmt.Printf("============.=========\n");
            id := (service)["id"]
            status := ((service)["attributes"]).(map[string]interface{})["status"]

            fmt.Printf("%-12s %s\n", id, status);
        } else {
            printErrorResponse(response)
        }
    }
}

func printErrorResponse(response *http.Response) {
    responseBody, _ := ioutil.ReadAll(response.Body)
    var obj interface{}
    json.Unmarshal(responseBody, &obj)

    if obj != nil {
        error := obj.(map[string]interface{})
        errorCode := error["errorCode"].(float64)
        errorMessage := error["errorMessage"].(string)
        fmt.Printf("Error code:%.0f\nError message:%s\n", errorCode, errorMessage)
    } else {
        responseDetails, _ := httputil.DumpResponse(response, true);
        fmt.Printf(string(responseDetails))
    }

    panic("Request failed");
}
