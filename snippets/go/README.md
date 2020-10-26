# NetBackup package for GO language

This package gives a wrapper to call NetBackup APIs.
There are few raw functions that can be used generically to 
call NetBackup APIs. 
There are also some specific call that creates the URL, calls the API, parse the output and return back the data.


## Building and executing sample program
Pre-requisites:
- NetBackup 8.1.1 or higher
- Go version 1.10.2

Use the following commands to build and execute the sample program
```sh
$ cd netbackup
$ # Build sample program for fetching server mappings
$ go build example/get_nb_mapping.go
$ ./get_nb_mapping

$ # Build sample program for fetching catalog images
$ go build example/get_nb_images.go
$ ./get_nb_images

$ # Build sample program for fetching backup jobs
$ go build example/get_nb_jobs.go
$ ./get_nb_jobs
```
