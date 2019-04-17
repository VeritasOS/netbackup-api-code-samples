#Load module netbackup.pm from current directory
use lib '.';

use netbackup;
use strict;
use warnings;
use Getopt::Long qw(GetOptions);

sub printUsage {
  print "\nUsage : perl get_vm_server.pl -nbmaster <master_server> -username <username> -password <password> -servername <servername> [-domainname <domain_name>] [-domaintype <domain_type>] [--verbose]\n\n";
  die;
}

my $fqdn_hostname;
my $username;
my $password;
my $servername;
my $domainname;
my $domaintype;
my $verbose;

GetOptions(
'nbmaster=s' => \$fqdn_hostname,
'username=s' => \$username,
'password=s' => \$password,
'servername=s' => \$servername,
'domainname=s' => \$domainname,
'domaintype=s' => \$domaintype,
'verbose' => \$verbose
) or printUsage();

if (!$fqdn_hostname || !$username || !$password || !$servername) {
  printUsage();
}

if($verbose){
  print "\nRecieved the following parameters : \n";
  print " FQDN Hostname : $fqdn_hostname\n";
  print " Username : $username\n";
  print " Password : $password\n";
  print " Servername : $servername\n";
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

my $jsonstring = netbackup::getVM_Server($fqdn_hostname, $myToken, $servername);

print "\nVM Server:\n";
netbackup::displayVM_Server($jsonstring);

netbackup::logout($fqdn_hostname, $myToken);
print "\n";
