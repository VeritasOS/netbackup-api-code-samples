### NetBackup API Code Samples

Contains code samples of using NetBackup REST APIs in different scripting/programming languages.

##### Disclaimer
These samples are only meant to be used as a reference. Please do not use these in production.

##### Executing the 'snippets'

The `snippets` folder contains code samples to invoke NetBackup APIs using different scripting/programming languages. 
These are usually simple examples that demonstrate specific API. 

Pre-requisites:

- NetBackup 8.1.1 or higher
- See the script's README for the corresponding requirements and usage


##### Executing the 'recipes'

The `recipes` folder contains code samples to invoke NetBackup APIs using different scripting/programming languages. 
These are usually examples of usage of multiple APIs covering specific use-cases.

Pre-requisites:

- NetBackup 8.1.2 or higher
- See the script's README for the corresponding requirements and usage



##### Tools
The `tools` folder contains utilities that have proven useful in the development of projects using NetBackup APIs, but do not provide any API usage examples.  Again, these tools are not for production use, but they may be of some use in your work.

#### NetBackup 8.3 RBAC Design Shift
NetBackup 8.3 introduced a major change in its RBAC configuration and enforcement design.  

RBAC was introduced to NetBackup in the 8.1.2 release, offering access control for a limited number of security settings and workloads.  That access control configuration was based on a dynamic object-level enforcement model using “Access Rules”.

With the NetBackup 8.3 release, RBAC has moved away from the dynamic access rule design.  
The new RBAC allows more granular permissions, improved flexibility and greater control. The RBAC design is now based on Access Control Lists (ACLs) and closely follows the ANSI INCITS 359-2004.  While the earlier design of RBAC enforcement was dynamic in nature, the new RBAC is static in its configuration.

The system-defined roles shipped with NetBackup also changed from 8.1.2 to the 8.3 release.  In 8.1.2, there were three system-defined roles available for RBAC configuration.  In the 8.3 release, this was simplified to offer a single “Administrator” role which has all privileges for RBAC.

Due to the significant design shift, automatic upgrade conversion of 8.1.2 RBAC roles to the new 8.3 roles is not feasible.  However, tools are available to migrate the Backup administrator role and create a new Security administrator role for the users that had the old RBAC Security administrator role. Other roles must be reconfigured manually. 
There is also a script in this repository available to generate templated NetBackup roles.
See **/recipes/perl/rbac-roles/rbac_role_templates.pl**


Any API keys in use prior to upgrade will still be valid, however, the underlying access granted those API keys must
 be reconfigured using the new RBAC configuration, after which any active user sessions must be removed.
A utility script exists in this repository to help convert active API keys after upgrade to NetBackup 8.3.  
See **/recipes/perl/access-control/access_control_api_requests.pl**

Most of the API examples in this repository assume a valid JWT (Json Web Token) or API Key issued by NetBackup and do not incorporate role configuration as part of the script. 
However, there may be some examples which do configure RBAC as part of the script and have not yet been updated to use the RBAC design.
