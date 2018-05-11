Examine permissions of the current login token

Compatibility
———————————————————————————————————————————————————
NetBackup 8.1.1 Linux/Unix master server


Who is this for?
---------------------------------------------------
NetBackup Administrators
IT Operations Teams


What is This?
---------------------------------------------------
The NetBackup REST API will authenticate any valid user account provided to the login API. Not every user
has permissions to do anything in NetBackup, however, and this script simply dumps the payload of the 
token returned by NetBackup.  The token is a JSON Web Token (jwt - see RFC7519) and the "payload" here
refers to the payload section of the jwt. The payload contains some standard JWT "claims" as well as some
NetBackup-specific claims.  Of particular interest is teh contents of the claim "authz_context" which 
represents the permissions "granted" to this user.

Setup:
---------------------------------------------------
Perl 5.20.2 or later

PERl modules required
++ JSON
++ Compress::Zlib
++ MIME::Base64

This utility is written in perl and it has been developed and tested on RedHat Linux.


Overview:
---------------------------------------------------
Occasionally users have been stumped by the fact that the NetBackup REST login API successfully authenticates
a user, but the resulting token results in http 401 Not Authorized responses to any of the other REST apis.

The cause is nearly always that the user is not a known NetBackup administrator.  Valid known NetBackup
administrators are "root" on unix, "administrator" on windows, or any user account configured for Enhanced
Auditing. For non-root users Enhanced Auditing is generally the answer and a helper script makeEAadmi.pl is
also provided.


Outline:
---------------------------------------------------
A successful call to https://<yourmaster>:1556/netbackup/gateway/login will return a JSON Web Token in its
response body.  Use that token as a (string) argument to this script and the claims are displayed as a JSON
document.  In NetBackup 8.1.1, permission is generally all-or-nothing.  Look for the specific API permissions
in the "authz_context" claim such as 
      "LIST_JOBS" : [
         "*"
      ],
This tells you that this token is issued with a grant to list jobs, and permission is on ALL jobs - ["*"].

In addition you may see a claim 
	"is_admin" : "true",
this indicates that your jwt is issued with the intent of granting all access a NetBackup administrator would
have in previous versions of NetBackup.

If the claims you see do not provide the permission you expected, your user account is not an administrator
known to NetBackup. 
