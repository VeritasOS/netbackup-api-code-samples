// Package netbackup provides functions for calling netbackup APIs and
// get there response back in structured formata.
package netbackup

import (
	"bytes"
	"crypto/tls"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
)

// NetBackup structure to directly call raw APIs
// or some predefined APIs
type NetBackup struct {
	jwt              string
	baseURL          string
	skipVerification bool
}

// ----------------------------------------
//
// Raw functions to call APIs and their helper functions
//
// ----------------------------------------

// Get Raw function to call any GET APIs of NetBackup
func Get(jwt string, url string) (jsonData map[string]interface{}, code int, err error) {

	client := getHTTPClient()
	req, err := http.NewRequest("GET", url, nil)
	if jwt != "" {
		req.Header.Add("Authorization", jwt)
	}
	req.Header.Add("ContentType", "application/vnd.netbackup+json; version=1.0")

	response, err := client.Do(req)
	if err == nil {
		code = response.StatusCode
		if code >= 200 && code <= 299 {
			data, _ := ioutil.ReadAll(response.Body)
			if err := json.Unmarshal(data, &jsonData); err != nil {
				panic(err)
			}
		}
	}
	defer response.Body.Close()
	return jsonData, response.StatusCode, err
}

// Post Raw function to call any POST APIs of NetBackup
func Post(jwt string, url string, reqValue []byte) (jsonData map[string]interface{}, code int, err error) {

	client := getHTTPClient()
	req, err := http.NewRequest("POST", url, bytes.NewBuffer(reqValue))
	if jwt != "" {
		req.Header.Add("Authorization", jwt)
	}
	req.Header.Add("Content-Type", "application/vnd.netbackup+json; version=1.0")
	response, err := client.Do(req)

	if err == nil {
		code = response.StatusCode
		if code >= 200 && code <= 299 {
			resData, _ := ioutil.ReadAll(response.Body)
			if err := json.Unmarshal(resData, &jsonData); err != nil {
				panic(err)
			}
		}
	}
	defer response.Body.Close()
	return jsonData, code, err
}

// ----------------------------------------
//
// Some additional functions that you can directly call to
// achieve some basic functionality.
//
// ----------------------------------------

// Ping function call the netbackup ping API. This can be used
// to check the connectivity to Master server web services
func Ping(server string) string {
	var data []byte
	url := GetBaseURLString(server) + "/ping"
	client := getHTTPClient()
	response, err := client.Get(url)
	if err != nil {
		fmt.Printf("Request Failed %s \n", err)
	} else {
		data, _ = ioutil.ReadAll(response.Body)
		return (string(data))
	}
	return (string(""))
}

//Login function
func Login(username string, password string, domain string, domainType string, server string) string {
	url := GetBaseURLString(server) + "/login"
	reqData := map[string]string{"userName": username, "password": password, "domainName": domain, "domainType": domainType}
	reqValue, _ := json.Marshal(reqData)

	jsonData, code, err := Post("", url, reqValue)

	if err != nil {
		fmt.Printf("Request Failed %s \n", err)
	} else {
		fmt.Println(code)
		if code != 201 {
			fmt.Printf("Wrong response %d \n", code)
			return ""
		}
	}
	fmt.Printf("Login succesful. got jwt[%s]", jsonData["token"].(string))
	return jsonData["token"].(string)
}

// MappingList Returns list of mappings for the server in JSON format
func MappingList(jwt string, server string) {
	url := GetBaseURLString(server) + "/config/hosts"

	jsonData, code, err := Get(jwt, url)
	if err != nil {
		fmt.Printf("Request Failed %s \n", err)
	} else {
		if code != 200 {
			fmt.Printf("Request returned wrong code %d \n", code)
			return
		}
	}
	fmt.Println(jsonData)
}

// ImagesList API Returns list of catalog images
func ImagesList(jwt string, server string) {

	url := GetBaseURLString(server) + "/catalog/images"

	client := getHTTPClient()
	req, err := http.NewRequest("GET", url, nil)
	if jwt != "" {
		req.Header.Add("Authorization", jwt)
	}
	req.Header.Add("ContentType", "application/vnd.netbackup+json; version=1.0")

	//Adding filters in query string
	q := req.URL.Query()
	q.Add("filter", "policyType eq 'Standard'")
	q.Add("page[limit]", "10")
	req.URL.RawQuery = q.Encode()

	var jsonData map[string]interface{}

	response, err := client.Do(req)
	if err == nil {
		if response.StatusCode >= 200 && response.StatusCode <= 299 {
			data, _ := ioutil.ReadAll(response.Body)
			if err := json.Unmarshal(data, &jsonData); err != nil {
				panic(err)
			}
		}
	}
	defer response.Body.Close()

	if err != nil {
		fmt.Printf("Request Failed %s \n", err)
	} else {
		if response.StatusCode != 200 {
			fmt.Printf("Request returned wrong code %d \n", response.StatusCode)
			return
		}
	}

	b, err := json.MarshalIndent(jsonData, "", "    ")
	if err != nil {
		fmt.Println("error:", err)
	}
	os.Stdout.Write(b)
}

// JobList API Returns list of backup jobs
func JobList(jwt string, server string) {
	url := GetBaseURLString(server) + "/admin/jobs"

	client := getHTTPClient()
	req, err := http.NewRequest("GET", url, nil)
	if jwt != "" {
		req.Header.Add("Authorization", jwt)
	}
	req.Header.Add("ContentType", "application/vnd.netbackup+json; version=1.0")

	//Adding filters in query string
	q := req.URL.Query()
	q.Add("filter", "jobType eq 'BACKUP'")
	q.Add("page[limit]", "10")
	req.URL.RawQuery = q.Encode()

	var jsonData map[string]interface{}

	response, err := client.Do(req)
	if err == nil {
		if response.StatusCode >= 200 && response.StatusCode <= 299 {
			data, _ := ioutil.ReadAll(response.Body)
			if err := json.Unmarshal(data, &jsonData); err != nil {
				panic(err)
			}
		}
	}
	defer response.Body.Close()

	if err != nil {
		fmt.Printf("Request Failed %s \n", err)
	} else {
		if response.StatusCode != 200 {
			fmt.Printf("Request returned wrong code %d \n", response.StatusCode)
			return
		}
	}

	b, err := json.MarshalIndent(jsonData, "", "    ")
	if err != nil {
		fmt.Println("error:", err)
	}
	os.Stdout.Write(b)
}

// GetBaseURLString This returns the base URL for netbackup
func GetBaseURLString(server string) string {
	return "https://" + server + ":1556/netbackup"
}

func getContentType() string {
	return "application/vnd.netbackup+json; version=1.0"
}

func getHTTPClient() http.Client {
	tr := &http.Transport{
		TLSClientConfig: &tls.Config{InsecureSkipVerify: true},
	}
	client := &http.Client{Transport: tr}
	return *client
}
