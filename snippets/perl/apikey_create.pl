#Load module netbackup.pm from current directory
use lib '.';

use strict;
use warnings;

use Getopt::Long qw(GetOptions);

use netbackup;
use apikeys;

sub printUsage {
  print "\nUsage : perl apikey_create.pl -nbmaster <master_server> -login_username <login_username> -login_password <login_password> [-login_domainname <login_domain_name> -login_domaintype <domain_type>] [-apikey_username <apikey_username> -apikey_domainname <apikey_domain_name> -apikey_domaintype <domain_type>] -expiryindays <expiry_in_days> -description <description> [--verbose]\n\n";
  print "-nbmaster : Name of the NetBackup master server\n";
  print "-login_username : User name of the user performing action\n";
  print "-login_password : Password of the user performing action\n";
  print "-login_domainname : Domain name of the user performing action\n";
  print "-login_domaintype : Domain type of the user performing action\n";
  print "-apikey_username : (Optional) User name of the user for whom API key needs to be generated. Optional in case API key is to be generated for self\n";
  print "-apikey_domainname : Domain name of the user for whom API key needs to be generated. Optional in case API key is to be generated for self\n";
  print "-apikey_domaintype : Domain type of the user for whom API key needs to be generated. Optional in case API key is to be generated for self\n";
  print "-expiryindays : Number of days from today after which API key should expire\n";
  print "-description : A textual description to be associated with API key\n";
  print "--verbose : Detail logging\n\n\n";
  die;
}

my $fqdn_hostname;
my $login_username;
my $login_password;
my $login_domainname;
my $login_domaintype;
my $apikey_username;
my $apikey_domainname;
my $apikey_domaintype;
my $verbose;
my $expiryindays;
my $description;

GetOptions(
	'nbmaster=s' => \$fqdn_hostname,
	'login_username=s' => \$login_username,
	'login_password=s' => \$login_password,
	'login_domainname=s' => \$login_domainname,
	'login_domaintype=s' => \$login_domaintype,
	'apikey_username=s' => \$apikey_username,
	'apikey_domainname=s' => \$apikey_domainname,
	'apikey_domaintype=s' => \$apikey_domaintype,
	'expiryindays=s' => \$expiryindays,
	'description=s' => \$description,
	'verbose' => \$verbose
) or printUsage();

if (!$fqdn_hostname || !$login_username || !$login_password || !$expiryindays || !$description) {
  printUsage();
}

if($verbose){
  print "\nRecieved the following parameters : \n";
  print " FQDN Hostname : $fqdn_hostname\n";
  print " Login Username : $login_username\n";
  print " Login Password : $login_password\n";
  print " Login Domain Name : $login_domainname\n" if (defined $login_domainname);
  print " Login Domain Type : $login_domaintype\n" if (defined $login_domaintype);
  print " API Key Username : $apikey_username\n" if (defined $apikey_username);
  print " API Key Domain Name : $apikey_domainname\n" if (defined $apikey_domainname);
  print " API Key Domain Type : $apikey_domaintype\n" if (defined $apikey_domaintype);
  print " Expiry period in days : $expiryindays\n";
  print " Description : $description\n";
}

print "\nLogging in to NetBackup using user-credentials of user [$login_username]\n" if($verbose);
my $token;
if (defined $login_domainname && defined $login_domaintype) {
  $token = netbackup::login($fqdn_hostname, $login_username, $login_password, $login_domainname, $login_domaintype);
}
else{
  $token = netbackup::login($fqdn_hostname, $login_username, $login_password);
}

if(!defined $token) {
	print "\nFailed to login using credentials provided for user [$login_username]\n";
	exit -1;
}
print "\nSuccessfully acquired auth-token" if($verbose);

my($apikey, $apikey_tag, $apikey_expiry);
my $is_success = 0;
if (defined $apikey_username and defined $apikey_domainname and defined $apikey_domaintype) {
	print "\nUser [$login_username] creating API key for user [$apikey_username]" if($verbose);
	$is_success = apikeys::create_apikey($fqdn_hostname, $token, $expiryindays, $description, \$apikey, \$apikey_tag, \$apikey_expiry, $apikey_username, $apikey_domainname, $apikey_domaintype);
}
else {
	print "\n [$login_username] creating API key for self" if($verbose);
	$is_success = apikeys::create_apikey($fqdn_hostname, $token, $expiryindays, $description, \$apikey, \$apikey_tag, \$apikey_expiry);
}
if (!$is_success) {
	print "\nFailed to create API key\n";
	exit -1;
}
print "\nSuccessfully created API key" if($verbose);

print "\nAPI Key : [" . $apikey . "]";
print "\nAPI Key Tag : [" . $apikey_tag . "]";
print "\nAPI Key Expiration : [" . $apikey_expiry. "]";

netbackup::logout($fqdn_hostname, $token);
print "\n";

exit 0;
