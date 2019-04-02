//This script consists of the helper functions to excute NetBackup APIs to assist in policy CRUD operations

// 1. Get the HTTP client to perform API requests
// 2. Login to the NetBackup webservices
// 3. Create a policy with default values for the policy attributes
// 4. Create a policy with specific values for the policy attributes, schedules, clients, and backup selection
// 5. Read a policy
// 6. List all policies
// 7. Add/Update a schedule
// 8. Delete a schedule
// 9. Add/Update a client
// 10. Delete a client
// 11. Add/Update backup selection
// 12. Delete a policy

package apiUtil

import (
    "bufio"
	"os"
    "strings"
	"io"
    "fmt"
	"bytes"
)

func TakeInput(displayStr string)(string) {

	reader := bufio.NewReader(os.Stdin)
	fmt.Print(displayStr)
    output, _ := reader.ReadString('\n')
    // convert CRLF to LF
    output = strings.Replace(output, "\r\n", "", -1)
	output = strings.Replace(output, "\n", "", -1)
	return output
}

func AskForResponseDisplay(response io.ReadCloser) {
	if strings.Compare(TakeInput("Show response? (Yes/No)"), "Yes") == 0 {
		buf := new(bytes.Buffer)
		buf.ReadFrom(response)
		responseStr := buf.String()
		responseStr = strings.Replace(responseStr, "}", "}\r\n", -1)
		responseStr = strings.Replace(responseStr, ",", ",\r\n", -1)
		responseStr = strings.Replace(responseStr, "]", "]\r\n", -1)
		
		fmt.Print(responseStr)
	} else {
		fmt.Println("Response is not Yes!!")
	}
}

func AskForGETResponseDisplay(response []byte) {
	if strings.Compare(TakeInput("Show response? (Yes/No)"), "Yes") == 0 {
		responseStr := string(response)
		responseStr = strings.Replace(responseStr, "}", "}\r\n", -1)
		responseStr = strings.Replace(responseStr, ",", ",\r\n", -1)
		responseStr = strings.Replace(responseStr, "]", "]\r\n", -1)
		
		fmt.Print(responseStr)
	} else {
		fmt.Println("Response is not Yes!!")
	}
}