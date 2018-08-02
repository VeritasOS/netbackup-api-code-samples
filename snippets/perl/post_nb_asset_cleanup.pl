#Load module netbackup.pm from current directory
use lib '.';

use netbackup;
use strict;
use warnings;
use Getopt::Long qw(GetOptions);
use JSON;

sub printUsage {
  print "\nUsage : perl post_nb_asset_cleanup.pl -nbmaster <master_server> -username <username> -password <password> -filter <filter> -cleanuptime <cleanuptime> [-domainname <domain_name>] [-domaintype <domain_type>] [--verbose]\n\n";
  die;
}

my $fqdn_hostname;
my $username;
my $password;
my $filter;
my $cleanuptime;
my $domainname;
my $domaintype;
my $verbose;

GetOptions(
'nbmaster=s' => \$fqdn_hostname,
'username=s' => \$username,
'password=s' => \$password,
'filter=s' => \$filter,
'cleanuptime=s' => \$cleanuptime,
'domainname=s' => \$domainname,
'domaintype=s' => \$domaintype,
'verbose' => \$verbose
) or printUsage();

if (!$fqdn_hostname || !$username || !$password || !$filter || !$cleanuptime) {
  printUsage();
}

if($verbose){
  print "\nRecieved the following parameters : \n";
  print " FQDN Hostname : $fqdn_hostname\n";
  print " Username : $username\n";
  print " Password : $password\n";
  print " Filter: $filter\n";
  print " CleanupTime $cleanuptime\n";
  if ($domainname) {
    print " Domain Name : $domainname\n";
  }
  if ($domaintype) {
    print " Domain Type : $domaintype\n";
  }
}

print "\n";
my $myToken;
if ($domainname && $domaintype) {
  $myToken = netbackup::login($fqdn_hostname, $username, $password, $domainname, $domaintype);
}
else{
  $myToken = netbackup::login($fqdn_hostname, $username, $password);
}

my $jsonstring = netbackup::getAssetsByFilter($fqdn_hostname, $myToken, $filter);
my $page_count = decode_json($jsonstring)->{'meta'}->{'pagination'}->{'count'};

if ($page_count ne 0 ){
   print "\nNetBackup Assets returned by filter: $filter\n";
   netbackup::displayAssets($jsonstring);
   netbackup::cleanAssets($fqdn_hostname, $myToken, $jsonstring, $cleanuptime);
} else {
   print "\n Your filter: $filter did not return any asset."
}

netbackup::logout($fqdn_hostname, $myToken);
print "\n";
