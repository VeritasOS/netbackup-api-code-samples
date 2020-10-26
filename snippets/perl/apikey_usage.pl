#Load module netbackup.pm from current directory
use lib '.';

use netbackup;
use strict;
use warnings;
use Getopt::Long qw(GetOptions);

sub printUsage {
  print "\nUsage : perl apikey_usage.pl -nbmaster <master_server> -apikey <apikey> [--verbose]\n";
  print "-nbmaster : Name of the NetBackup master server\n";
  print "-apikey : API key to be used instead of JWT";
  print "--verbose : Detail logging\n\n";
  die;
}

my $fqdn_hostname;
my $apikey;
my $verbose;

GetOptions(
'nbmaster=s' => \$fqdn_hostname,
'apikey=s' => \$apikey,
'verbose' => \$verbose
) or printUsage();

if (!$fqdn_hostname || !$apikey) {
  printUsage();
}

if($verbose){
  print "\nRecieved the following parameters : \n";
  print " FQDN Hostname : $fqdn_hostname\n";
  print " API key : $apikey\n";
}
print "\n";

print "\nUsing API key [$apikey] instead of JWT token to trigger job REST API\n\n";
my $jsonstring = netbackup::getJobs($fqdn_hostname, $apikey);

print "\nNetBackup Jobs:\n";
netbackup::displayJobs($jsonstring);

netbackup::logout($fqdn_hostname, $apikey);
print "\n";
