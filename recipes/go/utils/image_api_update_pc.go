package images

import (
    "fmt"
    "strings"
    "net/http"
    "io/ioutil"
)


func UpdateImagePrimaryCopy(httpClient *http.Client, nbmaster string, token string, optionval string) {
    uri := protocol + nbmaster + port + imagesUri + update_apiname
    fmt.Printf("\n Calling UpdateImagePrimaryCopy\n USING : %s \n", uri )
    jsonConfig := []byte(`{
                            "data": {
                              "type": "updatePrimaryCopyAttributes",
                              "attributes": {
                                    "option": "copy",
                                    "optionValue": "$OPTION_VALUE",
                                    "startDate": "2019-01-26T15:39:00.729Z",
                                    "endDate": "2019-03-26T15:39:00.729Z",
                                    "policyName":"MyPolicy1"
                              }
                            }
                          }`)
    jsonString := string(jsonConfig)
    requestJson := strings.Replace(jsonString, "$OPTION_VALUE", optionval, 1)

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
