### NetBackup API Code Samples for go (often referred to as golang)

This directory contains code samples to invoke NetBackup Catalog (Image) APIs using go.

#### Disclaimer

These scripts are only meant to be used as a reference. If you intend to use them in production, use it at your own risk.

#### Pre-requisites:

- Image update related API samples will work on NetBackup 8.2 or higher.
- go1.10.2 or higher

#### Executing the recipes using go

Use the following commands to run the go samples.
- The following assumes you set MASTERSERVER, USERID,PASSWORD, backupID, serverName, serverType and optionValue in your environment.
- `go run ./update_nb_images.go -nbmaster ${MASTERSERVER} -username ${USERID} -password ${PASSWORD} -backupId ${backupID}`
- `go run ./update_nb_images_by_server_name.go -nbmaster ${MASTERSERVER} -username ${USERID} -password ${PASSWORD} -serverName ${serverName}`
- `go run ./update_nb_images_by_server_type.go -nbmaster ${MASTERSERVER} -username ${USERID} -password ${PASSWORD} -serverType ${serverType}`
- `go run ./update_nb_images_primary_copy.go -nbmaster ${MASTERSERVER} -username ${USERID} -password ${PASSWORD} -optionValue ${optionValue}`
