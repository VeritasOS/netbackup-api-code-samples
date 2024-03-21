#!/usr/bin/env perl

use Getopt::Long;

require 'api_requests.pl';
require 'access_control_api_requests.pl';

my $hostname;
my $username;
my $password;
my $domain_name;
my $domain_type;
my $role_name;
my $role_description;

my $base_url;
my $token;

GetOptions(
    'hostname=s' => \$hostname,
    'username=s' => \$username,
    'password=s' => \$password,
    'domain_name=s' => \$domain_name,
    'domain_type=s' => \$domain_type,
    'role_name=s' => \$role_name,
    'role_description=s' => \$role_description
) or pod2usage(2);

$hostname ne "" or die "Please provide a value for '--hostname'\n";

$username ne "" or die "Please provide a value for '--username'\n";

$password ne "" or die "Please provide a value for '--password'\n";

$role_name ne "" or die "Please provide a value for '--role_name'\n";

$base_url = "https://$hostname/netbackup";
$token = perform_login($base_url, $username, $password, $domain_name, $domain_type);

create_access_control_role($base_url, $token, $role_name, $role_description);


sub print_usage {
    say "Usage:";
    say "perl create_access_control_role.pl -hostname <master_server> -username <username> -password <password> -role_name <role_name> [-role_description <role_description>] [-domain_name <domain_name>] [-domain_type <domain_type>]";
}

