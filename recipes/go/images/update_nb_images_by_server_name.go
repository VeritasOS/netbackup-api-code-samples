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
    serverName          = flag.String ("serverName","", "Server name for the image to which expiration date needs update.")
)



const usage = "\n\nUsage: go run ./update_nb_images_by_server_name.go -nbmaster <masterServer> -username <username> -password <password> [-domainName <domainName>] [-domainType <domainType>] -serverName <serverName> n\n"

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

    if len(*serverName) == 0 {
        log.Fatalf("Please specify the serverName using the -serverName parameter.\n")
    }

    httpClient := apihelper.GetHTTPClient()
    token := apihelper.Login(*nbmaster, httpClient, *username, *password, *domainName, *domainType)

    images.UpdateImageExpirationDateByServerName ( httpClient, *nbmaster, token, *serverName )

}
