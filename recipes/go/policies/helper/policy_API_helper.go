//This script consists of the helper functions to excute NetBackup APIs to assist in policy CRUD operations

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

package helper

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
    contentType       = "application/vnd.netbackup+json;version=2.0"
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
    fmt.Printf("\nLogin to the NetBackup webservices...\n")

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
    request.Header.Add("Content-Type", contentType);

    response, err := httpClient.Do(request)

    token := ""
    if err != nil {
        fmt.Printf("The HTTP request failed with error: %s\n", err)
        panic("Unable to login to the NetBackup webservices")
    } else {
        if response.StatusCode == 201 {
            data, _ := ioutil.ReadAll(response.Body)
            var obj interface{}
            json.Unmarshal(data, &obj)
            loginResponse := obj.(map[string]interface{})
            token = loginResponse["token"].(string)
        } else {
            responseBody, _ := ioutil.ReadAll(response.Body)
            fmt.Printf("%s\n", responseBody)
            panic("Unable to login to the NetBackup webservices")
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
    request.Header.Add("Content-Type", contentType);
    request.Header.Add("Authorization", jwt);
    request.Header.Add("X-NetBackup-Audit-Reason", "created policy " + testPolicyName);

    response, err := httpClient.Do(request)

    if err != nil {
        fmt.Printf("The HTTP request failed with error: %s\n", err)
        panic("Unable to create policy.\n")
    } else {
        if response.StatusCode != 204 {
            responseBody, _ := ioutil.ReadAll(response.Body)
            fmt.Printf("%s\n", responseBody)
            panic("Unable to create policy.\n")
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
    request.Header.Add("Content-Type", contentType);
    request.Header.Add("Authorization", jwt);

    response, err := httpClient.Do(request)

    if err != nil {
        fmt.Printf("The HTTP request failed with error: %s\n", err)
        panic("Unable to create policy.\n")
    } else {
        if response.StatusCode != 204 {
            responseBody, _ := ioutil.ReadAll(response.Body)
            fmt.Printf("%s\n", responseBody)
            panic("Unable to create policy.\n")
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
            responseBody, _ := ioutil.ReadAll(response.Body)
            fmt.Printf("%s\n", responseBody)
            panic("Unable to list policies.\n")
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
            responseBody, _ := ioutil.ReadAll(response.Body)
            fmt.Printf("%s\n", responseBody)
            panic("Unable to read policy.\n")
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
            responseBody, _ := ioutil.ReadAll(response.Body)
            fmt.Printf("%s\n", responseBody)
            panic("Unable to delete policy.\n")
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
    request.Header.Add("Content-Type", contentType);
    request.Header.Add("Authorization", jwt);
    request.Header.Add("If-Match", "1");
    request.Header.Add("X-NetBackup-Audit-Reason", "added client " + testClientName + " to policy " + testPolicyName);

    response, err := httpClient.Do(request)

    if err != nil {
        fmt.Printf("The HTTP request failed with error: %s\n", err)
        panic("Unable to add client to policy.\n")
    } else {
        if response.StatusCode != 201 {
            responseBody, _ := ioutil.ReadAll(response.Body)
            fmt.Printf("%s\n", responseBody)
            panic("Unable to add client to policy.\n")
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
            responseBody, _ := ioutil.ReadAll(response.Body)
            fmt.Printf("%s\n", responseBody)
            panic("Unable to delete client.\n")
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
    request.Header.Add("Content-Type", contentType);
    request.Header.Add("Authorization", jwt);

    response, err := httpClient.Do(request)

    if err != nil {
        fmt.Printf("The HTTP request failed with error: %s\n", err)
        panic("Unable to add schedule to policy.\n")
    } else {
        if response.StatusCode != 201 {
            responseBody, _ := ioutil.ReadAll(response.Body)
            fmt.Printf("%s\n", responseBody)
            panic("Unable to add schedule to policy.\n")
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
            responseBody, _ := ioutil.ReadAll(response.Body)
            fmt.Printf("%s\n", responseBody)
            panic("Unable to delete schedule.\n")
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
    request.Header.Add("Content-Type", contentType);
    request.Header.Add("Authorization", jwt);

    response, err := httpClient.Do(request)

    if err != nil {
        fmt.Printf("The HTTP request failed with error: %s\n", err)
        panic("Unable to add backupselection to policy.\n")
    } else {
        if response.StatusCode != 204 {
            responseBody, _ := ioutil.ReadAll(response.Body)
            fmt.Printf("%s\n", responseBody)
            panic("Unable to add backupselection to policy.\n")
        } else {
            fmt.Printf("backupselection added to %s successfully.\n", testPolicyName);
        }
    }
}
