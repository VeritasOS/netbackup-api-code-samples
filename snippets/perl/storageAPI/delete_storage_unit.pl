#Load module netbackup.pm from current directory
use lib"../.";

use gateway;
use storage;
use Getopt::Long qw(GetOptions);
sub printUsage {
  print "\nUsage : perl delete_storage_unit.pl -nbmaster <master_server> -username <username> -password <password> -stu_name <Storage unit name> [-domainname <domain_name>] [-domaintype <domain_type>]\n\n";
  die;
}

my $master_server;
my $username;
my $password;
my $stu_name;
my $domainname;
my $domaintype;

GetOptions(
'nbmaster=s' => \$master_server,
'username=s' => \$username,
'password=s' => \$password,
'stu_name=s'	 => \$stu_name,
'domainname=s' => \$domain_name,
'domaintype=s' => \$domain_type,
) or printUsage();

if (!$master_server || !$username || !$password) {
  printUsage();
}

my $token = gateway::perform_login($master_server, $username, $password, $domain_name, $domain_type);

my $jsonString = storage::delete_storage_unit($master_server, $token, $stu_name);
print "$jsonString\n";

gateway::perform_logout($master_server, $token);
