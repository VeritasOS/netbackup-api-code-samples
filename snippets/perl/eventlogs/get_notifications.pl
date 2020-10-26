#Load module netbackup.pm
use lib"../.";

use netbackup;
use strict;
use eventlogs::eventlogs;
use warnings;
use Getopt::Long qw(GetOptions);

sub printUsage {
  print "\nUsage : perl get_notifications.pl -nbmaster <master_server> -username <username> -password <password> [-domainname <domain_name>] [-domaintype <domain_type>] [-filter <filter>] [--verbose]\n\n";
  die;
}

my $fqdn_hostname;
my $username;
my $password;
my $domainname;
my $domaintype;
my $filter;
my $verbose;

GetOptions(
'nbmaster=s' => \$fqdn_hostname,
'username=s' => \$username,
'password=s' => \$password,
'domainname=s' => \$domainname,
'domaintype=s' => \$domaintype,
'filter=s' => \$filter,
'verbose' => \$verbose
) or printUsage();

if (!$fqdn_hostname || !$username || !$password) {
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

if ($filter) {
  $jsonstring = eventlogs::getNotificationsByFilter($fqdn_hostname, $myToken, $filter);
} else {
  $jsonstring = eventlogs::getNotificationsByFilter($fqdn_hostname, $myToken);
}


print "\nNotifications:\n";
eventlogs::displayNotifications($jsonstring);

netbackup::logout($fqdn_hostname, $myToken);
print "\n";
