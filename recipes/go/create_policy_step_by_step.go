//This script can be run using NetBackup 8.1.2 and higher.
//It creates a policy with the default values for policy type specific attributes, adds a client, schedule, and backup selection to it, 
//then deletes the client, schedule and finally deletes the policy.

package main

import (
    "bytes"
    "crypto/tls"
    "encoding/json"
    "flag"
    "fmt"
    "io/ioutil"
    "log"
    "net/http"
    "os"
)

//###################
// Global Variables
//###################
var (
    usage               = "\n\nUsage: go run ./create_policy_step_by_step.go -nbmaster <masterServer> -username <username> -password <password> [-domainName <domainName>] [-domainType <domainType>]\n\n"

    nbmaster            = flag.String("nbmaster", "", "NetBackup Master Server")
    username            = flag.String("username", "", "User name to log into the NetBackup webservices")
    password            = flag.String("password", "", "Password for the given user")
    domainName          = flag.String("domainName", "", "Domain name of the given user")
    domainType          = flag.String("domainType", "", "Domain type of the given user")

    policiesUri         = "config/policies/"
    contentType         = "application/vnd.netbackup+json;version=2.0"
    testPolicyName      = "vmware_test_policy"
    testClientName      = "MEDIA_SERVER"
    testScheduleName    = "vmware_test_schedule"
    port                = "1556"
    baseUri string
    httpClient *http.Client
    authorizationToken string
)

