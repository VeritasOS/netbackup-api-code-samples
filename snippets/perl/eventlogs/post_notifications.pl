#Load module netbackup.pm
use lib"../.";

use netbackup;
use gateway;
use eventlogs::eventlogs;
use Getopt::Long qw(GetOptions);
sub printUsage {
  print "\nUsage : perl post_notifications.pl -nbmaster <master_server> -username <username> -password <password> -payload <payload file path> [-domainname <domain_name>] [-domaintype <domain_type>]\n\n";
  die;
}

my $master_server;
my $username;
my $password;
my $payload;
my $domainname;
my $domaintype;

GetOptions(
'nbmaster=s' => \$fqdn_hostname,
'username=s' => \$username,
'password=s' => \$password,
'domainname=s' => \$domainname,
'domaintype=s' => \$domaintype,
'payload=s' => \$payload,
'verbose' => \$verbose
) or printUsage();


if (!$fqdn_hostname || !$username || !$password || !$payload) {
  printUsage();
}

if($verbose){
  print "\nRecieved the following parameters : \n";
  print " FQDN Hostname : $fqdn_hostname\n";
  print " Username : $username\n";
  print " Password : $password\n";
  if ($domainname) {
    print " Domain Name : $domainname\n";
  }
  if ($domaintype) {
    print " Domain Type : $domaintype\n";
  }
  if ($filter) {
    print " Filter : $filter\n";
  }
}

print "\n";
my $myToken;
my $jsonstring;

if ($domainname && $domaintype) {
  $myToken = netbackup::login($fqdn_hostname, $username, $password, $domainname, $domaintype);
} else {
  $myToken = netbackup::login($fqdn_hostname, $username, $password);
}

my $jsonString = eventlogs::postNotifications($fqdn_hostname, $myToken, $payload);
print "$jsonString\n";

gateway::perform_logout($fqdn_hostname, $myToken);
