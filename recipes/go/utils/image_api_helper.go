package images

import (
    "fmt"
    "strings"
    "net/http"
    "io/ioutil"
)


//###################
// Global Variables
//###################
const (
    protocol          = "https://"
    port              = ":1556"
    imagesUri         = "/netbackup/catalog/images"
    apiname           = "/update-expiration-date"
    update_apiname    = "/update-primary-copy"
    contentType       = "application/vnd.netbackup+json;version=3.0"
)
func UpdateImageExpirationDateByBackupId(httpClient *http.Client, nbmaster string, token string, backupId string) {
    fmt.Printf("\n Calling expire image by using backupId...\n")
    uri := protocol + nbmaster + port + imagesUri + apiname

    jsonConfig := []byte(`{
                            "data": {
                              "type": "byBackupId",
                              "attributes": {
                                    "backupId": "$BACKUPID",
                                    "date": "2020-02-01T20:36:28.750Z"
                              }
                            }
                          }`)
    jsonString := string(jsonConfig)
    requestJson := strings.Replace(jsonString, "$BACKUPID", backupId, 1)

    fmt.Println(requestJson)

    payload := strings.NewReader(string(requestJson))

    request, _ := http.NewRequest(http.MethodPost, uri, payload)

    request.Header.Add("Authorization", token)
    request.Header.Add("Content-Type", contentType)
    request.Header.Add("cache-control", "no-cache")

    res, responseError := httpClient.Do(request)

    if  ( res != nil ){
      defer res.Body.Close()
      body, _ := ioutil.ReadAll(res.Body)

      fmt.Println(res)
      fmt.Println(string(body))
     } else {
      if ( responseError != nil ) {
       fmt.Println(responseError.Error())
      }
      fmt.Println("There is no response!")
     }
}

func UpdateImageExpirationDateByRecalculating(httpClient *http.Client, nbmaster string, token string, backupId string) {
    fmt.Printf("\n Calling expire image by using recalculating and using additional params ( backupId )...\n")
    uri := protocol + nbmaster + port + imagesUri + apiname

    jsonConfig := []byte(`{
                            "data": {
                              "type": "byRecalculating",
                              "attributes": {
                                   "backupId": "$BACKUPID",
                                   "byBackupTime": true
                              }
                            }
                          }`)
    jsonString := string(jsonConfig)
    requestJson := strings.Replace(jsonString, "$BACKUPID", backupId, 1)

    fmt.Println(requestJson)

    payload := strings.NewReader(string(requestJson))

    request, _ := http.NewRequest(http.MethodPost, uri, payload)

    request.Header.Add("Authorization", token)
    request.Header.Add("Content-Type", contentType)
    request.Header.Add("cache-control", "no-cache")

    res, responseError := httpClient.Do(request)

    if  ( res != nil ){
      defer res.Body.Close()
      body, _ := ioutil.ReadAll(res.Body)

      fmt.Println(res)
      fmt.Println(string(body))
     } else {
      if ( responseError != nil ) {
       fmt.Println(responseError.Error())
      }
      fmt.Println("There is no response!")
     }
}

func UpdateImageExpirationDateByServerName(httpClient *http.Client, nbmaster string, token string, servername string) {
    fmt.Printf("\n Calling expire image by server name...\n")
    uri := protocol + nbmaster + port + imagesUri + apiname
    fmt.Println(uri)
    jsonConfig := []byte(`{
                            "data": {
                              "type": "byServerName",
                              "attributes": {
                                    "serverName": "$SERVERNAME",
                                    "date": "2025-02-01T20:36:28.750Z"
                              }
                            }
                          }`)
    jsonString := string(jsonConfig)
    requestJson := strings.Replace(jsonString, "$SERVERNAME", servername, 1)

    fmt.Println(requestJson)

    payload := strings.NewReader(string(requestJson))

    request, _ := http.NewRequest(http.MethodPost, uri, payload)

    request.Header.Add("Authorization", token)
    request.Header.Add("Content-Type", contentType)
    request.Header.Add("cache-control", "no-cache")

    res, responseError := httpClient.Do(request)

    if  ( res != nil ){
      defer res.Body.Close()
      body, _ := ioutil.ReadAll(res.Body)

      fmt.Println(res)
      fmt.Println(string(body))
     } else {
      if ( responseError != nil ) {
       fmt.Println(responseError.Error())
      }
      fmt.Println("There is no response!")
     }
}

func UpdateImageExpirationDateByServerType(httpClient *http.Client, nbmaster string, token string, servertype string) {
    fmt.Printf("\n Calling expire image by server type...\n")
    uri := protocol + nbmaster + port + imagesUri + apiname
    jsonConfig := []byte(`{
                            "data": {
                              "type": "byServerType",
                              "attributes": {
                                    "serverType": "$SERVERTYPE",
                                   "date": "2020-02-01T20:36:28.750Z"
                               }
                              }
                          }`)
    jsonString := string(jsonConfig)
    requestJson := strings.Replace(jsonString, "$SERVERTYPE", servertype, 1)

    fmt.Println(requestJson)

    payload := strings.NewReader(string(requestJson))

    request, _ := http.NewRequest(http.MethodPost, uri, payload)

    request.Header.Add("Authorization", token)
    request.Header.Add("Content-Type", contentType)
    request.Header.Add("cache-control", "no-cache")

    res, responseError := httpClient.Do(request)

    if  ( res != nil ){
      defer res.Body.Close()
      body, _ := ioutil.ReadAll(res.Body)

      fmt.Println(res)
      fmt.Println(string(body))
     } else {
      if ( responseError != nil ) {
       fmt.Println(responseError.Error())
      }
      fmt.Println("There is no response!")
     }
}
