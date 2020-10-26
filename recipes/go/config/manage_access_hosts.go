//This script can be run using NetBackup 8.2 and higher.

package main

import (
    "bytes"
    "encoding/json"
    "flag"
    "fmt"
    "io/ioutil"
    "log"
    "net/http"
    "net/http/httputil"
    "os"
    "apihelper"
)

//###################
// Global Variables
//###################
var (
    nbmaster      = flag.String("nbmaster", "", "NetBackup Master Server")
    username      = flag.String("username", "", "User name to log into the NetBackup webservices")
    password      = flag.String("password", "", "Password for the given user")
    domainName    = flag.String("domainName", "", "Domain name of the given user")
    domainType    = flag.String("domainType", "", "Domain type of the given user")
    accessHost    = flag.String("accessHost", "dummy.access.host", "Access Host used for demonstration")
)

//###################
// Global Constants
//###################
const (
    baseUrl              = "https://%s:1556/netbackup"
    accessHostsUri       = "/config/%s/access-hosts"
    contentTypeV3        = "application/vnd.netbackup+json;version=3.0"
    authorizationHeader  = "Authorization"
    contentTypeHeader    = "Content-Type"
    acceptHeader         = "Accept"

    usage    = "\n\nUsage: go run ./manage_access_hosts.go [-nbmaster <masterServer>] -username <username> -password <password> [-domainName <domainName>] [-domainType <domainType>] [-accessHost <accessHost>]\n\n"
    workload = "vmware"
)

func main() {
    flag.Usage = func() {
        fmt.Println(usage)
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
    if len(*accessHost) == 0 {
        log.Println("-accessHost parameter not specified in the command line. Defaulting to 'dummy.access.host'.\n")
    }

    httpClient := apihelper.GetHTTPClient()
    jwt := apihelper.Login(*nbmaster, httpClient, *username, *password, *domainName, *domainType)
    
    // Prints all the access hosts configured on the master server
    fmt.Println("Use-case 1\n==========\nReading all the configured access hosts.")
    getAllAccessHosts(httpClient, jwt)
    fmt.Println("\n\n")

    // Add the provided access host to the list of access hosts
    fmt.Println("Use-case 2\n==========\nAdding a new access host.")
    addAccessHost(httpClient, jwt)
    fmt.Println("\n\n")

    // Get access hosts of type 'CLIENT'
    fmt.Println("Use-case 3\n==========\nReading 'CLIENT' type access hosts.")
    getAccessHostsOfSpecificType("CLIENT", httpClient, jwt)
    fmt.Println("\n\n")

    // Delete the recently added access host
    fmt.Println("Use-case 4\n==========\nDeleting the dummy access host.")
    deleteAccessHost(httpClient, jwt)
    fmt.Println("\n\n")

    // Prints all the access hosts configured on the master server
    fmt.Println("Use-case 5\n==========\nReading all the configured access hosts.")
    getAllAccessHosts(httpClient, jwt)
    fmt.Println("\n\n")
}

func getAllAccessHosts(httpClient *http.Client, jwt string) {
    fmt.Println("Workload: " + workload +"\t\tMaster Server: " + *nbmaster)
    apiResponse := getAccessHosts(httpClient, jwt, "")
    printAccessHostsResponse(apiResponse)
}

func getAccessHostsOfSpecificType(hostType string, httpClient *http.Client, jwt string) {
    fmt.Println("Workload: " + workload +"\tHost Type: " + hostType + "\tMaster Server: " + *nbmaster)
    filter := "hostType eq '" + hostType + "'"
    apiResponse := getAccessHosts(httpClient, jwt, filter)
    printAccessHostsResponse(apiResponse)
}

func getAccessHosts(httpClient *http.Client, jwt string, filter string) []byte {
    apiUrl := fmt.Sprintf(baseUrl, *nbmaster) + fmt.Sprintf(accessHostsUri, workload)

    request, _ := http.NewRequest(http.MethodGet, apiUrl, nil)
    request.Header.Add(authorizationHeader, jwt)
    request.Header.Add(acceptHeader, contentTypeV3)
    if filter != "" {
        query := request.URL.Query()
        query.Add("filter", filter)
        request.URL.RawQuery = query.Encode()
    }
    
    response, err := httpClient.Do(request)
    var emptyByte []byte

    if err != nil {
        fmt.Println("The HTTP request failed with error: %s\n", err)
        panic("Unable to read access hosts for the master server: " + *nbmaster)
    } else {
        if response.StatusCode != http.StatusOK {
            printErrorResponse(response)
        } else {
            resp, _ := ioutil.ReadAll(response.Body)
            return resp
        }
    }
    return emptyByte
}

func addAccessHost(httpClient *http.Client, jwt string) {
    fmt.Println("Adding access host: " + *accessHost)
    apiUrl := fmt.Sprintf(baseUrl, *nbmaster) + fmt.Sprintf(accessHostsUri, workload)

    accessHostRequest := map[string]interface{}{
        "data": map[string]interface{}{
            "type": "accessHostRequest",
            "id": workload,
            "attributes": map[string]interface{}{
                "hostname": *accessHost,
                "validate": false}}}

    accessHostRequestBody, _ := json.Marshal(accessHostRequest)

    request, _ := http.NewRequest(http.MethodPost, apiUrl, bytes.NewBuffer(accessHostRequestBody))
    request.Header.Add(authorizationHeader, jwt)
    request.Header.Add(contentTypeHeader, contentTypeV3)

    response, err := httpClient.Do(request)

    if err != nil {
        fmt.Printf("The HTTP request failed with error: %s\n", err)
        panic("Unable to add access host for workload '" + workload + "' on master '" + *nbmaster +"'\n")
    } else {
        if response.StatusCode != 204 {
            printErrorResponse(response)
        } else {
            fmt.Printf("Access Host '%s' added successfully.\n", *accessHost);
        }
    }
}

func deleteAccessHost(httpClient *http.Client, jwt string) {
    fmt.Println("Deleting access host: " + *accessHost)
    apiUrl := fmt.Sprintf(baseUrl, *nbmaster) + fmt.Sprintf(accessHostsUri, workload) + "/" + *accessHost

    request, _ := http.NewRequest(http.MethodDelete, apiUrl, nil)
    request.Header.Add(authorizationHeader, jwt)
    request.Header.Add(acceptHeader, contentTypeV3)

    response, err := httpClient.Do(request)

    if err != nil {
        fmt.Println("The HTTP request failed with error: %s\n", err)
        panic("Unable to delete access host for the master server: " + *nbmaster)
    } else {
        if response.StatusCode != http.StatusNoContent {
            printErrorResponse(response)
        } else {
            fmt.Printf("Access Host '%s' deleted successfully.", *accessHost)
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

func printAccessHostsResponse(apiResponse []byte) {
    var obj interface{}
    json.Unmarshal([]byte(apiResponse), &obj)
    data := obj.(map[string]interface{})
    var accessHosts []interface{} = data["data"].([]interface{})
    fmt.Println("      Host Type        Workload                  Hostname")
    fmt.Println("===============.===============.=========================")
    for _, host := range accessHosts {
        hostName := (host.(map[string]interface{}))["id"]
        attributes := ((host.(map[string]interface{}))["attributes"]).(map[string]interface{})
        respWorkload := attributes["workloadType"]
        respHostType := attributes["hostType"]
        fmt.Printf("%15s %15s %25s\n", respHostType, respWorkload, hostName)
    }
}
