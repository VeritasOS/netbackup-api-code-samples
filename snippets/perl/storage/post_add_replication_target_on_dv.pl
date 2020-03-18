#Load module netbackup.pm from current directory
use lib"../.";

use gateway;
use storage::storage;
use Getopt::Long qw(GetOptions);
sub printUsage {
  print "\nUsage : perl post_add_replication_target_on_dv.pl -nbmaster <master_server> -username <username> -password <password> -stsid <storage server id> -dvid <diskvolume id> -payload <payload file path> [-domainname <domain_name>] [-domaintype <domain_type>]\n\n";
  die;
}

my $master_server;
my $username;
my $password;
my $payload_file;
my $domainname;
my $domaintype;

GetOptions(
'nbmaster=s'  => \$master_server,
'username=s'   => \$username,
'password=s'   => \$password,
'stsid=s'      => \$stsid,
'dvid=s'       => \$dvid,
'payload=s'    => \$payload_file,
'domainname=s' => \$domain_name,
'domaintype=s' => \$domain_type,
) or printUsage();

if (!$master_server || !$username || !$password || !$stsid || !$dvid) {
  printUsage();
}

my $token = gateway::perform_login($master_server, $username, $password, $domain_name, $domain_type);

my $jsonString = storage::post_add_replication_target_on_dv($master_server, $token, $stsid, $dvid, $payload_file);
print "$jsonString\n";

gateway::perform_logout($master_server, $token);
