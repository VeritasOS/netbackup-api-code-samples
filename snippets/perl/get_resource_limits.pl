#Load module netbackup.pm from current directory
use lib '.';

use netbackup;
use strict;
use warnings;
use Getopt::Long qw(GetOptions);

sub printUsage {
  print "\nUsage : perl get_resource_limits.pl -nbmaster <master_server> -username <username> -password <password> -workloadtype <workloadtype> [-domainname <domain_name>] [-domaintype <domain_type>] [--verbose]\n\n";
  die;
}

my $fqdn_hostname;
my $username;
my $password;
my $workloadtype;
my $domainname;
my $domaintype;
my $verbose;

GetOptions(
'nbmaster=s' => \$fqdn_hostname,
'username=s' => \$username,
'password=s' => \$password,
'workloadtype=s' => \$workloadtype,
'domainname=s' => \$domainname,
'domaintype=s' => \$domaintype,
'verbose' => \$verbose
) or printUsage();

if (!$fqdn_hostname || !$username || !$password || !$workloadtype) {
  printUsage();
}

if($verbose){
  print "\nRecieved the following parameters : \n";
  print " FQDN Hostname : $fqdn_hostname\n";
  print " Username : $username\n";
  print " Password : $password\n";
  print " Workload Type : $workloadtype\n";
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

my $jsonstring = netbackup::getResourceLimits($fqdn_hostname, $myToken, $workloadtype);

print "\n Resource limits for a given workload type:\n";
netbackup::displayResourceLimits($jsonstring);

netbackup::logout($fqdn_hostname, $myToken);
print "\n";
