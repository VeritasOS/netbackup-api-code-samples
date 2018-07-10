Create API user for NetBackup 8.1.1 using Enhanced Auditing

Compatibility
———————————————————————————————————————————————————
NetBackup 8.1.1 Linux/Unix master server
NetBackup REST API version 1.0 
(content type is application/vnd.netbackup+json;version=1.0)


Who is this for?
---------------------------------------------------
NetBackup Administrators
IT Operations Teams


What is This?
---------------------------------------------------
This script is provided as a demonstration of how to create a non-root admin account to be used for the 
purpose of invoking the NetBackup REST APIs.

This demonstration is written as a perl script and uses the perl module “UserAgent” to invoke https 
requests to the NetBackup REST APIs.


Setup:
---------------------------------------------------
Perl 5.20.2 or later

PERl modules required
++ LWP::UserAgent
++ JSON
++ HTTP

This utility is written in perl, and is meant to be run directly on the NetBackup master server.  The caller of this utility must have sufficient privileges to execute a NetBackup command line on the Master.  Although 
it has been developed and tested on RedHat Linux, it should be compatible with any non-windows NetBackup 
master server.  

This utility can be easily modified to work with NetBackup master servers running on Windows platforms 
as well, simply change the path to the necessary command lines and pay attention to the domain types of 
the user account you are authenticating which will likely be the windows local host or an Active Directory 
account.


Overview:
---------------------------------------------------
This script provides an example of how to login to the NetBackup Rest APIs and get a "token" to be used in 
subsequent REST API calls.  In this demonstration, the utility creates a new "fictional user" in NetBackup
using the mechanisms described by the "Enhanced Auditing" mechanism in NetBackup. At the time of this writing, 
NetBackup 8.1.1 will accept root, local/administrator and any Enhanced Auditing user as a fully-privileged 
REST API user.

Once an administrator is created, the script demonstrates how to "login" to the REST API services and get 
a token with 24 hour validity (this is NOT configurable), and then use this token to call other REST APIs. 


Outline:
---------------------------------------------------
Setup: First a fictional user is added to "vx domain" using standard NetBackup command lines (bpnbat) for
the purposes of testing.  Next, this new fictional user is added to the list of non-root administrators 
in the Enhanced Auditing configuration, making this account pseudo root privileged for the purposes of 
NetBackup administration.

APIs: The new administrator user is logged into the REST APIs and receives a session token.  This token is
captured and included in each subsequent API call as the contents of the standard http "Authorization" 
header. The Front End Data report is run as an example of this. Finally the user is logged out of 
NetBackup REST which ends the session associated with that token.

Cleanup: Remove our fictional user from the Enhanced Auditing users list and remove the user account 
from the vx domain.

  
