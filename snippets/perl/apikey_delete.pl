#Load module netbackup.pm from current directory
use lib '.';

use strict;
use warnings;

use Getopt::Long qw(GetOptions);

use netbackup;
use apikeys;

sub printUsage {
  print "\nUsage : perl apikey_delete.pl -nbmaster <master_server> -login_username <login_username> -login_password <login_password> [-login_domainname <login_domain_name> -login_domaintype <domain_type>] -apikey_tag <apikey_tag> [--verbose]\n";
  print "-nbmaster : Name of the NetBackup master server\n";
  print "-login_username : User name of the user performing action\n";
  print "-login_password : Password of the user performing action\n";
  print "-login_domainname : Domain name of the user performing action\n";
  print "-login_domaintype : Domain type of the user performing action\n";
  print "-apikey_tag : Tag associate with API key to be deleted\n";
  print "--verbose : Detail logging\n\n\n";
  die;
}

my $fqdn_hostname;
my $login_username;
my $login_password;
my $login_domainname;
my $login_domaintype;
my $apikey_tag;
my $verbose;

GetOptions(
	'nbmaster=s' => \$fqdn_hostname,
	'login_username=s' => \$login_username,
	'login_password=s' => \$login_password,
	'login_domainname=s' => \$login_domainname,
	'login_domaintype=s' => \$login_domaintype,
	'apikey_tag=s' => \$apikey_tag,
	'verbose' => \$verbose
) or printUsage();

if (!$fqdn_hostname || !$login_username || !$login_password || !$apikey_tag) {
  printUsage();
}

if($verbose){
  print "\nReceived the following parameters : \n";
  print " FQDN Hostname : $fqdn_hostname\n";
  print " Login Username : $login_username\n";
  print " Login Password : $login_password\n";
  print " Login Domain Name : $login_domainname\n" if (defined $login_domainname);
  print " Login Domain Type : $login_domaintype\n" if (defined $login_domaintype);
  print " API Key Tag to be deleted : $apikey_tag\n";
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

print "\nUser [$login_username] deleting API key with tag [$apikey_tag]" if($verbose);
my $is_success = apikeys::delete_apikey($fqdn_hostname, $token, $apikey_tag);
if (!$is_success) {
	print "\nFailed to delete API key with tag [$apikey_tag]\n";
	exit -1;
}
print "\nSuccessfully deleted API key" if($verbose);

netbackup::logout($fqdn_hostname, $token);
print "\n";

exit 0;
