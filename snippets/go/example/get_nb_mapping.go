package main
 import (
	"bufio"
	"fmt"
	"netbackup"
	"os"
)
 func main() {
	fmt.Printf("Welcome to sample Go program to call NetBackup APIs\n")
	scanner := bufio.NewScanner(os.Stdin)
	fmt.Printf("Enter the server to connect: ")
	scanner.Scan()
	server := scanner.Text()
	fmt.Printf("Checking connectivity with NetBackup Server[%s]\n", server)
	fmt.Printf("-----------------------\n")
	fmt.Println(netbackup.Ping(server))
	fmt.Printf("-----------------------\n")
	fmt.Printf("Enter username for server:")
	scanner.Scan()
	username := scanner.Text()
	fmt.Printf("Enter password for server:")
	scanner.Scan()
	password := scanner.Text()
	fmt.Printf("Enter domain name for server:")
	scanner.Scan()
	domain := scanner.Text()
	fmt.Printf("Enter domain type <unixpwd/nt>:")
	scanner.Scan()
	domainType := scanner.Text()
	fmt.Printf("Calling NetBackup Login\n")
	fmt.Printf("-----------------------\n")
	jwt := netbackup.Login(username, password, domain, domainType, server)
	fmt.Printf("-----------------------\n")
	fmt.Printf("Mapping List using jwt\n")
	fmt.Printf("-----------------------\n")
	netbackup.MappingList(jwt, server)
	fmt.Printf("-----------------------\n")
}
