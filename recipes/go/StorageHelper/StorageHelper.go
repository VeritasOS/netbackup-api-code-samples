//This script consists of the helper functions to excute NetBackup APIs to assist in Air operation for MSDP sts

// 1. Get the HTTP client to perform API requests
// 2. Login to the NetBackup webservices
// 3. Create MSDP storage server
// 4. Get Replication candidates
// 5. Add Replication target
// 6. Get Replication targets
// 7. Delete Replication target

package storageHelper

import (
    "bufio"
	"os"
    "strings"
    "bytes"
    "crypto/tls"
    "encoding/json"
    "fmt"
    "io/ioutil"
    "net/http"
	"strconv"
	"apiUtil"
)

type Data struct {
	id string `json:"id"`
	apiType string `json:"type"`
	attr interface{} `json:"attributes"`
}

type DataArray struct {
	dataList []Data `json:"data"`
}


//###################
// Global Variables
//###################

var mediaServerName string
const (
    port              = "1556"
    storageUri        = "storage/"
	storageServerUri  = "storage-servers/"
	storageUnitUri	  = "storage-units"
    contentType       = "application/vnd.netbackup+json;version=3.0"
	replicationTargetsUri = "/replication-targets"
	replicationCandidatesUri = "/target-storage-servers"
)

//##############################################################
// Setup the HTTP client to make NetBackup Storage API requests
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
// Create a MSDP Storage server
//#######################################################################
func CreateMSDPStorageServer(nbmaster string, httpClient *http.Client, jwt string)(int, string) {
    fmt.Printf("\nSending a POST request to create with defaults...\n")	
	if strings.Compare(apiUtil.TakeInput("Want to create new MSDP storage server?(Or you can use existing)(Yes/No):"), "Yes") != 0 {
	    stsName := apiUtil.TakeInput("Enter MSDP/CloudCatalyst Storage Server Name for other operations:")
		return 201, stsName;
	}

    stsName := apiUtil.TakeInput("Enter Storage/Media Server Name:")
	mediaServerName = stsName
	
	storagePath := apiUtil.TakeInput("Enter Storage Path:")

    MSDPstorageServer := map[string]interface{}{
        "data": map[string]interface{}{
            "type": "storageServer",
            "id": stsName,
            "attributes": map[string]interface{}{
                "name":stsName,
				"storageCategory":"MSDP",
				"mediaServerDetails": map[string]interface{}{
                    "name": mediaServerName},
				"msdpAttributes": map[string]interface{}{
					"storagePath": storagePath,
                    "credentials":map[string]interface{}{
                    "userName": "a",
					"password": "a"}}}}}
				


    stsRequest, _ := json.Marshal(MSDPstorageServer)

    uri := "https://" + nbmaster + ":" + port + "/netbackup/" + storageUri + storageServerUri

    request, _ := http.NewRequest(http.MethodPost, uri, bytes.NewBuffer(stsRequest))
    request.Header.Add("Content-Type", contentType);
    request.Header.Add("Authorization", jwt);

    response, err := httpClient.Do(request)

    if err != nil {
        fmt.Printf("The HTTP request failed with error: %s\n", err)
        panic("Unable to create storage server.\n")
    } else {
        if response.StatusCode != 201 {
            responseBody, _ := ioutil.ReadAll(response.Body)
            fmt.Printf("%s\n", responseBody)
            panic("Unable to create MSDP Sts.\n")
        } else {
            fmt.Printf("%s created successfully.\n", stsName);
            //responseDetails, _ := httputil.DumpResponse(response, true);
            apiUtil.AskForResponseDisplay(response.Body)
        }
    }
	
	return response.StatusCode, mediaServerName;
}

