#Load module netbackup.pm from current directory
use lib".";

use gateway;
use asset_group;
use Getopt::Long qw(GetOptions);
sub printUsage {
  print "\nUsage : perl delete_nb_asset_groups.pl -nbmaster <master_server> -username <username> -password <password> [-domainname <domain_name>] [-domaintype <domain_type>] -guid <assetGroupGuid>\n\n";
  die;
}

my $master_server;
my $username;
my $password;
my $domain_name;
my $domain_type;

GetOptions(
'nbmaster=s' => \$master_server,
'username=s' => \$username,
'password=s' => \$password,
'domainname=s' => \$domain_name,
'domaintype=s' => \$domain_type,
'guid=s' => \$guid
) or printUsage();

if (!$master_server || !$username || !$password || !$guid) {
  printUsage();
}

my $token = gateway::perform_login($master_server, $username, $password, $domain_name, $domain_type);

asset_group::delete_asset_groups($master_server, $token, $guid);

gateway::perform_logout($master_server, $token);
