Run the AIRAPIs.go file using Go.

Prerequisites
1. Atleast a couple of NBU master servers.
2. MSDP or CC storage server created on one of them. (Use the nbmaster as the other master server for the script execution)
3. Trust relationship established between the two NBU masters.

Run cli in AIRAPIs directory
Go run AIRAPIs.go -nbmaster <master server name> -username <username> -password <passwd>

The script can also create new MSDP storage server (with creds as a/a) depending on user inputs.
Further lists the replication candidates based on the no of trusted master servers and storage server (MSDP and CC) on them.
User need to select one of the replication candidate to create AIR relationship on the earlier created MSDP/CC sts or existing one.
User can delete any existing AIR relationship as well.

