//This script can be run using NetBackup 8.3 and higher.
//It gets the list of VMware assets in NetBackup (based on the given filter if specified, else returns all the VMware assets).

package main

import (
    "flag"
    "fmt"
    "log"
    "os"
    "strconv"
    "net/url"
    "net/http"
    "io/ioutil"
    "encoding/json"
    "utils"
)

var (
    nbserver            = flag.String("nbserver", "", "NetBackup Server")
    username            = flag.String("username", "", "User name for NetBackup API login")
    password            = flag.String("password", "", "Password for the given user")
    domainName          = flag.String("domainName", "", "Domain name")
    domainType          = flag.String("domainType", "", "Domain type")
    assetsFilter        = flag.String("assetsFilter", "", "Filter string (odata format) to filter the assets")
)

const usage = "\n\nUsage: go run ./get_vmware_assets.go -nbserver <NetBackup server> -username <username> -password <password> [-domainName <domainName>] [-domainType <domainType>] [-assetsFilter <filter>]\n\n"

func main() {
    // Print usage
    flag.Usage = func() {
        fmt.Fprintf(os.Stderr, usage)
        os.Exit(1)
    }

    // Read command line arguments
    flag.Parse()

    if len(*nbserver) == 0 {
        log.Fatalf("Please specify the name of the NetBackup Server using the -nbserver option.\n")
    }
    if len(*username) == 0 {
        log.Fatalf("Please specify the username using the -username option.\n")
    }
    if len(*password) == 0 {
        log.Fatalf("Please specify the password using the -password option.\n")
    }

    httpClient := apihelper.GetHTTPClient()
    jwt := apihelper.Login(*nbserver, httpClient, *username, *password, *domainName, *domainType)

    vmwareAssetsApiUrl := "https://" + *nbserver + "/netbackup/asset-service/workloads/vmware/assets"
    defaultSort := "commonAssetAttributes.displayName"
    assetTypeFilter := "(assetType eq 'vm')"

    req, err := http.NewRequest("GET", vmwareAssetsApiUrl, nil)

    if err != nil {
        fmt.Printf("Making new HTTP request failed with error: %s\n", err)
        panic("Script failed.")
    }

    req.Header.Add("Authorization", jwt)
    pageLimit := 100
    offset := 0
    next := true
    params := url.Values{}

    if assetsFilter != nil {
      filter := ""
      if *assetsFilter != "" {
        filter = *assetsFilter + " and " + assetTypeFilter
      } else {
          filter = assetTypeFilter
      }
      params.Add("filter", filter)
    }

    params.Add("sort", defaultSort)
    params.Add("page[offset]", strconv.Itoa(offset))
    params.Add("page[limit]", strconv.Itoa(pageLimit))

    fmt.Println("\nGetting VMware assets...")
    fmt.Println("Printing the following asset details: Display Name, VM InstanceId, vCenter, Protection Plan Names\n")

    for next {
      req.URL.RawQuery = params.Encode()
      resp, err := httpClient.Do(req)

      if err != nil {
          fmt.Printf("Get VMware Assets failed with error: %s\n", err)
          panic("Script failed.")
      } else {
          respJson, _ := ioutil.ReadAll(resp.Body)
          if resp.StatusCode == 200 {
            var respPayload interface{}
            json.Unmarshal(respJson, &respPayload)
            respData := respPayload.(map[string]interface{})
            assetsData := respData["data"].([]interface{})
            printAssetDetails(assetsData)
            next = respData["meta"].(map[string]interface{})["pagination"].
                (map[string]interface{})["hasNext"].(bool)
          } else {
            fmt.Println(string(respJson))
            next = false
          }
      }
      offset, _ = strconv.Atoi(params["page[offset]"][0])
      params["page[offset]"][0] = strconv.Itoa(offset + pageLimit)
    }

    fmt.Println("\nScript completed.\n")
}

func printAssetDetails(assets []interface{}) {
  for _, asset := range assets {
    assetAttrs := asset.(map[string]interface{})["attributes"].(map[string]interface{})
    assetCommonAttrs := assetAttrs["commonAssetAttributes"].(map[string]interface{})
    displayName := assetCommonAttrs["displayName"]
    instanceId := assetAttrs["instanceUuid"]
    vCenter := assetAttrs["vCenter"]

    var protectionPlans []string
    if activeProtections, protected := assetCommonAttrs["activeProtection"]; protected {
      protectionDetailsList := activeProtections.(map[string]interface{})["protectionDetailsList"].([]interface{})

      for _, protectionDetails := range protectionDetailsList {
        protectionPlans = append(protectionPlans, protectionDetails.
                (map[string]interface{})["protectionPlanName"].(string))
      }
    }
    fmt.Printf("%s\t%s\t%s\t%v\n", displayName, instanceId, vCenter, protectionPlans)
  }

}
