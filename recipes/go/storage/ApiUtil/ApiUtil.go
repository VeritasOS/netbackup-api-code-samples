//This script consists of the helper functions to read and process user inpus

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