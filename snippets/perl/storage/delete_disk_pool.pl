#Load module netbackup.pm from current directory
use lib"../.";

use gateway;
use storage::storage;
use Getopt::Long qw(GetOptions);
sub printUsage {
  print "\nUsage : perl delete_disk_pool.pl -nbmaster <master_server> -username <username> -password <password> -dpid <disk pool id> [-domainname <domain_name>] [-domaintype <domain_type>]\n\n";
  die;
}

my $master_server;
my $username;
my $password;
my $dpid;
my $domainname;
my $domaintype;

GetOptions(
'nbmaster=s' => \$master_server,
'username=s' => \$username,
'password=s' => \$password,
'dpid=s'	 => \$dpid,
'domainname=s' => \$domain_name,
'domaintype=s' => \$domain_type,
) or printUsage();

if (!$master_server || !$username || !$password) {
  printUsage();
}

my $token = gateway::perform_login($master_server, $username, $password, $domain_name, $domain_type);

my $jsonString = storage::delete_disk_pool($master_server, $token, $dpid);
print "$jsonString\n";

gateway::perform_logout($master_server, $token);
