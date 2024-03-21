#Load module netbackup.pm from current directory
use lib '.';

use netbackup;
use strict;
use warnings;
use Getopt::Long qw(GetOptions);

sub printUsage {
  print "\nUsage : perl get_vm_servers.pl -nbmaster <master_server> -username <username> -password <password> [-domainname <domain_name>] [-domaintype <domain_type>] [--verbose]\n\n";
  die;
}

my $fqdn_hostname;
my $username;
my $password;
my $domainname;
my $domaintype;
my $verbose;

GetOptions(
'nbmaster=s' => \$fqdn_hostname,
'username=s' => \$username,
'password=s' => \$password,
'domainname=s' => \$domainname,
'domaintype=s' => \$domaintype,
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
}

print "\n";
my $myToken;
if ($domainname && $domaintype) {
  $myToken = netbackup::login($fqdn_hostname, $username, $password, $domainname, $domaintype);
}
else{
  $myToken = netbackup::login($fqdn_hostname, $username, $password);
}

my $jsonstring = netbackup::getVM_Servers($fqdn_hostname, $myToken);

print "\nVM servers:\n";
netbackup::displayVM_Servers($jsonstring);

netbackup::logout($fqdn_hostname, $myToken);
print "\n";