//#######################################################################
// Get Replication candidates
//#######################################################################
func GetReplicationCandidates(nbmaster string, httpClient *http.Client, jwt string)(int, string) {
    fmt.Printf("\nSending a GET request for replication candidates...\n")

	reader := bufio.NewReader(os.Stdin)
	var candidateinx int
	var candidateID string
    uri := "https://" + nbmaster + ":" + port + "/netbackup/" + storageUri + replicationCandidatesUri

    request, _ := http.NewRequest(http.MethodGet, uri, nil)
    request.Header.Add("Content-Type", contentType);
    request.Header.Add("Authorization", jwt);

	fmt.Println ("Firing request: GET: " + uri)
    response, err := httpClient.Do(request)

    if err != nil {
        fmt.Printf("The HTTP request failed with error: %s\n", err)
        panic("Unable to create storage server.\n")
    } else {
        if response.StatusCode == 200 {
            data, _ := ioutil.ReadAll(response.Body)
            var obj interface{}
            err := json.Unmarshal(data, &obj)
			if(err == nil){
				//responseDetails, _ := httputil.DumpResponse(response, true);
				apiUtil.AskForGETResponseDisplay(data)
				dataArray := obj.(map[string]interface{})
				var dataObj = dataArray["data"].([]interface{})
				addRepTar := apiUtil.TakeInput("Do you want to add replication target?(Yes/No)")
				if strings.Compare(addRepTar, "Yes") == 0 {
					for i := 0; i < len(dataObj); i++ {
						var indobj = dataObj[i].(map[string]interface{})
						candidateID = indobj["id"].(string)
						fmt.Printf("%d. %s\n", i+1, candidateID)
					}
					fmt.Print("Select index of candidate to add as target: ")
					loopCont := true
					for ok := true; ok; ok = loopCont {
						candInx, _ := reader.ReadString('\n')
						candInx = strings.Replace(candInx, "\r\n", "", -1)
					    candInxInt, err := strconv.Atoi(candInx)
						if err != nil || candInxInt > len(dataObj) {
							fmt.Print("Invalid indexx. Try again. (0 to exit):")
						} else {
							loopCont = false
							candidateinx = candInxInt
						}
					}
				}
			}
        } else {
            responseBody, _ := ioutil.ReadAll(response.Body)
            fmt.Printf("%s\n", responseBody)
            panic("Failed to successfully execute get replication candidates API ")
        }
    }
	
	return candidateinx, candidateID;
}


//#######################################################################
// Add replication target to MSDP Sts
//#######################################################################
func AddReplicationTarget(nbmaster string, httpClient *http.Client, jwt string, stsName string, candId string)(int) {
    fmt.Printf("\nSending a POST request to create with defaults...\n")

	//reader := bufio.NewReader(os.Stdin)
	IdSlice := strings.Split(candId, ":")

    username := apiUtil.TakeInput("Enter target storage server username:")
	password := apiUtil.TakeInput("Enter target storage server password:")

    replicationtarget := map[string]interface{}{
        "data": map[string]interface{}{
            "type": "replicationTargetRequest",
            "attributes": map[string]interface{}{
				"targetStorageServerInfo": map[string]interface{}{
                    "targetMasterServer": IdSlice[3],
					"targetStorageServer": IdSlice[1],
					"targetStorageServerType": IdSlice[0],
					"targetMediaServer": IdSlice[2]},
				"targetStorageServerCredentials": map[string]interface{}{
					"userName": username,
					"password": password}}}}
				


    stsRequest, _ := json.Marshal(replicationtarget)

    uri := "https://" + nbmaster + ":" + port + "/netbackup/" + storageUri + storageServerUri + "PureDisk:" + stsName + replicationTargetsUri

    request, _ := http.NewRequest(http.MethodPost, uri, bytes.NewBuffer(stsRequest))
    request.Header.Add("Content-Type", contentType);
    request.Header.Add("Authorization", jwt);

    fmt.Println ("Firing request: POST: " + uri)
    response, err := httpClient.Do(request)

    if err != nil {
        fmt.Printf("The HTTP request failed with error: %s\n", err)
        panic("Unable to add replication target.\n")
    } else {
        if response.StatusCode != 201 {
            responseBody, _ := ioutil.ReadAll(response.Body)
            fmt.Printf("%s\n", responseBody)
            panic("Unable to add replication target.\n")
        } else {
            fmt.Printf("%s created successfully.\n", "");
            //responseDetails, _ := httputil.DumpResponse(response, true);
            apiUtil.AskForResponseDisplay(response.Body)
        }
    }
	
	return response.StatusCode;
}


