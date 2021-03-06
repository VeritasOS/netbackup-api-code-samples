#Load module netbackup.pm from current directory
use lib"../.";

use gateway;
use storage::storage;
use Getopt::Long qw(GetOptions);
sub printUsage {
  print "\nUsage : perl patch_storage_unit.pl -nbmaster <master_server> -username <username> -password <password> -payload <payload file path> -stu_name <stu name>[-domainname <domain_name>] [-domaintype <domain_type>]\n\n";
  die;
}

my $master_server;
my $username;
my $password;
my $payload_file;
my $stu_name;
my $domainname;
my $domaintype;

GetOptions(
'nbmaster=s' => \$master_server,
'username=s' => \$username,
'password=s' => \$password,
'payload=s'	 => \$payload_file,
'stu_name=s'  => \$stu_name,
'domainname=s' => \$domain_name,
'domaintype=s' => \$domain_type,
) or printUsage();

if (!$master_server || !$username || !$password) {
  printUsage();
}

my $token = gateway::perform_login($master_server, $username, $password, $domain_name, $domain_type);

my $jsonString = storage::patch_storage_unit($master_server, $token, $payload_file, $stu_name);
print "$jsonString\n";

gateway::perform_logout($master_server, $token);