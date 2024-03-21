//This script can be run using NetBackup 8.2 and higher.

package main

import (
    "flag"
    "fmt"
    "log"
    "os"
	"storageHelper"
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
)

const usage = "\n\nUsage: go run ./AIRAPIs.go -nbmaster <masterServer> -username <username> -password <password> [-domainName <domainName>] [-domainType <domainType>]\n\n"

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

    httpClient := storageHelper.GetHTTPClient()
    jwt := storageHelper.Login(*nbmaster, httpClient, *username, *password, *domainName, *domainType)

	status, stsName := storageHelper.CreateMSDPStorageServer(*nbmaster, httpClient, jwt)
    if( status != 201){
	    panic("CreateMSDPStorageServer Failed. Exiting.\n")
	}

	candInx, candId := storageHelper.GetReplicationCandidates(*nbmaster, httpClient, jwt)
	if ( candInx == 0 ) {
	    fmt.Println("Exiting")
		os.Exit(0)
    }
	
	if ( storageHelper.AddReplicationTarget(*nbmaster, httpClient, jwt, stsName, candId) != 201 ) {
		panic("AddReplicationTarget Failed. Exiting.\n")
	}
	
	tarInx, tarId := storageHelper.GetReplicationTargets(*nbmaster, httpClient, jwt, stsName)
	if ( tarInx == 0 ) {
	    fmt.Println("Exiting")
		os.Exit(0)
    }
	storageHelper.DeleteReplicationTargets(*nbmaster, httpClient, jwt, stsName, tarId)
}
