//This script can be run using NetBackup 8.2 and higher.
//It gets all NetBackup processes running on the given host.

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
    nbmaster            = flag.String("nbmaster", "", "NetBackup Master Server")
    username            = flag.String("username", "", "User name to log into the NetBackup webservices")
    password            = flag.String("password", "", "Password for the given user")
    domainName          = flag.String("domainName", "", "Domain name of the given user")
    domainType          = flag.String("domainType", "", "Domain type of the given user")
    client              = flag.String("client", "", "NetBackup host name")
)

const usage = "\n\nUsage: go run ./get_processes.go -nbmaster <masterServer> -username <username> -password <password> [-domainName <domainName>] [-domainType <domainType>] -client <client>\n\n"

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
    if len(*client) == 0 {
        log.Fatalf("Please specify the name of a NetBackup host using the -client parameter.\n")
    }

    httpClient := apihelper.GetHTTPClient()
    jwt := apihelper.Login(*nbmaster, httpClient, *username, *password, *domainName, *domainType)
    hostUuid := apihelper.GetHostUUID(*nbmaster, httpClient, jwt, *client);
    filter := "";
    apihelper.GetProcesses(*nbmaster, httpClient, jwt, *client, hostUuid, filter);
}
