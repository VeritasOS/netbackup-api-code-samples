//This script can be run using NetBackup 8.2 and higher.
//It gets all NetBackup services available on the given host.

package main

import (
    "bytes"
    "flag"
    "fmt"
    "log"
    "os"
    "crypto/tls"
    "encoding/json"
    "io/ioutil"
    "net/http"
    "net/http/httputil"
)

const(

    port              = "1556"
    policiesUri       = "config/policies/"
    contentTypeV2       = "application/vnd.netbackup+json;version=2.0"
    contentTypeV3     = "application/vnd.netbackup+json;version=3.0"
    testPolicyName    = "vmware_test_policy"
    testClientName    = "MEDIA_SERVER"
    testScheduleName  = "vmware_test_schedule"
)


//###################
// Global Variables
//###################
var (
    nbmaster            = flag.String("nbmaster", "", "NetBackup Master Server")
    username            = flag.String("username", "", "User name to log into the NetBackup webservices")
    password            = flag.String("password", "", "Password for the given user")
    domainType          = flag.String("domainType", "", "Domain type of the given user")
)

const usage = "\n\nUsage: go run ./get-nb-jobs.go -nbmaster <masterServer> -userName <username> -password <password>\n\n"

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

    httpClient := GetHTTPClient()

    jwt := Login(*nbmaster, httpClient, *username, *password)

    //gives all the netbackup jobs
    fmt.Printf("====================================================\n")
    fmt.Printf("Gives list of all Netbackup jobs\n")
    GetNetbackupJobs(httpClient, jwt, *nbmaster)
    fmt.Printf("====================================================\n")

   //to get all the netbackup jobs whose jobType is 'Backup'
    fmt.Printf("====================================================\n")
    fmt.Printf("Gives list of all Netbackup jobs of jobType 'Backup'\n")
    GetBackupJobs(httpClient, jwt, *nbmaster)
    fmt.Printf("====================================================\n")
}


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
func Login(nbmaster string, httpClient *http.Client, username string, password string) string {
    fmt.Printf("\nLog into the NetBackup webservices...\n")
    fmt.Printf("\nLog into the NetBackup webservices...\n")

    loginDetails := map[string]string{"userName": username, "password": password}
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

//#####################################################
// Get NETBACKUP JOBS
//#####################################################
func GetNetbackupJobs(httpClient *http.Client, jwt string, nbmaster string) {
    fmt.Printf("Get the netbackup jobs\n")
    fmt.Printf("================================================\n")
    url := "https://" + nbmaster + ":" + port + "/netbackup" + "/admin/jobs"

    request, _ := http.NewRequest(http.MethodGet, url, nil)
    query := request.URL.Query()
    request.URL.RawQuery = query.Encode()

    request.Header.Add("Authorization", jwt);
    request.Header.Add("Accept", contentTypeV3);

    response, err := httpClient.Do(request)
       
    var jsonDataresponse map[string]interface{}

    if err != nil {
        fmt.Printf("The HTTP request failed with error: %s\n", err)
        panic("Unable to get the netbackup jobs")
    } else {
        if response.StatusCode == 200 {
            data, _ := ioutil.ReadAll(response.Body)
            json.Unmarshal(data, &jsonDataresponse)
            jobs, err := json.MarshalIndent(jsonDataresponse, "", "    ")
            fmt.Printf("\n\nAdmin jobs are: %s\n", jobs)
            
            if err != nil {
		fmt.Println("error:", err)
	    }
	    
         
        } else {
            printErrorResponse(response)
        }
    }
}

//#####################################################
// Get NETBACKUP JOBS of jobtype Backup
//#####################################################
func GetBackupJobs(httpClient *http.Client, jwt string, nbmaster string) {
    fmt.Printf("\n===================Get the netbackup jobs of jobType Backup=================")

    url := "https://" + nbmaster + ":" + port + "/netbackup" + "/admin/jobs"

    request, _ := http.NewRequest(http.MethodGet, url, nil)
    query := request.URL.Query()
    query.Add("filter","jobType eq 'BACKUP'")
    request.URL.RawQuery = query.Encode()

    request.Header.Add("Authorization", jwt);
    request.Header.Add("Accept", contentTypeV3);

    response, err := httpClient.Do(request)

    var jsonDataresponse map[string]interface{}

    if err != nil {
        fmt.Printf("The HTTP request failed with error: %s\n", err)
        panic("Unable to get the netbackup jobs")
    } else {
        if response.StatusCode == 200 {
            data, _ := ioutil.ReadAll(response.Body)
            json.Unmarshal(data, &jsonDataresponse)
            backupJobs, err := json.MarshalIndent(jsonDataresponse, "", "    ")

            fmt.Printf("\n\nBackup Jobs are: %s\n", backupJobs)

            if err != nil {
                fmt.Println("error:", err)
            }

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
