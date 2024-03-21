//This script can be run using NetBackup 8.1.2 and higher.
//It creates a VMware policy with the default attribute values, then adds a client, a schedule, and a VIP query backup selection to it.
//It then delets the client, schedule from the policy and finally deletes the policy.

package main

import (
    "flag"
    "fmt"
    "log"
    "os"
    "apihelper"
)

//###################
// Global Variables
//###################
var (
    nbmaster    = flag.String("nbmaster", "", "NetBackup Master Server")
    username    = flag.String("username", "", "User name to log into the NetBackup webservices")
    password    = flag.String("password", "", "Password for the given user")
    domainName  = flag.String("domainName", "", "Domain name of the given user")
    domainType  = flag.String("domainType", "", "Domain type of the given user")
)

const usage = "\n\nUsage: go run ./create_policy_step_by_step.go -nbmaster <masterServer> -username <username> -password <password> [-domainName <domainName>] [-domainType <domainType>]\n\n"

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

    httpClient := helper.GetHTTPClient()
    jwt := helper.Login(*nbmaster, httpClient, *username, *password, *domainName, *domainType)

    helper.CreatePolicyWithDefaults(*nbmaster, httpClient, jwt)
    helper.ListPolicies(*nbmaster, httpClient, jwt)
    helper.ReadPolicy(*nbmaster, httpClient, jwt)
    helper.AddClient(*nbmaster, httpClient, jwt)
    helper.AddSchedule(*nbmaster, httpClient, jwt)
    helper.AddBackupSelection(*nbmaster, httpClient, jwt)
    helper.ReadPolicy(*nbmaster, httpClient, jwt)
    helper.DeleteClient(*nbmaster, httpClient, jwt)
    helper.DeleteSchedule(*nbmaster, httpClient, jwt)
    helper.ReadPolicy(*nbmaster, httpClient, jwt)
    helper.DeletePolicy(*nbmaster, httpClient, jwt)
    helper.ListPolicies(*nbmaster, httpClient, jwt)
}
