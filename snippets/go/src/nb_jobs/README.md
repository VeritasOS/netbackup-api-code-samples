Call Netbackup APIs

Calls the API and returns the data

Call Get Admin/NetBackup/Jobs API and returns all Netbackup Admin Jobs

Also, returns all the NetBackup jobs of the jobType 'Backup'


#######Use following command to execute the program

  go build get-nb-jobs.go
  go run ./get-nb-jobs.go -nbmaster rsvlmvc01vm231.rmnus.sen.symantec.com  -username <USERNAME> -password <PASSWORD> 