//#######################################################################
// Get Replication targets
//#######################################################################
func GetReplicationTargets(nbmaster string, httpClient *http.Client, jwt string, stsName string)(int, string) {
    fmt.Printf("\nSending a GET request for replication targets...\n")

	reader := bufio.NewReader(os.Stdin)
	var candidateinx int
	var candidateID string
    uri := "https://" + nbmaster + ":" + port + "/netbackup/" + storageUri + storageServerUri + "PureDisk:" + stsName + replicationTargetsUri

    request, _ := http.NewRequest(http.MethodGet, uri, nil)
    request.Header.Add("Content-Type", contentType);
    request.Header.Add("Authorization", jwt);

	fmt.Println ("Firing request: GET: " + uri)
    response, err := httpClient.Do(request)

    if err != nil {
        fmt.Printf("The HTTP request failed with error: %s\n", err)
        panic("Unable to create storage server.\n")
    } else {
        if response.StatusCode == 200 {
            data, _ := ioutil.ReadAll(response.Body)
            var obj interface{}
            err := json.Unmarshal(data, &obj)
			if(err == nil){
				dataArray := obj.(map[string]interface{})
				var dataObj = dataArray["data"].([]interface{})
				apiUtil.AskForGETResponseDisplay(data)
				delRepTar := apiUtil.TakeInput("Do you want to delete replication target?(Yes/No)")
				if strings.Compare(delRepTar, "Yes") == 0 {
					for i := 0; i < len(dataObj); i++ {
						var indobj = dataObj[i].(map[string]interface{})
						candidateID = indobj["id"].(string)
						fmt.Printf("%d. %s\n", i+1, candidateID)
					}
					fmt.Print("Select index to delete replication target: ")
					loopCont := true
					for ok := true; ok; ok = loopCont {
						candInx, _ := reader.ReadString('\n')
						candInx = strings.Replace(candInx, "\r\n", "", -1)
					    candInxInt, err := strconv.Atoi(candInx)
						if err != nil || candInxInt > len(dataObj) {
							fmt.Print("InvalidInx. Try again. (0 to exit):")
						} else {
							loopCont = false
							candidateinx = candInxInt
						}
					}
				}
			}
        } else {
            responseBody, _ := ioutil.ReadAll(response.Body)
            fmt.Printf("%s\n", responseBody)
            panic("Unable to login to the NetBackup webservices")
        }
    }
	return candidateinx, candidateID;
}


//#######################################################################
// Delete Replication targets
//#######################################################################
func DeleteReplicationTargets(nbmaster string, httpClient *http.Client, jwt string, stsName string, id string)(int) {
    fmt.Printf("\nSending a GET request for replication targets...\n")

    uri := "https://" + nbmaster + ":" + port + "/netbackup/" + storageUri + storageServerUri + "PureDisk:" + stsName + replicationTargetsUri + "/" + id

    request, _ := http.NewRequest(http.MethodDelete, uri, nil)
    request.Header.Add("Content-Type", contentType);
    request.Header.Add("Authorization", jwt);

	fmt.Println ("Firing request: DELETE: " + uri)
    response, err := httpClient.Do(request)

    if err != nil {
        fmt.Printf("The HTTP request failed with error: %s\n", err)
        panic("Unable to delete replication target.\n")
    } else {
        if response.StatusCode == 204 {
			fmt.Printf("Replication Target deleted successfully.\n")
        } else {
            responseBody, _ := ioutil.ReadAll(response.Body)
            fmt.Printf("%s\n", responseBody)
            panic("Unable to login to the NetBackup webservices")
        }
    }
	return response.StatusCode;
}
