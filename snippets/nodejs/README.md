### NetBackup API Code Samples for Node.js

This directory contains code samples to invoke NetBackup REST APIs using node.js.

#### Disclaimer

These scripts are only meant to be used as a reference. If you intend to use them in production, use it at your own risk.

#### Pre-requisites:

- NetBackup 8.1.1 or higher
- node.js v8.9.4 or higher
- node.js modules: `https, fs, stdio, pem`
- openssl and openssl path should be configured in system path.

* To install node.js module, Run `npm install <module_name>`.

#### Executing the snippets in Node.js

Before running API samples, run following command to store CA certificate.
- `node get_ca_cert.js --nbmaster <master_server> [--port <port_number>] [--verbose]`
or
- `node get_ca_cert.js -n<master_server> [-pr <port_number>] [-v]`

Use the following commands to run the node.js samples.
- `node get_nb_images.js --nbmaster <master_server> [--port <port_number>] --username <username> --password <password> [--domainname <domain_name>] [--domaintype <domain_type>] [--verbose]`
or
- `node get_nb_hosts.js -n<master_server> [-pr <port_number>] -u <username> -p <password> [-d <domain_name>] [-t <domain_type>] [-v]`