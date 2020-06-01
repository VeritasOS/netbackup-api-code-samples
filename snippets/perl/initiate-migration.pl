#Load module netbackup.pm from current directory
use lib '.';

use strict;
use warnings;
use LWP::UserAgent;
use LWP::Protocol::https;
print "LWP::UserAgent: ".LWP::UserAgent->VERSION,"\n";
print "LWP::Protocol::https: ".LWP::Protocol::https->VERSION,"\n";

use JSON;
use Getopt::Long qw(GetOptions);
use netbackup;
use migration;

sub printUsage {
  print "\nUsage : perl initiate-migration.pl -nbmaster <master_server> -login_username <login_username> -login_password <login_password> [-login_domainname <login_domain_name> -login_domaintype <domain_type>] -keysize <keysize> [-reason <reason>] [--verbose]\n\n";
  print "-nbmaster         : Name of the NetBackup master server\n";
  print "-login_username   : User name of the user performing action\n";
  print "-login_password   : Password of the user performing action\n";
  print "-login_domainname : Domain name of the user performing action\n";
  print "-login_domaintype : Domain type of the user performing action\n";
  print "-keysize          : Keysize of the CA\n";
  print "-reason           : A textual description to initiate the CA migration\n";
  print "--verbose         : Detail logging\n\n\n";
  die;
}

my $content_type_v4 = "application/vnd.netbackup+json;version=4.0";
my $protocol = "https";
my $port = 1556;
my $fqdn_hostname;
my $login_username;
my $login_password;
my $login_domainname;
my $login_domaintype;
my $reason;
my $key_size;
my $description;
my $verbose;

GetOptions(
	'nbmaster=s' => \$fqdn_hostname,
	'login_username=s' => \$login_username,
	'login_password=s' => \$login_password,
	'login_domainname=s' => \$login_domainname,
	'login_domaintype=s' => \$login_domaintype,
	'keysize=s' => \$key_size,
	'reason=s' => \$reason,
        'verbose' => \$verbose
) or printUsage();

if (!$fqdn_hostname || !$login_username || !$login_password || !$login_domainname || !$login_domaintype || !$key_size) {
  printUsage();
}

if($verbose){
  print "\nRecieved the following parameters : \n";
  print " FQDN Hostname : $fqdn_hostname\n";
  print " Login Username : $login_username\n";
  print " Login Password : $login_password\n";
  print " Login Domain Name : $login_domainname\n" if (defined $login_domainname);
  print " Login Domain Type : $login_domaintype\n" if (defined $login_domaintype);
  print " Keysize of the CA : $key_size\n";
  print " Reason for initiating migration : $reason\n" if (defined $reason);
}

my $ua = LWP::UserAgent->new(
                ssl_opts => { verify_hostname => 0, verify_peer => 0},
            );

my $base_url = "$protocol://$fqdn_hostname:$port/netbackup";

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

if (defined $reason) {
    migration::initiate_migration($base_url, $token, $key_size, $reason);
}
else {
    migration::initiate_migration($base_url, $token, $key_size);
} 

netbackup::logout($fqdn_hostname, $token);

print "\n";

exit 0;
