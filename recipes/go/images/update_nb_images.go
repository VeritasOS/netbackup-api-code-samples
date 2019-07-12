package main

import (
    "fmt"
    "flag"
    "log"
    "os"
    "apihelper"
    "images"
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
    backupId            = flag.String ("backupId","", "BackupId of the image for which expiration date needs update.")
)




const usage = "\n\nUsage: go run ./update_nb_images.go -nbmaster <masterServer> -username <username> -password <password> [-domainName <domainName>] [-domainType <domainType>] -backupId <backupId> n\n"

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

    if len(*backupId) == 0 {
        log.Fatalf("Please specify the backupId using the -backupId parameter.\n")
    }

    httpClient := apihelper.GetHTTPClient()
    token := apihelper.Login(*nbmaster, httpClient, *username, *password, *domainName, *domainType)

    images.UpdateImageExpirationDateByBackupId ( httpClient, *nbmaster, token, *backupId )
    images.UpdateImageExpirationDateByRecalculating ( httpClient, *nbmaster, token, *backupId )
}