//##############################################################
// Setup the HTTP client to make NetBackup Policy API requests
//##############################################################
func setup() *http.Client {
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
func login() string {
    fmt.Printf("\nLogin to the NetBackup webservices...\n")

    loginDetails := map[string]string{"userName": *username, "password": *password}
    if len(*domainName) > 0 {
        loginDetails["domainName"] = *domainName
    }
    if len(*domainType) > 0 {
        loginDetails["domainType"] = *domainType
    }
    loginRequest, _ := json.Marshal(loginDetails)

    request, _ := http.NewRequest(http.MethodPost, baseUri + "login", bytes.NewBuffer(loginRequest))
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

//################################################
// Create a policy with default attribute values
//################################################
func createPolicyWithDefaults() {
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

    uri := baseUri + policiesUri
    request, _ := http.NewRequest(http.MethodPost, uri, bytes.NewBuffer(policyRequest))
    request.Header.Add("Content-Type", contentType);
    request.Header.Add("Authorization", authorizationToken);
    response, err := httpClient.Do(request)

    if err != nil {
        fmt.Printf("Unable to create policy %s.\n%s", testPolicyName, err)
    } else {
        if response.StatusCode != 204 {
            fmt.Printf("Unable to create policy %s.\n", testPolicyName)
            responseBody, _ := ioutil.ReadAll(response.Body)
            fmt.Printf("%s\n", responseBody)
        } else {
            fmt.Printf("%s created successfully.\n", testPolicyName);
        }
    }
}

//####################
// List all policies
//####################
func listPolicies() {
    fmt.Printf("\nSending a GET request to list all policies...\n")

    uri := baseUri + policiesUri
    request, _ := http.NewRequest(http.MethodGet, uri, nil)
    request.Header.Add("Authorization", authorizationToken);
    response, err := httpClient.Do(request)

    if err != nil {
        fmt.Printf("Unable to list policies.\n%s", err)
    } else {
        if response.StatusCode != 200 {
            fmt.Printf("Unable to list policies.\n")
            responseBody, _ := ioutil.ReadAll(response.Body)
            fmt.Printf("%s\n", responseBody)
        } else {
            responseBody, _ := ioutil.ReadAll(response.Body)
            fmt.Printf("%s\n", responseBody)
        }
    }
}

//################
// Read a policy
//################
func readPolicy() {
    fmt.Printf("\nSending a GET request to read policy %s...\n", testPolicyName)

    uri := baseUri + policiesUri + testPolicyName
    request, _ := http.NewRequest(http.MethodGet, uri, nil)
    request.Header.Add("Authorization", authorizationToken);
    response, err := httpClient.Do(request)

    if err != nil {
        fmt.Printf("Unable to read policy %s.\n%s", testPolicyName, err)
    } else {
        if response.StatusCode != 200 {
            fmt.Printf("Unable to read policy %s.\n", testPolicyName)
            responseBody, _ := ioutil.ReadAll(response.Body)
            fmt.Printf("%s\n", responseBody)
        } else {
            responseBody, _ := ioutil.ReadAll(response.Body)
            fmt.Printf("%s\n", responseBody)
        }
    }
}

//##################
// Delete a policy
//##################
func deletePolicy() {
    fmt.Printf("\nSending a DELETE request to delete policy %s...\n", testPolicyName)

    uri := baseUri + policiesUri + testPolicyName
    request, _ := http.NewRequest(http.MethodDelete, uri, nil)
    request.Header.Add("Authorization", authorizationToken);
    response, err := httpClient.Do(request)

    if err != nil {
        fmt.Printf("Unable to delete policy %s.\n%s", testPolicyName, err)
    } else {
        if response.StatusCode != 204 {
            fmt.Printf("Unable to delete policy %s.\n", testPolicyName)
            responseBody, _ := ioutil.ReadAll(response.Body)
            fmt.Printf("%s\n", responseBody)
        } else {
            fmt.Printf("%s deleted successfully.\n", testPolicyName);
        }
    }
}

//###########################
// Add a client to a policy
//###########################
func addClient() {
    fmt.Printf("\nSending a PUT request to add client %s to policy %s...\n", testClientName, testPolicyName)

    client := map[string]interface{}{
        "data": map[string]interface{}{
            "type": "client",
            "attributes": map[string]string{
                "hardware": "VMware",
                "hostName": "MEDIA_SERVER",
                "OS": "VMware"}}}

    clientRequest, _ := json.Marshal(client)

    uri := baseUri + policiesUri + testPolicyName + "/clients/" + testClientName
    request, _ := http.NewRequest(http.MethodPut, uri, bytes.NewBuffer(clientRequest))
    request.Header.Add("Content-Type", contentType);
    request.Header.Add("Authorization", authorizationToken);
    response, err := httpClient.Do(request)

    if err != nil {
        fmt.Printf("Unable to add client %s to policy %s.\n%s", testClientName, testPolicyName, err)
    } else {
        if response.StatusCode != 201 {
            fmt.Printf("Unable to add client %s to policy %s.\n", testClientName, testPolicyName)
            responseBody, _ := ioutil.ReadAll(response.Body)
            fmt.Printf("%s\n", responseBody)
        } else {
            fmt.Printf("%s added to %s successfully.\n", testClientName, testPolicyName);
        }
    }
}

//#################################
// Delete a client from a policy
//#################################
func deleteClient() {
    fmt.Printf("\nSending a DELETE request to delete client %s from policy %s...\n", testClientName, testPolicyName)

    uri := baseUri + policiesUri + testPolicyName + "/clients/" + testClientName
    request, _ := http.NewRequest(http.MethodDelete, uri, nil)
    request.Header.Add("Authorization", authorizationToken);
    response, err := httpClient.Do(request)

    if err != nil {
        fmt.Printf("Unable to delete client %s.\n%s", testClientName, err)
    } else {
        if response.StatusCode != 204 {
            fmt.Printf("Unable to delete client %s.\n", testClientName)
            responseBody, _ := ioutil.ReadAll(response.Body)
            fmt.Printf("%s\n", responseBody)
        } else {
            fmt.Printf("%s deleted successfully.\n", testClientName);
        }
    }
}

//###########################
// Add a schedule to policy
//###########################
func addSchedule() {
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

    uri := baseUri + policiesUri + testPolicyName + "/schedules/" + testScheduleName
    request, _ := http.NewRequest(http.MethodPut, uri, bytes.NewBuffer(scheduleRequest))
    request.Header.Add("Content-Type", contentType);
    request.Header.Add("Authorization", authorizationToken);
    response, err := httpClient.Do(request)

    if err != nil {
        fmt.Printf("Unable to add schedule %s to policy %s.\n%s", testScheduleName, testPolicyName, err)
    } else {
        if response.StatusCode != 201 {
            fmt.Printf("Unable to add schedule %s to policy %s.\n", testScheduleName, testPolicyName)
            responseBody, _ := ioutil.ReadAll(response.Body)
            fmt.Printf("%s\n", responseBody)
        } else {
            fmt.Printf("%s added to %s successfully.\n", testScheduleName, testPolicyName);
        }
    }
}

//#################################
// Delete a schedule from a policy
//#################################
func deleteSchedule() {
    fmt.Printf("\nSending a DELETE request to delete schedule %s from policy %s...\n", testScheduleName, testPolicyName)

    uri := baseUri + policiesUri + testPolicyName + "/schedules/" + testScheduleName
    request, _ := http.NewRequest(http.MethodDelete, uri, nil)
    request.Header.Add("Authorization", authorizationToken);
    response, err := httpClient.Do(request)

    if err != nil {
        fmt.Printf("Unable to delete schedule %s.\n%s", testScheduleName, err)
    } else {
        if response.StatusCode != 204 {
            fmt.Printf("Unable to delete schedule %s.\n", testScheduleName)
            responseBody, _ := ioutil.ReadAll(response.Body)
            fmt.Printf("%s\n", responseBody)
        } else {
            fmt.Printf("%s deleted successfully.\n", testScheduleName);
        }
    }
}

//#####################################
// Add a backup selection to a policy
//#####################################
func addBackupSelection() {
    fmt.Printf("\nSending a PUT request to add backupselection to policy %s...\n", testPolicyName)

    bkupSelection := map[string]interface{}{
        "data": map[string]interface{}{
            "type": "backupSelection",
            "attributes": map[string]interface{}{
                "selections": []string{"vmware:/?filter=Displayname Contains 'rsv' OR Displayname Contains 'mtv'"}}}}

    bkupSelectionRequest, _ := json.Marshal(bkupSelection)

    uri := baseUri + policiesUri + testPolicyName + "/backupselections"
    request, _ := http.NewRequest(http.MethodPut, uri, bytes.NewBuffer(bkupSelectionRequest))
    request.Header.Add("Content-Type", contentType);
    request.Header.Add("Authorization", authorizationToken);
    response, err := httpClient.Do(request)

    if err != nil {
        fmt.Printf("Unable to add backupselection to policy %s.\n%s", testPolicyName, err)
    } else {
        if response.StatusCode != 204 {
            fmt.Printf("Unable to add backupselection to policy %s.\n", testPolicyName)
            responseBody, _ := ioutil.ReadAll(response.Body)
            fmt.Printf("%s\n", responseBody)
        } else {
            fmt.Printf("backupselection added to %s successfully.\n", testPolicyName);
        }
    }
}

func main() {
    // Print usage
    flag.Usage = func() {
        fmt.Fprintf(os.Stderr, usage)
        os.Exit(1)
    }

    // Read command line arguments
    flag.Parse()

    if len(*nbmaster) == 0 {
        log.Fatalf("Please specify the name of the NetBackup Master Server using the -nbmaster parameter.\n")
    }
    if len(*username) == 0 {
        log.Fatalf("Please specify the username using the -username parameter.\n")
    }
    if len(*password) == 0 {
        log.Fatalf("Please specify the password using the -password parameter.\n")
    }

    baseUri = "https://" + *nbmaster + ":" + port + "/netbackup/"
    httpClient = setup()
    authorizationToken = login();
    createPolicyWithDefaults()
    listPolicies()
    readPolicy()
    addClient()
    addSchedule()
    addBackupSelection()
    readPolicy()
    deleteClient()
    deleteSchedule()
    readPolicy()
    deletePolicy()
    listPolicies()
}
