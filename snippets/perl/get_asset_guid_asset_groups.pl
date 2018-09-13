#Load module netbackup.pm from current directory
use lib".";

use gateway;
use asset_group;
use Getopt::Long qw(GetOptions);
sub printUsage {
  print "\nUsage : perl get_asset_guid_asset_groups.pl -nbmaster <master_server> -username <username> -password <password> [-domainname <domain_name>] [-domaintype <domain_type>] -guid <guid>\n\n";
  die;
}

my $master_server;
my $username;
my $password;
my $domain_name;
my $domain_type;
my $guid;

GetOptions(
'nbmaster=s' => \$master_server,
'username=s' => \$username,
'password=s' => \$password,
'domainname=s' => \$domain_name,
'domaintype=s' => \$domain_type,
'guid=s' => \$guid,
) or printUsage();

if (!$master_server || !$username || !$password) {
  printUsage();
}

my $token = gateway::perform_login($master_server, $username, $password, $domain_name, $domain_type);

my $jsonString = asset_group::get_asset_guid_asset_groups($master_server, $token, $guid);
print "$jsonString\n";

gateway::perform_logout($master_server, $token);
