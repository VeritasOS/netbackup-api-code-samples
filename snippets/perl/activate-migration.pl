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
  print "\nUsage : perl activate_migration.pl -nbmaster <master_server> -login_username <login_username> -login_password <login_password> [-login_domainname <login_domain_name> -login_domaintype <domain_type>] [-reason <reason>] [--force] [--verbose]\n\n";
  print "-nbmaster         : Name of the NetBackup master server\n";
  print "-login_username   : User name of the user performing action\n";
  print "-login_password   : Password of the user performing action\n";
  print "-login_domainname : Domain name of the user performing action\n";
  print "-login_domaintype : Domain type of the user performing action\n";
  print "-reason           : A textual description to activate the new CA\n";
  print "--force           : Forcefully activate the new CA in migration process\n";
  print "--verbose         : Detail logging\n\n\n";
  die;
}

my $protocol = "https";
my $port = 1556;
my $fqdn_hostname;
my $login_username;
my $login_password;
my $login_domainname;
my $login_domaintype;
my $reason;
my $verbose;
my $force = 0;

GetOptions(
	'nbmaster=s' => \$fqdn_hostname,
	'login_username=s' => \$login_username,
	'login_password=s' => \$login_password,
	'login_domainname=s' => \$login_domainname,
	'login_domaintype=s' => \$login_domaintype,
	'reason=s' => \$reason,
        'verbose' => \$verbose,
        'force' => \$force
) or printUsage();

if (!$fqdn_hostname || !$login_username || !$login_password || !$login_domainname || !$login_domaintype) {
  printUsage();
}

if($verbose){
  print "\nRecieved the following parameters : \n";
  print " FQDN Hostname : $fqdn_hostname\n";
  print " Login Username : $login_username\n";
  print " Login Password : $login_password\n";
  print " Login Domain Name : $login_domainname\n" if (defined $login_domainname);
  print " Login Domain Type : $login_domaintype\n" if (defined $login_domaintype);
  print " Reason for activate the new CA: $reason\n" if (defined $reason);
  print " Force:  $force\n\n";
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
    migration::activate_migration($base_url, $token, $reason, $force);
} else {
    migration::activate_migration($base_url, $token, $force);
}
   
netbackup::logout($fqdn_hostname, $token);

print "\n";

exit 0;
